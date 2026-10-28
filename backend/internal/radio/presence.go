package radio

import (
	"context"
	"fmt"
	"slices"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/store"
)

// QuietHoursRule is one quiet-hours schedule (contracts: QuietHours, FR-021). Weekdays go from
// 1 (lunes) to 7 (domingo); a window that ends before it starts crosses midnight and belongs to
// the day it starts.
type QuietHoursRule struct {
	Weekdays []int  `json:"weekdays"`
	Starts   string `json:"starts"`
	Ends     string `json:"ends"`
	Enabled  bool   `json:"enabled"`
}

// MaxQuietRules bounds the schedules per user.
const MaxQuietRules = 10

func parseClock(v string) (time.Duration, bool) {
	t, err := time.Parse("15:04", v)
	if err != nil {
		return 0, false
	}
	return time.Duration(t.Hour())*time.Hour + time.Duration(t.Minute())*time.Minute, true
}

func clockOf(d time.Duration) string {
	return fmt.Sprintf("%02d:%02d", int(d.Hours()), int(d.Minutes())%60)
}

func isoWeekday(t time.Time) int {
	if t.Weekday() == time.Sunday {
		return 7
	}
	return int(t.Weekday())
}

// quietAt reports whether a rule silences the local time t.
func quietAt(weekdays []int, starts, ends time.Duration, t time.Time) bool {
	day := isoWeekday(t)
	prev := day - 1
	if prev == 0 {
		prev = 7
	}
	now := time.Duration(t.Hour())*time.Hour + time.Duration(t.Minute())*time.Minute
	if starts == ends {
		return false
	}
	if starts < ends {
		return slices.Contains(weekdays, day) && now >= starts && now < ends
	}
	return (slices.Contains(weekdays, day) && now >= starts) || (slices.Contains(weekdays, prev) && now < ends)
}

// GetQuietHours returns the caller's schedules.
func (s *Service) GetQuietHours(ctx context.Context, userID uuid.UUID) ([]QuietHoursRule, error) {
	rows, err := s.Store.ListRadioQuietHours(ctx, userID)
	if err != nil {
		return nil, err
	}
	out := make([]QuietHoursRule, 0, len(rows))
	for _, r := range rows {
		days := make([]int, len(r.Weekdays))
		for i, d := range r.Weekdays {
			days[i] = int(d)
		}
		out = append(out, QuietHoursRule{
			Weekdays: days, Enabled: r.Enabled,
			Starts: clockOf(time.Duration(r.Starts.Microseconds) * time.Microsecond),
			Ends:   clockOf(time.Duration(r.Ends.Microseconds) * time.Microsecond),
		})
	}
	return out, nil
}

// SetQuietHours replaces the caller's schedules.
func (s *Service) SetQuietHours(ctx context.Context, userID uuid.UUID, rules []QuietHoursRule) error {
	if _, _, _, err := s.allowed(ctx, userID); err != nil {
		return err
	}
	if len(rules) > MaxQuietRules {
		return ErrInvalid
	}
	type parsed struct {
		days         []int16
		starts, ends time.Duration
		enabled      bool
	}
	ok := make([]parsed, 0, len(rules))
	for _, r := range rules {
		starts, okS := parseClock(r.Starts)
		ends, okE := parseClock(r.Ends)
		if !okS || !okE || starts == ends || len(r.Weekdays) == 0 || len(r.Weekdays) > 7 {
			return ErrInvalid
		}
		days := make([]int16, 0, len(r.Weekdays))
		for _, d := range r.Weekdays {
			if d < 1 || d > 7 || slices.Contains(days, int16(d)) {
				return ErrInvalid
			}
			days = append(days, int16(d))
		}
		ok = append(ok, parsed{days, starts, ends, r.Enabled})
	}
	if _, err := s.Store.EnsureRadioPresence(ctx, store.EnsureRadioPresenceParams{UserID: userID, UpdatedAt: s.now()}); err != nil {
		return err
	}
	return s.Store.WithTx(ctx, func(q *store.Queries) error {
		if err := q.DeleteRadioQuietHours(ctx, userID); err != nil {
			return err
		}
		for _, r := range ok {
			id, err := newID()
			if err != nil {
				return err
			}
			if err := q.InsertRadioQuietHours(ctx, store.InsertRadioQuietHoursParams{
				ID: id, UserID: userID, Weekdays: r.days, Enabled: r.enabled,
				Starts: pgtype.Time{Microseconds: r.starts.Microseconds(), Valid: true},
				Ends:   pgtype.Time{Microseconds: r.ends.Microseconds(), Valid: true},
			}); err != nil {
				return err
			}
		}
		return nil
	})
}

// QuietHours switches users into Busy when one of their schedules starts and back to their
// previous state when it ends (FR-021), in their time zone. It acts on the edges only, once a
// minute, so a state chosen by hand during a schedule is respected until the next one.
func (s *Service) QuietHours(ctx context.Context) error {
	now := s.now()
	if !s.lastQuiet.IsZero() && now.Sub(s.lastQuiet) < time.Minute {
		return nil
	}
	prev := s.lastQuiet
	if prev.IsZero() {
		prev = now.Add(-time.Minute)
	}
	s.lastQuiet = now
	rows, err := s.Store.ListQuietHoursDue(ctx)
	if err != nil {
		return err
	}
	type state struct {
		row      store.ListQuietHoursDueRow
		now, was bool
	}
	users := map[uuid.UUID]*state{}
	order := []uuid.UUID{}
	for _, r := range rows {
		loc, err := time.LoadLocation(r.Timezone)
		if err != nil {
			loc, _ = time.LoadLocation("America/Bogota")
		}
		days := make([]int, len(r.Weekdays))
		for i, d := range r.Weekdays {
			days[i] = int(d)
		}
		starts := time.Duration(r.Starts.Microseconds) * time.Microsecond
		ends := time.Duration(r.Ends.Microseconds) * time.Microsecond
		st, ok := users[r.UserID]
		if !ok {
			st = &state{row: r}
			users[r.UserID] = st
			order = append(order, r.UserID)
		}
		st.now = st.now || quietAt(days, starts, ends, now.In(loc))
		st.was = st.was || quietAt(days, starts, ends, prev.In(loc))
	}
	for _, id := range order {
		st := users[id]
		var params store.SetRadioQuietStatusParams
		switch {
		case st.now && !st.was && !st.row.StatusBeforeQuiet.Valid:
			params = store.SetRadioQuietStatusParams{
				UserID: id, Status: store.RadioPresenceStatusBusy, UpdatedAt: now,
				StatusBeforeQuiet: store.NullRadioPresenceStatus{RadioPresenceStatus: st.row.Status, Valid: true},
			}
		case !st.now && st.was && st.row.StatusBeforeQuiet.Valid:
			params = store.SetRadioQuietStatusParams{UserID: id, Status: st.row.StatusBeforeQuiet.RadioPresenceStatus, UpdatedAt: now}
		default:
			continue
		}
		if _, err := s.Store.SetRadioQuietStatus(ctx, params); err != nil {
			return err
		}
		p, err := s.Store.EnsureRadioPresence(ctx, store.EnsureRadioPresenceParams{UserID: id, UpdatedAt: now})
		if err != nil {
			return err
		}
		s.announcePresence(ctx, id, p)
		// La barra superior del propio usuario cambia sola (US5-4).
		s.publish(ctx, id, EventPresence, now, map[string]any{"user_id": id, "status": string(p.Status), "quiet_hours": st.now})
	}
	return nil
}
