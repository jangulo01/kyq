package radio

import (
	"context"
	"strings"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/telemetry"
)

// Room events from the LiveKit webhook for radio-* rooms (telemetry.LiveKitWebhook forwards them).
// Each microphone publication is one message: the floor creates it in `recording`, the track
// egress records it and egress_ended leaves it `ready` with its file (research R3).

// TrackPublished marks that the turn holder's audio is flowing (the turn is not silent).
func (s *Service) TrackPublished(ctx context.Context, room, identity string) {
	conv, ok := ConversationIDFromRoom(room)
	user, err := uuid.Parse(identity)
	if !ok || err != nil {
		return
	}
	if _, err := s.Store.SetRadioFloorAudio(ctx, store.SetRadioFloorAudioParams{
		ConversationID: conv, HolderID: user, LastAudioAt: ts(s.now()),
	}); err != nil {
		s.logger().WarnContext(ctx, "radio floor audio", "room", room, "err", err)
	}
}

// TrackUnpublished or a participant that left frees the turn at once when it was the holder's:
// whoever loses signal mid-turn does not block the channel (edge cases).
func (s *Service) TrackUnpublished(ctx context.Context, room, identity string) {
	conv, ok := ConversationIDFromRoom(room)
	user, err := uuid.Parse(identity)
	if !ok || err != nil {
		return
	}
	held, err := s.Store.GetRadioFloor(ctx, conv)
	if err != nil || held.HolderID != user {
		return
	}
	if err := s.Rooms.SetCanPublish(ctx, room, identity, false); err != nil {
		s.logger().WarnContext(ctx, "revoke radio publish on unpublish", "room", room, "err", err)
		return
	}
	if err := s.endTurn(ctx, conv, user, s.now()); err != nil {
		s.logger().WarnContext(ctx, "end radio turn on unpublish", "room", room, "err", err)
	}
}

// ParticipantLeft counts voice seconds (FR-038) and frees the turn of a holder who left.
func (s *Service) ParticipantLeft(ctx context.Context, room, identity string, seconds int64) {
	s.TrackUnpublished(ctx, room, identity)
	user, err := uuid.Parse(identity)
	if err != nil || seconds <= 0 {
		return
	}
	if driver := s.payer(ctx, room, user); driver != uuid.Nil {
		telemetry.Add(s.Usage, driver, telemetry.RadioVoiceSeconds, seconds)
	}
}

// payer is the driver whose usage a participant counts in (R11): the participant if driver, the
// conversation's driver for a client; passengers in channels count in nobody.
func (s *Service) payer(ctx context.Context, room string, user uuid.UUID) uuid.UUID {
	sub, err := s.Store.GetRadioSubject(ctx, user)
	if err != nil {
		return uuid.Nil
	}
	if string(sub.Role) == RoleDriver {
		return user
	}
	conv, ok := ConversationIDFromRoom(room)
	if !ok {
		return uuid.Nil
	}
	c, err := s.Store.GetRadioConversation(ctx, conv)
	if err != nil || c.Kind != store.RadioConversationKindClient {
		return uuid.Nil
	}
	if c.PairA.UUID == user {
		return c.PairB.UUID
	}
	return c.PairA.UUID
}

// EgressStarted ties a track recording to the voice message in progress of its conversation.
func (s *Service) EgressStarted(ctx context.Context, room, egressID string) {
	if _, err := s.attachEgress(ctx, room, egressID); err != nil && !store.IsNotFound(err) {
		s.logger().WarnContext(ctx, "attach radio egress", "room", room, "err", err)
	}
}

func (s *Service) attachEgress(ctx context.Context, room, egressID string) (store.RadioMessage, error) {
	conv, ok := ConversationIDFromRoom(room)
	if !ok {
		return store.RadioMessage{}, ErrNotFound
	}
	params := store.AttachRadioEgressParams{EgressID: text(egressID), ConversationID: conv}
	if held, err := s.Store.GetRadioFloor(ctx, conv); err == nil {
		params.AuthorID = nullID(held.HolderID)
	}
	return s.Store.AttachRadioEgress(ctx, params)
}

// EgressEnded leaves the message ready with its file and duration and tells the conversation
// (FR-010). Shorter than MinVoice it is dropped with its file; a failed recording keeps the
// entry (who talked and when) without audio.
func (s *Service) EgressEnded(ctx context.Context, room, egressID, key string, durationMs, size int64, failed bool) {
	msg, err := s.Store.GetRadioMessageByEgress(ctx, text(egressID))
	if store.IsNotFound(err) {
		// egress_started se perdió: se asocia ahora.
		msg, err = s.attachEgress(ctx, room, egressID)
	}
	if err != nil {
		if !store.IsNotFound(err) {
			s.logger().WarnContext(ctx, "radio egress message", "room", room, "err", err)
		} else if key != "" {
			// Grabación sin mensaje (turno descartado antes de empezar): no se guarda.
			s.removeObject(ctx, strings.TrimPrefix(key, "/"), false)
		}
		return
	}
	key = strings.TrimPrefix(key, "/")
	if msg.Status != store.RadioMessageStatusRecording {
		if key != "" {
			s.removeObject(ctx, key, false)
		}
		return
	}
	if !failed && key != "" && durationMs > 0 && durationMs < MinVoice.Milliseconds() {
		s.discard(ctx, msg.ID)
		s.removeObject(ctx, key, false)
		return
	}
	params := store.CompleteRadioMessageParams{ID: msg.ID}
	if !failed && key != "" {
		params.ObjectKey = text(key)
		params.DurationMs = int32Of(durationMs)
		params.SizeBytes.Int64, params.SizeBytes.Valid = size, true
	}
	done, err := s.Store.CompleteRadioMessage(ctx, params)
	if err != nil {
		if !store.IsNotFound(err) {
			s.logger().WarnContext(ctx, "complete radio message", "message_id", msg.ID, "err", err)
		}
		return
	}
	if done.AuthorID.Valid {
		if driver := s.payer(ctx, room, done.AuthorID.UUID); driver != uuid.Nil {
			telemetry.Add(s.Usage, driver, telemetry.RadioMessages, 1)
			telemetry.Add(s.Usage, driver, telemetry.RadioStorageBytes, size)
		}
	}
	s.announceMessage(ctx, done)
}
