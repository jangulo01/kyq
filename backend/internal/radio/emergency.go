package radio

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/store"
)

// EmergencyResult is POST …/emergency: the SOS of 003 that was opened (and its trip, if any).
type EmergencyResult struct {
	AlertID uuid.UUID  `json:"alert_id"`
	TripID  *uuid.UUID `json:"trip_id"`
}

// Emergency is the Emergency button of Radio (FR-030, FR-031): it opens the SOS of 003 (the
// trip's if there is one in progress) and leaves an emergency message with the location in the
// conversation and in the driver's cooperative, which rings even in Busy. It works without
// consent and in listen-only: an emergency is never blocked by Radio's rules.
func (s *Service) Emergency(ctx context.Context, userID, conversationID uuid.UUID, lat, lng *float64) (EmergencyResult, error) {
	_, sub, st, err := s.allowed(ctx, userID)
	if err != nil {
		return EmergencyResult{}, err
	}
	if _, err := s.member(ctx, conversationID, userID); err != nil {
		return EmergencyResult{}, err
	}
	if (lat == nil) != (lng == nil) || (lat != nil && (*lat < -90 || *lat > 90 || *lng < -180 || *lng > 180)) {
		return EmergencyResult{}, ErrInvalid
	}
	if s.SOS == nil {
		return EmergencyResult{}, ErrUnavailable
	}
	alertID, tripID, err := s.SOS.RaiseFromRadio(ctx, userID, conversationID, lat, lng)
	if err != nil {
		return EmergencyResult{}, err
	}
	targets := []uuid.UUID{conversationID}
	if coop, err := s.syncCooperative(ctx, userID, sub.Role); err == nil && coop.ID != conversationID &&
		coop.Status == store.RadioConversationStatusActive {
		// Toda la cooperativa, también quien aún no abrió Radio.
		if err := s.syncCooperativeMembers(ctx, coop.ID, coop.CooperativeID.UUID); err != nil {
			s.logger().WarnContext(ctx, "sync cooperative members for emergency", "err", err)
		}
		targets = append(targets, coop.ID)
	}
	now := s.now()
	var plat, plng pgtype.Float8
	if lat != nil {
		plat, plng = pgtype.Float8{Float64: *lat, Valid: true}, pgtype.Float8{Float64: *lng, Valid: true}
	}
	for _, conv := range targets {
		id, err := newID()
		if err != nil {
			return EmergencyResult{}, err
		}
		msg, err := s.Store.InsertRadioMessage(ctx, store.InsertRadioMessageParams{
			ID: id, ConversationID: conv, AuthorID: nullID(userID), Kind: store.RadioMessageKindEmergency,
			Status: store.RadioMessageStatusReady, Body: text(sub.Name + " activó una emergencia"),
			Lat: plat, Lng: plng,
			SosAlertID: nullID(alertID), ExpiresAt: now.Add(time.Duration(st.RetentionDays) * 24 * time.Hour), CreatedAt: now,
		})
		if err != nil {
			return EmergencyResult{}, err
		}
		s.announceMessage(ctx, msg)
	}
	return EmergencyResult{AlertID: alertID, TripID: tripID}, nil
}
