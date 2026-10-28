package radio

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/storage"
	"github.com/kyq/backend/internal/store"
)

// Conversation kinds (data-model).
const (
	KindDirect      = "direct"
	KindClient      = "client"
	KindChannel     = "channel"
	KindCooperative = "cooperative"
)

// participant is the caller's membership in a conversation, checked for every operation:
// a user who does not take part gets ErrNotFound (the conversation is not revealed, FR-014).
type participant struct {
	store.GetRadioMemberRow
}

func (p participant) isChannel() bool {
	return p.Kind == store.RadioConversationKindChannel || p.Kind == store.RadioConversationKindCooperative
}

// member returns the active membership of userID in conversationID. Clients also need the
// affiliation and "Radio con mis clientes" (FR-003).
func (s *Service) member(ctx context.Context, conversationID, userID uuid.UUID) (participant, error) {
	m, err := s.Store.GetRadioMember(ctx, store.GetRadioMemberParams{ConversationID: conversationID, UserID: userID})
	if store.IsNotFound(err) {
		return participant{}, ErrNotFound
	}
	if err != nil {
		return participant{}, err
	}
	if m.ConversationStatus == store.RadioConversationStatusDeleted ||
		(m.Status != store.RadioMemberStatusActive && m.Status != store.RadioMemberStatusMuted) {
		return participant{}, ErrNotFound
	}
	if m.Kind == store.RadioConversationKindClient {
		passenger, driver, err := s.clientPair(ctx, m.PairA.UUID, m.PairB.UUID)
		if err != nil {
			return participant{}, err
		}
		ok, err := s.Store.IsRadioClientPair(ctx, store.IsRadioClientPairParams{PassengerID: passenger, DriverID: driver})
		if err != nil {
			return participant{}, err
		}
		if !ok {
			return participant{}, ErrNotFound
		}
	}
	return participant{m}, nil
}

// clientPair orders a client conversation's pair as (passenger, driver).
func (s *Service) clientPair(ctx context.Context, a, b uuid.UUID) (uuid.UUID, uuid.UUID, error) {
	sub, err := s.Store.GetRadioSubject(ctx, a)
	if err != nil {
		return uuid.Nil, uuid.Nil, err
	}
	if string(sub.Role) == RolePassenger {
		return a, b, nil
	}
	return b, a, nil
}

// mayTalk checks that the caller may transmit (voice, text, photo, location, alert) here.
func (s *Service) mayTalk(ctx context.Context, d Decision, p participant) error {
	if d.Level == Listen {
		return ErrListenOnly
	}
	if p.ConversationStatus == store.RadioConversationStatusSuspended {
		return ErrSuspended
	}
	if p.Role == store.RadioRoleListener {
		return ErrListenOnly
	}
	if p.Status == store.RadioMemberStatusMuted {
		return ErrMuted
	}
	if p.BlockedByPeer {
		return ErrBlocked
	}
	if p.Kind == store.RadioConversationKindClient {
		// El pasajero bloqueado lleva la marca en su fila; el conductor no puede escribir a quien
		// bloqueó sin desbloquearlo.
		peer := p.PairA.UUID
		if peer == p.UserID {
			peer = p.PairB.UUID
		}
		pm, err := s.Store.GetRadioMember(ctx, store.GetRadioMemberParams{ConversationID: p.ConversationID, UserID: peer})
		if err == nil && pm.BlockedByPeer {
			return ErrBlocked
		}
	}
	consent, err := s.Store.GetRadioConsent(ctx, p.UserID)
	if store.IsNotFound(err) {
		return ErrConsentRequired
	}
	if err != nil {
		return err
	}
	st, err := s.settings(ctx)
	if err != nil {
		return err
	}
	if int(consent.RetentionDaysAccepted) != st.RetentionDays {
		return ErrConsentRequired
	}
	return nil
}

// List is the single list of contacts, clients, channels and cooperative (FR-001).
func (s *Service) List(ctx context.Context, userID uuid.UUID) ([]Conversation, error) {
	d, sub, _, err := s.allowed(ctx, userID)
	if err != nil {
		return nil, err
	}
	if err := s.syncClients(ctx, userID, sub.Role); err != nil {
		return nil, err
	}
	if _, err := s.syncCooperative(ctx, userID, sub.Role); err != nil && !errors.Is(err, ErrNotFound) {
		return nil, err
	}
	now := s.now()
	rows, err := s.Store.ListRadioConversations(ctx, store.ListRadioConversationsParams{
		UserID: userID, FreshAfter: now.Add(-OfflineAfter), Now: now,
	})
	if err != nil {
		return nil, err
	}
	out := make([]Conversation, 0, len(rows))
	for _, r := range rows {
		out = append(out, conversationView(r, d))
	}
	return out, nil
}

func conversationView(r store.ListRadioConversationsRow, d Decision) Conversation {
	c := Conversation{
		ID: r.ID, Kind: string(r.Kind), Title: r.Title, MyMemberStatus: string(r.MemberStatus),
		Listening: r.Listening, UnreadCount: int(r.UnreadCount), Status: string(r.Status),
	}
	if r.LastMessageAt.After(time.Unix(0, 0)) {
		at := r.LastMessageAt
		c.LastMessageAt = &at
	}
	if r.HasPeer {
		id := r.PeerID
		status := presenceOf(r.PeerStatus, r.PeerOnline)
		c.PeerID, c.PeerStatus = &id, &status
		c.PeerMuted = r.PeerMuted
	} else {
		n := int(r.OnlineCount)
		c.OnlineCount = &n
		role := string(r.Role)
		c.MyRole = &role
	}
	c.CanTalk = d.Level == Full && r.Status == store.RadioConversationStatusActive &&
		r.MemberStatus == store.RadioMemberStatusActive && r.Role != store.RadioRoleListener &&
		!r.BlockedByPeer && !r.PeerBlocked
	return c
}

// Detail returns a conversation with its visible members (never phones, FR-004).
func (s *Service) Detail(ctx context.Context, userID, conversationID uuid.UUID) (ConversationDetail, error) {
	d, _, _, err := s.allowed(ctx, userID)
	if err != nil {
		return ConversationDetail{}, err
	}
	p, err := s.member(ctx, conversationID, userID)
	if err != nil {
		return ConversationDetail{}, err
	}
	now := s.now()
	rows, err := s.Store.ListRadioConversations(ctx, store.ListRadioConversationsParams{
		UserID: userID, FreshAfter: now.Add(-OfflineAfter), Now: now,
	})
	if err != nil {
		return ConversationDetail{}, err
	}
	var out ConversationDetail
	found := false
	for _, r := range rows {
		if r.ID == conversationID {
			out.Conversation, found = conversationView(r, d), true
			break
		}
	}
	if !found {
		return ConversationDetail{}, ErrNotFound
	}
	conv, err := s.Store.GetRadioConversation(ctx, conversationID)
	if err != nil {
		return ConversationDetail{}, err
	}
	if conv.Description.Valid {
		v := conv.Description.String
		out.Description = &v
	}
	if conv.JoinMode.Valid {
		v := string(conv.JoinMode.RadioJoinMode)
		out.JoinMode = &v
	}
	if conv.PassengerRoleMax.Valid {
		v := string(conv.PassengerRoleMax.RadioRole)
		out.PassengerRoleMax = &v
	}
	members, err := s.Store.ListRadioMembers(ctx, store.ListRadioMembersParams{
		ConversationID: conversationID, FreshAfter: now.Add(-OfflineAfter),
	})
	if err != nil {
		return ConversationDetail{}, err
	}
	moderator := p.Role == store.RadioRoleOwner || p.Role == store.RadioRoleModerator
	out.Members = make([]Member, 0, len(members))
	for _, m := range members {
		// Las solicitudes y los bloqueados solo los ven quienes moderan.
		if !moderator && (m.Status == store.RadioMemberStatusPending || m.Status == store.RadioMemberStatusBlocked) {
			continue
		}
		out.Members = append(out.Members, Member{
			UserID: m.UserID, DisplayName: m.DisplayName, Role: string(m.Role), Status: string(m.Status),
			Presence: presenceOf(m.PresenceStatus, m.Online), IsPassenger: m.UserRole == store.UserRolePassenger,
		})
	}
	return out, nil
}

// Delete removes a contact (FR-002) or, for its owner, a channel (US4-7). The cooperative
// channel belongs to 006 and cannot be deleted from Radio (FR-018).
func (s *Service) Delete(ctx context.Context, userID, conversationID uuid.UUID) error {
	if _, _, _, err := s.allowed(ctx, userID); err != nil {
		return err
	}
	p, err := s.member(ctx, conversationID, userID)
	if err != nil {
		return err
	}
	switch p.Kind {
	case store.RadioConversationKindCooperative:
		return ErrCooperative
	case store.RadioConversationKindClient:
		// La conversación de cliente vive con la afiliación; se cierra al quitarla (US3-5).
		return ErrInvalid
	case store.RadioConversationKindChannel:
		if p.Role != store.RadioRoleOwner {
			return ErrNotOwner
		}
	}
	recipients, err := s.Store.ListRadioRecipients(ctx, conversationID)
	if err != nil {
		return err
	}
	now := s.now()
	if _, err := s.Store.DeleteRadioConversation(ctx, store.DeleteRadioConversationParams{ID: conversationID, DeletedAt: ts(now)}); err != nil {
		return err
	}
	if err := s.Rooms.DeleteRoom(ctx, p.RoomName); err != nil {
		s.logger().WarnContext(ctx, "delete radio room", "room", p.RoomName, "err", err)
	}
	s.purgeConversation(ctx, conversationID)
	for _, r := range recipients {
		s.publish(ctx, r.UserID, EventMember, now, map[string]any{
			"conversation_id": conversationID, "user_id": r.UserID, "change": "conversation_deleted",
		})
	}
	return nil
}

// syncClients makes sure every active client relationship with "Radio con mis clientes" has its
// conversation (FR-003). Conversations whose affiliation ended stay hidden by the list query.
func (s *Service) syncClients(ctx context.Context, userID uuid.UUID, role string) error {
	if role != RoleDriver && role != RolePassenger {
		return nil
	}
	pairs, err := s.Store.ListRadioActiveAffiliations(ctx, userID)
	if err != nil {
		return err
	}
	for _, pr := range pairs {
		if _, err := s.ensurePair(ctx, store.RadioConversationKindClient, pr.PassengerID, pr.DriverID, uuid.Nil); err != nil {
			return err
		}
	}
	return nil
}

// ensurePair returns the conversation of a pair (contact or client), creating it with both as
// members when missing.
func (s *Service) ensurePair(ctx context.Context, kind store.RadioConversationKind, x, y, createdBy uuid.UUID) (store.RadioConversation, error) {
	a, b := x, y
	if b.String() < a.String() {
		a, b = b, a
	}
	conv, err := s.Store.GetRadioPair(ctx, store.GetRadioPairParams{Kind: kind, PairA: nullID(a), PairB: nullID(b)})
	if err == nil {
		return conv, nil
	}
	if !store.IsNotFound(err) {
		return store.RadioConversation{}, err
	}
	id, err := newID()
	if err != nil {
		return store.RadioConversation{}, err
	}
	room, err := roomName(id)
	if err != nil {
		return store.RadioConversation{}, err
	}
	now := s.now()
	err = s.Store.WithTx(ctx, func(q *store.Queries) error {
		params := store.InsertRadioConversationParams{
			ID: id, Kind: kind, RoomName: room, CreatedAt: now, PairA: nullID(a), PairB: nullID(b),
		}
		if createdBy != uuid.Nil {
			params.CreatedBy = nullID(createdBy)
		}
		conv, err = q.InsertRadioConversation(ctx, params)
		if store.IsNotFound(err) {
			// Otra petición la creó a la vez.
			conv, err = q.GetRadioPair(ctx, store.GetRadioPairParams{Kind: kind, PairA: nullID(a), PairB: nullID(b)})
			return err
		}
		if err != nil {
			return err
		}
		for _, u := range []uuid.UUID{a, b} {
			if _, err := q.UpsertRadioMember(ctx, store.UpsertRadioMemberParams{
				ConversationID: id, UserID: u, Role: store.RadioRoleMember, Status: store.RadioMemberStatusActive,
				Listening: true, JoinedAt: now,
			}); err != nil {
				return err
			}
		}
		return nil
	})
	return conv, err
}

// purgeConversation deletes the history and media of a deleted conversation (US4-7).
func (s *Service) purgeConversation(ctx context.Context, conversationID uuid.UUID) {
	s.background(ctx, func(ctx context.Context) {
		objects, err := s.Store.ListRadioConversationObjects(ctx, conversationID)
		if err != nil {
			s.logger().WarnContext(ctx, "list radio objects", "conversation_id", conversationID, "err", err)
			return
		}
		for _, o := range objects {
			s.removeObject(ctx, o.Key.String, o.Saved)
		}
		if err := s.Store.DeleteRadioConversationMessages(ctx, conversationID); err != nil {
			s.logger().WarnContext(ctx, "delete radio history", "conversation_id", conversationID, "err", err)
		}
	})
}

// removeObject deletes a message object (or its saved copy); a failure is logged and the bucket
// lifecycle removes it anyway.
func (s *Service) removeObject(ctx context.Context, key string, saved bool) {
	if key == "" {
		return
	}
	var bucket storage.Objects = s.Media
	if saved {
		bucket = s.Saved
	}
	if bucket == nil {
		return
	}
	if err := bucket.Remove(ctx, key); err != nil {
		s.logger().WarnContext(ctx, "remove radio object", "key", key, "err", err)
	}
}

// SetListening turns "Escuchar" on or off for a conversation; at most MaxListening on (FR-024).
func (s *Service) SetListening(ctx context.Context, userID, conversationID uuid.UUID, on bool) error {
	if _, _, _, err := s.allowed(ctx, userID); err != nil {
		return err
	}
	p, err := s.member(ctx, conversationID, userID)
	if err != nil {
		return err
	}
	if on && !p.Listening {
		n, err := s.Store.CountRadioListening(ctx, userID)
		if err != nil {
			return err
		}
		if n >= MaxListening {
			return ErrListeningLimit
		}
	}
	_, err = s.Store.SetRadioListening(ctx, store.SetRadioListeningParams{
		ConversationID: conversationID, UserID: userID, Listening: on, UpdatedAt: s.now(),
	})
	return err
}
