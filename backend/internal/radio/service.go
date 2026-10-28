package radio

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"log/slog"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/ptt"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/storage"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/telemetry"
)

// Limits of the stage (spec FR-012, FR-015, FR-022, FR-024, US3-7).
const (
	MaxOwnedChannels   = 10
	MaxChannelMembers  = 200
	MaxListening       = 10
	MaxSaved           = 200
	SavedFor           = 366 * 24 * time.Hour
	MaxTextLength      = 500
	MaxAlertLength     = 80
	AlertsPerWindow    = 3
	AlertWindow        = 10 * time.Minute
	ClientMessagesHour = 20
	// MinVoice: una pulsación más corta no se guarda (edge case).
	MinVoice = 500 * time.Millisecond
	// FloorTTL caps one turn, as in 001 (FR-006).
	FloorTTL = 60 * time.Second
	// SilentFloor libera un turno concedido sin audio (el que habla perdió la señal).
	SilentFloor = 3 * time.Second
	// TokenTTL: tokens de sala cortos porque la membresía cambia (R1); la app los renueva.
	TokenTTL = time.Minute
	// MediaURLTTL is the life of a signed audio or photo URL (FR-010).
	MediaURLTTL = 10 * time.Minute
	// InviteTTL: las invitaciones vencen a los 14 días (FR-035).
	InviteTTL = 14 * 24 * time.Hour
	// HeartbeatEvery and OfflineAfter rule presence (R5).
	HeartbeatEvery = 30 * time.Second
	OfflineAfter   = 90 * time.Second
	// DirectRoomParticipants: contactos 1 a 1 y clientes; el grabador no ocupa plaza.
	DirectRoomParticipants = 2
)

var (
	ErrAccessDenied     = errors.New("radio access denied")
	ErrListenOnly       = errors.New("radio listen only")
	ErrConsentRequired  = errors.New("radio consent required")
	ErrNotFound         = errors.New("not found")
	ErrInvalid          = errors.New("invalid radio request")
	ErrFloorBusy        = errors.New("floor busy")
	ErrMuted            = errors.New("member muted")
	ErrBlocked          = errors.New("blocked")
	ErrSuspended        = errors.New("conversation suspended")
	ErrNotOwner         = errors.New("not owner")
	ErrNotModerator     = errors.New("not moderator")
	ErrCooperative      = errors.New("cooperative channel")
	ErrNameTaken        = errors.New("channel name taken")
	ErrChannelLimit     = errors.New("channel limit")
	ErrChannelFull      = errors.New("channel full")
	ErrListeningLimit   = errors.New("listening limit")
	ErrSavedLimit       = errors.New("saved limit")
	ErrRateLimited      = errors.New("rate limited")
	ErrInviteExpired    = errors.New("invite expired")
	ErrInviteWrongApp   = errors.New("invite for the other app")
	ErrPassengersClosed = errors.New("passengers not allowed")
	ErrUnavailable      = errors.New("voice server unavailable")
	ErrNoMedia          = errors.New("message without media")
)

// FloorBusyError tells who holds the turn (409 floor_busy).
type FloorBusyError struct{ HolderName string }

func (e *FloorBusyError) Error() string { return "floor taken by " + e.HolderName }
func (e *FloorBusyError) Unwrap() error { return ErrFloorBusy }

// Rooms is what Radio needs from LiveKit. The recording sits behind CreateRadioRoom: with record,
// every microphone track is saved by itself (track egress, research R3), so the plan B of T004
// (the client also sends its audio) can replace it without touching the rest.
type Rooms interface {
	CreateRadioRoom(ctx context.Context, name string, maxParticipants int, record bool) error
	// DeleteRoom succeeds when the room no longer exists.
	DeleteRoom(ctx context.Context, name string) error
	SetCanPublish(ctx context.Context, room, identity string, canPublish bool) error
	RemoveParticipant(ctx context.Context, room, identity string) error
}

// Media keeps message audio and photos (kyq-radio) and copies saved ones out of the retention.
type Media interface {
	storage.Objects
	// SaveCopy copies key into the saved bucket as savedKey (FR-012).
	SaveCopy(ctx context.Context, key, savedKey string) error
}

// Emergency opens SOS alerts from Radio (003, R7).
type Emergency interface {
	// RaiseFromRadio opens the SOS of the trip in progress, or one without trip.
	RaiseFromRadio(ctx context.Context, userID, conversationID uuid.UUID, lat, lng float64) (alertID uuid.UUID, tripID *uuid.UUID, err error)
}

// Service implements the Radio use cases.
type Service struct {
	Store     *store.Store
	LiveKit   ptt.LiveKit // firma los tokens de las salas
	Rooms     Rooms
	VoiceURL  string // URL WebSocket de LiveKit para las apps
	Publisher realtime.Publisher
	Media     Media
	// Saved reads and removes the copies in kyq-radio-saved.
	Saved storage.Objects
	SMS   notify.SMSSender
	SOS   Emergency
	// Record turns on the automatic track egress of the rooms (research R3).
	Record bool
	// PublicBaseURL builds invite links: {PublicBaseURL}/r/{code}.
	PublicBaseURL string
	// Tiendas de cada app para la página /r/{code}.
	PlayDriverURL string
	PlayRiderURL  string
	Usage         telemetry.Usage
	Now           func() time.Time
	Logger        *slog.Logger
	// Go runs background work (SMS) after answering; nil: a goroutine. Tests run it inline.
	Go func(func())

	cache        settingsCache
	lastRetained time.Time // último barrido de retención (una vez al día)
	lastQuiet    time.Time // última evaluación de horarios de silencio (cada minuto)
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

func (s *Service) background(ctx context.Context, fn func(ctx context.Context)) {
	ctx = context.WithoutCancel(ctx)
	if s.Go != nil {
		s.Go(func() { fn(ctx) })
		return
	}
	go fn(ctx)
}

// publish sends one event to a user channel; a failure is logged (the history still has it).
func (s *Service) publish(ctx context.Context, userID uuid.UUID, typ string, now time.Time, data any) {
	if s.Publisher == nil {
		return
	}
	ev := realtime.Event{Type: typ, OccurredAt: now, Data: data}
	if err := s.Publisher.Publish(ctx, "user:"+userID.String(), ev); err != nil {
		s.logger().WarnContext(ctx, "publish radio event", "type", typ, "err", err)
	}
}

func ts(t time.Time) pgtype.Timestamptz { return pgtype.Timestamptz{Time: t, Valid: true} }

func nullID(id uuid.UUID) uuid.NullUUID { return uuid.NullUUID{UUID: id, Valid: true} }

func text(v string) pgtype.Text { return pgtype.Text{String: v, Valid: true} }

func optText(v *string) pgtype.Text {
	if v == nil {
		return pgtype.Text{}
	}
	return text(*v)
}

func newID() (uuid.UUID, error) { return uuid.NewV7() }

// roomName es un nombre de sala que no se repite: `radio-{id}-{aleatorio}` (R1).
func roomName(conversationID uuid.UUID) (string, error) {
	var b [6]byte
	if _, err := rand.Read(b[:]); err != nil {
		return "", err
	}
	return "radio-" + conversationID.String() + "-" + hex.EncodeToString(b[:]), nil
}

// ConversationIDFromRoom extracts the conversation of a `radio-{id}-{hex}` room.
func ConversationIDFromRoom(room string) (uuid.UUID, bool) {
	const prefix = "radio-"
	if len(room) < len(prefix)+36 || room[:len(prefix)] != prefix {
		return uuid.Nil, false
	}
	id, err := uuid.Parse(room[len(prefix) : len(prefix)+36])
	return id, err == nil
}
