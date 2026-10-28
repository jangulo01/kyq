package trippay

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
)

// Reminders (FR-015): ten minutes after a trip completes without payment nor report.
const RemindAfter = 10 * time.Minute

// SendReminders reminds the passenger (live event) and the driver (notice) once per payment
// and returns how many payments were reminded.
func (s *Service) SendReminders(ctx context.Context) (int, error) {
	now := s.now()
	ids, err := s.Store.ListTripPaymentsToRemind(ctx, now.Add(-RemindAfter))
	if err != nil {
		return 0, err
	}
	count := 0
	for _, id := range ids {
		var reminded *store.TripPayment
		err := s.mutate(ctx, id, func(q *store.Queries, p *store.TripPayment, c *change) error {
			if p.Status != statusPending || p.RemindedAt.Valid {
				return nil
			}
			p.RemindedAt = ts(now)
			day := p.CreatedAt.In(bogota).Format("02/01 15:04")
			n, err := notify.Create(ctx, q, p.DriverID, now, notify.Notice{
				Kind: "trip_payment_pending", DedupKey: "trip_payment_pending:" + p.ID.String(), Title: "¿Te pagaron el viaje?",
				Body: "El pasajero del viaje del " + day + " aún no reporta el pago de " + formatMoney(p.AmountMinor, p.Currency) +
					". Si te pagó en efectivo, confírmalo; si no, márcalo como no pagado en Pagos de viajes.",
			})
			if err != nil {
				return err
			}
			c.notices = append(c.notices, n)
			cp := *p
			reminded = &cp
			return nil
		})
		if err != nil {
			return count, err
		}
		if reminded != nil {
			s.publish(ctx, "user:"+reminded.PassengerID.String(), reminderEvent(*reminded, now))
			count++
		}
	}
	return count, nil
}

func reminderEvent(p store.TripPayment, now time.Time) realtime.Event {
	return realtime.Event{Type: "trip_payment.reminder", OccurredAt: now, Data: map[string]any{
		"trip_id": p.TripID, "payment_id": p.ID, "amount_minor": p.AmountMinor, "currency": p.Currency,
	}}
}

// PollPayments asks Bold for the open checkouts of the last 2 hours and closes older ones as
// expired. It returns how many were polled.
func (s *Service) PollPayments(ctx context.Context) (int, error) {
	if s.Bold == nil {
		return 0, nil
	}
	since := pgtype.Timestamptz{Time: s.now().Add(-pollWindow), Valid: true}
	stale, err := s.Store.ListStaleBoldTripPayments(ctx, since)
	if err != nil {
		return 0, err
	}
	for _, id := range stale {
		if err := s.expire(ctx, id); err != nil {
			return 0, err
		}
	}
	ids, err := s.Store.ListBoldInFlightTripPayments(ctx, since)
	if err != nil {
		return 0, err
	}
	for _, id := range ids {
		p, err := s.Store.GetTripPayment(ctx, id)
		if err != nil {
			return 0, err
		}
		if _, err := s.poll(ctx, p); err != nil {
			s.logger().WarnContext(ctx, "poll bold trip payment", "trip_payment_id", id, "err", err)
		}
	}
	return len(ids), nil
}

func (s *Service) expire(ctx context.Context, id uuid.UUID) error {
	return s.mutate(ctx, id, func(_ *store.Queries, p *store.TripPayment, _ *change) error {
		if p.Status == statusBoldInProgress {
			p.Status, p.CheckoutUrl, p.Method = s.withoutBold(*p), pgtype.Text{}, store.NullTripPaymentMethod{}
		}
		return nil
	})
}

// RunSweeper polls checkouts every interval and sends reminders every reminderEvery until ctx
// ends.
func (s *Service) RunSweeper(ctx context.Context, interval, reminderEvery time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	var lastReminders time.Time
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			if _, err := s.PollPayments(ctx); err != nil {
				s.logger().ErrorContext(ctx, "poll trip payments", "err", err)
			}
			if time.Since(lastReminders) < reminderEvery {
				continue
			}
			lastReminders = time.Now()
			if n, err := s.SendReminders(ctx); err != nil {
				s.logger().ErrorContext(ctx, "trip payment reminders", "err", err)
			} else if n > 0 {
				s.logger().InfoContext(ctx, "trip payment reminders", "count", n)
			}
		}
	}
}
