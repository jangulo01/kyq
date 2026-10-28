package support

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/store"
)

// PaymentCaseOpened opens (or reopens) the payment case of a 004 dispute or "no me pagó", inside
// the transaction of trippay (research R3). The driver opens it and the passenger takes part;
// text is the first message of the system. It returns the case to announce after commit.
func (s *Service) PaymentCaseOpened(ctx context.Context, q *store.Queries, p store.TripPayment, subject, text string, now time.Time) (uuid.UUID, error) {
	sc, err := q.GetSupportCaseByPayment(ctx, uuid.NullUUID{UUID: p.ID, Valid: true})
	switch {
	case store.IsNotFound(err):
		sc = store.SupportCase{
			ID: uuid.New(), UserID: p.DriverID, UserRole: store.UserRoleDriver,
			CounterpartID: uuid.NullUUID{UUID: p.PassengerID, Valid: true}, Topic: store.SupportTopicPayment,
			Subject: subject, TripID: uuid.NullUUID{UUID: p.TripID, Valid: true},
			TripPaymentID: uuid.NullUUID{UUID: p.ID, Valid: true}, Status: store.SupportStatusOpen,
			CreatedAt: now, LastMessageAt: now, LastUserMessageAt: ts(now), LastAuthorIsUser: true,
		}
		if err := q.InsertSupportCase(ctx, insertParams(sc)); err != nil {
			return uuid.Nil, err
		}
	case err != nil:
		return uuid.Nil, err
	default:
		if sc, err = q.LockSupportCase(ctx, sc.ID); err != nil {
			return uuid.Nil, err
		}
		sc.Status, sc.ResolvedAt, sc.ClosedAt = store.SupportStatusOpen, pgtype.Timestamptz{}, pgtype.Timestamptz{}
		sc.LastMessageAt, sc.LastUserMessageAt, sc.LastAuthorIsUser = now, ts(now), true
		if err := save(ctx, q, sc); err != nil {
			return uuid.Nil, err
		}
	}
	return sc.ID, insertMessage(ctx, q, sc.ID, uuid.NullUUID{}, AuthorSystem, text, false, now)
}

// PaymentCaseResolved marks the payment case resolved when 004 settles the payment (FR-010). It
// does nothing when the payment has no case.
func (s *Service) PaymentCaseResolved(ctx context.Context, q *store.Queries, p store.TripPayment, text string, now time.Time) (uuid.UUID, error) {
	sc, err := q.GetSupportCaseByPayment(ctx, uuid.NullUUID{UUID: p.ID, Valid: true})
	if store.IsNotFound(err) {
		return uuid.Nil, nil
	}
	if err != nil {
		return uuid.Nil, err
	}
	if sc, err = q.LockSupportCase(ctx, sc.ID); err != nil {
		return uuid.Nil, err
	}
	if sc.Status != store.SupportStatusClosed {
		sc.Status, sc.ResolvedAt = store.SupportStatusResolved, ts(now)
	}
	sc.LastMessageAt, sc.LastAuthorIsUser = now, false
	if err := save(ctx, q, sc); err != nil {
		return uuid.Nil, err
	}
	return sc.ID, insertMessage(ctx, q, sc.ID, uuid.NullUUID{}, AuthorSystem, text, false, now)
}
