package billing

import (
	"context"
	"regexp"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/store"
)

var currencyPattern = regexp.MustCompile(`^[A-Z]{3}$`)

// LastPayment summarizes the latest payment of a driver.
type LastPayment struct {
	ID          uuid.UUID `json:"id"`
	AmountMinor int64     `json:"amount_minor"`
	Currency    string    `json:"currency"`
	Method      string    `json:"method"`
	Status      string    `json:"status"`
	CreatedAt   time.Time `json:"created_at"`
}

// SubscriptionRow is one row of GET /v1/admin/subscriptions (FR-022).
type SubscriptionRow struct {
	DriverID     uuid.UUID    `json:"driver_id"`
	DisplayName  string       `json:"display_name"`
	PhoneE164    string       `json:"phone_e164"`
	VehiclePlate string       `json:"vehicle_plate"`
	Status       string       `json:"status"`
	PaidUntil    *time.Time   `json:"paid_until"`
	GraceUntil   *time.Time   `json:"grace_until"`
	LastPayment  *LastPayment `json:"last_payment"`
}

// Subscriptions lists every driver's subscription, optionally only those in status.
func (s *Service) Subscriptions(ctx context.Context, status string) ([]SubscriptionRow, error) {
	rows, err := s.Store.ListSubscriptionsForAdmin(ctx)
	if err != nil {
		return nil, err
	}
	last, err := s.Store.ListLastPayments(ctx)
	if err != nil {
		return nil, err
	}
	byDriver := map[uuid.UUID]LastPayment{}
	for _, p := range last {
		byDriver[p.DriverID] = LastPayment{
			ID: p.ID, AmountMinor: p.AmountMinor, Currency: p.Currency, Method: string(p.Method), Status: string(p.Status), CreatedAt: p.CreatedAt,
		}
	}
	now := s.now()
	out := []SubscriptionRow{}
	for _, r := range rows {
		row := SubscriptionRow{DriverID: r.DriverID, DisplayName: r.DisplayName, PhoneE164: r.PhoneE164, VehiclePlate: r.VehiclePlate}
		if r.PaidUntil.Valid {
			pu := r.PaidUntil.Time
			g := pu.Add(drivers.GracePeriod)
			row.PaidUntil, row.GraceUntil = &pu, &g
		}
		row.Status = drivers.BillingStatus(row.PaidUntil, now)
		if status != "" && row.Status != status {
			continue
		}
		if lp, ok := byDriver[r.DriverID]; ok {
			row.LastPayment = &lp
		}
		out = append(out, row)
	}
	return out, nil
}

// DriverPayments returns the payment history of a driver for admins.
func (s *Service) DriverPayments(ctx context.Context, driverID uuid.UUID) ([]AdminPaymentView, error) {
	if _, err := s.Store.GetDriverProfile(ctx, driverID); store.IsNotFound(err) {
		return nil, ErrNotFound
	} else if err != nil {
		return nil, err
	}
	rows, err := s.Store.ListPaymentsForDriver(ctx, driverID)
	if err != nil {
		return nil, err
	}
	out := make([]AdminPaymentView, len(rows))
	for i, p := range rows {
		out[i] = toAdminView(p)
	}
	return out, nil
}

// ManualPayment is the body of POST /v1/admin/drivers/{id}/payments.
type ManualPayment struct {
	MethodDetail string `json:"method_detail"`
	Reference    string `json:"reference"`
}

// RegisterManualPayment records a payment received outside Bold (e.g. cash) at the current
// price and extends the subscription exactly like Bold; the admin is recorded (FR-021).
func (s *Service) RegisterManualPayment(ctx context.Context, adminID, driverID uuid.UUID, in ManualPayment) (AdminPaymentView, error) {
	in.MethodDetail = strings.TrimSpace(in.MethodDetail)
	in.Reference = strings.TrimSpace(in.Reference)
	if in.MethodDetail == "" || in.Reference == "" || utf8.RuneCountInString(in.MethodDetail) > 40 || utf8.RuneCountInString(in.Reference) > 80 {
		return AdminPaymentView{}, ErrInvalidManual
	}
	now := s.now()
	id, err := uuid.NewV7()
	if err != nil {
		return AdminPaymentView{}, err
	}
	var p store.Payment
	var notice *store.Notice
	err = s.Store.WithTx(ctx, func(q *store.Queries) error {
		if _, err := q.LockDriver(ctx, driverID); store.IsNotFound(err) {
			return ErrNotFound
		} else if err != nil {
			return err
		}
		price, err := s.CurrentPrice(ctx, q)
		if err != nil {
			return err
		}
		p, err = q.InsertPayment(ctx, store.InsertPaymentParams{
			ID: id, DriverID: driverID, AmountMinor: price.AmountMinor, Currency: price.Currency,
			Method: store.PaymentMethodManual, Status: store.PaymentStatusCreated,
			ManualReference: optText(in.Reference), PaymentMethodDetail: optText(in.MethodDetail), CreatedBy: adminID,
			CreatedAt: now,
		})
		if err != nil {
			return err
		}
		until, err := approve(ctx, q, p, now, in.MethodDetail, "", uuid.NullUUID{UUID: adminID, Valid: true})
		if err != nil {
			return err
		}
		if p, err = q.GetPayment(ctx, id); err != nil {
			return err
		}
		notice, err = notify.Create(ctx, q, driverID, now, notify.Notice{
			Kind: "payment_approved", DedupKey: "payment_approved:" + id.String(),
			Title: "Pago registrado", Body: "Kyq registró tu pago. Tu suscripción está activa hasta el " + until.In(bogota).Format("02/01/2006") + ".",
		})
		return err
	})
	if err != nil {
		return AdminPaymentView{}, err
	}
	s.Notify.Announce(ctx, notice)
	return toAdminView(p), nil
}

// VoidPayment cancels an approved payment with a reason (e.g. chargeback) and recalculates
// paid_until; the admin is recorded and the driver notified (FR-021).
func (s *Service) VoidPayment(ctx context.Context, adminID, paymentID uuid.UUID, reason string) (AdminPaymentView, error) {
	reason = strings.TrimSpace(reason)
	if reason == "" || utf8.RuneCountInString(reason) > 200 {
		return AdminPaymentView{}, ErrReasonRequired
	}
	p, err := s.Store.GetPayment(ctx, paymentID)
	if store.IsNotFound(err) {
		return AdminPaymentView{}, ErrNotFound
	}
	if err != nil {
		return AdminPaymentView{}, err
	}
	var notice *store.Notice
	err = s.Store.WithTx(ctx, func(q *store.Queries) error {
		if _, err := q.LockDriver(ctx, p.DriverID); err != nil {
			return err
		}
		locked, err := q.GetPaymentForUpdate(ctx, paymentID)
		if err != nil {
			return err
		}
		if locked.Status != store.PaymentStatusApproved {
			return ErrNotApproved
		}
		notice, err = void(ctx, q, locked, s.now(), uuid.NullUUID{UUID: adminID, Valid: true}, reason)
		if err != nil {
			return err
		}
		p, err = q.GetPayment(ctx, paymentID)
		return err
	})
	if err != nil {
		return AdminPaymentView{}, err
	}
	s.Notify.Announce(ctx, notice)
	return toAdminView(p), nil
}

// NewPrice is the body of PUT /v1/admin/subscription-prices/{city}.
type NewPrice struct {
	Currency      string     `json:"currency"`
	AmountMinor   int64      `json:"amount_minor"`
	EffectiveFrom *time.Time `json:"effective_from"`
}

// PriceView is a stored price.
type PriceView struct {
	CityCode      string    `json:"city_code"`
	Currency      string    `json:"currency"`
	AmountMinor   int64     `json:"amount_minor"`
	EffectiveFrom time.Time `json:"effective_from"`
}

// SetPrice adds a monthly price for a city from EffectiveFrom (default now) (FR-013). A payment
// already started keeps the price it was created with.
func (s *Service) SetPrice(ctx context.Context, adminID uuid.UUID, city string, in NewPrice) (PriceView, error) {
	in.Currency = strings.ToUpper(strings.TrimSpace(in.Currency))
	// Bold cobra COP en pesos enteros: el precio no puede tener centavos.
	if !currencyPattern.MatchString(in.Currency) || in.AmountMinor <= 0 || (in.Currency == "COP" && in.AmountMinor%100 != 0) {
		return PriceView{}, ErrInvalidPrice
	}
	exists, err := s.Store.FareTableExists(ctx, city)
	if err != nil {
		return PriceView{}, err
	}
	if !exists {
		return PriceView{}, ErrNotFound
	}
	from := s.now()
	if in.EffectiveFrom != nil {
		from = *in.EffectiveFrom
	}
	from = from.UTC().Truncate(time.Second)
	err = s.Store.InsertSubscriptionPrice(ctx, store.InsertSubscriptionPriceParams{
		CityCode: city, Currency: in.Currency, AmountMinor: in.AmountMinor, EffectiveFrom: from, CreatedBy: adminID,
	})
	return PriceView{CityCode: city, Currency: in.Currency, AmountMinor: in.AmountMinor, EffectiveFrom: from}, err
}
