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
)

const (
	// FloorTTL caps one turn; a client that dies mid-turn frees the channel by itself (FR-017).
	FloorTTL = 60 * time.Second
	// openTokenTTL bounds tokens while the trip is active and closes_at is still unknown;
	// clients ask again when they reconnect.
	openTokenTTL = 4 * time.Hour
)

var (
	ErrNotFound = errors.New("trip not found")
	ErrNotOpen  = errors.New("ptt channel not open yet")
	ErrClosed   = errors.New("ptt channel closed")
	ErrBusy     = errors.New("floor taken by the other party")
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
type Service struct {
	Store     *store.Store
	LiveKit   LiveKit
	Rooms     Rooms
	PublicURL string // LiveKit WebSocket URL handed to the apps
	Publisher realtime.Publisher
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

func ts(t time.Time) pgtype.Timestamptz { return pgtype.Timestamptz{Time: t, Valid: true} }

func (s *Service) checkParticipant(ctx context.Context, userID, tripID uuid.UUID) error {
	ok, err := s.Store.IsTripParticipant(ctx, store.IsTripParticipantParams{ID: tripID, PassengerID: userID})
	if err != nil {
		return err
	}
	if !ok {
		return ErrNotFound // no revela que el viaje existe
	}
	return nil
}

// channel returns the open channel of a trip the user takes part in.
func (s *Service) channel(ctx context.Context, userID, tripID uuid.UUID, now time.Time) (store.PttChannel, error) {
	if err := s.checkParticipant(ctx, userID, tripID); err != nil {
		return store.PttChannel{}, err
	}
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

// Token issues room credentials valid until the channel closes (FR-016, FR-020).
func (s *Service) Token(ctx context.Context, userID, tripID uuid.UUID) (Credentials, error) {
	now := s.now()
	ch, err := s.channel(ctx, userID, tripID, now)
	if err != nil {
		return Credentials{}, err
	}
	ttl := openTokenTTL
	var closesAt *time.Time
	if ch.ClosesAt.Valid {
		ttl = ch.ClosesAt.Time.Sub(now)
		closesAt = &ch.ClosesAt.Time
	}
	name, err := s.Store.GetUserDisplayName(ctx, userID)
	if err != nil {
		return Credentials{}, err
	}
	// La sala se crea al entrar el primero; si falla, LiveKit la crea igualmente al unirse.
	if s.Rooms != nil {
		if err := s.Rooms.CreateRoom(ctx, ch.RoomName); err != nil {
			s.logger().WarnContext(ctx, "create livekit room", "room", ch.RoomName, "err", err)
		}
	}
	token, err := s.LiveKit.ParticipantToken(userID.String(), name, ch.RoomName, now, ttl)
	if err != nil {
		return Credentials{}, err
	}
	return Credentials{URL: s.PublicURL, Token: token, Room: ch.RoomName, ClosesAt: closesAt}, nil
}

// TakeFloor grants the exclusive turn for FloorTTL; the holder may renew it (FR-017).
func (s *Service) TakeFloor(ctx context.Context, userID, tripID uuid.UUID) (time.Time, error) {
	now := s.now()
	if _, err := s.channel(ctx, userID, tripID, now); err != nil {
		return time.Time{}, err
	}
	expires, err := s.Store.TakePTTFloor(ctx, store.TakePTTFloorParams{
		UserID: uuid.NullUUID{UUID: userID, Valid: true}, ExpiresAt: ts(now.Add(FloorTTL)), TripID: tripID, Now: ts(now),
	})
	if store.IsNotFound(err) {
		// Entre la lectura y el UPDATE el canal pudo cerrarse.
		if _, err := s.channel(ctx, userID, tripID, now); err != nil {
			return time.Time{}, err
		}
		return time.Time{}, ErrBusy
	}
	if err != nil {
		return time.Time{}, err
	}
	return expires.Time, nil
}

// ReleaseFloor frees the turn if the user holds it; releasing a turn you do not hold is a no-op.
func (s *Service) ReleaseFloor(ctx context.Context, userID, tripID uuid.UUID) error {
	if err := s.checkParticipant(ctx, userID, tripID); err != nil {
		return err
	}
	return s.Store.ReleasePTTFloor(ctx, store.ReleasePTTFloorParams{TripID: tripID, FloorHolderID: uuid.NullUUID{UUID: userID, Valid: true}})
}

// CloseDue closes every channel whose closes_at has passed: marks it, deletes the LiveKit room
// and tells both parties (RN-KYQ-014). Same sweeper pattern as trips (research R10).
func (s *Service) CloseDue(ctx context.Context) (int, error) {
	now := s.now()
	var due []store.ListDuePTTChannelsRow
	err := s.Store.WithTx(ctx, func(q *store.Queries) error {
		var err error
		if due, err = q.ListDuePTTChannels(ctx, ts(now)); err != nil {
			return err
		}
		for _, ch := range due {
			if err := q.MarkPTTClosed(ctx, store.MarkPTTClosedParams{TripID: ch.TripID, ClosedAt: ts(now)}); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return 0, err
	}
	for _, ch := range due {
		if s.Rooms != nil {
			if err := s.Rooms.DeleteRoom(ctx, ch.RoomName); err != nil {
				s.logger().WarnContext(ctx, "delete livekit room", "room", ch.RoomName, "err", err)
			}
		}
		if s.Publisher == nil {
			continue
		}
		ev := realtime.Event{Type: "ptt.closed", OccurredAt: now, Data: map[string]any{"trip_id": ch.TripID}}
		for _, user := range []uuid.UUID{ch.PassengerID, ch.DriverID} {
			if err := s.Publisher.Publish(ctx, "user:"+user.String(), ev); err != nil {
				s.logger().WarnContext(ctx, "publish ptt.closed", "trip_id", ch.TripID, "err", err)
			}
		}
	}
	return len(due), nil
}

// RunSweeper closes due channels every interval until ctx ends.
func (s *Service) RunSweeper(ctx context.Context, interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			if n, err := s.CloseDue(ctx); err != nil {
				s.logger().ErrorContext(ctx, "close due ptt channels", "err", err)
			} else if n > 0 {
				s.logger().InfoContext(ctx, "closed ptt channels", "count", n)
			}
		}
	}
}
