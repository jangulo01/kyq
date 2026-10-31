package radio

import (
	"context"
	"path"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/store"
)

// Message kinds (data-model).
const (
	MessageVoice     = "voice"
	MessageText      = "text"
	MessagePhoto     = "photo"
	MessageLocation  = "location"
	MessageAlert     = "alert"
	MessageEmergency = "emergency"
)

// HistoryLimit bounds one history page.
const HistoryLimit = 100

// History returns the conversation's messages backwards from before (FR-010, FR-011), only
// those since the user joined (FR-014).
func (s *Service) History(ctx context.Context, userID, conversationID uuid.UUID, before *uuid.UUID, limit int) ([]Message, error) {
	if _, _, _, err := s.allowed(ctx, userID); err != nil {
		return nil, err
	}
	p, err := s.member(ctx, conversationID, userID)
	if err != nil {
		return nil, err
	}
	if limit <= 0 || limit > HistoryLimit {
		limit = 50
	}
	params := store.ListRadioMessagesParams{
		UserID: userID, ConversationID: conversationID, Since: p.JoinedAt, Now: s.now(), MaxRows: int32(limit),
	}
	if before != nil {
		params.Before = nullID(*before)
	}
	rows, err := s.Store.ListRadioMessages(ctx, params)
	if err != nil {
		return nil, err
	}
	out := make([]Message, 0, len(rows))
	for _, r := range rows {
		out = append(out, messageView(store.RadioMessage{
			ID: r.ID, ConversationID: r.ConversationID, AuthorID: r.AuthorID, Kind: r.Kind, Status: r.Status,
			Body: r.Body, Lat: r.Lat, Lng: r.Lng, ObjectKey: r.ObjectKey, DurationMs: r.DurationMs,
			ExpiresAt: r.ExpiresAt, CreatedAt: r.CreatedAt,
		}, r.AuthorName, r.Heard, r.Saved))
	}
	return out, nil
}

// visibleMessage returns a ready message the user may see: a participant since before it was
// sent; expired, only if the user saved it (FR-012). The receipt is the user's, if any.
func (s *Service) visibleMessage(ctx context.Context, userID, messageID uuid.UUID) (store.RadioMessage, participant, *store.RadioReceipt, error) {
	m, err := s.Store.GetRadioMessage(ctx, messageID)
	if store.IsNotFound(err) {
		return m, participant{}, nil, ErrNotFound
	}
	if err != nil {
		return m, participant{}, nil, err
	}
	p, err := s.member(ctx, m.ConversationID, userID)
	if err != nil {
		return m, participant{}, nil, err
	}
	if m.Status != store.RadioMessageStatusReady || m.CreatedAt.Before(p.JoinedAt) {
		return m, participant{}, nil, ErrNotFound
	}
	var receipt *store.RadioReceipt
	r, err := s.Store.GetRadioReceipt(ctx, store.GetRadioReceiptParams{MessageID: messageID, UserID: userID})
	switch {
	case err == nil:
		receipt = &r
	case !store.IsNotFound(err):
		return m, participant{}, nil, err
	}
	if !m.ExpiresAt.After(s.now()) && (receipt == nil || !receipt.SavedAt.Valid) {
		return m, participant{}, nil, ErrNotFound
	}
	return m, p, receipt, nil
}

// MediaURL signs the audio or photo of a message for MediaURLTTL (FR-010). A saved message
// past the retention plays from its saved copy.
func (s *Service) MediaURL(ctx context.Context, userID, messageID uuid.UUID) (string, error) {
	if _, _, _, err := s.allowed(ctx, userID); err != nil {
		return "", err
	}
	m, _, receipt, err := s.visibleMessage(ctx, userID, messageID)
	if err != nil {
		return "", err
	}
	if receipt != nil && receipt.SavedKey.Valid && s.Saved != nil {
		return s.Saved.PresignGet(ctx, receipt.SavedKey.String, MediaURLTTL)
	}
	if !m.ObjectKey.Valid || s.Media == nil {
		return "", ErrNoMedia
	}
	return s.Media.PresignGet(ctx, m.ObjectKey.String, MediaURLTTL)
}

// ReceiptInput is PUT …/receipt.
type ReceiptInput struct {
	Heard *bool `json:"heard"`
	Saved *bool `json:"saved"`
}

// Receipt marks a message heard or read, and saves or unsaves it (FR-011, FR-012). Saving copies
// its object out of the retention; at most MaxSaved per user.
func (s *Service) Receipt(ctx context.Context, userID, messageID uuid.UUID, in ReceiptInput) error {
	if _, _, _, err := s.allowed(ctx, userID); err != nil {
		return err
	}
	m, _, receipt, err := s.visibleMessage(ctx, userID, messageID)
	if err != nil {
		return err
	}
	now := s.now()
	if in.Heard != nil && *in.Heard {
		if err := s.Store.UpsertRadioHeard(ctx, store.UpsertRadioHeardParams{MessageID: messageID, UserID: userID, HeardAt: ts(now)}); err != nil {
			return err
		}
	}
	if in.Saved == nil {
		return nil
	}
	if !*in.Saved {
		key, err := s.Store.UnsaveRadioReceipt(ctx, store.UnsaveRadioReceiptParams{MessageID: messageID, UserID: userID})
		if store.IsNotFound(err) {
			return nil
		}
		if err != nil {
			return err
		}
		if key.Valid {
			s.removeObject(ctx, key.String, true)
		}
		return nil
	}
	if receipt != nil && receipt.SavedAt.Valid {
		return nil
	}
	count, err := s.Store.CountRadioSaved(ctx, userID)
	if err != nil {
		return err
	}
	if count >= MaxSaved {
		return ErrSavedLimit
	}
	var savedKey pgtype.Text
	if m.ObjectKey.Valid && s.Media != nil {
		key := "saved/" + userID.String() + "/" + messageID.String() + path.Ext(m.ObjectKey.String)
		if err := s.Media.SaveCopy(ctx, m.ObjectKey.String, key); err != nil {
			s.logger().ErrorContext(ctx, "copy saved radio message", "message_id", messageID, "err", err)
			return ErrUnavailable
		}
		savedKey = text(key)
	}
	return s.Store.SaveRadioReceipt(ctx, store.SaveRadioReceiptParams{MessageID: messageID, UserID: userID, HeardAt: ts(now), SavedKey: savedKey})
}

// SendInput is POST …/messages: text, location or alert (FR-022, FR-023).
type SendInput struct {
	Kind string   `json:"kind"`
	Body string   `json:"body"`
	Lat  *float64 `json:"lat"`
	Lng  *float64 `json:"lng"`
}

// Send stores a text, location or call alert and tells the conversation.
func (s *Service) Send(ctx context.Context, userID, conversationID uuid.UUID, in SendInput) (Message, error) {
	d, sub, st, err := s.allowed(ctx, userID)
	if err != nil {
		return Message{}, err
	}
	p, err := s.member(ctx, conversationID, userID)
	if err != nil {
		return Message{}, err
	}
	if err := s.mayTalk(ctx, d, p); err != nil {
		return Message{}, err
	}
	params := store.InsertRadioMessageParams{
		ConversationID: conversationID, AuthorID: nullID(userID), Status: store.RadioMessageStatusReady,
	}
	body := strings.TrimSpace(in.Body)
	switch in.Kind {
	case MessageText:
		if n := utf8.RuneCountInString(body); n == 0 || n > MaxTextLength {
			return Message{}, ErrInvalid
		}
		params.Kind, params.Body = store.RadioMessageKindText, text(body)
	case MessageLocation:
		if in.Lat == nil || in.Lng == nil || *in.Lat < -90 || *in.Lat > 90 || *in.Lng < -180 || *in.Lng > 180 {
			return Message{}, ErrInvalid
		}
		params.Kind = store.RadioMessageKindLocation
		params.Lat, params.Lng = pgtype.Float8{Float64: *in.Lat, Valid: true}, pgtype.Float8{Float64: *in.Lng, Valid: true}
		if body != "" {
			if utf8.RuneCountInString(body) > MaxTextLength {
				return Message{}, ErrInvalid
			}
			params.Body = text(body)
		}
	case MessageAlert:
		if utf8.RuneCountInString(body) > MaxAlertLength {
			return Message{}, ErrInvalid
		}
		params.Kind = store.RadioMessageKindAlert
		if body != "" {
			params.Body = text(body)
		}
	default:
		return Message{}, ErrInvalid
	}
	now := s.now()
	if err := s.rateLimit(ctx, p, sub, string(params.Kind), now); err != nil {
		return Message{}, err
	}
	id, err := newID()
	if err != nil {
		return Message{}, err
	}
	params.ID, params.CreatedAt = id, now
	params.ExpiresAt = now.Add(time.Duration(st.RetentionDays) * 24 * time.Hour)
	msg, err := s.Store.InsertRadioMessage(ctx, params)
	if err != nil {
		return Message{}, err
	}
	s.announceMessage(ctx, msg)
	return messageView(msg, sub.Name, true, false), nil
}

// rateLimit applies the call alert limit (3 per sender and destination in 10 minutes, FR-022)
// and the passenger limit towards a driver (20 messages per hour, US3-7).
func (s *Service) rateLimit(ctx context.Context, p participant, sub Subject, kind string, now time.Time) error {
	if kind == MessageAlert {
		n, err := s.Store.CountRadioRecentMessages(ctx, store.CountRadioRecentMessagesParams{
			ConversationID: p.ConversationID, AuthorID: nullID(p.UserID), CreatedAt: now.Add(-AlertWindow),
			Kinds: []string{MessageAlert},
		})
		if err != nil {
			return err
		}
		if n >= AlertsPerWindow {
			return ErrRateLimited
		}
	}
	if p.Kind == store.RadioConversationKindClient && sub.Role == RolePassenger {
		n, err := s.Store.CountRadioRecentMessages(ctx, store.CountRadioRecentMessagesParams{
			ConversationID: p.ConversationID, AuthorID: nullID(p.UserID), CreatedAt: now.Add(-time.Hour),
			Kinds: []string{MessageVoice, MessageText, MessagePhoto, MessageLocation, MessageAlert},
		})
		if err != nil {
			return err
		}
		if n >= ClientMessagesHour {
			return ErrRateLimited
		}
	}
	return nil
}

// announceMessage tells every participant about a ready message. silent marks the recipients
// for whom it must not ring: Busy (FR-020), "Escuchar" off (FR-024) or a client the driver
// silenced (FR-003). Alerts ring in Busy too (FR-022); emergencies always (FR-031).
func (s *Service) announceMessage(ctx context.Context, msg store.RadioMessage) {
	recipients, err := s.Store.ListRadioRecipients(ctx, msg.ConversationID)
	if err != nil {
		s.logger().WarnContext(ctx, "list radio recipients", "err", err)
		return
	}
	authorName := "Usuario eliminado"
	authorMuted := false
	if msg.AuthorID.Valid {
		if n, err := s.Store.GetUserDisplayName(ctx, msg.AuthorID.UUID); err == nil {
			authorName = n
		}
		for _, r := range recipients {
			if r.UserID == msg.AuthorID.UUID {
				authorMuted = r.MutedByPeer
			}
		}
	}
	view := messageView(msg, authorName, false, false)
	typ := EventMessage
	switch msg.Kind {
	case store.RadioMessageKindAlert:
		typ = EventAlert
	case store.RadioMessageKindEmergency:
		typ = EventEmergency
	}
	now := s.now()
	for _, r := range recipients {
		if msg.AuthorID.Valid && r.UserID == msg.AuthorID.UUID {
			continue
		}
		silent := !r.Listening || r.PresenceStatus == StatusBusy || authorMuted
		switch msg.Kind {
		case store.RadioMessageKindAlert:
			silent = authorMuted
		case store.RadioMessageKindEmergency:
			silent = false
		}
		s.publish(ctx, r.UserID, typ, now, map[string]any{"message": view, "silent": silent})
	}
}
