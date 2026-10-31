package trippay

import (
	"context"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/store"
)

// inDispute reports whether the payment waits for Kyq: driver's "No recibí el efectivo" or
// "No me pagó" (FR-005, FR-006).
func inDispute(st store.TripPaymentStatus) bool { return st == statusDisputed || st == statusUnpaid }

// syncCase opens, resolves or leaves alone the support case of the payment after a change
// (009, research R3). It returns the case to announce after commit.
func (s *Service) syncCase(ctx context.Context, q *store.Queries, before, after store.TripPayment) (uuid.UUID, error) {
	if s.Cases == nil {
		return uuid.Nil, nil
	}
	now := s.now()
	amount := formatMoney(after.AmountMinor, after.Currency)
	switch {
	case !inDispute(before.Status) && after.Status == statusDisputed:
		return s.Cases.PaymentCaseOpened(ctx, q, after, "Pago del viaje: efectivo no recibido",
			"El conductor indica que no recibió los "+amount+" en efectivo que el pasajero reportó. Kyq revisará el caso con los dos.", now)
	case !inDispute(before.Status) && after.Status == statusUnpaid:
		return s.Cases.PaymentCaseOpened(ctx, q, after, "Pago del viaje: no pagado",
			"El conductor indica que el pasajero no pagó los "+amount+" del viaje. Kyq revisará el caso con los dos.", now)
	case after.ResolvedAt.Valid && after.ResolvedAt != before.ResolvedAt:
		text := "Kyq resolvió que el viaje quedó sin pagar."
		if after.Status == statusPaid {
			text = "Kyq resolvió el pago como pagado en efectivo."
		}
		if after.ResolutionNote.Valid {
			text += " Nota: " + after.ResolutionNote.String
		}
		return s.Cases.PaymentCaseResolved(ctx, q, after, text, now)
	case inDispute(before.Status) && after.Status == statusPaid:
		return s.Cases.PaymentCaseResolved(ctx, q, after, "El pago del viaje quedó registrado como pagado.", now)
	}
	return uuid.Nil, nil
}

// ResolvePayment applies the resolution of 004 from a support case (support.PaymentResolver).
func (s *Service) ResolvePayment(ctx context.Context, adminID, paymentID uuid.UUID, outcome, note string) error {
	_, err := s.Resolve(ctx, adminID, paymentID, outcome, note)
	return err
}
