package radio

import (
	"context"
	"errors"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/store"
)

// Report decisions (FR-037).
const (
	DecisionDismissed        = "dismissed"
	DecisionMessageDeleted   = "message_deleted"
	DecisionChannelSuspended = "channel_suspended"
	DecisionUserSuspended    = "user_suspended"
)

// ErrNotChannel: only group channels are suspended from the panel.
var ErrNotChannel = errors.New("not a channel")

// Report is one open report as the panel lists it: what and where, never the content.
type Report struct {
	ID                uuid.UUID `json:"id"`
	MessageKind       string    `json:"message_kind"`
	ConversationTitle string    `json:"conversation_title"`
	Reason            string    `json:"reason"`
	CreatedAt         time.Time `json:"created_at"`
}

// ReportDetail is the reported message, the only Radio content the staff can open (R10).
type ReportDetail struct {
	Report
	Message    Message `json:"message"`
	MediaURL   *string `json:"media_url"`
	AuthorName string  `json:"author_name"`
}

// ReportMessage reports a message the caller can see (FR-036); reporting twice is the same.
func (s *Service) ReportMessage(ctx context.Context, userID, messageID uuid.UUID, reason string) error {
	if _, _, _, err := s.allowed(ctx, userID); err != nil {
		return err
	}
	reason = strings.TrimSpace(reason)
	if utf8.RuneCountInString(reason) > 200 {
		return ErrInvalid
	}
	m, _, _, err := s.visibleMessage(ctx, userID, messageID)
	if err != nil {
		return err
	}
	if m.AuthorID.UUID == userID {
		return ErrInvalid
	}
	id, err := newID()
	if err != nil {
		return err
	}
	if _, err := s.Store.InsertRadioReport(ctx, store.InsertRadioReportParams{
		ID: id, MessageID: messageID, ReporterID: userID, Reason: reason, CreatedAt: s.now(),
	}); err != nil {
		return err
	}
	return s.Store.MarkRadioMessageReported(ctx, messageID)
}

// Reports is the queue of open reports (FR-036).
func (s *Service) Reports(ctx context.Context) ([]Report, error) {
	rows, err := s.Store.ListOpenRadioReports(ctx)
	if err != nil {
		return nil, err
	}
	out := make([]Report, 0, len(rows))
	for _, r := range rows {
		out = append(out, Report{
			ID: r.ID, MessageKind: r.MessageKind, ConversationTitle: r.ConversationTitle, Reason: r.Reason, CreatedAt: r.CreatedAt,
		})
	}
	return out, nil
}

// OpenReport returns the reported message with its audio or photo and records who opened it
// and when (FR-037, radio_report_access): opening is the access, so it is never anonymous.
func (s *Service) OpenReport(ctx context.Context, adminID, reportID uuid.UUID) (ReportDetail, error) {
	r, err := s.Store.GetRadioReport(ctx, reportID)
	if store.IsNotFound(err) {
		return ReportDetail{}, ErrNotFound
	}
	if err != nil {
		return ReportDetail{}, err
	}
	if err := s.Store.InsertRadioReportAccess(ctx, store.InsertRadioReportAccessParams{ReportID: reportID, AdminID: adminID, At: s.now()}); err != nil {
		return ReportDetail{}, err
	}
	msg := store.RadioMessage{
		ID: r.MessageID, ConversationID: r.ConversationID, AuthorID: r.AuthorID, Kind: r.MessageKind, Status: r.MessageStatus,
		Body: r.Body, Lat: r.Lat, Lng: r.Lng, ObjectKey: r.ObjectKey, DurationMs: r.DurationMs,
		CreatedAt: r.MessageCreatedAt, ExpiresAt: r.MessageExpiresAt,
	}
	out := ReportDetail{
		Report: Report{
			ID: r.ID, MessageKind: string(r.MessageKind), ConversationTitle: r.ConversationTitle, Reason: r.Reason,
			CreatedAt: r.CreatedAt,
		},
		Message:    messageView(msg, r.AuthorName, true, false),
		AuthorName: r.AuthorName,
	}
	if r.ObjectKey.Valid && s.Media != nil {
		if url, err := s.Media.PresignGet(ctx, r.ObjectKey.String, MediaURLTTL); err == nil {
			out.MediaURL = &url
		}
	}
	return out, nil
}

// ResolveInput is POST …/reports/{id}/resolve.
type ResolveInput struct {
	Decision string `json:"decision"`
	Note     string `json:"note"`
}

// ResolveReport closes a report and the other open ones of the same message (FR-037): dismiss,
// delete the message (and its file), suspend the channel or suspend the author (007).
func (s *Service) ResolveReport(ctx context.Context, adminID, reportID uuid.UUID, in ResolveInput) error {
	in.Note = strings.TrimSpace(in.Note)
	if utf8.RuneCountInString(in.Note) > 200 {
		return ErrInvalid
	}
	r, err := s.Store.GetRadioReport(ctx, reportID)
	if store.IsNotFound(err) {
		return ErrNotFound
	}
	if err != nil {
		return err
	}
	if r.Status != "open" {
		return ErrInvalid
	}
	switch in.Decision {
	case DecisionDismissed:
	case DecisionMessageDeleted:
		old, err := s.Store.DeleteRadioMessage(ctx, r.MessageID)
		if err != nil && !store.IsNotFound(err) {
			return err
		}
		if old.ObjectKey.Valid {
			s.removeObject(ctx, old.ObjectKey.String, false)
		}
	case DecisionChannelSuspended:
		if r.ConversationKind != store.RadioConversationKindChannel {
			return ErrNotChannel
		}
		if err := s.SetChannelSuspended(ctx, r.ConversationID, true); err != nil {
			return err
		}
	case DecisionUserSuspended:
		if !r.AuthorID.Valid || s.SuspendUser == nil {
			return ErrInvalid
		}
		reason := "Radio: mensaje reportado"
		if in.Note != "" {
			reason += " · " + in.Note
		}
		if err := s.SuspendUser(ctx, r.AuthorID.UUID, adminID, reason); err != nil {
			return err
		}
	default:
		return ErrInvalid
	}
	_, err = s.Store.ResolveRadioReports(ctx, store.ResolveRadioReportsParams{
		Decision: text(in.Decision), Note: optText(&in.Note), ResolvedBy: nullID(adminID), ResolvedAt: ts(s.now()), MessageID: r.MessageID,
	})
	return err
}

// SetChannelSuspended suspends or reactivates a group channel from the panel (US11-2): while
// suspended nobody talks, and the room is closed so everyone leaves it at once.
func (s *Service) SetChannelSuspended(ctx context.Context, conversationID uuid.UUID, suspended bool) error {
	c, err := s.Store.GetRadioConversation(ctx, conversationID)
	if store.IsNotFound(err) {
		return ErrNotFound
	}
	if err != nil {
		return err
	}
	if c.Kind != store.RadioConversationKindChannel {
		return ErrNotChannel
	}
	status := store.RadioConversationStatusActive
	change := "channel_reactivated"
	if suspended {
		status, change = store.RadioConversationStatusSuspended, "channel_suspended"
	}
	if _, err := s.Store.SetRadioConversationStatus(ctx, store.SetRadioConversationStatusParams{
		ID: conversationID, Status: status, Column3: s.now(),
	}); err != nil {
		return err
	}
	if suspended {
		if held, err := s.Store.GetRadioFloor(ctx, conversationID); err == nil {
			if err := s.Rooms.SetCanPublish(ctx, c.RoomName, held.HolderID.String(), false); err == nil {
				if err := s.endTurn(ctx, conversationID, held.HolderID, s.now()); err != nil {
					s.logger().WarnContext(ctx, "release radio floor on channel suspension", "err", err)
				}
			}
		}
		if err := s.rotateRoom(ctx, conversationID, c.RoomName); err != nil {
			s.logger().WarnContext(ctx, "rotate suspended channel room", "err", err)
		}
	}
	recipients, err := s.Store.ListRadioRecipients(ctx, conversationID)
	if err != nil {
		return err
	}
	now := s.now()
	for _, r := range recipients {
		s.publish(ctx, r.UserID, EventMember, now, map[string]any{"conversation_id": conversationID, "user_id": r.UserID, "change": change})
	}
	return nil
}
