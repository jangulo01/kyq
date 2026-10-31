package radio

import (
	"context"
	"crypto/rand"
	"math/big"
	"strings"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/store"
)

const codeAlphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

// newCode is a 10-character base62 invitation code (R9).
func newCode() (string, error) {
	var b strings.Builder
	max := big.NewInt(int64(len(codeAlphabet)))
	for range 10 {
		n, err := rand.Int(rand.Reader, max)
		if err != nil {
			return "", err
		}
		b.WriteByte(codeAlphabet[n.Int64()])
	}
	return b.String(), nil
}

// InviteURL is the shared link of an invitation: it opens the app or the store (FR-032).
func (s *Service) InviteURL(code string) string {
	return strings.TrimRight(s.PublicBaseURL, "/") + "/r/" + code
}

func (s *Service) inviteView(i store.RadioInvite) Invite {
	return Invite{Code: i.Code, URL: s.InviteURL(i.Code), ExpiresAt: i.ExpiresAt}
}

// ContactInviteInput is POST /v1/radio/contacts/invites: no phone for a QR or link.
type ContactInviteInput struct {
	PhoneE164 string `json:"phone_e164"`
}

// InviteContact creates a contact invitation by QR or link, or sends it by SMS (FR-002). With a
// phone it never reveals whether an account exists: the answer is the same and the SMS carries
// the link either way.
func (s *Service) InviteContact(ctx context.Context, userID uuid.UUID, in ContactInviteInput) (*Invite, error) {
	d, sub, _, err := s.allowed(ctx, userID)
	if err != nil {
		return nil, err
	}
	if sub.Role != RoleDriver {
		// Los pasajeros solo hablan con sus conductores (FR-003).
		return nil, ErrInvalid
	}
	if d.Level == Listen {
		return nil, ErrListenOnly
	}
	var phone string
	if in.PhoneE164 != "" {
		p, ok := NormalizePhone(in.PhoneE164)
		if !ok {
			return nil, ErrInvalid
		}
		phone = p
	}
	code, err := newCode()
	if err != nil {
		return nil, err
	}
	id, err := newID()
	if err != nil {
		return nil, err
	}
	now := s.now()
	params := store.InsertRadioInviteParams{
		ID: id, Code: code, InviterID: nullID(userID), ContactOf: nullID(userID),
		InviteeKind: store.UserRoleDriver, Status: store.RadioInviteStatusPending,
		CreatedAt: now, ExpiresAt: now.Add(InviteTTL),
	}
	if phone != "" {
		params.PhoneE164 = text(phone)
	}
	inv, err := s.Store.InsertRadioInvite(ctx, params)
	if err != nil {
		return nil, err
	}
	if phone == "" {
		v := s.inviteView(inv)
		return &v, nil
	}
	body := sub.Name + " te invita a su Radio en Kyq: " + s.InviteURL(code) +
		" (vence en 14 días). Para no recibir más invitaciones abre " + s.InviteURL(code) + "/baja"
	s.background(ctx, func(ctx context.Context) { s.sendInviteSMS(ctx, inv, body) })
	return nil, nil
}

// sendInviteSMS sends one invitation unless the phone opted out, and records the result.
func (s *Service) sendInviteSMS(ctx context.Context, inv store.RadioInvite, body string) {
	if !inv.PhoneE164.Valid || s.SMS == nil {
		return
	}
	out, err := s.Store.IsRadioOptedOut(ctx, inv.PhoneE164.String)
	if err != nil {
		s.logger().WarnContext(ctx, "radio opt-out lookup", "err", err)
		return
	}
	params := store.SetRadioInviteStatusParams{ID: inv.ID}
	switch {
	case out:
		params.Status, params.Error = store.RadioInviteStatusFailed, text("no quiere invitaciones")
	default:
		if err := s.SMS.SendSMS(ctx, inv.PhoneE164.String, body); err != nil {
			s.logger().WarnContext(ctx, "send radio invite sms", "invite_id", inv.ID, "err", err)
			params.Status, params.Error = store.RadioInviteStatusFailed, text("no se pudo enviar el SMS")
		} else {
			params.Status, params.SentAt = store.RadioInviteStatusSent, ts(s.now())
		}
	}
	if err := s.Store.SetRadioInviteStatus(ctx, params); err != nil {
		s.logger().WarnContext(ctx, "save radio invite status", "invite_id", inv.ID, "err", err)
	}
}

// invite returns a valid invitation by code: ErrNotFound or ErrInviteExpired otherwise.
func (s *Service) invite(ctx context.Context, code string) (store.GetRadioInviteByCodeRow, error) {
	inv, err := s.Store.GetRadioInviteByCode(ctx, code)
	if store.IsNotFound(err) {
		return inv, ErrNotFound
	}
	if err != nil {
		return inv, err
	}
	switch {
	case inv.Status == store.RadioInviteStatusExpired, !inv.ExpiresAt.After(s.now()):
		return inv, ErrInviteExpired
	case inv.PhoneE164.Valid && (inv.Status == store.RadioInviteStatusAccepted || inv.Status == store.RadioInviteStatusAlreadyMember):
		// Con teléfono, una sola vez (data-model).
		return inv, ErrInviteExpired
	}
	return inv, nil
}

// Preview is the public view of an invitation: who invites and to what, never a phone.
func (s *Service) Preview(ctx context.Context, code string) (InvitePreview, error) {
	inv, err := s.invite(ctx, code)
	if err != nil {
		return InvitePreview{}, err
	}
	out := InvitePreview{Kind: "contact", InviterName: inv.InviterName, InviteeKind: string(inv.InviteeKind)}
	if inv.ConversationID.Valid {
		out.Kind = "channel"
		if inv.ConversationName.Valid {
			n := inv.ConversationName.String
			out.ChannelName = &n
		}
	}
	return out, nil
}

// AcceptResult is the conversation the invitation led to; Pending when a channel with approval
// still has to admit the user (202).
type AcceptResult struct {
	Conversation Conversation
	Pending      bool
}

// Accept accepts a contact or asks to join a channel (FR-002, FR-032).
func (s *Service) Accept(ctx context.Context, userID uuid.UUID, code string) (AcceptResult, error) {
	d, sub, st, err := s.allowed(ctx, userID)
	if err != nil {
		return AcceptResult{}, err
	}
	inv, err := s.invite(ctx, code)
	if err != nil {
		return AcceptResult{}, err
	}
	if inv.ConversationID.Valid {
		return s.joinChannel(ctx, userID, sub, st, d, inv)
	}
	return s.acceptContact(ctx, userID, sub, d, inv)
}

func (s *Service) acceptContact(ctx context.Context, userID uuid.UUID, sub Subject, d Decision, inv store.GetRadioInviteByCodeRow) (AcceptResult, error) {
	if sub.Role != RoleDriver {
		return AcceptResult{}, ErrInviteWrongApp
	}
	inviter := inv.ContactOf.UUID
	if !inv.ContactOf.Valid || inviter == userID {
		return AcceptResult{}, ErrInvalid
	}
	conv, err := s.ensurePair(ctx, store.RadioConversationKindDirect, inviter, userID, inviter)
	if err != nil {
		return AcceptResult{}, err
	}
	if err := s.Store.SetRadioInviteStatus(ctx, store.SetRadioInviteStatusParams{
		ID: inv.ID, Status: store.RadioInviteStatusAccepted, AcceptedBy: nullID(userID),
	}); err != nil {
		return AcceptResult{}, err
	}
	now := s.now()
	s.publish(ctx, inviter, EventInvite, now, map[string]any{
		"conversation_id": conv.ID, "user_id": userID, "display_name": sub.Name, "change": "accepted",
	})
	c, err := s.conversationFor(ctx, userID, conv.ID, d)
	return AcceptResult{Conversation: c}, err
}

// conversationFor is the list row of one conversation for userID.
func (s *Service) conversationFor(ctx context.Context, userID, conversationID uuid.UUID, d Decision) (Conversation, error) {
	now := s.now()
	rows, err := s.Store.ListRadioConversations(ctx, store.ListRadioConversationsParams{
		UserID: userID, FreshAfter: now.Add(-OfflineAfter), Now: now,
	})
	if err != nil {
		return Conversation{}, err
	}
	for _, r := range rows {
		if r.ID == conversationID {
			return conversationView(r, d), nil
		}
	}
	return Conversation{}, ErrNotFound
}

// OptOut records that a phone does not want more invitations (FR-035): the link of any of its
// invitations is enough, so no account is needed.
func (s *Service) OptOut(ctx context.Context, code string) error {
	inv, err := s.Store.GetRadioInviteByCode(ctx, code)
	if store.IsNotFound(err) {
		return ErrNotFound
	}
	if err != nil {
		return err
	}
	if !inv.PhoneE164.Valid {
		return ErrInvalid
	}
	return s.Store.InsertRadioOptOut(ctx, store.InsertRadioOptOutParams{PhoneE164: inv.PhoneE164.String, At: s.now()})
}

// ApplyPhoneInvites accepts the pending invitations sent to a phone once its owner verifies it
// by OTP (R9): the new user lands in the contact or channel without opening any link. It returns
// the conversations it led to; an invitation for the other app or no longer valid is skipped.
// auth.InviteApplier.
func (s *Service) ApplyPhoneInvites(ctx context.Context, userID uuid.UUID, phone string) ([]uuid.UUID, error) {
	invites, err := s.Store.ListPendingRadioInvitesForPhone(ctx, store.ListPendingRadioInvitesForPhoneParams{
		PhoneE164: text(phone), ExpiresAt: s.now(),
	})
	if err != nil {
		return nil, err
	}
	out := []uuid.UUID{}
	for _, inv := range invites {
		res, err := s.Accept(ctx, userID, inv.Code)
		if err != nil {
			s.logger().InfoContext(ctx, "radio phone invite not applied", "invite_id", inv.ID, "err", err)
			continue
		}
		out = append(out, res.Conversation.ID)
	}
	return out, nil
}
