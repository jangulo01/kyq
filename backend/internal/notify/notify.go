// Package notify keeps the in-app notices of drivers and sends the critical ones by SMS
// (research R5). There are no push notifications: the app lists notices and receives
// notice.created on its user:{id} channel.
package notify

import (
	"context"
	"log/slog"
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
)

// smsWindow bounds SMS retries: an SMS not sent within a day is no longer useful.
const smsWindow = 24 * time.Hour

// Notice is a notice to create. DedupKey makes creation idempotent per driver, e.g.
// "doc_expiring:{docId}:3".
type Notice struct {
	Kind     string
	DedupKey string
	Title    string
	Body     string
	SMS      bool
}

// View is the JSON of a notice (contracts: Notice).
type View struct {
	ID        uuid.UUID  `json:"id"`
	Kind      string     `json:"kind"`
	Title     string     `json:"title"`
	Body      string     `json:"body"`
	CreatedAt time.Time  `json:"created_at"`
	ReadAt    *time.Time `json:"read_at"`
}

// ToView converts a stored notice.
func ToView(n store.Notice) View {
	v := View{ID: n.ID, Kind: n.Kind, Title: n.Title, Body: n.Body, CreatedAt: n.CreatedAt}
	if n.ReadAt.Valid {
		t := n.ReadAt.Time
		v.ReadAt = &t
	}
	return v
}

// Service creates, announces and delivers notices.
type Service struct {
	Store     *store.Store
	Publisher realtime.Publisher
	SMS       SMSSender
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

// Create stores n with q (which may be a transaction) and returns nil when a notice with the
// same DedupKey already existed. Call Announce after the transaction commits.
func Create(ctx context.Context, q *store.Queries, driverID uuid.UUID, now time.Time, n Notice) (*store.Notice, error) {
	id, err := uuid.NewV7()
	if err != nil {
		return nil, err
	}
	row, err := q.InsertNotice(ctx, store.InsertNoticeParams{
		ID: id, DriverID: driverID, Kind: n.Kind, DedupKey: n.DedupKey, Title: n.Title, Body: n.Body, Sms: n.SMS,
		CreatedAt: now,
	})
	if store.IsNotFound(err) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &row, nil
}

// Announce publishes notice.created to the driver. Errors are logged: the notice is already
// stored and the app also lists them.
func (s *Service) Announce(ctx context.Context, n *store.Notice) {
	if s == nil || n == nil || s.Publisher == nil {
		return
	}
	ev := realtime.Event{Type: "notice.created", OccurredAt: n.CreatedAt, Data: ToView(*n)}
	if err := s.Publisher.Publish(ctx, "user:"+n.DriverID.String(), ev); err != nil {
		s.logger().WarnContext(ctx, "publish notice.created", "err", err)
	}
}

// Notify creates and announces a notice outside any transaction. It returns whether the notice
// was new.
func (s *Service) Notify(ctx context.Context, driverID uuid.UUID, n Notice) (bool, error) {
	row, err := Create(ctx, s.Store.Queries, driverID, s.now(), n)
	if err != nil || row == nil {
		return false, err
	}
	s.Announce(ctx, row)
	return true, nil
}

// SendPendingSMS sends the SMS of recent notices that still have none. It returns how many were
// sent; a failed one is retried on the next run.
func (s *Service) SendPendingSMS(ctx context.Context) (int, error) {
	if s.SMS == nil {
		return 0, nil
	}
	now := s.now()
	rows, err := s.Store.ListPendingSMS(ctx, now.Add(-smsWindow))
	if err != nil {
		return 0, err
	}
	sent := 0
	for _, r := range rows {
		if err := s.SMS.SendSMS(ctx, r.PhoneE164, "Kyq: "+r.Body); err != nil {
			s.logger().WarnContext(ctx, "send notice sms", "notice_id", r.ID, "err", err)
			continue
		}
		if err := s.Store.MarkNoticeSMSSent(ctx, store.MarkNoticeSMSSentParams{ID: r.ID, SmsSentAt: timestamptz(now)}); err != nil {
			return sent, err
		}
		sent++
	}
	return sent, nil
}

// RunSweeper sends pending SMS every interval until ctx ends.
func (s *Service) RunSweeper(ctx context.Context, interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			if n, err := s.SendPendingSMS(ctx); err != nil {
				s.logger().ErrorContext(ctx, "send notice sms", "err", err)
			} else if n > 0 {
				s.logger().InfoContext(ctx, "notice sms sent", "count", n)
			}
		}
	}
}
