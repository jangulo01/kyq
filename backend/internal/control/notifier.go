package control

import (
	"context"
	"log/slog"
	"time"

	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
)

// TowerChannel is the Centrifugo channel of the tower; only admins may subscribe (FR-006).
const TowerChannel = realtime.AdminTowerChannel

// EventTowerChanged tells the admin panel to fetch the snapshot again. It carries no data.
const EventTowerChanged = "tower.changed"

// Fingerprint is a cheap summary of the tower state: when it does not change, the panel is not
// notified (research R3).
type Fingerprint = store.TowerFingerprintRow

// FingerprintSource reads the current fingerprint.
type FingerprintSource interface {
	TowerFingerprint(ctx context.Context, since time.Time) (store.TowerFingerprintRow, error)
}

// Notifier publishes "tower.changed" on admin:tower at most once per tick, only when the
// fingerprint changed.
type Notifier struct {
	Source    FingerprintSource
	Publisher realtime.Publisher
	Now       func() time.Time
	Logger    *slog.Logger

	last    Fingerprint
	hasLast bool
}

func (n *Notifier) now() time.Time {
	if n.Now != nil {
		return n.Now()
	}
	return time.Now()
}

func (n *Notifier) logger() *slog.Logger {
	if n.Logger != nil {
		return n.Logger
	}
	return slog.Default()
}

// Tick checks the fingerprint once and publishes when it changed. It reports whether it
// published. The first tick only records the state.
func (n *Notifier) Tick(ctx context.Context) bool {
	now := n.now()
	fp, err := n.Source.TowerFingerprint(ctx, now.Add(-RequestWindow))
	if err != nil {
		n.logger().WarnContext(ctx, "huella de la torre", "err", err)
		return false
	}
	changed := n.hasLast && !sameFingerprint(fp, n.last)
	n.last, n.hasLast = fp, true
	if !changed || n.Publisher == nil {
		return false
	}
	ev := realtime.Event{Type: EventTowerChanged, OccurredAt: now, Data: map[string]any{}}
	if err := n.Publisher.Publish(ctx, TowerChannel, ev); err != nil {
		n.logger().WarnContext(ctx, "publicar tower.changed", "err", err)
		return false
	}
	return true
}

func sameFingerprint(a, b Fingerprint) bool {
	return a.Online == b.Online && a.Busy == b.Busy && a.OpenTrips == b.OpenTrips &&
		a.LastLocationAt.Equal(b.LastLocationAt) && a.LastTripChange.Equal(b.LastTripChange)
}

// Run ticks every interval until ctx ends.
func (n *Notifier) Run(ctx context.Context, interval time.Duration) {
	t := time.NewTicker(interval)
	defer t.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-t.C:
			n.Tick(ctx)
		}
	}
}
