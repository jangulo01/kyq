package trippay

import (
	"context"
	"regexp"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/store"
)

var currencyPattern = regexp.MustCompile(`^[A-Z]{3}$`)

// Balance is the ledger of a driver in one currency (contracts: Balance, research R4).
type Balance struct {
	Currency      string `json:"currency"`
	CreditedMinor int64  `json:"credited_minor"`
	DebitedMinor  int64  `json:"debited_minor"`
	PaidOutMinor  int64  `json:"paid_out_minor"`
	BalanceMinor  int64  `json:"balance_minor"`
}

// LedgerEntry is one ledger movement (contracts: LedgerEntry).
type LedgerEntry struct {
	ID            uuid.UUID  `json:"id"`
	Kind          string     `json:"kind"`
	AmountMinor   int64      `json:"amount_minor"`
	Currency      string     `json:"currency"`
	TripPaymentID *uuid.UUID `json:"trip_payment_id"`
	TripID        *uuid.UUID `json:"trip_id"`
	PayoutID      *uuid.UUID `json:"payout_id"`
	Reference     *string    `json:"reference"`
	CreatedAt     time.Time  `json:"created_at"`
}

// DriverSettlement is the body of GET /v1/driver/settlement and of the admin view of a driver.
type DriverSettlement struct {
	Balances []Balance     `json:"balances"`
	Entries  []LedgerEntry `json:"entries"`
	Payments []View        `json:"payments"`
}

// Settlement returns the balances, ledger and recent trip payments of a driver (FR-013).
func (s *Service) Settlement(ctx context.Context, driverID uuid.UUID) (DriverSettlement, error) {
	if _, err := s.Store.GetDriverPaymentMethods(ctx, driverID); store.IsNotFound(err) {
		return DriverSettlement{}, ErrNotFound
	} else if err != nil {
		return DriverSettlement{}, err
	}
	out := DriverSettlement{Balances: []Balance{}, Entries: []LedgerEntry{}, Payments: []View{}}
	balances, err := s.Store.GetDriverBalances(ctx, driverID)
	if err != nil {
		return out, err
	}
	for _, b := range balances {
		out.Balances = append(out.Balances, Balance{
			Currency: b.Currency, CreditedMinor: b.CreditedMinor, DebitedMinor: b.DebitedMinor, PaidOutMinor: b.PaidOutMinor,
			BalanceMinor: b.BalanceMinor,
		})
	}
	entries, err := s.Store.ListLedgerEntries(ctx, driverID)
	if err != nil {
		return out, err
	}
	for _, e := range entries {
		out.Entries = append(out.Entries, LedgerEntry{
			ID: e.ID, Kind: string(e.Kind), AmountMinor: e.AmountMinor, Currency: e.Currency, TripPaymentID: uuidPtr(e.TripPaymentID),
			TripID: uuidPtr(e.TripID), PayoutID: uuidPtr(e.PayoutID), Reference: textPtr(e.Reference), CreatedAt: e.CreatedAt,
		})
	}
	payments, err := s.Store.ListTripPaymentsForDriver(ctx, driverID)
	if err != nil {
		return out, err
	}
	for _, p := range payments {
		out.Payments = append(out.Payments, s.view(p.TripPayment, p.DriverName, p.PassengerName))
	}
	return out, nil
}

// SettlementRow is one row of GET /v1/admin/settlements (FR-012).
type SettlementRow struct {
	Balance
	DriverID     uuid.UUID  `json:"driver_id"`
	DisplayName  string     `json:"display_name"`
	PhoneE164    string     `json:"phone_e164"`
	VehiclePlate string     `json:"vehicle_plate"`
	LastPayoutAt *time.Time `json:"last_payout_at"`
}

// Settlements lists every driver with ledger movements and currency, those with a balance first.
func (s *Service) Settlements(ctx context.Context) ([]SettlementRow, error) {
	rows, err := s.Store.ListSettlements(ctx)
	if err != nil {
		return nil, err
	}
	last, err := s.Store.ListLastPayouts(ctx)
	if err != nil {
		return nil, err
	}
	lastBy := map[string]time.Time{}
	for _, l := range last {
		lastBy[l.DriverID.String()+l.Currency] = l.CreatedAt
	}
	out := make([]SettlementRow, len(rows))
	for i, r := range rows {
		out[i] = SettlementRow{
			Balance: Balance{
				Currency: r.Currency, CreditedMinor: r.CreditedMinor, DebitedMinor: r.DebitedMinor, PaidOutMinor: r.PaidOutMinor,
				BalanceMinor: r.BalanceMinor,
			},
			DriverID: r.DriverID, DisplayName: r.DisplayName, PhoneE164: r.PhoneE164, VehiclePlate: r.VehiclePlate,
		}
		if t, ok := lastBy[r.DriverID.String()+r.Currency]; ok {
			out[i].LastPayoutAt = &t
		}
	}
	return out, nil
}

// NewPayout is the body of POST /v1/admin/drivers/{id}/payouts.
type NewPayout struct {
	AmountMinor int64  `json:"amount_minor"`
	Currency    string `json:"currency"`
	Reference   string `json:"reference"`
	Note        string `json:"note"`
}

// PayoutView is a registered payout (contracts: Payout).
type PayoutView struct {
	ID          uuid.UUID `json:"id"`
	DriverID    uuid.UUID `json:"driver_id"`
	AmountMinor int64     `json:"amount_minor"`
	Currency    string    `json:"currency"`
	Reference   string    `json:"reference"`
	Note        *string   `json:"note"`
	CreatedBy   uuid.UUID `json:"created_by"`
	CreatedAt   time.Time `json:"created_at"`
}

// RegisterPayout records a transfer an admin made to the driver outside the app. It never
// exceeds the balance in that currency (FR-012); the driver row is locked so concurrent payouts
// cannot overdraw it.
func (s *Service) RegisterPayout(ctx context.Context, adminID, driverID uuid.UUID, in NewPayout) (PayoutView, error) {
	in.Currency = strings.ToUpper(strings.TrimSpace(in.Currency))
	in.Reference = strings.TrimSpace(in.Reference)
	in.Note = strings.TrimSpace(in.Note)
	if in.AmountMinor <= 0 || !currencyPattern.MatchString(in.Currency) || in.Reference == "" ||
		utf8.RuneCountInString(in.Reference) > 80 || utf8.RuneCountInString(in.Note) > 200 {
		return PayoutView{}, ErrInvalidPayout
	}
	now := s.now()
	id, err := uuid.NewV7()
	if err != nil {
		return PayoutView{}, err
	}
	entryID, err := uuid.NewV7()
	if err != nil {
		return PayoutView{}, err
	}
	var payout store.DriverPayout
	var notice *store.Notice
	err = s.Store.WithTx(ctx, func(q *store.Queries) error {
		if _, err := q.LockDriver(ctx, driverID); store.IsNotFound(err) {
			return ErrNotFound
		} else if err != nil {
			return err
		}
		balances, err := q.GetDriverBalances(ctx, driverID)
		if err != nil {
			return err
		}
		var available int64
		for _, b := range balances {
			if b.Currency == in.Currency {
				available = b.BalanceMinor
			}
		}
		if in.AmountMinor > available {
			return ErrExceedsBalance
		}
		payout, err = q.InsertPayout(ctx, store.InsertPayoutParams{
			ID: id, DriverID: driverID, AmountMinor: in.AmountMinor, Currency: in.Currency, Reference: in.Reference,
			Note: optText(in.Note), CreatedBy: adminID, CreatedAt: now,
		})
		if err != nil {
			return err
		}
		if _, err := q.InsertLedgerEntry(ctx, store.InsertLedgerEntryParams{
			ID: entryID, DriverID: driverID, Kind: store.LedgerEntryKindPayout, AmountMinor: -in.AmountMinor, Currency: in.Currency,
			PayoutID: uuid.NullUUID{UUID: id, Valid: true}, CreatedBy: uuid.NullUUID{UUID: adminID, Valid: true}, CreatedAt: now,
		}); err != nil {
			return err
		}
		notice, err = notify.Create(ctx, q, driverID, now, notify.Notice{
			Kind: "payout_registered", DedupKey: "payout_registered:" + id.String(), Title: "Kyq te giró tus pagos con Bold",
			Body: "Te giramos " + formatMoney(in.AmountMinor, in.Currency) + " (referencia " + in.Reference + "). Lo ves en Pagos de viajes.",
		})
		return err
	})
	if err != nil {
		return PayoutView{}, err
	}
	s.Notify.Announce(ctx, notice)
	return PayoutView{
		ID: payout.ID, DriverID: payout.DriverID, AmountMinor: payout.AmountMinor, Currency: payout.Currency,
		Reference: payout.Reference, Note: textPtr(payout.Note), CreatedBy: payout.CreatedBy, CreatedAt: payout.CreatedAt,
	}, nil
}

// StatusIssues is the admin filter for unpaid, disputed and needs_review payments (FR-017).
const StatusIssues = "issues"

// ValidAdminStatus reports whether status is a filter of GET /v1/admin/trip-payments.
func ValidAdminStatus(status string) bool {
	switch store.TripPaymentStatus(status) {
	case statusPending, statusBoldInProgress, statusCashReported, statusPaid, statusUnpaid, statusDisputed, statusNeedsReview,
		statusVoided:
		return true
	}
	return status == "" || status == StatusIssues
}

// AdminList lists trip payments by status, or the issues (FR-017).
func (s *Service) AdminList(ctx context.Context, status string) ([]AdminView, error) {
	arg := store.ListTripPaymentsForAdminParams{Issues: status == StatusIssues}
	if status != "" && status != StatusIssues {
		arg.Status = store.NullTripPaymentStatus{TripPaymentStatus: store.TripPaymentStatus(status), Valid: true}
	}
	rows, err := s.Store.ListTripPaymentsForAdmin(ctx, arg)
	if err != nil {
		return nil, err
	}
	out := make([]AdminView, len(rows))
	for i, r := range rows {
		out[i] = s.adminView(r.TripPayment, r.DriverName, r.PassengerName)
	}
	return out, nil
}

func (s *Service) adminGet(ctx context.Context, id uuid.UUID) (AdminView, error) {
	r, err := s.Store.GetTripPaymentWithNames(ctx, id)
	if store.IsNotFound(err) {
		return AdminView{}, ErrNotFound
	}
	if err != nil {
		return AdminView{}, err
	}
	return s.adminView(r.TripPayment, r.DriverName, r.PassengerName), nil
}

// Resolution outcomes of a dispute or an unpaid trip.
const (
	ResolvePaid   = "paid"
	ResolveUnpaid = "unpaid"
)

// Resolve closes a dispute or an unpaid trip after the admin talked to both parties: paid in
// cash or unpaid, with an audited note (FR-017).
func (s *Service) Resolve(ctx context.Context, adminID, id uuid.UUID, outcome, note string) (AdminView, error) {
	note = strings.TrimSpace(note)
	if outcome != ResolvePaid && outcome != ResolveUnpaid {
		return AdminView{}, ErrInvalidOutcome
	}
	if note == "" || utf8.RuneCountInString(note) > 200 {
		return AdminView{}, ErrNoteRequired
	}
	now := s.now()
	err := s.mutate(ctx, id, func(_ *store.Queries, p *store.TripPayment, _ *change) error {
		if p.Status != statusDisputed && p.Status != statusUnpaid {
			return ErrInvalidState
		}
		if outcome == ResolvePaid {
			p.Status, p.Method, p.PaidAt = statusPaid, method(store.TripPaymentMethodCash), ts(now)
		} else {
			p.Status = statusUnpaid
			if !p.UnpaidMarkedAt.Valid {
				p.UnpaidMarkedAt = ts(now)
			}
		}
		p.ResolvedBy = uuid.NullUUID{UUID: adminID, Valid: true}
		p.ResolutionNote, p.ResolvedAt = optText(note), ts(now)
		return nil
	})
	if store.IsNotFound(err) {
		return AdminView{}, ErrNotFound
	}
	if err != nil {
		return AdminView{}, err
	}
	return s.adminGet(ctx, id)
}

// Void cancels a Bold payment refunded in Bold, or one in review, with a reason and debits the
// credit (FR-014).
func (s *Service) Void(ctx context.Context, adminID, id uuid.UUID, reason string) (AdminView, error) {
	reason = strings.TrimSpace(reason)
	if reason == "" || utf8.RuneCountInString(reason) > 200 {
		return AdminView{}, ErrReasonRequired
	}
	now := s.now()
	err := s.mutate(ctx, id, func(q *store.Queries, p *store.TripPayment, c *change) error {
		bold := p.Method.Valid && p.Method.TripPaymentMethod == store.TripPaymentMethodBold
		if !(p.Status == statusPaid && bold) && p.Status != statusNeedsReview {
			return ErrInvalidState
		}
		n, err := void(ctx, q, p, now, uuid.NullUUID{UUID: adminID, Valid: true}, reason)
		if err != nil {
			return err
		}
		c.notices = append(c.notices, n)
		return nil
	})
	if store.IsNotFound(err) {
		return AdminView{}, ErrNotFound
	}
	if err != nil {
		return AdminView{}, err
	}
	return s.adminGet(ctx, id)
}
