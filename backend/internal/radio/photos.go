package radio

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/storage"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/telemetry"
)

// Photo limits (research R6): the app sends a JPEG of at most 1280 px without location data.
const (
	PhotoContentType = "image/jpeg"
	MaxPhotoBytes    = 2 << 20
	photoUploadTTL   = 10 * time.Minute
)

// ErrPhotoInvalid: what was uploaded is not a JPEG of at most MaxPhotoBytes; it is deleted.
var ErrPhotoInvalid = errors.New("radio photo invalid")

// PhotoUpload is POST …/photos: the message reserved and where to PUT the JPEG.
type PhotoUpload struct {
	MessageID   uuid.UUID `json:"message_id"`
	UploadURL   string    `json:"upload_url"`
	ContentType string    `json:"content_type"`
}

// photoKey is where a conversation's photo lives in kyq-radio (with the retention of the rest).
func photoKey(conversationID, messageID uuid.UUID) string {
	return "radio/photos/" + conversationID.String() + "/" + messageID.String() + ".jpg"
}

// ReservePhoto creates a photo message in `recording` and signs its upload (FR-023, R6). The
// message is visible only after PhotoUploaded checks the file.
func (s *Service) ReservePhoto(ctx context.Context, userID, conversationID uuid.UUID) (PhotoUpload, error) {
	d, sub, st, err := s.allowed(ctx, userID)
	if err != nil {
		return PhotoUpload{}, err
	}
	p, err := s.member(ctx, conversationID, userID)
	if err != nil {
		return PhotoUpload{}, err
	}
	if err := s.mayTalk(ctx, d, p); err != nil {
		return PhotoUpload{}, err
	}
	if s.Media == nil {
		return PhotoUpload{}, ErrUnavailable
	}
	now := s.now()
	if err := s.rateLimit(ctx, p, sub, MessagePhoto, now); err != nil {
		return PhotoUpload{}, err
	}
	id, err := newID()
	if err != nil {
		return PhotoUpload{}, err
	}
	key := photoKey(conversationID, id)
	url, err := s.Media.PresignPut(ctx, key, PhotoContentType, photoUploadTTL)
	if err != nil {
		s.logger().ErrorContext(ctx, "presign radio photo", "err", err)
		return PhotoUpload{}, ErrUnavailable
	}
	if _, err := s.Store.InsertRadioMessage(ctx, store.InsertRadioMessageParams{
		ID: id, ConversationID: conversationID, AuthorID: nullID(userID), Kind: store.RadioMessageKindPhoto,
		Status: store.RadioMessageStatusRecording, ObjectKey: text(key),
		ExpiresAt: now.Add(time.Duration(st.RetentionDays) * 24 * time.Hour), CreatedAt: now,
	}); err != nil {
		return PhotoUpload{}, err
	}
	return PhotoUpload{MessageID: id, UploadURL: url, ContentType: PhotoContentType}, nil
}

// PhotoUploaded confirms the upload: a JPEG of at most MaxPhotoBytes makes the message `ready`
// and tells the conversation; anything else is deleted (photo_invalid).
func (s *Service) PhotoUploaded(ctx context.Context, userID, messageID uuid.UUID) error {
	if _, _, _, err := s.allowed(ctx, userID); err != nil {
		return err
	}
	m, err := s.Store.GetRadioMessage(ctx, messageID)
	if store.IsNotFound(err) {
		return ErrNotFound
	}
	if err != nil {
		return err
	}
	if m.AuthorID.UUID != userID || m.Kind != store.RadioMessageKindPhoto {
		return ErrNotFound
	}
	if m.Status != store.RadioMessageStatusRecording {
		if m.Status == store.RadioMessageStatusReady {
			return nil // reintento de la app
		}
		return ErrNotFound
	}
	p, err := s.member(ctx, m.ConversationID, userID)
	if err != nil {
		return err
	}
	info, err := s.Media.Stat(ctx, m.ObjectKey.String)
	if errors.Is(err, storage.ErrNotFound) {
		return ErrPhotoInvalid
	}
	if err != nil {
		return err
	}
	if info.Size == 0 || info.Size > MaxPhotoBytes || !strings.HasPrefix(info.ContentType, PhotoContentType) {
		s.removeObject(ctx, m.ObjectKey.String, false)
		if _, err := s.Store.DiscardRadioMessage(ctx, messageID); err != nil {
			return err
		}
		return ErrPhotoInvalid
	}
	done, err := s.Store.CompleteRadioMessage(ctx, store.CompleteRadioMessageParams{
		ID: messageID, ObjectKey: m.ObjectKey, SizeBytes: pgtype.Int8{Int64: info.Size, Valid: true},
	})
	if store.IsNotFound(err) {
		return nil // otra confirmación ganó
	}
	if err != nil {
		return err
	}
	if driver := s.payer(ctx, p.RoomName, userID); driver != uuid.Nil {
		telemetry.Add(s.Usage, driver, telemetry.RadioMessages, 1)
		telemetry.Add(s.Usage, driver, telemetry.RadioStorageBytes, info.Size)
	}
	s.announceMessage(ctx, done)
	return nil
}
