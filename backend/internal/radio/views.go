package radio

import (
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/store"
)

// Presence states as the apps show them (FR-019). offline is derived: radio off or no heartbeat.
const (
	StatusAvailable  = "available"
	StatusBusy       = "busy"
	StatusListenOnly = "listen_only"
	StatusOffline    = "offline"
)

// Me is GET /v1/radio/me (contracts: RadioMe). Never carries a phone number (FR-004).
type Me struct {
	Access          Level   `json:"access"`
	AccessReason    *string `json:"access_reason"`
	TrialDaysLeft   *int    `json:"trial_days_left"`
	Status          string  `json:"status"`
	RadioOn         bool    `json:"radio_on"`
	PushMode        string  `json:"push_mode"`
	ConsentRequired bool    `json:"consent_required"`
	RetentionDays   int     `json:"retention_days"`
	ClientsEnabled  *bool   `json:"clients_enabled"`
}

// Conversation is one row of the Radio list (contracts: Conversation).
type Conversation struct {
	ID             uuid.UUID  `json:"id"`
	Kind           string     `json:"kind"`
	Title          string     `json:"title"`
	PhotoURL       *string    `json:"photo_url"`
	PeerID         *uuid.UUID `json:"peer_id"`
	PeerStatus     *string    `json:"peer_status"`
	PeerMuted      bool       `json:"peer_muted"`
	OnlineCount    *int       `json:"online_count"`
	MyRole         *string    `json:"my_role"`
	MyMemberStatus string     `json:"my_member_status"`
	Listening      bool       `json:"listening"`
	UnreadCount    int        `json:"unread_count"`
	LastMessageAt  *time.Time `json:"last_message_at"`
	Status         string     `json:"status"`
	// CanTalk tells the app whether its big button transmits here (role, silencing, blocking).
	CanTalk bool `json:"can_talk"`
}

// Member is one participant in ConversationDetail.
type Member struct {
	UserID      uuid.UUID `json:"user_id"`
	DisplayName string    `json:"display_name"`
	Role        string    `json:"role"`
	Status      string    `json:"status"`
	Presence    string    `json:"presence"`
	IsPassenger bool      `json:"is_passenger"`
}

// ConversationDetail is GET /v1/radio/conversations/{id}.
type ConversationDetail struct {
	Conversation
	Description      *string  `json:"description"`
	JoinMode         *string  `json:"join_mode"`
	PassengerRoleMax *string  `json:"passenger_role_max"`
	Members          []Member `json:"members"`
}

// Message is one history entry (contracts: Message).
type Message struct {
	ID             uuid.UUID  `json:"id"`
	ConversationID uuid.UUID  `json:"conversation_id"`
	AuthorID       *uuid.UUID `json:"author_id"`
	AuthorName     string     `json:"author_name"`
	Kind           string     `json:"kind"`
	Status         string     `json:"status"`
	Body           *string    `json:"body"`
	Lat            *float64   `json:"lat"`
	Lng            *float64   `json:"lng"`
	DurationMs     *int       `json:"duration_ms"`
	HasMedia       bool       `json:"has_media"`
	CreatedAt      time.Time  `json:"created_at"`
	ExpiresAt      *time.Time `json:"expires_at"`
	Heard          bool       `json:"heard"`
	Saved          bool       `json:"saved"`
}

// Invite is a contact or channel invitation link (contracts: Invite).
type Invite struct {
	Code      string    `json:"code"`
	URL       string    `json:"url"`
	ExpiresAt time.Time `json:"expires_at"`
}

// InvitePreview is the public view of an invitation, without personal data.
type InvitePreview struct {
	Kind        string  `json:"kind"`
	InviterName string  `json:"inviter_name"`
	ChannelName *string `json:"channel_name"`
	InviteeKind string  `json:"invitee_kind"`
}

func messageView(m store.RadioMessage, authorName string, heard, saved bool) Message {
	out := Message{
		ID: m.ID, ConversationID: m.ConversationID, AuthorName: authorName, Kind: string(m.Kind),
		Status: string(m.Status), CreatedAt: m.CreatedAt, Heard: heard, Saved: saved,
		HasMedia: m.ObjectKey.Valid,
	}
	if m.AuthorID.Valid {
		id := m.AuthorID.UUID
		out.AuthorID = &id
	}
	if m.Body.Valid {
		b := m.Body.String
		out.Body = &b
	}
	if m.Lat.Valid && m.Lng.Valid {
		lat, lng := m.Lat.Float64, m.Lng.Float64
		out.Lat, out.Lng = &lat, &lng
	}
	if m.DurationMs.Valid {
		d := int(m.DurationMs.Int32)
		out.DurationMs = &d
	}
	exp := m.ExpiresAt
	out.ExpiresAt = &exp
	return out
}

// presenceOf is the status others see: offline when the radio is off or silent too long.
func presenceOf(status string, online bool) string {
	if !online {
		return StatusOffline
	}
	return status
}
