package radio

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/ptt"
	"github.com/kyq/backend/internal/store"
)

// La conversación `cooperative` sigue a 006 (FR-018): sus miembros son los de la cooperativa
// activa, el coordinador modera, nadie entra ni sale desde Radio y la suspensión de la
// cooperativa la suspende. El canal de grupo de 006 (`/v1/driver/cooperative/ptt/*`) usa la misma
// sala y el mismo turno (ver ptt.GroupRadio), así que Radio y las apps anteriores se oyen.

// ensureCooperative creates the conversation of a cooperative if it does not exist yet.
func (s *Service) ensureCooperative(ctx context.Context, cooperativeID uuid.UUID) (store.RadioConversation, error) {
	conv, err := s.Store.GetRadioCooperativeConversation(ctx, nullID(cooperativeID))
	if err == nil || !store.IsNotFound(err) {
		return conv, err
	}
	id, err := newID()
	if err != nil {
		return store.RadioConversation{}, err
	}
	room, err := roomName(id)
	if err != nil {
		return store.RadioConversation{}, err
	}
	conv, err = s.Store.InsertRadioConversation(ctx, store.InsertRadioConversationParams{
		ID: id, Kind: store.RadioConversationKindCooperative, CooperativeID: nullID(cooperativeID), RoomName: room, CreatedAt: s.now(),
	})
	if store.IsNotFound(err) {
		// Otra petición la creó a la vez.
		return s.Store.GetRadioCooperativeConversation(ctx, nullID(cooperativeID))
	}
	return conv, err
}

// syncCooperative puts a driver in the conversation of his active cooperative, with the role
// that matches 006 (coordinador → moderador). It does nothing for passengers or drivers without
// cooperative; leaving is eager (LeaveGroup), so a stale row never lets anybody in.
func (s *Service) syncCooperative(ctx context.Context, userID uuid.UUID, role string) (store.RadioConversation, error) {
	if role != RoleDriver {
		return store.RadioConversation{}, ErrNotFound
	}
	m, err := s.Store.GetCurrentMembership(ctx, userID)
	if store.IsNotFound(err) {
		return store.RadioConversation{}, ErrNotFound
	}
	if err != nil {
		return store.RadioConversation{}, err
	}
	if m.Status != store.MembershipStatusActive || m.CooperativeStatus != store.CooperativeStatusActive {
		return store.RadioConversation{}, ErrNotFound
	}
	conv, err := s.ensureCooperative(ctx, m.CooperativeID)
	if err != nil {
		return store.RadioConversation{}, err
	}
	if conv.Status == store.RadioConversationStatusSuspended {
		// La cooperativa se reactivó en 006.
		if _, err := s.Store.SetRadioConversationStatus(ctx, store.SetRadioConversationStatusParams{
			ID: conv.ID, Status: store.RadioConversationStatusActive,
		}); err != nil {
			return store.RadioConversation{}, err
		}
		conv.Status = store.RadioConversationStatusActive
	}
	want := store.RadioRoleMember
	if m.Role == store.CooperativeRoleCoordinator {
		want = store.RadioRoleModerator
	}
	cur, err := s.Store.GetRadioMember(ctx, store.GetRadioMemberParams{ConversationID: conv.ID, UserID: userID})
	switch {
	case err == nil && cur.Role == want && (cur.Status == store.RadioMemberStatusActive || cur.Status == store.RadioMemberStatusMuted):
		return conv, nil
	case err == nil:
		_, err = s.Store.UpdateRadioMember(ctx, store.UpdateRadioMemberParams{
			ConversationID: conv.ID, UserID: userID, Now: s.now(),
			Role:   store.NullRadioRole{RadioRole: want, Valid: true},
			Status: store.NullRadioMemberStatus{RadioMemberStatus: store.RadioMemberStatusActive, Valid: true},
		})
	case store.IsNotFound(err):
		_, err = s.Store.UpsertRadioMember(ctx, store.UpsertRadioMemberParams{
			ConversationID: conv.ID, UserID: userID, Role: want, Status: store.RadioMemberStatusActive,
			Listening: true, JoinedAt: s.now(),
		})
	}
	return conv, err
}

// LeaveGroup takes a driver who left or was removed from his cooperative out of its
// conversation and rotates the room (FR-018, FR-014). cooperatives.GroupChannel.
func (s *Service) LeaveGroup(ctx context.Context, cooperativeID, driverID uuid.UUID) error {
	conv, err := s.Store.GetRadioCooperativeConversation(ctx, nullID(cooperativeID))
	if store.IsNotFound(err) {
		return nil
	}
	if err != nil {
		return err
	}
	if _, err := s.Store.UpdateRadioMember(ctx, store.UpdateRadioMemberParams{
		ConversationID: conv.ID, UserID: driverID, Now: s.now(),
		Status: store.NullRadioMemberStatus{RadioMemberStatus: store.RadioMemberStatusRemoved, Valid: true},
	}); err != nil && !store.IsNotFound(err) {
		return err
	}
	s.takeOut(ctx, conv.ID, conv.RoomName, driverID)
	s.publish(ctx, driverID, EventMember, s.now(), map[string]any{
		"conversation_id": conv.ID, "user_id": driverID, "change": "removed",
	})
	return nil
}

// CloseGroup suspends the conversation of a suspended cooperative and closes its room: nobody
// talks or listens until 006 reactivates it (FR-018). cooperatives.GroupChannel.
func (s *Service) CloseGroup(ctx context.Context, cooperativeID uuid.UUID) error {
	conv, err := s.Store.GetRadioCooperativeConversation(ctx, nullID(cooperativeID))
	if store.IsNotFound(err) {
		return nil
	}
	if err != nil {
		return err
	}
	if _, err := s.Store.SetRadioConversationStatus(ctx, store.SetRadioConversationStatusParams{
		ID: conv.ID, Status: store.RadioConversationStatusSuspended, Column3: s.now(),
	}); err != nil {
		return err
	}
	if held, err := s.Store.GetRadioFloor(ctx, conv.ID); err == nil {
		if err := s.Rooms.SetCanPublish(ctx, conv.RoomName, held.HolderID.String(), false); err == nil {
			if err := s.endTurn(ctx, conv.ID, held.HolderID, s.now()); err != nil {
				s.logger().WarnContext(ctx, "release radio floor on cooperative suspension", "err", err)
			}
		}
	}
	return s.rotateRoom(ctx, conv.ID, conv.RoomName)
}

// The 006 group channel on the Radio room (ptt.GroupRadio).

func (s *Service) cooperativeFor(ctx context.Context, driverID uuid.UUID) (uuid.UUID, error) {
	_, sub, _, err := s.access(ctx, driverID)
	if err != nil {
		return uuid.Nil, err
	}
	conv, err := s.syncCooperative(ctx, driverID, sub.Role)
	if err != nil {
		return uuid.Nil, groupError(err)
	}
	return conv.ID, nil
}

// groupError translates Radio errors into the ones 006 clients already understand.
func groupError(err error) error {
	var busy *FloorBusyError
	switch {
	case errors.As(err, &busy):
		return ptt.ErrBusy
	case errors.Is(err, ErrNotFound), errors.Is(err, ErrSuspended):
		return ptt.ErrNoCooperative
	case errors.Is(err, ErrUnavailable):
		return ptt.ErrUnavailable
	case errors.Is(err, ErrAccessDenied), errors.Is(err, ErrListenOnly), errors.Is(err, ErrMuted),
		errors.Is(err, ErrConsentRequired):
		return ptt.ErrGroupDenied
	}
	return err
}

// GroupToken is POST /v1/driver/cooperative/ptt/token on the Radio room.
func (s *Service) GroupToken(ctx context.Context, driverID uuid.UUID) (ptt.Credentials, error) {
	conv, err := s.cooperativeFor(ctx, driverID)
	if err != nil {
		return ptt.Credentials{}, err
	}
	c, err := s.Token(ctx, driverID, conv)
	if err != nil {
		return ptt.Credentials{}, groupError(err)
	}
	return ptt.Credentials{URL: c.URL, Token: c.Token, Room: c.Room}, nil
}

// TakeGroupFloor is POST /v1/driver/cooperative/ptt/floor: the Radio turn, recorded as any other.
func (s *Service) TakeGroupFloor(ctx context.Context, driverID uuid.UUID) (time.Time, error) {
	conv, err := s.cooperativeFor(ctx, driverID)
	if err != nil {
		return time.Time{}, err
	}
	f, err := s.TakeFloor(ctx, driverID, conv)
	if err != nil {
		return time.Time{}, groupError(err)
	}
	return f.ExpiresAt, nil
}

// ReleaseGroupFloor is DELETE /v1/driver/cooperative/ptt/floor.
func (s *Service) ReleaseGroupFloor(ctx context.Context, driverID uuid.UUID) error {
	conv, err := s.cooperativeFor(ctx, driverID)
	if err != nil {
		return err
	}
	return groupError(s.ReleaseFloor(ctx, driverID, conv))
}
