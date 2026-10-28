// Package ptt runs the 1:1 walkie-talkie channel of each trip: LiveKit room credentials, the
// floor (who may talk) and the channel closing (RN-KYQ-009, RN-KYQ-011, RN-KYQ-014).
package ptt

import (
	"context"
	"errors"
	"log/slog"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/telemetry"
)

const (
	// FloorTTL caps one turn; a client that dies mid-turn frees the channel by itself (FR-017).
	FloorTTL = 60 * time.Second
	// TokenTTL bounds a room token. LiveKit renews the credentials of connected clients, so it
	// only limits joining: the apps ask for a new one when they reconnect.
	TokenTTL = 10 * time.Minute
)

var (
	ErrNotFound    = errors.New("trip not found")
	ErrNotOpen     = errors.New("ptt channel not open yet")
	ErrClosed      = errors.New("ptt channel closed")
	ErrBusy        = errors.New("floor taken by the other party")
	ErrUnavailable = errors.New("voice server unavailable")
)

// Credentials is the body of POST /v1/trips/{tripId}/ptt/token.
type Credentials struct {
	URL      string     `json:"url"`
	Token    string     `json:"token"`
	Room     string     `json:"room"`
	ClosesAt *time.Time `json:"closes_at"`
}

// Service implements the PTT use cases. The trips module opens the channel row and schedules
// its closing in the same transaction as the trip transition.
//
// LiveKit must run with room auto-creation off (infra/livekit.yaml): rooms exist only while
// this service keeps them, so a token issued before the channel closed cannot reopen it.
type Service struct {
	Store   *store.Store
	LiveKit LiveKit
	Rooms   Rooms
	// Groups serves the cooperative group channel (006); nil disables it.
	Groups    GroupRooms
	PublicURL string // LiveKit WebSocket URL handed to the apps
	Publisher realtime.Publisher
	Usage     telemetry.Usage
	Now       func() time.Time
	Logger    *slog.Logger

	lastPurge time.Time // último borrado de pre-consultas viejas (solo el barrido)
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

func ts(t time.Time) pgtype.Timestamptz { return pgtype.Timestamptz{Time: t, Valid: true} }

func holder(id uuid.UUID) uuid.NullUUID { return uuid.NullUUID{UUID: id, Valid: true} }

// other returns the party of the trip that is not userID, or ErrNotFound when userID takes no
// part in it (the trip's existence is not revealed).
func (s *Service) other(ctx context.Context, userID, tripID uuid.UUID) (uuid.UUID, error) {
	p, err := s.Store.GetTripParties(ctx, tripID)
	if store.IsNotFound(err) {
		return uuid.Nil, ErrNotFound
	}
	if err != nil {
		return uuid.Nil, err
	}
	switch userID {
	case p.PassengerID:
		return p.DriverID, nil
	case p.DriverID:
		return p.PassengerID, nil
	}
	return uuid.Nil, ErrNotFound
}

// channel returns the open channel of tripID.
func (s *Service) channel(ctx context.Context, tripID uuid.UUID, now time.Time) (store.PttChannel, error) {
	ch, err := s.Store.GetPTTChannel(ctx, tripID)
	if store.IsNotFound(err) {
		return store.PttChannel{}, ErrNotOpen
	}
	if err != nil {
		return store.PttChannel{}, err
	}
	if ch.ClosedAt.Valid || (ch.ClosesAt.Valid && !ch.ClosesAt.Time.After(now)) {
		return store.PttChannel{}, ErrClosed
	}
	return ch, nil
}

// Token issues room credentials, never valid past the channel closing (FR-016, FR-020).
func (s *Service) Token(ctx context.Context, userID, tripID uuid.UUID) (Credentials, error) {
	now := s.now()
	if _, err := s.other(ctx, userID, tripID); err != nil {
		return Credentials{}, err
	}
	ch, err := s.channel(ctx, tripID, now)
	if err != nil {
		return Credentials{}, err
	}
	ttl := TokenTTL
	var closesAt *time.Time
	if ch.ClosesAt.Valid {
		ttl = min(ttl, ch.ClosesAt.Time.Sub(now))
		closesAt = &ch.ClosesAt.Time
	}
	name, err := s.Store.GetUserDisplayName(ctx, userID)
	if err != nil {
		return Credentials{}, err
	}
	// Sin creación automática en LiveKit, el token no sirve si la sala no existe.
	if err := s.Rooms.CreateRoom(ctx, ch.RoomName); err != nil {
		s.logger().ErrorContext(ctx, "create livekit room", "room", ch.RoomName, "err", err)
		return Credentials{}, ErrUnavailable
	}
	token, err := s.LiveKit.ParticipantToken(userID.String(), name, ch.RoomName, now, ttl)
	if err != nil {
		return Credentials{}, err
	}
	return Credentials{URL: s.PublicURL, Token: token, Room: ch.RoomName, ClosesAt: closesAt}, nil
}

// TakeFloor grants the exclusive turn for FloorTTL and lets the caller publish audio in the
// room. The holder may renew it (FR-017).
//
// Publishing rights follow the floor row fail-closed: a row is cleared only after LiveKit
// confirmed the revoke (ReleaseFloor, ExpireFloors), so whoever may publish always holds the
// floor or an expired floor the sweeper keeps retrying, and nobody else can take it meanwhile.
func (s *Service) TakeFloor(ctx context.Context, userID, tripID uuid.UUID) (time.Time, error) {
	now := s.now()
	if _, err := s.other(ctx, userID, tripID); err != nil {
		return time.Time{}, err
	}
	ch, err := s.channel(ctx, tripID, now)
	if err != nil {
		return time.Time{}, err
	}
	expires, err := s.Store.TakePTTFloor(ctx, store.TakePTTFloorParams{
		UserID: holder(userID), ExpiresAt: ts(now.Add(FloorTTL)), TripID: tripID, Now: ts(now),
	})
	if store.IsNotFound(err) {
		// Entre la lectura y el UPDATE el canal pudo cerrarse.
		if _, err := s.channel(ctx, tripID, now); err != nil {
			return time.Time{}, err
		}
		return time.Time{}, ErrBusy
	}
	if err != nil {
		return time.Time{}, err
	}
	undo := func() error {
		return s.Store.ReleasePTTFloor(ctx, store.ReleasePTTFloorParams{TripID: tripID, FloorHolderID: holder(userID)})
	}
	if err := s.grantPublish(ctx, ch.RoomName, userID, undo); err != nil {
		return time.Time{}, err
	}
	return expires.Time, nil
}

// ReleaseFloor takes away the user's right to publish and then frees the turn. If LiveKit does
// not confirm the revoke the turn stays held, so it expires and the sweeper retries the revoke.
// Releasing a turn you do not hold changes nothing.
func (s *Service) ReleaseFloor(ctx context.Context, userID, tripID uuid.UUID) error {
	if _, err := s.other(ctx, userID, tripID); err != nil {
		return err
	}
	ch, err := s.Store.GetPTTChannel(ctx, tripID)
	if store.IsNotFound(err) {
		return nil
	}
	if err != nil {
		return err
	}
	if ch.FloorHolderID != holder(userID) {
		return nil
	}
	return s.revokeThenRelease(ctx, ch.RoomName, userID, func() error {
		return s.Store.ReleasePTTFloor(ctx, store.ReleasePTTFloorParams{TripID: tripID, FloorHolderID: holder(userID)})
	})
}

// ExpireFloors frees turns past their FloorTTL and revokes their holders' publishing, so an app
// that stopped calling DELETE cannot keep talking.
func (s *Service) ExpireFloors(ctx context.Context) (int, error) {
	now := s.now()
	expired, err := s.Store.ListExpiredPTTFloors(ctx, ts(now))
	if err != nil {
		return 0, err
	}
	floors := make([]expiredFloor, len(expired))
	for i, f := range expired {
		floors[i] = expiredFloor{room: f.RoomName, holder: f.FloorHolderID, clear: func() (int64, error) {
			return s.Store.ClearExpiredPTTFloor(ctx, store.ClearExpiredPTTFloorParams{TripID: f.TripID, HolderID: f.FloorHolderID, Now: ts(now)})
		}}
	}
	return s.expire(ctx, floors)
}

// CloseDue closes every channel whose closes_at has passed: deletes the LiveKit room, marks the
// channel closed and tells both parties (RN-KYQ-014). A failed deletion leaves the channel due,
// so the next sweep retries it. Same sweeper pattern as trips (research R10).
func (s *Service) CloseDue(ctx context.Context) (int, error) {
	now := s.now()
	due, err := s.Store.ListDuePTTChannels(ctx, ts(now))
	if err != nil {
		return 0, err
	}
	count := 0
	for _, ch := range due {
		if err := s.Rooms.DeleteRoom(ctx, ch.RoomName); err != nil {
			s.logger().WarnContext(ctx, "delete livekit room", "room", ch.RoomName, "err", err)
			continue
		}
		n, err := s.Store.MarkPTTClosed(ctx, store.MarkPTTClosedParams{TripID: ch.TripID, ClosedAt: ts(now)})
		if err != nil {
			return count, err
		}
		if n == 0 {
			continue // otra instancia lo cerró
		}
		count++
		if s.Publisher == nil {
			continue
		}
		ev := realtime.Event{Type: "ptt.closed", OccurredAt: now, Data: map[string]any{"trip_id": ch.TripID}}
		for _, user := range []uuid.UUID{ch.PassengerID, ch.DriverID} {
			if err := s.Publisher.Publish(ctx, "user:"+user.String(), ev); err != nil {
				s.logger().WarnContext(ctx, "publish ptt.closed", "trip_id", ch.TripID, "err", err)
			}
		}
		telemetry.Add(s.Usage, ch.DriverID, telemetry.Events, 2)
	}
	return count, nil
}

// RunSweeper expires turns and closes due channels every interval until ctx ends.
func (s *Service) RunSweeper(ctx context.Context, interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			if _, err := s.ExpireFloors(ctx); err != nil {
				s.logger().ErrorContext(ctx, "expire ptt floors", "err", err)
			}
			if _, err := s.ExpireGroupFloors(ctx); err != nil {
				s.logger().ErrorContext(ctx, "expire group ptt floors", "err", err)
			}
			if n, err := s.CloseDue(ctx); err != nil {
				s.logger().ErrorContext(ctx, "close due ptt channels", "err", err)
			} else if n > 0 {
				s.logger().InfoContext(ctx, "closed ptt channels", "count", n)
			}
			s.sweepPreconsults(ctx)
		}
	}
}
