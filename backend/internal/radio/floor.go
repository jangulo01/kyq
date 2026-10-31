package radio

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/store"
)

// Credentials is POST …/ptt/token: listen-only credentials for the conversation room (R1).
type Credentials struct {
	URL       string    `json:"url"`
	Token     string    `json:"token"`
	Room      string    `json:"room"`
	ExpiresAt time.Time `json:"expires_at"`
}

// Floor is POST …/ptt/floor: the voice message being recorded and when the turn ends.
type Floor struct {
	MessageID uuid.UUID `json:"message_id"`
	ExpiresAt time.Time `json:"expires_at"`
}

func roomCapacity(kind store.RadioConversationKind) int {
	if kind == store.RadioConversationKindDirect || kind == store.RadioConversationKindClient {
		return DirectRoomParticipants
	}
	return MaxChannelMembers
}

// ensureRoom creates the room of a conversation (idempotent) with the automatic track recording.
func (s *Service) ensureRoom(ctx context.Context, room string, kind store.RadioConversationKind) error {
	if err := s.Rooms.CreateRadioRoom(ctx, room, roomCapacity(kind), s.Record); err != nil {
		s.logger().ErrorContext(ctx, "create radio room", "room", room, "err", err)
		return ErrUnavailable
	}
	return nil
}

// Token issues a short listen-only token (TokenTTL): publishing comes with the floor, so a
// modified app cannot talk over the others, and an expelled user cannot come back with it.
func (s *Service) Token(ctx context.Context, userID, conversationID uuid.UUID) (Credentials, error) {
	if _, _, _, err := s.allowed(ctx, userID); err != nil {
		return Credentials{}, err
	}
	p, err := s.member(ctx, conversationID, userID)
	if err != nil {
		return Credentials{}, err
	}
	if p.ConversationStatus == store.RadioConversationStatusSuspended {
		return Credentials{}, ErrSuspended
	}
	name, err := s.Store.GetUserDisplayName(ctx, userID)
	if err != nil {
		return Credentials{}, err
	}
	if err := s.ensureRoom(ctx, p.RoomName, p.Kind); err != nil {
		return Credentials{}, err
	}
	now := s.now()
	token, err := s.LiveKit.ParticipantToken(userID.String(), name, p.RoomName, now, TokenTTL)
	if err != nil {
		return Credentials{}, err
	}
	return Credentials{URL: s.VoiceURL, Token: token, Room: p.RoomName, ExpiresAt: now.Add(TokenTTL)}, nil
}

// TakeFloor grants the conversation's single turn for FloorTTL (FR-006) and creates its voice
// message in `recording`. The turn row comes first and LiveKit's permission after it; if LiveKit
// fails, the row is undone only when the revocation is confirmed (fail-closed, 001).
func (s *Service) TakeFloor(ctx context.Context, userID, conversationID uuid.UUID) (Floor, error) {
	d, _, st, err := s.allowed(ctx, userID)
	if err != nil {
		return Floor{}, err
	}
	p, err := s.member(ctx, conversationID, userID)
	if err != nil {
		return Floor{}, err
	}
	if err := s.mayTalk(ctx, d, p); err != nil {
		return Floor{}, err
	}
	if err := s.ensureRoom(ctx, p.RoomName, p.Kind); err != nil {
		return Floor{}, err
	}
	now := s.now()
	msgID, err := newID()
	if err != nil {
		return Floor{}, err
	}
	var floor store.RadioFloor
	err = s.Store.WithTx(ctx, func(q *store.Queries) error {
		var err error
		floor, err = q.TakeRadioFloor(ctx, store.TakeRadioFloorParams{
			ConversationID: conversationID, HolderID: userID, MessageID: msgID, GrantedAt: now, ExpiresAt: now.Add(FloorTTL),
		})
		if store.IsNotFound(err) {
			held, err := q.GetRadioFloor(ctx, conversationID)
			if err != nil {
				return err
			}
			if held.HolderID == userID {
				// Reintento de la app: el turno y el mensaje siguen valiendo.
				floor = store.RadioFloor{ConversationID: conversationID, HolderID: userID, MessageID: held.MessageID, ExpiresAt: held.ExpiresAt}
				return nil
			}
			return &FloorBusyError{HolderName: held.HolderName}
		}
		if err != nil {
			return err
		}
		_, err = q.InsertRadioMessage(ctx, store.InsertRadioMessageParams{
			ID: msgID, ConversationID: conversationID, AuthorID: nullID(userID), Kind: store.RadioMessageKindVoice,
			Status: store.RadioMessageStatusRecording, ExpiresAt: now.Add(time.Duration(st.RetentionDays) * 24 * time.Hour),
			CreatedAt: now,
		})
		return err
	})
	if err != nil {
		return Floor{}, err
	}
	if floor.MessageID != msgID {
		return Floor{MessageID: floor.MessageID, ExpiresAt: floor.ExpiresAt}, nil
	}
	if err := s.Rooms.SetCanPublish(ctx, p.RoomName, userID.String(), true); err != nil {
		s.logger().ErrorContext(ctx, "grant radio publish", "room", p.RoomName, "err", err)
		// LiveKit pudo aplicar el permiso aunque la llamada fallara.
		if s.Rooms.SetCanPublish(ctx, p.RoomName, userID.String(), false) == nil {
			if err := s.endTurn(ctx, conversationID, userID, now); err != nil {
				return Floor{}, err
			}
		}
		return Floor{}, ErrUnavailable
	}
	return Floor{MessageID: msgID, ExpiresAt: floor.ExpiresAt}, nil
}

// ReleaseFloor revokes publishing and then frees the turn (FR-006); without the turn nothing
// changes. If LiveKit does not confirm, the turn stays and expires by itself.
func (s *Service) ReleaseFloor(ctx context.Context, userID, conversationID uuid.UUID) error {
	if _, _, _, err := s.access(ctx, userID); err != nil {
		return err
	}
	p, err := s.member(ctx, conversationID, userID)
	if err != nil {
		return err
	}
	held, err := s.Store.GetRadioFloor(ctx, conversationID)
	if store.IsNotFound(err) {
		return nil
	}
	if err != nil {
		return err
	}
	if held.HolderID != userID {
		return nil
	}
	if err := s.Rooms.SetCanPublish(ctx, p.RoomName, userID.String(), false); err != nil {
		s.logger().ErrorContext(ctx, "revoke radio publish", "room", p.RoomName, "err", err)
		return ErrUnavailable
	}
	return s.endTurn(ctx, conversationID, userID, s.now())
}

// endTurn deletes the turn row after the revocation and closes its message: shorter than
// MinVoice it is discarded; without recording it is ready right away with the turn's length.
func (s *Service) endTurn(ctx context.Context, conversationID, holderID uuid.UUID, now time.Time) error {
	f, err := s.Store.ReleaseRadioFloor(ctx, store.ReleaseRadioFloorParams{ConversationID: conversationID, HolderID: holderID})
	if store.IsNotFound(err) {
		return nil
	}
	if err != nil {
		return err
	}
	// Sin audio en la sala no hubo mensaje (pulsación sin voz o señal perdida); con audio, la
	// duración cuenta desde que empezó a sonar.
	if !f.LastAudioAt.Valid || now.Sub(f.LastAudioAt.Time) < MinVoice {
		s.discard(ctx, f.MessageID)
		return nil
	}
	if s.Record {
		// El webhook egress_ended lo pone listo con el archivo y su duración (egress.go).
		return nil
	}
	msg, err := s.Store.CompleteRadioMessage(ctx, store.CompleteRadioMessageParams{
		ID: f.MessageID, DurationMs: int32Of(now.Sub(f.LastAudioAt.Time).Milliseconds()),
	})
	if store.IsNotFound(err) {
		return nil
	}
	if err != nil {
		return err
	}
	s.announceMessage(ctx, msg)
	return nil
}

// discard drops an accidental press (< MinVoice) and its audio, if any already arrived.
func (s *Service) discard(ctx context.Context, messageID uuid.UUID) {
	key, err := s.Store.DiscardRadioMessage(ctx, messageID)
	if err != nil && !store.IsNotFound(err) {
		s.logger().WarnContext(ctx, "discard radio message", "message_id", messageID, "err", err)
		return
	}
	if key.Valid {
		s.removeObject(ctx, key.String, false)
	}
}

// ExpireFloors revokes and frees turns past FloorTTL or granted without audio for SilentFloor
// (edge cases). It returns how many were freed.
func (s *Service) ExpireFloors(ctx context.Context) (int, error) {
	now := s.now()
	due, err := s.Store.ListDueRadioFloors(ctx, store.ListDueRadioFloorsParams{Now: now, SilentBefore: now.Add(-SilentFloor)})
	if err != nil {
		return 0, err
	}
	n := 0
	for _, f := range due {
		if err := s.Rooms.SetCanPublish(ctx, f.RoomName, f.HolderID.String(), false); err != nil {
			s.logger().WarnContext(ctx, "revoke expired radio floor", "room", f.RoomName, "err", err)
			continue
		}
		if err := s.endTurn(ctx, f.ConversationID, f.HolderID, now); err != nil {
			return n, err
		}
		n++
	}
	return n, nil
}

func int32Of(v int64) pgtype.Int4 { return pgtype.Int4{Int32: int32(v), Valid: true} }
