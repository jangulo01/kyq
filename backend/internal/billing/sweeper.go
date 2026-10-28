package billing

import (
	"context"
	"time"

	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/store"
)

// PollPayments asks Bold for the state of the payments in progress created in the last 2 hours
// and expires older ones (research R2): the sandbox sends no webhooks and production ones may get
// lost. It returns how many payments were polled.
func (s *Service) PollPayments(ctx context.Context) (int, error) {
	if s.Bold == nil {
		return 0, nil
	}
	now := s.now()
	if _, err := s.Store.ExpireStalePayments(ctx, now.Add(-pollWindow)); err != nil {
		return 0, err
	}
	ids, err := s.Store.ListInFlightPayments(ctx, now.Add(-pollWindow))
	if err != nil {
		return 0, err
	}
	for _, id := range ids {
		p, err := s.Store.GetPayment(ctx, id)
		if err != nil {
			return 0, err
		}
		if err := s.poll(ctx, p); err != nil {
			s.logger().WarnContext(ctx, "poll bold payment", "payment_id", id, "err", err)
		}
	}
	return len(ids), nil
}

// Recordatorios de suscripción (FR-019, FR-027): 5 y 1 días antes y al entrar en gracia, en la
// app y por SMS. La clave incluye paid_until para que cada periodo tenga los suyos.
const (
	remindEarly = 5 * 24 * time.Hour
	remindLate  = 24 * time.Hour
)

// SendReminders creates the due subscription reminders once each and returns how many were new.
func (s *Service) SendReminders(ctx context.Context) (int, error) {
	now := s.now()
	rows, err := s.Store.ListSubscriptionsDue(ctx, store.ListSubscriptionsDueParams{
		Since: now.Add(-drivers.GracePeriod), Until: now.Add(remindEarly),
	})
	if err != nil {
		return 0, err
	}
	created := 0
	for _, r := range rows {
		left := r.PaidUntil.Sub(now)
		key := r.PaidUntil.UTC().Format(time.RFC3339)
		due := r.PaidUntil.In(bogota).Format("02/01/2006")
		var n notify.Notice
		switch {
		case left <= 0:
			graceEnd := r.PaidUntil.Add(drivers.GracePeriod).In(bogota).Format("02/01/2006 15:04")
			n = notify.Notice{
				Kind: "sub_grace", DedupKey: "sub_grace:" + key, SMS: true, Title: "Tu suscripción venció",
				Body: "Tu suscripción venció. Tienes hasta el " + graceEnd + " para pagar y seguir trabajando. Paga desde Mi suscripción.",
			}
		case left <= remindLate:
			n = notify.Notice{
				Kind: "sub_expiring", DedupKey: "sub_expiring:" + key + ":1", SMS: true, Title: "Tu suscripción vence mañana",
				Body: "Tu suscripción vence el " + due + ". Paga desde Mi suscripción para no perder días de trabajo.",
			}
		default:
			n = notify.Notice{
				Kind: "sub_expiring", DedupKey: "sub_expiring:" + key + ":5", SMS: true, Title: "Tu suscripción vence pronto",
				Body: "Tu suscripción vence el " + due + ". Puedes pagar desde ya en Mi suscripción; no pierdes los días que te quedan.",
			}
		}
		isNew, err := s.Notify.Notify(ctx, r.DriverID, n)
		if err != nil {
			return created, err
		}
		if isNew {
			created++
		}
	}
	return created, nil
}

// RunSweeper polls payments every interval and sends reminders every reminderEvery until ctx
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
				s.logger().ErrorContext(ctx, "poll payments", "err", err)
			}
			if time.Since(lastReminders) < reminderEvery {
				continue
			}
			lastReminders = time.Now()
			if n, err := s.SendReminders(ctx); err != nil {
				s.logger().ErrorContext(ctx, "subscription reminders", "err", err)
			} else if n > 0 {
				s.logger().InfoContext(ctx, "subscription reminders", "count", n)
			}
		}
	}
}
