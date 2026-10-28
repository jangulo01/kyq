package radio

import (
	"context"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/store"
)

// SetClients turns "Radio con mis clientes" on or off for a driver (FR-003, desactivado por
// defecto). On: every active client gets his conversation with the driver. Off: those
// conversations disappear from both lists and nobody can talk in them (List and member check
// clients_enabled), and the history comes back if the driver turns it on again.
func (s *Service) SetClients(ctx context.Context, userID uuid.UUID, enabled bool) error {
	d, sub, _, err := s.allowed(ctx, userID)
	if err != nil {
		return err
	}
	if sub.Role != RoleDriver {
		return ErrInvalid
	}
	if enabled && d.Level == Listen {
		return ErrListenOnly
	}
	now := s.now()
	if _, err := s.Store.EnsureRadioPresence(ctx, store.EnsureRadioPresenceParams{UserID: userID, UpdatedAt: now}); err != nil {
		return err
	}
	// Quienes la tenían antes de apagarla también se enteran.
	before, err := s.Store.ListRadioActiveAffiliations(ctx, userID)
	if err != nil {
		return err
	}
	if err := s.Store.SetRadioClientsEnabled(ctx, store.SetRadioClientsEnabledParams{
		UserID: userID, ClientsEnabled: enabled, UpdatedAt: now,
	}); err != nil {
		return err
	}
	if enabled {
		if err := s.syncClients(ctx, userID, sub.Role); err != nil {
			return err
		}
	}
	pairs, err := s.Store.ListRadioActiveAffiliations(ctx, userID)
	if err != nil {
		return err
	}
	seen := map[uuid.UUID]bool{}
	for _, pr := range append(before, pairs...) {
		if seen[pr.PassengerID] {
			continue
		}
		seen[pr.PassengerID] = true
		s.publish(ctx, pr.PassengerID, EventMember, now, map[string]any{
			"user_id": userID, "change": map[bool]string{true: "clients_on", false: "clients_off"}[enabled],
		})
	}
	return nil
}

// ClientUpdate is PUT /v1/radio/clients/{passengerId}; nil fields stay as they are.
type ClientUpdate struct {
	Muted   *bool `json:"muted"`
	Blocked *bool `json:"blocked"`
}

// SetClient lets the driver silence (sus mensajes llegan sin sonar) or block (no puede enviar)
// one client in their conversation (FR-003).
func (s *Service) SetClient(ctx context.Context, driverID, passengerID uuid.UUID, in ClientUpdate) error {
	_, sub, _, err := s.allowed(ctx, driverID)
	if err != nil {
		return err
	}
	if sub.Role != RoleDriver {
		return ErrInvalid
	}
	a, b := passengerID, driverID
	if b.String() < a.String() {
		a, b = b, a
	}
	conv, err := s.Store.GetRadioPair(ctx, store.GetRadioPairParams{Kind: store.RadioConversationKindClient, PairA: nullID(a), PairB: nullID(b)})
	if store.IsNotFound(err) {
		return ErrNotFound
	}
	if err != nil {
		return err
	}
	if _, err := s.member(ctx, conv.ID, driverID); err != nil {
		return err
	}
	m, err := s.Store.GetRadioMember(ctx, store.GetRadioMemberParams{ConversationID: conv.ID, UserID: passengerID})
	if store.IsNotFound(err) {
		return ErrNotFound
	}
	if err != nil {
		return err
	}
	muted, blocked := m.MutedByPeer, m.BlockedByPeer
	if in.Muted != nil {
		muted = *in.Muted
	}
	if in.Blocked != nil {
		blocked = *in.Blocked
	}
	now := s.now()
	if _, err := s.Store.SetRadioPeerFlags(ctx, store.SetRadioPeerFlagsParams{
		ConversationID: conv.ID, UserID: passengerID, MutedByPeer: muted, BlockedByPeer: blocked, UpdatedAt: now,
	}); err != nil {
		return err
	}
	if blocked && !m.BlockedByPeer {
		// Si estaba hablando, pierde el turno ya.
		if held, err := s.Store.GetRadioFloor(ctx, conv.ID); err == nil && held.HolderID == passengerID {
			if err := s.Rooms.SetCanPublish(ctx, conv.RoomName, passengerID.String(), false); err == nil {
				if err := s.endTurn(ctx, conv.ID, passengerID, now); err != nil {
					s.logger().WarnContext(ctx, "release radio floor on client block", "err", err)
				}
			}
		}
	}
	return nil
}
