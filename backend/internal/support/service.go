package support

import (
	"context"
	"log/slog"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
)

// EventCase tells the participants and the panel that a case changed; it carries no text.
const EventCase = "support.case"

// Desenlaces de la resolución de un pago desde el caso (los de 004).
const (
	OutcomePaid   = "paid"
	OutcomeUnpaid = "unpaid"
)

// PaymentResolver applies the resolution of 004 to a trip payment (trippay.Service).
type PaymentResolver interface {
	ResolvePayment(ctx context.Context, adminID, paymentID uuid.UUID, outcome, note string) error
}

// Service implements the support use cases.
type Service struct {
	Store     *store.Store
	Publisher realtime.Publisher
	Payments  PaymentResolver
	Now       func() time.Time
	Logger    *slog.Logger
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

// Open creates a case of userID with its first message (FR-005).
func (s *Service) Open(ctx context.Context, userID uuid.UUID, topic, description string, tripID *uuid.UUID) (Detail, error) {
	if !topics[topic] {
		return Detail{}, ErrInvalidTopic
	}
	body, err := validText(description, MinDescription)
	if err != nil {
		return Detail{}, err
	}
	now := s.now()
	id := uuid.New()
	var sc store.SupportCase
	err = s.Store.WithTx(ctx, func(q *store.Queries) error {
		role, err := q.GetUserRoleForSupport(ctx, userID)
		if err != nil {
			return err
		}
		var trip uuid.NullUUID
		if tripID != nil {
			t, err := q.GetTripPartiesForSupport(ctx, *tripID)
			if store.IsNotFound(err) {
				return ErrInvalidTrip
			}
			if err != nil {
				return err
			}
			if (t.PassengerID != userID && t.DriverID != userID) || now.Sub(t.CreatedAt) > TripWindow {
				return ErrInvalidTrip
			}
			trip = uuid.NullUUID{UUID: *tripID, Valid: true}
		}
		sc = store.SupportCase{
			ID: id, UserID: userID, UserRole: role, Topic: store.SupportTopic(topic), Subject: subjectOf(body),
			TripID: trip, Status: store.SupportStatusOpen, CreatedAt: now, LastMessageAt: now,
			LastUserMessageAt: ts(now), LastAuthorIsUser: true,
		}
		if err := q.InsertSupportCase(ctx, insertParams(sc)); err != nil {
			return err
		}
		return insertMessage(ctx, q, id, uuid.NullUUID{UUID: userID, Valid: true}, AuthorUser, body, false, now)
	})
	if err != nil {
		return Detail{}, err
	}
	s.announce(ctx, sc)
	return s.UserCase(ctx, userID, id)
}

// UserCases lists the cases userID opened or takes part in (FR-011).
func (s *Service) UserCases(ctx context.Context, userID uuid.UUID) ([]Case, error) {
	rows, err := s.Store.ListUserSupportCases(ctx, userID)
	if err != nil {
		return nil, err
	}
	out := make([]Case, len(rows))
	for i, r := range rows {
		out[i] = caseOf(r.SupportCase, r.UserName, r.CounterpartName, r.AssignedName)
	}
	return out, nil
}

// UserCase returns a case of userID without internal notes.
func (s *Service) UserCase(ctx context.Context, userID, caseID uuid.UUID) (Detail, error) {
	d, sc, err := s.detail(ctx, caseID, false, userID)
	if err != nil {
		return Detail{}, err
	}
	if !visibleTo(sc, userID) {
		return Detail{}, ErrNotFound
	}
	return d, nil
}

// AdminCase returns a case with its internal notes.
func (s *Service) AdminCase(ctx context.Context, adminID, caseID uuid.UUID) (Detail, error) {
	d, _, err := s.detail(ctx, caseID, true, adminID)
	return d, err
}

func (s *Service) detail(ctx context.Context, caseID uuid.UUID, internal bool, viewer uuid.UUID) (Detail, store.SupportCase, error) {
	row, err := s.Store.GetSupportCase(ctx, caseID)
	if store.IsNotFound(err) {
		return Detail{}, store.SupportCase{}, ErrNotFound
	}
	if err != nil {
		return Detail{}, store.SupportCase{}, err
	}
	msgs, err := s.Store.ListSupportMessages(ctx, store.ListSupportMessagesParams{CaseID: caseID, IncludeInternal: internal})
	if err != nil {
		return Detail{}, store.SupportCase{}, err
	}
	d := Detail{Case: caseOf(row.SupportCase, row.UserName, row.CounterpartName, row.AssignedName), Messages: make([]Message, len(msgs))}
	for i, m := range msgs {
		d.Messages[i] = Message{
			ID: m.ID, AuthorKind: m.AuthorKind, Body: m.Body, Internal: m.Internal, CreatedAt: m.CreatedAt,
			Mine: m.AuthorID.Valid && m.AuthorID.UUID == viewer,
		}
		if m.AuthorName.Valid {
			d.Messages[i].AuthorName = &m.AuthorName.String
		}
	}
	return d, row.SupportCase, nil
}

// UserReply adds a message of userID. Answering a case waiting for the user or resolved
// reopens it; a closed case does not admit messages (FR-007).
func (s *Service) UserReply(ctx context.Context, userID, caseID uuid.UUID, body string) (Detail, error) {
	body, err := validText(body, 1)
	if err != nil {
		return Detail{}, err
	}
	sc, err := s.change(ctx, caseID, func(q *store.Queries, sc *store.SupportCase, now time.Time) error {
		if !visibleTo(*sc, userID) {
			return ErrNotFound
		}
		if sc.Status == store.SupportStatusClosed {
			return ErrCaseClosed
		}
		if sc.Status == store.SupportStatusWaitingUser || sc.Status == store.SupportStatusResolved {
			sc.Status, sc.ResolvedAt = store.SupportStatusOpen, pgtype.Timestamptz{}
		}
		sc.LastMessageAt, sc.LastUserMessageAt, sc.LastAuthorIsUser = now, ts(now), true
		return insertMessage(ctx, q, caseID, uuid.NullUUID{UUID: userID, Valid: true}, AuthorUser, body, false, now)
	})
	if err != nil {
		return Detail{}, err
	}
	return s.UserCase(ctx, userID, sc.ID)
}

// AdminReply adds an answer or, with internal, a note only admins see (FR-006). An answer to an
// open case puts it in progress and, if nobody had it, assigns it to adminID.
func (s *Service) AdminReply(ctx context.Context, adminID, caseID uuid.UUID, body string, internal bool) (Detail, error) {
	body, err := validText(body, 1)
	if err != nil {
		return Detail{}, err
	}
	_, err = s.change(ctx, caseID, func(q *store.Queries, sc *store.SupportCase, now time.Time) error {
		if sc.Status == store.SupportStatusClosed {
			return ErrCaseClosed
		}
		if !sc.AssignedTo.Valid {
			sc.AssignedTo = uuid.NullUUID{UUID: adminID, Valid: true}
		}
		if !internal {
			if sc.Status == store.SupportStatusOpen {
				sc.Status = store.SupportStatusInProgress
			}
			sc.LastMessageAt, sc.LastAuthorIsUser = now, false
		}
		return insertMessage(ctx, q, caseID, uuid.NullUUID{UUID: adminID, Valid: true}, AuthorAdmin, body, internal, now)
	})
	if err != nil {
		return Detail{}, err
	}
	return s.AdminCase(ctx, adminID, caseID)
}

// SetStatus changes the status of a case (FR-007). A closed case stays closed.
func (s *Service) SetStatus(ctx context.Context, adminID, caseID uuid.UUID, status string) (Detail, error) {
	if !statuses[status] {
		return Detail{}, ErrInvalidStatus
	}
	_, err := s.change(ctx, caseID, func(_ *store.Queries, sc *store.SupportCase, now time.Time) error {
		if sc.Status == store.SupportStatusClosed {
			return ErrCaseClosed
		}
		sc.Status = store.SupportStatus(status)
		switch sc.Status {
		case store.SupportStatusResolved:
			sc.ResolvedAt = ts(now)
		case store.SupportStatusClosed:
			sc.ClosedAt = ts(now)
		default:
			sc.ResolvedAt = pgtype.Timestamptz{}
		}
		return nil
	})
	if err != nil {
		return Detail{}, err
	}
	return s.AdminCase(ctx, adminID, caseID)
}

// Assign gives the case to an admin, or nobody with uuid.Nil.
func (s *Service) Assign(ctx context.Context, adminID, caseID, assignee uuid.UUID) (Detail, error) {
	_, err := s.change(ctx, caseID, func(q *store.Queries, sc *store.SupportCase, _ time.Time) error {
		if assignee == uuid.Nil {
			sc.AssignedTo = uuid.NullUUID{}
			return nil
		}
		role, err := q.GetUserRoleForSupport(ctx, assignee)
		if store.IsNotFound(err) || (err == nil && role != store.UserRoleAdmin) {
			return ErrInvalidAssignee
		}
		if err != nil {
			return err
		}
		sc.AssignedTo = uuid.NullUUID{UUID: assignee, Valid: true}
		return nil
	})
	if err != nil {
		return Detail{}, err
	}
	return s.AdminCase(ctx, adminID, caseID)
}

// ResolvePayment applies the resolution of 004 from a payment case (FR-010); trippay marks the
// case resolved in the same transaction.
func (s *Service) ResolvePayment(ctx context.Context, adminID, caseID uuid.UUID, outcome, note string) (Detail, error) {
	row, err := s.Store.GetSupportCase(ctx, caseID)
	if store.IsNotFound(err) {
		return Detail{}, ErrNotFound
	}
	if err != nil {
		return Detail{}, err
	}
	if !row.SupportCase.TripPaymentID.Valid || s.Payments == nil {
		return Detail{}, ErrNotPaymentCase
	}
	if err := s.Payments.ResolvePayment(ctx, adminID, row.SupportCase.TripPaymentID.UUID, outcome, note); err != nil {
		return Detail{}, err
	}
	return s.AdminCase(ctx, adminID, caseID)
}

// Inbox lists the cases of the panel (FR-008).
func (s *Service) Inbox(ctx context.Context, f Filter) ([]Case, error) {
	p := store.ListAdminSupportCasesParams{Unanswered: f.Unanswered, IncludeClosed: f.IncludeClosed}
	if f.Status != "" {
		if !statuses[f.Status] {
			return nil, ErrInvalidStatus
		}
		p.Status = store.NullSupportStatus{SupportStatus: store.SupportStatus(f.Status), Valid: true}
	}
	if f.Topic != "" {
		if !topics[f.Topic] {
			return nil, ErrInvalidTopic
		}
		p.Topic = store.NullSupportTopic{SupportTopic: store.SupportTopic(f.Topic), Valid: true}
	}
	if f.AssignedTo != uuid.Nil {
		p.AssignedTo = uuid.NullUUID{UUID: f.AssignedTo, Valid: true}
	}
	rows, err := s.Store.ListAdminSupportCases(ctx, p)
	if err != nil {
		return nil, err
	}
	out := make([]Case, len(rows))
	for i, r := range rows {
		out[i] = caseOf(r.SupportCase, r.UserName, r.CounterpartName, r.AssignedName)
	}
	return out, nil
}

// RecentTrips lists the trips of userID of the last 30 days to attach to a case.
func (s *Service) RecentTrips(ctx context.Context, userID uuid.UUID) ([]RecentTrip, error) {
	rows, err := s.Store.ListRecentTripsForSupport(ctx, store.ListRecentTripsForSupportParams{
		UserID: userID, Since: s.now().Add(-TripWindow),
	})
	if err != nil {
		return nil, err
	}
	out := make([]RecentTrip, len(rows))
	for i, r := range rows {
		other := r.DriverName
		if r.DriverID == userID {
			other = r.PassengerName
		}
		out[i] = RecentTrip{ID: r.ID, Status: string(r.Status), CreatedAt: r.CreatedAt, OtherParty: other}
	}
	return out, nil
}

// CloseStale closes the resolved cases without an answer in 7 days (FR-012).
func (s *Service) CloseStale(ctx context.Context) (int, error) {
	now := s.now()
	rows, err := s.Store.CloseStaleSupportCases(ctx, store.CloseStaleSupportCasesParams{Now: ts(now), Cutoff: ts(now.Add(-AutoCloseAfter))})
	if err != nil {
		return 0, err
	}
	for _, r := range rows {
		s.announce(ctx, store.SupportCase{ID: r.ID, UserID: r.UserID, CounterpartID: r.CounterpartID, Status: store.SupportStatusClosed})
	}
	return len(rows), nil
}

// RunSweeper closes stale cases every interval until ctx ends.
func (s *Service) RunSweeper(ctx context.Context, every time.Duration) {
	t := time.NewTicker(every)
	defer t.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-t.C:
			if _, err := s.CloseStale(ctx); err != nil && ctx.Err() == nil {
				s.logger().WarnContext(ctx, "close stale support cases", "err", err)
			}
		}
	}
}

// change locks the case, applies fn and saves it; then announces it.
func (s *Service) change(ctx context.Context, caseID uuid.UUID, fn func(q *store.Queries, sc *store.SupportCase, now time.Time) error) (store.SupportCase, error) {
	now := s.now()
	var sc store.SupportCase
	err := s.Store.WithTx(ctx, func(q *store.Queries) error {
		var err error
		sc, err = q.LockSupportCase(ctx, caseID)
		if store.IsNotFound(err) {
			return ErrNotFound
		}
		if err != nil {
			return err
		}
		if err := fn(q, &sc, now); err != nil {
			return err
		}
		return save(ctx, q, sc)
	})
	if err != nil {
		return store.SupportCase{}, err
	}
	s.announce(ctx, sc)
	return sc, nil
}

func save(ctx context.Context, q *store.Queries, sc store.SupportCase) error {
	return q.UpdateSupportCase(ctx, store.UpdateSupportCaseParams{
		ID: sc.ID, Status: sc.Status, AssignedTo: sc.AssignedTo, LastMessageAt: sc.LastMessageAt,
		LastUserMessageAt: sc.LastUserMessageAt, LastAuthorIsUser: sc.LastAuthorIsUser,
		ResolvedAt: sc.ResolvedAt, ClosedAt: sc.ClosedAt,
	})
}

func insertParams(sc store.SupportCase) store.InsertSupportCaseParams {
	return store.InsertSupportCaseParams{
		ID: sc.ID, UserID: sc.UserID, UserRole: sc.UserRole, CounterpartID: sc.CounterpartID, Topic: sc.Topic,
		Subject: sc.Subject, TripID: sc.TripID, TripPaymentID: sc.TripPaymentID, Status: sc.Status,
		CreatedAt: sc.CreatedAt, LastMessageAt: sc.LastMessageAt, LastUserMessageAt: sc.LastUserMessageAt,
		LastAuthorIsUser: sc.LastAuthorIsUser,
	}
}

func insertMessage(ctx context.Context, q *store.Queries, caseID uuid.UUID, author uuid.NullUUID, kind, body string, internal bool, now time.Time) error {
	// UUIDv7 crece con cada mensaje: ordena la conversación aunque dos tengan la misma hora.
	id, err := uuid.NewV7()
	if err != nil {
		return err
	}
	return q.InsertSupportMessage(ctx, store.InsertSupportMessageParams{
		ID: id, CaseID: caseID, AuthorID: author, AuthorKind: kind, Body: body, Internal: internal, CreatedAt: now,
	})
}

// announce publishes "support.case" to the participants and to the inbox of the panel (FR-009).
func (s *Service) announce(ctx context.Context, sc store.SupportCase) {
	if s.Publisher == nil {
		return
	}
	ev := realtime.Event{Type: EventCase, OccurredAt: s.now(), Data: map[string]any{
		"case_id": sc.ID, "status": sc.Status,
	}}
	channels := []string{realtime.AdminSupportChannel, "user:" + sc.UserID.String()}
	if sc.CounterpartID.Valid {
		channels = append(channels, "user:"+sc.CounterpartID.UUID.String())
	}
	for _, ch := range channels {
		if err := s.Publisher.Publish(ctx, ch, ev); err != nil {
			s.logger().WarnContext(ctx, "publish support event", "channel", ch, "err", err)
		}
	}
}

// Announce publishes a case changed by another module (the payment cases of trippay).
func (s *Service) Announce(ctx context.Context, caseID uuid.UUID) {
	row, err := s.Store.GetSupportCase(ctx, caseID)
	if err != nil {
		s.logger().WarnContext(ctx, "load support case to announce", "case", caseID, "err", err)
		return
	}
	s.announce(ctx, row.SupportCase)
}
