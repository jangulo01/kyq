package billing

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/store"
)

const (
	// LinkTTL is how long a Bold payment link accepts payments (research R1).
	LinkTTL = 30 * time.Minute
	// linkExpiryMargin covers clock skew with Bold before treating a still-ACTIVE link as expired.
	linkExpiryMargin = 2 * time.Minute
	// pollWindow: los pagos en curso se consultan a Bold durante 2 h (research R2).
	pollWindow = 2 * time.Hour
)

var (
	ErrNotFound          = errors.New("not found")
	ErrDocumentsNotOK    = errors.New("documents not ok")
	ErrPaymentInProgress = errors.New("payment in progress")
	ErrPriceNotSet       = errors.New("subscription price not set")
	ErrNotApproved       = errors.New("payment not approved")
	ErrReasonRequired    = errors.New("reason required")
	ErrInvalidManual     = errors.New("invalid manual payment")
	ErrInvalidPrice      = errors.New("invalid price")
	ErrInvalidSignature  = errors.New("invalid webhook signature")
)

// Service holds the subscription and payment use cases.
type Service struct {
	Store *store.Store
	// Bold is nil when KYQ_BOLD_ENV is empty: drivers then cannot pay online.
	Bold     BoldAPI
	Notify   *notify.Service
	CityCode string
	// WebhookSecret signs Bold webhooks (empty in the sandbox).
	WebhookSecret string
	Now           func() time.Time
	Logger        *slog.Logger
}

func (s *Service) now() time.Time {
	if s.Now != nil {
		return s.Now()
	}
	return time.Now()
}

func (s *Service) logger() *slog.Logger {
	if s.Logger != nil {
		return s.Logger
	}
	return slog.Default()
}

// Extend computes the new paid_until after an approved payment: one calendar month from the
// later of the current paid_until and the payment time (FR-015, research R3).
func Extend(paidUntil *time.Time, at time.Time) (from, until time.Time) {
	from = at
	if paidUntil != nil && paidUntil.After(at) {
		from = *paidUntil
	}
	return from, from.AddDate(0, 1, 0)
}

// Price is the monthly price of a city.
type Price struct {
	AmountMinor int64  `json:"amount_minor"`
	Currency    string `json:"currency"`
}

// CurrentPrice returns the price in force for the service city, or ErrPriceNotSet.
func (s *Service) CurrentPrice(ctx context.Context, q *store.Queries) (Price, error) {
	p, err := q.GetCurrentPrice(ctx, store.GetCurrentPriceParams{CityCode: s.CityCode, EffectiveFrom: s.now()})
	if store.IsNotFound(err) {
		return Price{}, ErrPriceNotSet
	}
	if err != nil {
		return Price{}, err
	}
	return Price{AmountMinor: p.AmountMinor, Currency: p.Currency}, nil
}

// PaymentView is the JSON of a payment (contracts: Payment).
type PaymentView struct {
	ID                  uuid.UUID  `json:"id"`
	AmountMinor         int64      `json:"amount_minor"`
	Currency            string     `json:"currency"`
	Method              string     `json:"method"`
	Status              string     `json:"status"`
	CheckoutURL         *string    `json:"checkout_url"`
	PaymentMethodDetail *string    `json:"payment_method_detail"`
	CoversFrom          *time.Time `json:"covers_from"`
	CoversUntil         *time.Time `json:"covers_until"`
	VoidReason          *string    `json:"void_reason"`
	CreatedAt           time.Time  `json:"created_at"`
}

// AdminPaymentView adds the audit fields admins see.
type AdminPaymentView struct {
	PaymentView
	ManualReference *string    `json:"manual_reference"`
	ReviewNote      *string    `json:"review_note"`
	CreatedBy       uuid.UUID  `json:"created_by"`
	VoidedBy        *uuid.UUID `json:"voided_by"`
}

func textPtr(t pgtype.Text) *string {
	if !t.Valid {
		return nil
	}
	s := t.String
	return &s
}

func timePtr(t pgtype.Timestamptz) *time.Time {
	if !t.Valid {
		return nil
	}
	v := t.Time
	return &v
}

func toView(p store.Payment) PaymentView {
	v := PaymentView{
		ID: p.ID, AmountMinor: p.AmountMinor, Currency: p.Currency, Method: string(p.Method), Status: string(p.Status),
		PaymentMethodDetail: textPtr(p.PaymentMethodDetail), CoversFrom: timePtr(p.CoversFrom),
		CoversUntil: timePtr(p.CoversUntil), VoidReason: textPtr(p.VoidReason), CreatedAt: p.CreatedAt,
	}
	// El checkout solo sirve mientras el pago está en curso.
	if p.Status == store.PaymentStatusCreated || p.Status == store.PaymentStatusProcessing {
		v.CheckoutURL = textPtr(p.CheckoutUrl)
	}
	return v
}

func toAdminView(p store.Payment) AdminPaymentView {
	v := AdminPaymentView{
		PaymentView: toView(p), ManualReference: textPtr(p.ManualReference), ReviewNote: textPtr(p.ReviewNote),
		CreatedBy: p.CreatedBy,
	}
	if p.VoidedBy.Valid {
		id := p.VoidedBy.UUID
		v.VoidedBy = &id
	}
	return v
}

// SubscriptionView is the body of GET /v1/driver/subscription.
type SubscriptionView struct {
	Status     string        `json:"status"`
	PaidUntil  *time.Time    `json:"paid_until"`
	GraceUntil *time.Time    `json:"grace_until"`
	Price      *Price        `json:"price"`
	CanPay     bool          `json:"can_pay"`
	Payments   []PaymentView `json:"payments"`
}

// View returns the subscription of driverID with its price and payments.
func (s *Service) View(ctx context.Context, driverID uuid.UUID) (SubscriptionView, error) {
	now := s.now()
	out := SubscriptionView{Payments: []PaymentView{}}
	pu, err := s.Store.GetSubscription(ctx, driverID)
	switch {
	case err == nil:
		out.PaidUntil = &pu
		g := pu.Add(drivers.GracePeriod)
		out.GraceUntil = &g
	case !store.IsNotFound(err):
		return out, err
	}
	out.Status = drivers.BillingStatus(out.PaidUntil, now)
	price, err := s.CurrentPrice(ctx, s.Store.Queries)
	switch {
	case err == nil:
		out.Price = &price
	case !errors.Is(err, ErrPriceNotSet):
		return out, err
	}
	payments, err := s.Store.ListPaymentsForDriver(ctx, driverID)
	if err != nil {
		return out, err
	}
	for _, p := range payments {
		out.Payments = append(out.Payments, toView(p))
	}
	ok, err := documentsOK(ctx, s.Store.Queries, driverID, now)
	if err != nil {
		return out, err
	}
	out.CanPay = ok && out.Price != nil && s.Bold != nil
	return out, nil
}

func documentsOK(ctx context.Context, q *store.Queries, driverID uuid.UUID, now time.Time) (bool, error) {
	docs, err := q.ListDocumentsForDrivers(ctx, []uuid.UUID{driverID})
	if err != nil {
		return false, err
	}
	return len(drivers.DocumentProblems(drivers.GateDocuments(docs), now)) == 0, nil
}

// CreatePayment starts a Bold payment at the current price and returns its checkout URL. The
// driver needs documents in force (FR-004) and at most one payment in progress.
func (s *Service) CreatePayment(ctx context.Context, driverID uuid.UUID) (PaymentView, error) {
	if s.Bold == nil {
		return PaymentView{}, ErrBoldUnavailable
	}
	now := s.now()
	id, err := uuid.NewV7()
	if err != nil {
		return PaymentView{}, err
	}
	var p store.Payment
	err = s.Store.WithTx(ctx, func(q *store.Queries) error {
		if _, err := q.LockDriver(ctx, driverID); err != nil {
			if store.IsNotFound(err) {
				return ErrNotFound
			}
			return err
		}
		ok, err := documentsOK(ctx, q, driverID, now)
		if err != nil {
			return err
		}
		if !ok {
			return ErrDocumentsNotOK
		}
		price, err := s.CurrentPrice(ctx, q)
		if err != nil {
			return err
		}
		inFlight, err := q.GetInFlightPayment(ctx, driverID)
		switch {
		case err == nil && now.Sub(inFlight.CreatedAt) < LinkTTL:
			return ErrPaymentInProgress
		case err == nil:
			// El enlace ya caducó: el barrido lo confirmará con Bold; aquí deja de bloquear.
			if err := q.SetPaymentStatus(ctx, store.SetPaymentStatusParams{ID: inFlight.ID, Status: store.PaymentStatusExpired}); err != nil {
				return err
			}
		case !store.IsNotFound(err):
			return err
		}
		p, err = q.InsertPayment(ctx, store.InsertPaymentParams{
			ID: id, DriverID: driverID, AmountMinor: price.AmountMinor, Currency: price.Currency,
			Method: store.PaymentMethodBold, Status: store.PaymentStatusCreated, CreatedBy: driverID, CreatedAt: now,
		})
		return err
	})
	if err != nil {
		return PaymentView{}, err
	}
	link, err := s.Bold.CreateLink(ctx, LinkRequest{
		Reference: id.String(), Description: "Kyq: suscripción mensual", Currency: p.Currency,
		AmountMinor: p.AmountMinor, ExpiresAt: now.Add(LinkTTL),
	})
	if err != nil {
		// Nunca llegó a Bold: se borra para no dejar un pago "en curso" sin enlace.
		if derr := s.Store.DeletePayment(context.WithoutCancel(ctx), id); derr != nil {
			s.logger().ErrorContext(ctx, "delete payment without link", "err", derr)
		}
		return PaymentView{}, err
	}
	if err := s.Store.SetPaymentLink(ctx, store.SetPaymentLinkParams{
		ID: id, BoldLinkID: pgtype.Text{String: link.ID, Valid: true}, CheckoutUrl: pgtype.Text{String: link.URL, Valid: true},
	}); err != nil {
		return PaymentView{}, err
	}
	p.BoldLinkID = pgtype.Text{String: link.ID, Valid: true}
	p.CheckoutUrl = pgtype.Text{String: link.URL, Valid: true}
	return toView(p), nil
}

// Refresh asks Bold for the state of a payment of driverID now (the app calls it when the
// driver comes back from the checkout) and returns it.
func (s *Service) Refresh(ctx context.Context, driverID, paymentID uuid.UUID) (PaymentView, error) {
	p, err := s.Store.GetPayment(ctx, paymentID)
	if store.IsNotFound(err) || (err == nil && p.DriverID != driverID) {
		return PaymentView{}, ErrNotFound
	}
	if err != nil {
		return PaymentView{}, err
	}
	if err := s.poll(ctx, p); err != nil && !errors.Is(err, ErrBoldUnavailable) {
		return PaymentView{}, err
	} else if err != nil {
		s.logger().WarnContext(ctx, "refresh payment", "payment_id", paymentID, "err", err)
	}
	p, err = s.Store.GetPayment(ctx, paymentID)
	if err != nil {
		return PaymentView{}, err
	}
	return toView(p), nil
}

// poll reads the link status from Bold and applies it.
func (s *Service) poll(ctx context.Context, p store.Payment) error {
	if s.Bold == nil || !p.BoldLinkID.Valid || (p.Status != store.PaymentStatusCreated && p.Status != store.PaymentStatusProcessing) {
		return nil
	}
	ls, err := s.Bold.GetLink(ctx, p.BoldLinkID.String)
	if err != nil {
		return err
	}
	var o outcome
	switch ls.Status {
	case LinkPaid:
		o.status = store.PaymentStatusApproved
	case LinkProcessing:
		o.status = store.PaymentStatusProcessing
	case LinkRejected, LinkCancelled:
		o.status = store.PaymentStatusRejected
	case LinkExpired:
		o.status = store.PaymentStatusExpired
	default:
		// En el sandbox Bold sigue respondiendo ACTIVE después de caducar el enlace (su checkout ya
		// dice "expiró"): pasado el plazo con margen, el pago se da por caducado.
		if s.now().Sub(p.CreatedAt) < LinkTTL+linkExpiryMargin {
			return nil // ACTIVE: aún sin pagar
		}
		o.status = store.PaymentStatusExpired
	}
	o.totalMinor, o.currency = ls.TotalMinor, ls.Currency
	o.detail, o.boldPaymentID = ls.PaymentMethod, ls.TransactionID
	return s.apply(ctx, p.ID, o)
}

// outcome is a payment result confirmed by Bold (link status or signed webhook).
type outcome struct {
	status        store.PaymentStatus
	totalMinor    int64
	currency      string
	detail        string
	boldPaymentID string
	voidReason    string
}

func optText(s string) pgtype.Text { return pgtype.Text{String: s, Valid: s != ""} }

// apply moves a payment to o.status. Approving extends the subscription once (SC-005): a
// payment already approved or voided is never extended again, whatever arrives later and in
// whatever order (research R3). A different amount or currency goes to needs_review (FR-017).
func (s *Service) apply(ctx context.Context, paymentID uuid.UUID, o outcome) error {
	now := s.now()
	var notice *store.Notice
	err := s.Store.WithTx(ctx, func(q *store.Queries) error {
		p, err := q.GetPayment(ctx, paymentID)
		if err != nil {
			return err
		}
		// Siempre el conductor primero y luego el pago: mismo orden de bloqueo en todas partes.
		if _, err := q.LockDriver(ctx, p.DriverID); err != nil {
			return err
		}
		p, err = q.GetPaymentForUpdate(ctx, paymentID)
		if err != nil {
			return err
		}
		switch o.status {
		case store.PaymentStatusApproved:
			switch p.Status {
			case store.PaymentStatusApproved, store.PaymentStatusVoided, store.PaymentStatusNeedsReview:
				return nil
			}
			if o.totalMinor != p.AmountMinor || o.currency != p.Currency {
				s.logger().WarnContext(ctx, "bold payment amount mismatch", "payment_id", p.ID)
				return q.SetPaymentStatus(ctx, store.SetPaymentStatusParams{
					ID: p.ID, Status: store.PaymentStatusNeedsReview, Detail: optText(o.detail), BoldPaymentID: optText(o.boldPaymentID),
					ReviewNote: optText(fmt.Sprintf("Bold confirmó %d %s; se esperaba %d %s", o.totalMinor, o.currency, p.AmountMinor, p.Currency)),
				})
			}
			until, err := approve(ctx, q, p, now, o.detail, o.boldPaymentID, uuid.NullUUID{})
			if err != nil {
				return err
			}
			notice, err = notify.Create(ctx, q, p.DriverID, now, notify.Notice{
				Kind: "payment_approved", DedupKey: "payment_approved:" + p.ID.String(),
				Title: "Pago aprobado", Body: "Tu suscripción está activa hasta el " + until.In(bogota).Format("02/01/2006") + ".",
			})
			return err
		case store.PaymentStatusProcessing:
			if p.Status != store.PaymentStatusCreated {
				return nil
			}
		case store.PaymentStatusRejected, store.PaymentStatusExpired:
			if p.Status != store.PaymentStatusCreated && p.Status != store.PaymentStatusProcessing {
				return nil
			}
			if o.status == store.PaymentStatusRejected {
				notice, err = notify.Create(ctx, q, p.DriverID, now, notify.Notice{
					Kind: "payment_rejected", DedupKey: "payment_rejected:" + p.ID.String(),
					Title: "Pago rechazado", Body: "Bold rechazó el pago de tu suscripción. Puedes intentarlo otra vez.",
				})
				if err != nil {
					return err
				}
			}
		case store.PaymentStatusVoided:
			if p.Status != store.PaymentStatusApproved {
				return nil
			}
			notice, err = void(ctx, q, p, now, uuid.NullUUID{}, o.voidReason)
			return err
		default:
			return fmt.Errorf("unexpected outcome %s", o.status)
		}
		return q.SetPaymentStatus(ctx, store.SetPaymentStatusParams{
			ID: p.ID, Status: o.status, Detail: optText(o.detail), BoldPaymentID: optText(o.boldPaymentID),
		})
	})
	if err != nil {
		return err
	}
	s.Notify.Announce(ctx, notice)
	return nil
}

// bogota formats dates for drivers (Colombia, UTC-5 without DST).
var bogota = time.FixedZone("COT", -5*3600)

// approve extends the subscription with payment p. The driver row must be locked.
func approve(ctx context.Context, q *store.Queries, p store.Payment, now time.Time, detail, boldPaymentID string, by uuid.NullUUID) (time.Time, error) {
	var current *time.Time
	pu, err := q.GetSubscription(ctx, p.DriverID)
	switch {
	case err == nil:
		current = &pu
	case !store.IsNotFound(err):
		return time.Time{}, err
	}
	from, until := Extend(current, now)
	prev := pgtype.Timestamptz{}
	if current != nil {
		prev = pgtype.Timestamptz{Time: *current, Valid: true}
	}
	if err := q.ApprovePayment(ctx, store.ApprovePaymentParams{
		ID: p.ID, CoversFrom: pgtype.Timestamptz{Time: from, Valid: true}, CoversUntil: pgtype.Timestamptz{Time: until, Valid: true},
		PrevPaidUntil: prev, Detail: optText(detail), BoldPaymentID: optText(boldPaymentID),
	}); err != nil {
		return time.Time{}, err
	}
	return until, q.UpsertSubscriptionPaidUntil(ctx, store.UpsertSubscriptionPaidUntilParams{DriverID: p.DriverID, PaidUntil: until, UpdatedBy: by})
}

// void cancels an approved payment and takes its period off the subscription (FR-021): when it
// was the last extension, paid_until goes back to what it was before; otherwise the covered
// period is subtracted. The driver row must be locked.
func void(ctx context.Context, q *store.Queries, p store.Payment, now time.Time, by uuid.NullUUID, reason string) (*store.Notice, error) {
	pu, err := q.GetSubscription(ctx, p.DriverID)
	if err != nil {
		return nil, err
	}
	var paidUntil *time.Time
	switch {
	case pu.Equal(p.CoversUntil.Time) && !p.PrevPaidUntil.Valid:
		err = q.DeleteSubscription(ctx, p.DriverID)
	case pu.Equal(p.CoversUntil.Time):
		paidUntil = &p.PrevPaidUntil.Time
	default:
		t := pu.Add(-p.CoversUntil.Time.Sub(p.CoversFrom.Time))
		paidUntil = &t
	}
	if err != nil {
		return nil, err
	}
	if paidUntil != nil {
		if err := q.UpsertSubscriptionPaidUntil(ctx, store.UpsertSubscriptionPaidUntilParams{DriverID: p.DriverID, PaidUntil: *paidUntil, UpdatedBy: by}); err != nil {
			return nil, err
		}
	}
	if err := q.VoidPayment(ctx, store.VoidPaymentParams{ID: p.ID, VoidedBy: by, VoidReason: pgtype.Text{String: reason, Valid: true}}); err != nil {
		return nil, err
	}
	body := "Se anuló un pago de tu suscripción. Motivo: " + reason + "."
	if paidUntil != nil {
		body += " Tu suscripción vence el " + paidUntil.In(bogota).Format("02/01/2006") + "."
	}
	return notify.Create(ctx, q, p.DriverID, now, notify.Notice{
		Kind: "payment_voided", DedupKey: "payment_voided:" + p.ID.String(), Title: "Pago anulado", Body: body,
	})
}
