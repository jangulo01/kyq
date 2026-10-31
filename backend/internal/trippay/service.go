package trippay

import (
	"context"
	"log/slog"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/billing"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/trips"
)

// Service holds the trip payment use cases.
type Service struct {
	Store *store.Store
	// Bold is the client of 002; nil when KYQ_BOLD_ENV is empty: then only cash is offered.
	Bold      billing.BoldAPI
	Notify    *notify.Service
	Publisher realtime.Publisher
	// Cases keeps the support case of a dispute in step with the payment (009); nil without
	// the support center.
	Cases  PaymentCases
	Now    func() time.Time
	Logger *slog.Logger
}

// PaymentCases is the support center seen from 004 (support.Service): the payment case opens
// when the payment is disputed or marked unpaid and resolves with it (009, FR-010).
type PaymentCases interface {
	PaymentCaseOpened(ctx context.Context, q *store.Queries, p store.TripPayment, subject, text string, now time.Time) (uuid.UUID, error)
	PaymentCaseResolved(ctx context.Context, q *store.Queries, p store.TripPayment, text string, now time.Time) (uuid.UUID, error)
	Announce(ctx context.Context, caseID uuid.UUID)
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

// View is the JSON of a trip payment (contracts: TripPayment).
type View struct {
	ID                      uuid.UUID  `json:"id"`
	TripID                  uuid.UUID  `json:"trip_id"`
	DriverID                uuid.UUID  `json:"driver_id"`
	PassengerID             uuid.UUID  `json:"passenger_id"`
	DriverName              string     `json:"driver_name"`
	PassengerName           string     `json:"passenger_name"`
	AmountMinor             int64      `json:"amount_minor"`
	Currency                string     `json:"currency"`
	DriverAmountMinor       int64      `json:"driver_amount_minor"`
	PlatformCommissionMinor int64      `json:"platform_commission_minor"`
	Status                  string     `json:"status"`
	Method                  *string    `json:"method"`
	AcceptedMethods         []string   `json:"accepted_methods"`
	CheckoutURL             *string    `json:"checkout_url"`
	PaymentMethodDetail     *string    `json:"payment_method_detail"`
	CashReportedAt          *time.Time `json:"cash_reported_at"`
	CashConfirmedAt         *time.Time `json:"cash_confirmed_at"`
	DisputedAt              *time.Time `json:"disputed_at"`
	UnpaidMarkedAt          *time.Time `json:"unpaid_marked_at"`
	PaidAt                  *time.Time `json:"paid_at"`
	VoidedAt                *time.Time `json:"voided_at"`
	CreatedAt               time.Time  `json:"created_at"`
}

// AdminView adds the review, resolution and void fields admins see (contracts: AdminTripPayment).
type AdminView struct {
	View
	ReviewNote     *string    `json:"review_note"`
	ResolutionNote *string    `json:"resolution_note"`
	ResolvedBy     *uuid.UUID `json:"resolved_by"`
	ResolvedAt     *time.Time `json:"resolved_at"`
	VoidReason     *string    `json:"void_reason"`
	VoidedBy       *uuid.UUID `json:"voided_by"`
}

func textPtr(t pgtype.Text) *string {
	if !t.Valid {
		return nil
	}
	v := t.String
	return &v
}

func timePtr(t pgtype.Timestamptz) *time.Time {
	if !t.Valid {
		return nil
	}
	v := t.Time
	return &v
}

func uuidPtr(u uuid.NullUUID) *uuid.UUID {
	if !u.Valid {
		return nil
	}
	v := u.UUID
	return &v
}

func ts(t time.Time) pgtype.Timestamptz { return pgtype.Timestamptz{Time: t, Valid: true} }

func optText(v string) pgtype.Text { return pgtype.Text{String: v, Valid: v != ""} }

func method(m store.TripPaymentMethod) store.NullTripPaymentMethod {
	return store.NullTripPaymentMethod{TripPaymentMethod: m, Valid: true}
}

// acceptedMethods are the methods the passenger may use: the driver's when the trip completed,
// and Bold only while it is configured in Kyq (FR-002).
func (s *Service) acceptedMethods(p store.TripPayment) []string {
	out := []string{}
	if p.AcceptsBold && s.Bold != nil {
		out = append(out, string(store.TripPaymentMethodBold))
	}
	if p.AcceptsCash {
		out = append(out, string(store.TripPaymentMethodCash))
	}
	return out
}

func (s *Service) view(p store.TripPayment, driverName, passengerName string) View {
	v := View{
		ID: p.ID, TripID: p.TripID, DriverID: p.DriverID, PassengerID: p.PassengerID, DriverName: driverName,
		PassengerName: passengerName, AmountMinor: p.AmountMinor, Currency: p.Currency,
		DriverAmountMinor: p.DriverAmountMinor, PlatformCommissionMinor: p.PlatformCommissionMinor, Status: string(p.Status),
		AcceptedMethods: s.acceptedMethods(p), PaymentMethodDetail: textPtr(p.PaymentMethodDetail),
		CashReportedAt: timePtr(p.CashReportedAt), CashConfirmedAt: timePtr(p.CashConfirmedAt), DisputedAt: timePtr(p.DisputedAt),
		UnpaidMarkedAt: timePtr(p.UnpaidMarkedAt), PaidAt: timePtr(p.PaidAt), VoidedAt: timePtr(p.VoidedAt), CreatedAt: p.CreatedAt,
	}
	if p.Method.Valid {
		m := string(p.Method.TripPaymentMethod)
		v.Method = &m
	}
	// El checkout solo sirve mientras el pago con Bold está en curso.
	if p.Status == statusBoldInProgress {
		v.CheckoutURL = textPtr(p.CheckoutUrl)
	}
	return v
}

func (s *Service) adminView(p store.TripPayment, driverName, passengerName string) AdminView {
	return AdminView{
		View: s.view(p, driverName, passengerName), ReviewNote: textPtr(p.ReviewNote), ResolutionNote: textPtr(p.ResolutionNote),
		ResolvedBy: uuidPtr(p.ResolvedBy), ResolvedAt: timePtr(p.ResolvedAt), VoidReason: textPtr(p.VoidReason),
		VoidedBy: uuidPtr(p.VoidedBy),
	}
}

// OpenForTrip implements trips.PaymentOpener: the payment of a completed trip, for the agreed
// fare, 100 % for the driver and with the methods the driver accepts now (FR-001, FR-018).
func (s *Service) OpenForTrip(ctx context.Context, q *store.Queries, t trips.CompletedTrip, now time.Time) error {
	id, err := uuid.NewV7()
	if err != nil {
		return err
	}
	driverMinor, _ := Settle(t.FareMinor)
	_, err = q.InsertTripPayment(ctx, store.InsertTripPaymentParams{
		ID: id, TripID: t.ID, DriverID: t.DriverID, PassengerID: t.PassengerID, AmountMinor: t.FareMinor,
		Currency: t.Currency, DriverAmountMinor: driverMinor, CreatedAt: now,
	})
	return err
}

func partyOf(p store.TripPayment, userID uuid.UUID) (Party, bool) {
	switch userID {
	case p.PassengerID:
		return Passenger, true
	case p.DriverID:
		return Driver, true
	}
	return "", false
}

// loadForParticipant returns the payment of tripID when userID takes part in the trip; otherwise
// ErrNotFound, without revealing that it exists.
func (s *Service) loadForParticipant(ctx context.Context, userID, tripID uuid.UUID) (store.GetTripPaymentByTripRow, Party, error) {
	row, err := s.Store.GetTripPaymentByTrip(ctx, tripID)
	if store.IsNotFound(err) {
		return row, "", ErrNotFound
	}
	if err != nil {
		return row, "", err
	}
	party, ok := partyOf(row.TripPayment, userID)
	if !ok {
		return row, "", ErrNotFound
	}
	return row, party, nil
}

// Get returns the payment of a trip to its passenger or driver.
func (s *Service) Get(ctx context.Context, userID, tripID uuid.UUID) (View, error) {
	row, _, err := s.loadForParticipant(ctx, userID, tripID)
	if err != nil {
		return View{}, err
	}
	return s.view(row.TripPayment, row.DriverName, row.PassengerName), nil
}

// PendingForPassenger lists the passenger's trips still to pay (FR-016).
func (s *Service) PendingForPassenger(ctx context.Context, passengerID uuid.UUID) ([]View, error) {
	rows, err := s.Store.ListOpenTripPaymentsForPassenger(ctx, passengerID)
	if err != nil {
		return nil, err
	}
	out := make([]View, len(rows))
	for i, r := range rows {
		out[i] = s.view(r.TripPayment, r.DriverName, r.PassengerName)
	}
	return out, nil
}

// change is the result of a transaction on a payment: what to announce after commit.
type change struct {
	payment *store.TripPayment
	notices []*store.Notice
	cases   []uuid.UUID
}

// mutate locks the payment (driver row first, as everywhere) and saves what fn changes.
func (s *Service) mutate(ctx context.Context, paymentID uuid.UUID, fn func(q *store.Queries, p *store.TripPayment, c *change) error) error {
	var c change
	err := s.Store.WithTx(ctx, func(q *store.Queries) error {
		p, err := q.GetTripPayment(ctx, paymentID)
		if err != nil {
			return err
		}
		if _, err := q.LockDriver(ctx, p.DriverID); err != nil {
			return err
		}
		if p, err = q.GetTripPaymentForUpdate(ctx, paymentID); err != nil {
			return err
		}
		before := p
		if err := fn(q, &p, &c); err != nil {
			return err
		}
		if p == before {
			return nil
		}
		c.payment = &p
		if caseID, err := s.syncCase(ctx, q, before, p); err != nil {
			return err
		} else if caseID != uuid.Nil {
			c.cases = append(c.cases, caseID)
		}
		return save(ctx, q, p)
	})
	if err != nil {
		return err
	}
	for _, n := range c.notices {
		s.Notify.Announce(ctx, n)
	}
	for _, id := range c.cases {
		s.Cases.Announce(ctx, id)
	}
	if c.payment != nil {
		s.publishUpdated(ctx, *c.payment)
	}
	return nil
}

func save(ctx context.Context, q *store.Queries, p store.TripPayment) error {
	return q.UpdateTripPayment(ctx, store.UpdateTripPaymentParams{
		ID: p.ID, Status: p.Status, Method: p.Method, BoldLinkID: p.BoldLinkID, CheckoutUrl: p.CheckoutUrl,
		LinkCreatedAt: p.LinkCreatedAt, BoldPaymentID: p.BoldPaymentID, PaymentMethodDetail: p.PaymentMethodDetail,
		CashReportedAt: p.CashReportedAt, CashConfirmedAt: p.CashConfirmedAt, DisputedAt: p.DisputedAt,
		UnpaidMarkedAt: p.UnpaidMarkedAt, PaidAt: p.PaidAt, RemindedAt: p.RemindedAt, ReviewNote: p.ReviewNote,
		ResolvedBy: p.ResolvedBy, ResolutionNote: p.ResolutionNote, ResolvedAt: p.ResolvedAt, VoidedBy: p.VoidedBy,
		VoidReason: p.VoidReason, VoidedAt: p.VoidedAt,
	})
}

// Act applies a cash action of a participant: report, confirm, dispute or mark unpaid
// (FR-004..FR-006). StartBold goes through PayWithBold.
func (s *Service) Act(ctx context.Context, userID, tripID uuid.UUID, a Action) (View, error) {
	row, party, err := s.loadForParticipant(ctx, userID, tripID)
	if err != nil {
		return View{}, err
	}
	// Con un enlace de Bold abierto, el pasajero solo puede pasar a efectivo si Bold confirma que
	// sigue sin pagar; si ya terminó (pagado, rechazado), la consulta lo aplica antes.
	abandon := false
	if a == ReportCash && party == Passenger && row.TripPayment.Status == statusBoldInProgress {
		o, err := s.poll(ctx, row.TripPayment)
		if err != nil {
			return View{}, err
		}
		abandon = o == billing.OutcomeNone
	}
	now := s.now()
	err = s.mutate(ctx, row.TripPayment.ID, func(q *store.Queries, p *store.TripPayment, c *change) error {
		from := p.Status
		if a == ReportCash && from == statusBoldInProgress && abandon {
			from = s.withoutBold(*p)
		}
		to, err := Transition(from, a, party)
		if err != nil {
			return err
		}
		switch a {
		case ReportCash:
			if !p.AcceptsCash {
				return ErrMethodNotAccepted
			}
			p.Method, p.CashReportedAt, p.CheckoutUrl = method(store.TripPaymentMethodCash), ts(now), pgtype.Text{}
			n, err := notify.Create(ctx, q, p.DriverID, now, notify.Notice{
				Kind: "trip_cash_reported", DedupKey: "trip_cash_reported:" + p.ID.String(), Title: "Pago en efectivo reportado",
				Body: "El pasajero dice que te pagó " + formatMoney(p.AmountMinor, p.Currency) + " en efectivo. Confírmalo en el viaje o en Pagos de viajes.",
			})
			if err != nil {
				return err
			}
			c.notices = append(c.notices, n)
		case ConfirmCash:
			p.Method, p.CashConfirmedAt, p.PaidAt, p.CheckoutUrl = method(store.TripPaymentMethodCash), ts(now), ts(now), pgtype.Text{}
		case DisputeCash:
			p.DisputedAt = ts(now)
		case MarkUnpaid:
			p.UnpaidMarkedAt = ts(now)
		default:
			return ErrForbidden
		}
		p.Status = to
		return nil
	})
	if store.IsNotFound(err) {
		return View{}, ErrNotFound
	}
	if err != nil {
		return View{}, err
	}
	return s.Get(ctx, userID, tripID)
}

// withoutBold is the status a payment goes back to when its Bold checkout ends without paying.
func (s *Service) withoutBold(p store.TripPayment) store.TripPaymentStatus {
	if p.UnpaidMarkedAt.Valid {
		return statusUnpaid
	}
	return statusPending
}

// PaymentMethods is the body of GET/PUT /v1/driver/payment-methods (FR-018).
type PaymentMethods struct {
	AcceptsCash   bool `json:"accepts_cash"`
	AcceptsBold   bool `json:"accepts_bold"`
	BoldAvailable bool `json:"bold_available"`
}

// Methods returns the methods the driver accepts.
func (s *Service) Methods(ctx context.Context, driverID uuid.UUID) (PaymentMethods, error) {
	m, err := s.Store.GetDriverPaymentMethods(ctx, driverID)
	if store.IsNotFound(err) {
		return PaymentMethods{}, ErrNotFound
	}
	if err != nil {
		return PaymentMethods{}, err
	}
	return PaymentMethods{AcceptsCash: m.AcceptsCash, AcceptsBold: m.AcceptsBold, BoldAvailable: s.Bold != nil}, nil
}

// SetMethods changes the accepted methods; at least one. Trips already completed keep theirs.
func (s *Service) SetMethods(ctx context.Context, driverID uuid.UUID, cash, bold bool) (PaymentMethods, error) {
	if !cash && !bold {
		return PaymentMethods{}, ErrNoMethod
	}
	n, err := s.Store.SetDriverPaymentMethods(ctx, store.SetDriverPaymentMethodsParams{UserID: driverID, AcceptsCash: cash, AcceptsBold: bold})
	if err != nil {
		return PaymentMethods{}, err
	}
	if n == 0 {
		return PaymentMethods{}, ErrNotFound
	}
	return PaymentMethods{AcceptsCash: cash, AcceptsBold: bold, BoldAvailable: s.Bold != nil}, nil
}

// publishUpdated tells both parties the payment changed (trip_payment.updated). Best-effort:
// the apps also read the payment with GET.
func (s *Service) publishUpdated(ctx context.Context, p store.TripPayment) {
	var m *string
	if p.Method.Valid {
		v := string(p.Method.TripPaymentMethod)
		m = &v
	}
	ev := realtime.Event{Type: "trip_payment.updated", OccurredAt: s.now(), Data: map[string]any{
		"trip_id": p.TripID, "payment_id": p.ID, "status": p.Status, "method": m,
	}}
	s.publish(ctx, "user:"+p.PassengerID.String(), ev)
	s.publish(ctx, "user:"+p.DriverID.String(), ev)
}

func (s *Service) publish(ctx context.Context, channel string, ev realtime.Event) {
	if s.Publisher == nil {
		return
	}
	if err := s.Publisher.Publish(ctx, channel, ev); err != nil {
		s.logger().WarnContext(ctx, "publish trip payment event", "type", ev.Type, "err", err)
	}
}

// bogota formats dates for people (Colombia, UTC-5 without DST).
var bogota = time.FixedZone("COT", -5*3600)

// formatMoney writes an amount for a notice: "$ 18.000 COP"; centavos only when there are.
func formatMoney(minor int64, currency string) string {
	sign := ""
	if minor < 0 {
		sign, minor = "-", -minor
	}
	whole := strconv.FormatInt(minor/100, 10)
	var b strings.Builder
	for i, r := range whole {
		if i > 0 && (len(whole)-i)%3 == 0 {
			b.WriteByte('.')
		}
		b.WriteRune(r)
	}
	out := sign + "$ " + b.String()
	if cents := minor % 100; cents != 0 {
		out += "," + strconv.FormatInt(100+cents, 10)[1:]
	}
	return out + " " + currency
}
