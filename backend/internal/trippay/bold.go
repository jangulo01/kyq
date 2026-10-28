package trippay

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/billing"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/store"
)

// pollWindow: los enlaces en curso se consultan a Bold durante 2 h, como en 002.
const pollWindow = 2 * time.Hour

// PayWithBold opens (or returns the open) Bold checkout of the trip fare for its passenger
// (FR-003). The amount is the agreed fare, fixed by the server.
func (s *Service) PayWithBold(ctx context.Context, passengerID, tripID uuid.UUID) (View, error) {
	row, party, err := s.loadForParticipant(ctx, passengerID, tripID)
	if err != nil {
		return View{}, err
	}
	p := row.TripPayment
	if party != Passenger {
		return View{}, ErrForbidden
	}
	if !p.AcceptsBold {
		return View{}, ErrMethodNotAccepted
	}
	if s.Bold == nil {
		return View{}, billing.ErrBoldUnavailable
	}
	now := s.now()
	if p.Status == statusBoldInProgress {
		// El enlace vigente se reutiliza; uno caducado se consulta y, si sigue sin pagar, se cierra.
		if now.Sub(p.LinkCreatedAt.Time) < billing.LinkTTL {
			return s.view(p, row.DriverName, row.PassengerName), nil
		}
		o, err := s.poll(ctx, p)
		if err != nil {
			return View{}, err
		}
		if o == billing.OutcomeNone {
			if err := s.confirm(ctx, p.ID, billing.Confirmation{Outcome: billing.OutcomeExpired}, p.BoldLinkID.String); err != nil {
				return View{}, err
			}
		}
		if p, err = s.Store.GetTripPayment(ctx, p.ID); err != nil {
			return View{}, err
		}
	}
	if _, err := Transition(p.Status, StartBold, party); err != nil {
		return View{}, err
	}
	link, err := s.Bold.CreateLink(ctx, billing.LinkRequest{
		Reference: p.ID.String(), Description: "Kyq: pago del viaje", Currency: p.Currency,
		AmountMinor: p.AmountMinor, ExpiresAt: now.Add(billing.LinkTTL),
	})
	if err != nil {
		return View{}, err
	}
	err = s.mutate(ctx, p.ID, func(_ *store.Queries, p *store.TripPayment, _ *change) error {
		if p.Status == statusBoldInProgress {
			return nil // otra petición abrió un enlace mientras tanto: se devuelve ese
		}
		to, err := Transition(p.Status, StartBold, Passenger)
		if err != nil {
			return err
		}
		p.Status, p.Method = to, method(store.TripPaymentMethodBold)
		p.BoldLinkID, p.CheckoutUrl = optText(link.ID), optText(link.URL)
		p.LinkCreatedAt = ts(now)
		return nil
	})
	if err != nil {
		return View{}, err
	}
	return s.Get(ctx, passengerID, tripID)
}

// Refresh asks Bold for the state of the passenger's checkout now (when coming back from it).
func (s *Service) Refresh(ctx context.Context, passengerID, tripID uuid.UUID) (View, error) {
	row, party, err := s.loadForParticipant(ctx, passengerID, tripID)
	if err != nil {
		return View{}, err
	}
	if party != Passenger {
		return View{}, ErrForbidden
	}
	if _, err := s.poll(ctx, row.TripPayment); err != nil && !errors.Is(err, billing.ErrBoldUnavailable) {
		return View{}, err
	} else if err != nil {
		s.logger().WarnContext(ctx, "refresh trip payment", "trip_payment_id", row.TripPayment.ID, "err", err)
	}
	return s.Get(ctx, passengerID, tripID)
}

// poll reads the open link from Bold and applies a final result. It returns the outcome:
// OutcomeNone while the link is still unpaid.
func (s *Service) poll(ctx context.Context, p store.TripPayment) (billing.Outcome, error) {
	if s.Bold == nil || p.Status != statusBoldInProgress || !p.BoldLinkID.Valid {
		return billing.OutcomeNone, nil
	}
	ls, err := s.Bold.GetLink(ctx, p.BoldLinkID.String)
	if err != nil {
		return billing.OutcomeNone, err
	}
	o := billing.ClassifyLink(ls.Status, p.LinkCreatedAt.Time, s.now())
	if o == billing.OutcomeNone || o == billing.OutcomeProcessing {
		return o, nil
	}
	return o, s.confirm(ctx, p.ID, billing.Confirmation{
		Outcome: o, TotalMinor: ls.TotalMinor, Currency: ls.Currency, Detail: ls.PaymentMethod, BoldPaymentID: ls.TransactionID,
	}, p.BoldLinkID.String)
}

// HandleBoldConfirmation implements billing.ReferenceHandler: a signed webhook for a trip
// payment.
func (s *Service) HandleBoldConfirmation(ctx context.Context, reference uuid.UUID, c billing.Confirmation) (bool, error) {
	if _, err := s.Store.GetTripPayment(ctx, reference); store.IsNotFound(err) {
		return false, nil
	} else if err != nil {
		return true, err
	}
	return true, s.confirm(ctx, reference, c, "")
}

// confirm applies a result confirmed by Bold (link status, or webhook when linkID is empty).
// Approving credits the driver once (SC-003), whatever arrives later and in whatever order; a
// different amount or currency goes to needs_review (FR-010). Bold wins over a cash report: it
// is verifiable money (spec, Edge Cases).
func (s *Service) confirm(ctx context.Context, paymentID uuid.UUID, c billing.Confirmation, linkID string) error {
	now := s.now()
	return s.mutate(ctx, paymentID, func(q *store.Queries, p *store.TripPayment, ch *change) error {
		switch c.Outcome {
		case billing.OutcomeApproved:
			switch p.Status {
			case statusVoided, statusNeedsReview:
				return nil
			case statusPaid:
				sameCharge := p.Method.TripPaymentMethod == store.TripPaymentMethodBold &&
					(c.BoldPaymentID == "" || !p.BoldPaymentID.Valid || c.BoldPaymentID == p.BoldPaymentID.String)
				if sameCharge || p.ReviewNote.Valid {
					return nil
				}
				// Segundo cobro del mismo viaje (o efectivo ya confirmado): no se abona otra vez; el
				// administrador reembolsa el sobrante en Bold.
				s.logger().WarnContext(ctx, "second bold charge for a paid trip", "trip_payment_id", p.ID)
				p.ReviewNote = optText(fmt.Sprintf("Bold aprobó otro cobro de %s (transacción %s) para un viaje ya pagado: reembolsar en Bold",
					formatMoney(c.TotalMinor, c.Currency), c.BoldPaymentID))
				return nil
			}
			p.PaymentMethodDetail, p.BoldPaymentID = optText(c.Detail), optText(c.BoldPaymentID)
			p.Method, p.CheckoutUrl = method(store.TripPaymentMethodBold), pgtype.Text{}
			if c.TotalMinor != p.AmountMinor || c.Currency != p.Currency {
				s.logger().WarnContext(ctx, "bold trip payment amount mismatch", "trip_payment_id", p.ID)
				p.Status = statusNeedsReview
				p.ReviewNote = optText(fmt.Sprintf("Bold confirmó %s; se esperaba %s",
					formatMoney(c.TotalMinor, c.Currency), formatMoney(p.AmountMinor, p.Currency)))
				return nil
			}
			p.Status, p.PaidAt = statusPaid, ts(now)
			if err := credit(ctx, q, *p, now); err != nil {
				return err
			}
			n, err := notify.Create(ctx, q, p.DriverID, now, notify.Notice{
				Kind: "trip_payment_paid", DedupKey: "trip_payment_paid:" + p.ID.String(), Title: "Pago recibido con Bold",
				Body: "El pasajero pagó " + formatMoney(p.AmountMinor, p.Currency) + " con Bold. Kyq te lo gira completo, sin comisión.",
			})
			if err != nil {
				return err
			}
			ch.notices = append(ch.notices, n)
		case billing.OutcomeRejected, billing.OutcomeExpired:
			// Solo cierra el enlace en curso; el resultado de un enlace anterior ya no cuenta.
			if p.Status != statusBoldInProgress || (linkID != "" && linkID != p.BoldLinkID.String) {
				return nil
			}
			p.Status, p.CheckoutUrl = s.withoutBold(*p), pgtype.Text{}
			p.Method = store.NullTripPaymentMethod{}
		case billing.OutcomeVoided:
			if p.Status != statusPaid || p.Method.TripPaymentMethod != store.TripPaymentMethodBold {
				return nil
			}
			n, err := void(ctx, q, p, now, uuid.NullUUID{}, "anulado en Bold")
			if err != nil {
				return err
			}
			ch.notices = append(ch.notices, n)
		}
		return nil
	})
}

// credit adds 100 % of the fare to the driver's ledger (FR-011, RN-KYQ-001); once per payment.
func credit(ctx context.Context, q *store.Queries, p store.TripPayment, now time.Time) error {
	id, err := uuid.NewV7()
	if err != nil {
		return err
	}
	_, err = q.InsertLedgerEntry(ctx, store.InsertLedgerEntryParams{
		ID: id, DriverID: p.DriverID, Kind: store.LedgerEntryKindTripCredit, AmountMinor: p.DriverAmountMinor,
		Currency: p.Currency, TripPaymentID: uuid.NullUUID{UUID: p.ID, Valid: true}, CreatedAt: now,
	})
	return err
}

// void cancels a Bold payment (refunded in Bold) and debits what was credited (FR-014). The
// driver row must be locked.
func void(ctx context.Context, q *store.Queries, p *store.TripPayment, now time.Time, by uuid.NullUUID, reason string) (*store.Notice, error) {
	credited, err := q.HasLedgerEntry(ctx, store.HasLedgerEntryParams{
		TripPaymentID: uuid.NullUUID{UUID: p.ID, Valid: true}, Kind: store.LedgerEntryKindTripCredit,
	})
	if err != nil {
		return nil, err
	}
	if credited {
		id, err := uuid.NewV7()
		if err != nil {
			return nil, err
		}
		if _, err := q.InsertLedgerEntry(ctx, store.InsertLedgerEntryParams{
			ID: id, DriverID: p.DriverID, Kind: store.LedgerEntryKindVoidDebit, AmountMinor: -p.DriverAmountMinor,
			Currency: p.Currency, TripPaymentID: uuid.NullUUID{UUID: p.ID, Valid: true}, CreatedBy: by, CreatedAt: now,
		}); err != nil {
			return nil, err
		}
	}
	p.Status, p.VoidedBy, p.VoidReason, p.VoidedAt = statusVoided, by, optText(reason), ts(now)
	body := "Se anuló el pago con Bold de un viaje (" + formatMoney(p.AmountMinor, p.Currency) + "). Motivo: " + reason + "."
	if credited {
		body += " Se descontó de tu saldo por girar."
	}
	return notify.Create(ctx, q, p.DriverID, now, notify.Notice{
		Kind: "trip_payment_voided", DedupKey: "trip_payment_voided:" + p.ID.String(), Title: "Pago de viaje anulado", Body: body,
	})
}
