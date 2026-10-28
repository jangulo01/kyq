package radio

import (
	"context"
	"strings"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/store"
)

// Channel roles (FR-016).
const (
	RoleOwner     = "owner"
	RoleModerator = "moderator"
	RoleMember    = "member"
	RoleListener  = "listener"
)

// Join modes (FR-015).
const (
	JoinOpenLink = "open_link"
	JoinApproval = "approval"
)

// ChannelInput is POST /v1/radio/channels and PATCH …/channels/{id} (contracts: ChannelInput).
type ChannelInput struct {
	Name        *string `json:"name"`
	Description *string `json:"description"`
	JoinMode    *string `json:"join_mode"`
	// PassengerRoleMax: el rol máximo que el dueño admite para pasajeros, dentro de lo que el
	// panel permite (FR-017); null no admite pasajeros. SetPassengerRole distingue "no lo
	// cambies" de "ponlo en null" al editar.
	PassengerRoleMax *string `json:"passenger_role_max"`
	SetPassengerRole bool    `json:"-"`
}

func roleRank(r string) int {
	switch r {
	case RoleOwner:
		return 0
	case RoleModerator:
		return 1
	case RoleMember:
		return 2
	}
	return 3
}

// passengerCap is the highest role a passenger may have in a channel: the panel policy and the
// owner's choice, whichever is stricter. "" means no passengers.
func passengerCap(policy string, channelMax pgtype.Text) string {
	if !channelMax.Valid {
		return ""
	}
	switch policy {
	case PassengersNone:
		return ""
	case PassengersListenOnly:
		return RoleListener
	}
	if channelMax.String == RoleOwner {
		return RoleModerator
	}
	return channelMax.String
}

func validName(n string) (string, bool) {
	n = strings.TrimSpace(n)
	l := utf8.RuneCountInString(n)
	return n, l >= 3 && l <= 40
}

// validPassengerRole checks the owner's choice against the panel policy (FR-017).
func validPassengerRole(policy string, role *string) error {
	if role == nil {
		return nil
	}
	switch *role {
	case RoleModerator, RoleMember, RoleListener:
	default:
		return ErrInvalid
	}
	switch policy {
	case PassengersNone:
		return ErrPassengersClosed
	case PassengersListenOnly:
		if *role != RoleListener {
			return ErrPassengersClosed
		}
	}
	return nil
}

// CreateChannel creates a group channel owned by the caller (FR-015): unique name among active
// channels, at most MaxOwnedChannels per driver.
func (s *Service) CreateChannel(ctx context.Context, userID uuid.UUID, in ChannelInput) (Conversation, error) {
	d, sub, st, err := s.allowed(ctx, userID)
	if err != nil {
		return Conversation{}, err
	}
	if sub.Role != RoleDriver {
		return Conversation{}, ErrInvalid
	}
	if d.Level == Listen {
		return Conversation{}, ErrListenOnly
	}
	if in.Name == nil {
		return Conversation{}, ErrInvalid
	}
	name, ok := validName(*in.Name)
	if !ok {
		return Conversation{}, ErrInvalid
	}
	mode := JoinApproval
	if in.JoinMode != nil {
		if *in.JoinMode != JoinOpenLink && *in.JoinMode != JoinApproval {
			return Conversation{}, ErrInvalid
		}
		mode = *in.JoinMode
	}
	if in.Description != nil && utf8.RuneCountInString(*in.Description) > 200 {
		return Conversation{}, ErrInvalid
	}
	if err := validPassengerRole(st.PassengersInChannels, in.PassengerRoleMax); err != nil {
		return Conversation{}, err
	}
	owned, err := s.Store.CountRadioOwnedChannels(ctx, userID)
	if err != nil {
		return Conversation{}, err
	}
	if owned >= MaxOwnedChannels {
		return Conversation{}, ErrChannelLimit
	}
	conv, err := s.createChannel(ctx, userID, name, in.Description, mode, in.PassengerRoleMax)
	if err != nil {
		return Conversation{}, err
	}
	return s.conversationFor(ctx, userID, conv.ID, d)
}

// createChannel inserts the channel and its owner; also used by bulk uploads (FR-033).
func (s *Service) createChannel(ctx context.Context, ownerID uuid.UUID, name string, description *string, mode string, passengerMax *string) (store.RadioConversation, error) {
	id, err := newID()
	if err != nil {
		return store.RadioConversation{}, err
	}
	room, err := roomName(id)
	if err != nil {
		return store.RadioConversation{}, err
	}
	now := s.now()
	var conv store.RadioConversation
	err = s.Store.WithTx(ctx, func(q *store.Queries) error {
		params := store.InsertRadioConversationParams{
			ID: id, Kind: store.RadioConversationKindChannel, Name: text(name), Description: optText(description),
			JoinMode: store.NullRadioJoinMode{RadioJoinMode: store.RadioJoinMode(mode), Valid: true},
			RoomName: room, CreatedBy: nullID(ownerID), CreatedAt: now,
		}
		if passengerMax != nil {
			params.PassengerRoleMax = store.NullRadioRole{RadioRole: store.RadioRole(*passengerMax), Valid: true}
		}
		var err error
		conv, err = q.InsertRadioConversation(ctx, params)
		if store.IsNotFound(err) {
			// ON CONFLICT DO NOTHING: el único choque posible de un canal es su nombre.
			return ErrNameTaken
		}
		if err != nil {
			return err
		}
		_, err = q.UpsertRadioMember(ctx, store.UpsertRadioMemberParams{
			ConversationID: id, UserID: ownerID, Role: store.RadioRoleOwner, Status: store.RadioMemberStatusActive,
			Listening: true, JoinedAt: now,
		})
		return err
	})
	return conv, err
}

// UpdateChannel edits a channel; only its owner (FR-016).
func (s *Service) UpdateChannel(ctx context.Context, userID, conversationID uuid.UUID, in ChannelInput) (Conversation, error) {
	d, _, st, err := s.allowed(ctx, userID)
	if err != nil {
		return Conversation{}, err
	}
	p, err := s.member(ctx, conversationID, userID)
	if err != nil {
		return Conversation{}, err
	}
	if p.Kind != store.RadioConversationKindChannel {
		return Conversation{}, ErrCooperative
	}
	if p.Role != store.RadioRoleOwner {
		return Conversation{}, ErrNotOwner
	}
	params := store.UpdateRadioChannelParams{ID: conversationID, SetPassengerRole: in.SetPassengerRole}
	if in.Name != nil {
		name, ok := validName(*in.Name)
		if !ok {
			return Conversation{}, ErrInvalid
		}
		params.Name = text(name)
	}
	if in.Description != nil {
		if utf8.RuneCountInString(*in.Description) > 200 {
			return Conversation{}, ErrInvalid
		}
		params.Description = text(*in.Description)
	}
	if in.JoinMode != nil {
		if *in.JoinMode != JoinOpenLink && *in.JoinMode != JoinApproval {
			return Conversation{}, ErrInvalid
		}
		params.JoinMode = store.NullRadioJoinMode{RadioJoinMode: store.RadioJoinMode(*in.JoinMode), Valid: true}
	}
	if in.SetPassengerRole {
		if err := validPassengerRole(st.PassengersInChannels, in.PassengerRoleMax); err != nil {
			return Conversation{}, err
		}
		if in.PassengerRoleMax != nil {
			params.PassengerRoleMax = store.NullRadioRole{RadioRole: store.RadioRole(*in.PassengerRoleMax), Valid: true}
		}
	}
	if _, err := s.Store.UpdateRadioChannel(ctx, params); err != nil {
		if store.IsUniqueViolation(err) {
			return Conversation{}, ErrNameTaken
		}
		if store.IsNotFound(err) {
			return Conversation{}, ErrNotFound
		}
		return Conversation{}, err
	}
	if in.SetPassengerRole {
		if err := s.ApplyPassengerPolicy(ctx); err != nil {
			return Conversation{}, err
		}
	}
	return s.conversationFor(ctx, userID, conversationID, d)
}

// ChannelInvite returns a multi-use link and QR to the channel; owner or moderator (FR-016).
func (s *Service) ChannelInvite(ctx context.Context, userID, conversationID uuid.UUID) (Invite, error) {
	if _, _, _, err := s.allowed(ctx, userID); err != nil {
		return Invite{}, err
	}
	p, err := s.member(ctx, conversationID, userID)
	if err != nil {
		return Invite{}, err
	}
	if p.Kind != store.RadioConversationKindChannel {
		return Invite{}, ErrCooperative
	}
	if p.Role != store.RadioRoleOwner && p.Role != store.RadioRoleModerator {
		return Invite{}, ErrNotModerator
	}
	code, err := newCode()
	if err != nil {
		return Invite{}, err
	}
	id, err := newID()
	if err != nil {
		return Invite{}, err
	}
	now := s.now()
	inv, err := s.Store.InsertRadioInvite(ctx, store.InsertRadioInviteParams{
		ID: id, Code: code, InviterID: nullID(userID), ConversationID: nullID(conversationID),
		InviteeKind: store.UserRoleDriver, Status: store.RadioInviteStatusPending, CreatedAt: now, ExpiresAt: now.Add(InviteTTL),
	})
	if err != nil {
		return Invite{}, err
	}
	return s.inviteView(inv), nil
}

// joinChannel enters a channel by invitation: open link → member at once; with approval →
// pending until a moderator decides (US4-2). Invitations from the panel are pre-approved.
func (s *Service) joinChannel(ctx context.Context, userID uuid.UUID, sub Subject, st Settings, d Decision, inv store.GetRadioInviteByCodeRow) (AcceptResult, error) {
	conv, err := s.Store.GetRadioConversation(ctx, inv.ConversationID.UUID)
	if store.IsNotFound(err) {
		return AcceptResult{}, ErrNotFound
	}
	if err != nil {
		return AcceptResult{}, err
	}
	if conv.Status != store.RadioConversationStatusActive || conv.Kind != store.RadioConversationKindChannel {
		return AcceptResult{}, ErrInviteExpired
	}
	role := RoleMember
	if inv.Role.Valid {
		role = string(inv.Role.RadioRole)
	}
	if role == RoleOwner {
		role = RoleModerator
	}
	if sub.Role == RolePassenger {
		cap := passengerCap(st.PassengersInChannels, pgtype.Text{String: string(conv.PassengerRoleMax.RadioRole), Valid: conv.PassengerRoleMax.Valid})
		if cap == "" {
			return AcceptResult{}, ErrPassengersClosed
		}
		if roleRank(role) < roleRank(cap) {
			role = cap
		}
	}
	if d.Level == Listen && role != RoleListener {
		// Sin suscripción y con "Solo escucha": entra a oír (FR-005).
		role = RoleListener
	}
	now := s.now()
	existing, err := s.Store.GetRadioMember(ctx, store.GetRadioMemberParams{ConversationID: conv.ID, UserID: userID})
	switch {
	case err == nil:
		switch existing.Status {
		case store.RadioMemberStatusActive, store.RadioMemberStatusMuted:
			c, err := s.conversationFor(ctx, userID, conv.ID, d)
			return AcceptResult{Conversation: c}, err
		case store.RadioMemberStatusBlocked:
			return AcceptResult{}, ErrBlocked
		case store.RadioMemberStatusPending:
			c, err := s.conversationFor(ctx, userID, conv.ID, d)
			return AcceptResult{Conversation: c, Pending: true}, err
		}
	case !store.IsNotFound(err):
		return AcceptResult{}, err
	}
	count, err := s.Store.CountRadioActiveMembers(ctx, conv.ID)
	if err != nil {
		return AcceptResult{}, err
	}
	if count >= MaxChannelMembers {
		return AcceptResult{}, ErrChannelFull
	}
	status := store.RadioMemberStatusActive
	if conv.JoinMode.RadioJoinMode == store.RadioJoinModeApproval && !inv.BulkID.Valid {
		status = store.RadioMemberStatusPending
	}
	if _, err := s.Store.UpsertRadioMember(ctx, store.UpsertRadioMemberParams{
		ConversationID: conv.ID, UserID: userID, Role: store.RadioRole(role), Status: status, Listening: true, JoinedAt: now,
	}); err != nil {
		return AcceptResult{}, err
	}
	if err := s.Store.SetRadioInviteStatus(ctx, store.SetRadioInviteStatusParams{
		ID: inv.ID, Status: store.RadioInviteStatusAccepted, AcceptedBy: nullID(userID),
	}); err != nil {
		return AcceptResult{}, err
	}
	change := "joined"
	if status == store.RadioMemberStatusPending {
		change = "requested"
	}
	s.notifyModerators(ctx, conv.ID, userID, sub.Name, change)
	c, err := s.conversationFor(ctx, userID, conv.ID, d)
	return AcceptResult{Conversation: c, Pending: status == store.RadioMemberStatusPending}, err
}

func (s *Service) notifyModerators(ctx context.Context, conversationID, userID uuid.UUID, name, change string) {
	mods, err := s.Store.ListRadioModerators(ctx, conversationID)
	if err != nil {
		s.logger().WarnContext(ctx, "list radio moderators", "err", err)
		return
	}
	now := s.now()
	for _, m := range mods {
		if m == userID {
			continue
		}
		s.publish(ctx, m, EventMember, now, map[string]any{
			"conversation_id": conversationID, "user_id": userID, "display_name": name, "change": change,
		})
	}
}

// Moderation actions (FR-016).
const (
	ActApprove = "approve"
	ActReject  = "reject"
	ActMute    = "mute"
	ActUnmute  = "unmute"
	ActRemove  = "remove"
	ActBlock   = "block"
	ActUnblock = "unblock"
)

// ModerateInput is PUT …/members/{userId}: an action, a role change or both.
type ModerateInput struct {
	Action *string `json:"action"`
	Role   *string `json:"role"`
}

// Moderate lets an owner or moderator approve, reject, silence, expel, block or change roles
// (FR-016). Only the owner names moderators or transfers the channel; nobody acts on the owner.
// Expelling or blocking rotates the room so the old token opens nothing (FR-014, R1).
func (s *Service) Moderate(ctx context.Context, actorID, conversationID, targetID uuid.UUID, in ModerateInput) error {
	if _, _, st, err := s.allowed(ctx, actorID); err != nil {
		return err
	} else if err := s.moderate(ctx, actorID, conversationID, targetID, in, st); err != nil {
		return err
	}
	return nil
}

func (s *Service) moderate(ctx context.Context, actorID, conversationID, targetID uuid.UUID, in ModerateInput, st Settings) error {
	actor, err := s.member(ctx, conversationID, actorID)
	if err != nil {
		return err
	}
	if actor.Kind == store.RadioConversationKindCooperative {
		return ErrCooperative
	}
	if actor.Kind != store.RadioConversationKindChannel {
		return ErrInvalid
	}
	if actor.Role != store.RadioRoleOwner && actor.Role != store.RadioRoleModerator {
		return ErrNotModerator
	}
	if targetID == actorID {
		return ErrInvalid
	}
	target, err := s.Store.GetRadioMember(ctx, store.GetRadioMemberParams{ConversationID: conversationID, UserID: targetID})
	if store.IsNotFound(err) {
		return ErrNotFound
	}
	if err != nil {
		return err
	}
	if target.Role == store.RadioRoleOwner || (actor.Role == store.RadioRoleModerator && target.Role == store.RadioRoleModerator) {
		return ErrNotModerator
	}
	now := s.now()
	params := store.UpdateRadioMemberParams{ConversationID: conversationID, UserID: targetID, Now: now}
	rotate := false
	change := ""
	if in.Action != nil {
		next, ok := map[string]struct {
			from []store.RadioMemberStatus
			to   store.RadioMemberStatus
		}{
			ActApprove: {[]store.RadioMemberStatus{store.RadioMemberStatusPending}, store.RadioMemberStatusActive},
			ActReject:  {[]store.RadioMemberStatus{store.RadioMemberStatusPending}, store.RadioMemberStatusRejected},
			ActMute:    {[]store.RadioMemberStatus{store.RadioMemberStatusActive}, store.RadioMemberStatusMuted},
			ActUnmute:  {[]store.RadioMemberStatus{store.RadioMemberStatusMuted}, store.RadioMemberStatusActive},
			ActRemove:  {[]store.RadioMemberStatus{store.RadioMemberStatusActive, store.RadioMemberStatusMuted}, store.RadioMemberStatusRemoved},
			ActBlock: {[]store.RadioMemberStatus{
				store.RadioMemberStatusActive, store.RadioMemberStatusMuted, store.RadioMemberStatusPending,
				store.RadioMemberStatusRemoved, store.RadioMemberStatusRejected,
			}, store.RadioMemberStatusBlocked},
			// Desbloqueado puede volver a pedir entrada.
			ActUnblock: {[]store.RadioMemberStatus{store.RadioMemberStatusBlocked}, store.RadioMemberStatusRemoved},
		}[*in.Action]
		if !ok {
			return ErrInvalid
		}
		allowed := false
		for _, f := range next.from {
			allowed = allowed || target.Status == f
		}
		if !allowed {
			return ErrInvalid
		}
		if *in.Action == ActApprove {
			count, err := s.Store.CountRadioActiveMembers(ctx, conversationID)
			if err != nil {
				return err
			}
			if count >= MaxChannelMembers {
				return ErrChannelFull
			}
		}
		params.Status = store.NullRadioMemberStatus{RadioMemberStatus: next.to, Valid: true}
		rotate = *in.Action == ActRemove || (*in.Action == ActBlock &&
			(target.Status == store.RadioMemberStatusActive || target.Status == store.RadioMemberStatusMuted))
		change = *in.Action
	}
	if in.Role != nil {
		role := *in.Role
		if roleRank(role) > 3 || (role != RoleOwner && role != RoleModerator && role != RoleMember && role != RoleListener) {
			return ErrInvalid
		}
		if (role == RoleOwner || role == RoleModerator) && actor.Role != store.RadioRoleOwner {
			return ErrNotOwner
		}
		sub, err := s.Store.GetRadioSubject(ctx, targetID)
		if err != nil {
			return err
		}
		if string(sub.Role) == RolePassenger {
			conv, err := s.Store.GetRadioConversation(ctx, conversationID)
			if err != nil {
				return err
			}
			cap := passengerCap(st.PassengersInChannels, pgtype.Text{String: string(conv.PassengerRoleMax.RadioRole), Valid: conv.PassengerRoleMax.Valid})
			if cap == "" || roleRank(role) < roleRank(cap) {
				return ErrPassengersClosed
			}
		}
		params.Role = store.NullRadioRole{RadioRole: store.RadioRole(role), Valid: true}
		if change == "" {
			change = "role"
		}
		if role == RoleOwner {
			// Transferir: el dueño actual queda como moderador.
			if _, err := s.Store.UpdateRadioMember(ctx, store.UpdateRadioMemberParams{
				ConversationID: conversationID, UserID: actorID, Now: now,
				Role: store.NullRadioRole{RadioRole: store.RadioRoleModerator, Valid: true},
			}); err != nil {
				return err
			}
		}
	}
	if change == "" {
		return ErrInvalid
	}
	if _, err := s.Store.UpdateRadioMember(ctx, params); err != nil {
		return err
	}
	if rotate {
		s.takeOut(ctx, conversationID, actor.RoomName, targetID)
	}
	s.publish(ctx, targetID, EventMember, now, map[string]any{
		"conversation_id": conversationID, "user_id": targetID, "change": change,
	})
	s.notifyModerators(ctx, conversationID, targetID, "", change)
	return nil
}

// takeOut frees the turn of someone who leaves or is expelled, disconnects them and rotates the
// room, so the token they keep opens nothing (FR-014, as in 006).
func (s *Service) takeOut(ctx context.Context, conversationID uuid.UUID, room string, userID uuid.UUID) {
	if held, err := s.Store.GetRadioFloor(ctx, conversationID); err == nil && held.HolderID == userID {
		if err := s.Rooms.SetCanPublish(ctx, room, userID.String(), false); err == nil {
			if err := s.endTurn(ctx, conversationID, userID, s.now()); err != nil {
				s.logger().WarnContext(ctx, "release radio floor on leave", "err", err)
			}
		}
	}
	if err := s.Rooms.RemoveParticipant(ctx, room, userID.String()); err != nil {
		s.logger().WarnContext(ctx, "remove radio participant", "room", room, "err", err)
	}
	if err := s.rotateRoom(ctx, conversationID, room); err != nil {
		s.logger().WarnContext(ctx, "rotate radio room", "room", room, "err", err)
	}
}

// rotateRoom stores a new room name and then deletes the old room. In that order: if deleting
// fails, new tokens already point to the new room and nobody recreates the old one (LiveKit
// auto-creation is off). Members are told to reconnect.
func (s *Service) rotateRoom(ctx context.Context, conversationID uuid.UUID, oldRoom string) error {
	next, err := roomName(conversationID)
	if err != nil {
		return err
	}
	if _, err := s.Store.RotateRadioRoom(ctx, store.RotateRadioRoomParams{NewRoom: next, ID: conversationID, OldRoom: oldRoom}); err != nil {
		return err
	}
	if err := s.Rooms.DeleteRoom(ctx, oldRoom); err != nil {
		return err
	}
	recipients, err := s.Store.ListRadioRecipients(ctx, conversationID)
	if err != nil {
		return err
	}
	now := s.now()
	for _, r := range recipients {
		s.publish(ctx, r.UserID, EventMember, now, map[string]any{
			"conversation_id": conversationID, "user_id": r.UserID, "change": "room_rotated",
		})
	}
	return nil
}

// Leave takes the caller out of a channel (FR-014). The cooperative channel follows 006 and
// cannot be left from Radio (FR-018). An owner hands the channel to the oldest moderator or
// member; a channel left empty is deleted.
func (s *Service) Leave(ctx context.Context, userID, conversationID uuid.UUID) error {
	if _, _, _, err := s.access(ctx, userID); err != nil {
		return err
	}
	p, err := s.member(ctx, conversationID, userID)
	if err != nil {
		return err
	}
	switch p.Kind {
	case store.RadioConversationKindCooperative:
		return ErrCooperative
	case store.RadioConversationKindChannel:
	default:
		return ErrInvalid
	}
	now := s.now()
	if p.Role == store.RadioRoleOwner {
		heir, err := s.Store.GetRadioHeir(ctx, store.GetRadioHeirParams{ConversationID: conversationID, UserID: userID})
		switch {
		case store.IsNotFound(err):
			return s.Delete(ctx, userID, conversationID)
		case err != nil:
			return err
		}
		if _, err := s.Store.UpdateRadioMember(ctx, store.UpdateRadioMemberParams{
			ConversationID: conversationID, UserID: heir, Now: now,
			Role: store.NullRadioRole{RadioRole: store.RadioRoleOwner, Valid: true},
		}); err != nil {
			return err
		}
		s.publish(ctx, heir, EventMember, now, map[string]any{"conversation_id": conversationID, "user_id": heir, "change": "role"})
	}
	if _, err := s.Store.UpdateRadioMember(ctx, store.UpdateRadioMemberParams{
		ConversationID: conversationID, UserID: userID, Now: now,
		Status: store.NullRadioMemberStatus{RadioMemberStatus: store.RadioMemberStatusRemoved, Valid: true},
	}); err != nil {
		return err
	}
	s.takeOut(ctx, conversationID, p.RoomName, userID)
	return nil
}

// ApplyPassengerPolicy moves passengers already in channels to the highest role still allowed,
// or takes them out when none is (FR-017), with a radio.member notice.
func (s *Service) ApplyPassengerPolicy(ctx context.Context) error {
	st, err := s.settings(ctx)
	if err != nil {
		return err
	}
	rows, err := s.Store.ListRadioPassengerMembers(ctx)
	if err != nil {
		return err
	}
	now := s.now()
	for _, r := range rows {
		conv, err := s.Store.GetRadioConversation(ctx, r.ConversationID)
		if err != nil {
			return err
		}
		cap := passengerCap(st.PassengersInChannels, pgtype.Text{String: string(conv.PassengerRoleMax.RadioRole), Valid: conv.PassengerRoleMax.Valid})
		switch {
		case cap == "":
			if _, err := s.Store.UpdateRadioMember(ctx, store.UpdateRadioMemberParams{
				ConversationID: r.ConversationID, UserID: r.UserID, Now: now,
				Status: store.NullRadioMemberStatus{RadioMemberStatus: store.RadioMemberStatusRemoved, Valid: true},
			}); err != nil {
				return err
			}
			s.takeOut(ctx, r.ConversationID, conv.RoomName, r.UserID)
			s.publish(ctx, r.UserID, EventMember, now, map[string]any{
				"conversation_id": r.ConversationID, "user_id": r.UserID, "change": "removed_by_policy",
			})
		case roleRank(string(r.Role)) < roleRank(cap):
			if _, err := s.Store.UpdateRadioMember(ctx, store.UpdateRadioMemberParams{
				ConversationID: r.ConversationID, UserID: r.UserID, Now: now,
				Role: store.NullRadioRole{RadioRole: store.RadioRole(cap), Valid: true},
			}); err != nil {
				return err
			}
			s.publish(ctx, r.UserID, EventMember, now, map[string]any{
				"conversation_id": r.ConversationID, "user_id": r.UserID, "change": "role_by_policy", "role": cap,
			})
		}
	}
	return nil
}
