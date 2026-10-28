package ptt

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/store"
)

const (
	// GroupMaxParticipants caps a cooperative's group room (research R5).
	GroupMaxParticipants = 50
	// GroupTokenTTL es la vida de un token de la sala de grupo. Es corto porque la membresía
	// cambia: quien sale o es retirado no debe poder entrar con un token viejo. La app pide uno
	// nuevo cada vez que (re)conecta.
	GroupTokenTTL = time.Minute
)

// ErrNoCooperative means the driver is not an active member of an active cooperative (FR-022).
var ErrNoCooperative = errors.New("no active cooperative")

// GroupRooms adds what the cooperative group channel needs on top of Rooms: rooms for many
// participants and taking a participant out (COOP_GROUP, 006).
type GroupRooms interface {
	Rooms
	CreateGroupRoom(ctx context.Context, name string, maxParticipants int) error
	// RemoveParticipant succeeds when the participant or the room no longer exists.
	RemoveParticipant(ctx context.Context, room, identity string) error
}

// groupChannel returns the channel of the driver's active cooperative.
func (s *Service) groupChannel(ctx context.Context, driverID uuid.UUID) (store.GroupPttChannel, error) {
	coop, err := s.Store.GetDriverCooperative(ctx, driverID)
	if store.IsNotFound(err) {
		return store.GroupPttChannel{}, ErrNoCooperative
	}
	if err != nil {
		return store.GroupPttChannel{}, err
	}
	ch, err := s.Store.GetGroupPTTChannel(ctx, coop.ID)
	if store.IsNotFound(err) {
		return store.GroupPttChannel{}, ErrNoCooperative
	}
	return ch, err
}

// GroupToken issues credentials for the driver's cooperative room. Like the trip channel, the
// token lets the member listen and send data; publishing audio comes with the floor (FR-023).
func (s *Service) GroupToken(ctx context.Context, driverID uuid.UUID) (Credentials, error) {
	if s.Groups == nil {
		return Credentials{}, ErrUnavailable
	}
	now := s.now()
	ch, err := s.groupChannel(ctx, driverID)
	if err != nil {
		return Credentials{}, err
	}
	name, err := s.Store.GetUserDisplayName(ctx, driverID)
	if err != nil {
		return Credentials{}, err
	}
	if err := s.Groups.CreateGroupRoom(ctx, ch.RoomName, GroupMaxParticipants); err != nil {
		s.logger().ErrorContext(ctx, "create livekit group room", "room", ch.RoomName, "err", err)
		return Credentials{}, ErrUnavailable
	}
	token, err := s.LiveKit.ParticipantToken(driverID.String(), name, ch.RoomName, now, GroupTokenTTL)
	if err != nil {
		return Credentials{}, err
	}
	return Credentials{URL: s.PublicURL, Token: token, Room: ch.RoomName}, nil
}

// TakeGroupFloor grants the group's single turn for FloorTTL (FR-023), fail-closed as TakeFloor.
func (s *Service) TakeGroupFloor(ctx context.Context, driverID uuid.UUID) (time.Time, error) {
	if s.Groups == nil {
		return time.Time{}, ErrUnavailable
	}
	now := s.now()
	ch, err := s.groupChannel(ctx, driverID)
	if err != nil {
		return time.Time{}, err
	}
	expires, err := s.Store.TakeGroupPTTFloor(ctx, store.TakeGroupPTTFloorParams{
		UserID: holder(driverID), ExpiresAt: ts(now.Add(FloorTTL)), CooperativeID: ch.CooperativeID,
	})
	if store.IsNotFound(err) {
		return time.Time{}, ErrBusy
	}
	if err != nil {
		return time.Time{}, err
	}
	if err := s.Groups.SetCanPublish(ctx, ch.RoomName, driverID.String(), true); err != nil {
		s.logger().ErrorContext(ctx, "grant livekit group publish", "room", ch.RoomName, "err", err)
		if s.Groups.SetCanPublish(ctx, ch.RoomName, driverID.String(), false) == nil {
			if err := s.Store.ReleaseGroupPTTFloor(ctx, store.ReleaseGroupPTTFloorParams{CooperativeID: ch.CooperativeID, FloorHolderID: holder(driverID)}); err != nil {
				return time.Time{}, err
			}
		}
		return time.Time{}, ErrUnavailable
	}
	return expires.Time, nil
}

// ReleaseGroupFloor revokes publishing and then frees the turn; without the turn nothing changes.
func (s *Service) ReleaseGroupFloor(ctx context.Context, driverID uuid.UUID) error {
	if s.Groups == nil {
		return ErrUnavailable
	}
	ch, err := s.groupChannel(ctx, driverID)
	if err != nil {
		return err
	}
	return s.releaseGroupHolder(ctx, ch, driverID)
}

func (s *Service) releaseGroupHolder(ctx context.Context, ch store.GroupPttChannel, driverID uuid.UUID) error {
	if ch.FloorHolderID != holder(driverID) {
		return nil
	}
	if err := s.Groups.SetCanPublish(ctx, ch.RoomName, driverID.String(), false); err != nil {
		s.logger().ErrorContext(ctx, "revoke livekit group publish", "room", ch.RoomName, "err", err)
		return ErrUnavailable
	}
	return s.Store.ReleaseGroupPTTFloor(ctx, store.ReleaseGroupPTTFloorParams{CooperativeID: ch.CooperativeID, FloorHolderID: holder(driverID)})
}

// LeaveGroup takes a driver who left or was removed out of the group channel (FR-024): frees his
// turn after revoking publishing, disconnects him and rotates the room. The membership is already
// ended, so he cannot get a new token; rotating also voids the one he holds, which would otherwise
// let him back into the room until it expires. The rest of the group reconnects with new tokens.
func (s *Service) LeaveGroup(ctx context.Context, cooperativeID, driverID uuid.UUID) error {
	if s.Groups == nil {
		return nil
	}
	ch, err := s.Store.GetGroupPTTChannel(ctx, cooperativeID)
	if store.IsNotFound(err) {
		return nil
	}
	if err != nil {
		return err
	}
	if err := s.releaseGroupHolder(ctx, ch, driverID); err != nil {
		// El turno caduca solo y el barrido retira el permiso; se le saca de la sala igual.
		s.logger().WarnContext(ctx, "release group floor on leave", "room", ch.RoomName, "err", err)
	}
	if err := s.Groups.RemoveParticipant(ctx, ch.RoomName, driverID.String()); err != nil {
		s.logger().WarnContext(ctx, "remove group participant on leave", "room", ch.RoomName, "err", err)
	}
	return s.rotateGroupRoom(ctx, ch)
}

// CloseGroup deletes the room of a suspended cooperative, disconnecting everyone (FR-024), and
// leaves a new room name for when it is reactivated.
func (s *Service) CloseGroup(ctx context.Context, cooperativeID uuid.UUID) error {
	if s.Groups == nil {
		return nil
	}
	ch, err := s.Store.GetGroupPTTChannel(ctx, cooperativeID)
	if store.IsNotFound(err) {
		return nil
	}
	if err != nil {
		return err
	}
	return s.rotateGroupRoom(ctx, ch)
}

// rotateGroupRoom guarda un nombre de sala nuevo y después borra la sala vieja en LiveKit. En ese
// orden: si el borrado fallara, los tokens nuevos ya apuntan a la sala nueva y nadie recrea la
// vieja (la autocreación de LiveKit está apagada, infra/livekit.yaml).
func (s *Service) rotateGroupRoom(ctx context.Context, ch store.GroupPttChannel) error {
	next, err := groupRoomName(ch.CooperativeID)
	if err != nil {
		return err
	}
	// Sin filas: otra rotación ganó; la sala vieja se borra igual.
	if _, err := s.Store.RotateGroupPTTRoom(ctx, store.RotateGroupPTTRoomParams{
		NewRoom: next, CooperativeID: ch.CooperativeID, OldRoom: ch.RoomName,
	}); err != nil {
		return err
	}
	if err := s.Groups.DeleteRoom(ctx, ch.RoomName); err != nil {
		s.logger().ErrorContext(ctx, "delete rotated livekit group room", "room", ch.RoomName, "err", err)
		return err
	}
	return nil
}

// groupRoomName es un nombre de sala de grupo que no se repite: `coop-{id}-{aleatorio}`.
func groupRoomName(cooperativeID uuid.UUID) (string, error) {
	var b [6]byte
	if _, err := rand.Read(b[:]); err != nil {
		return "", err
	}
	return "coop-" + cooperativeID.String() + "-" + hex.EncodeToString(b[:]), nil
}

// ExpireGroupFloors frees group turns past FloorTTL after revoking publishing.
func (s *Service) ExpireGroupFloors(ctx context.Context) (int, error) {
	if s.Groups == nil {
		return 0, nil
	}
	now := s.now()
	expired, err := s.Store.ListExpiredGroupPTTFloors(ctx, ts(now))
	if err != nil {
		return 0, err
	}
	count := 0
	for _, f := range expired {
		if err := s.Groups.SetCanPublish(ctx, f.RoomName, f.FloorHolderID.UUID.String(), false); err != nil {
			s.logger().WarnContext(ctx, "revoke expired group floor", "room", f.RoomName, "err", err)
			continue
		}
		n, err := s.Store.ClearExpiredGroupPTTFloor(ctx, store.ClearExpiredGroupPTTFloorParams{
			CooperativeID: f.CooperativeID, HolderID: f.FloorHolderID, Now: ts(now),
		})
		if err != nil {
			return count, err
		}
		count += int(n)
	}
	return count, nil
}
