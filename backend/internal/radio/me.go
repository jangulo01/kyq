package radio

import (
	"context"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/store"
)

// Me returns the caller's Radio state, effective access and pending consent (FR-005, FR-013).
// It answers even without access, so the app can explain what is missing.
func (s *Service) Me(ctx context.Context, userID uuid.UUID) (Me, error) {
	d, sub, st, err := s.access(ctx, userID)
	if err != nil {
		return Me{}, err
	}
	p, err := s.Store.EnsureRadioPresence(ctx, store.EnsureRadioPresenceParams{UserID: userID, UpdatedAt: s.now()})
	if err != nil {
		return Me{}, err
	}
	return s.meView(ctx, userID, d, sub, st, p)
}

func (s *Service) meView(ctx context.Context, userID uuid.UUID, d Decision, sub Subject, st Settings, p store.RadioPresence) (Me, error) {
	out := Me{
		Access: d.Level, TrialDaysLeft: d.TrialDaysLeft, Status: string(p.Status), RadioOn: p.RadioOn,
		PushMode: p.PushMode, RetentionDays: st.RetentionDays,
	}
	if d.Reason != "" {
		r := d.Reason
		out.AccessReason = &r
	}
	consent, err := s.Store.GetRadioConsent(ctx, userID)
	switch {
	case store.IsNotFound(err):
		out.ConsentRequired = true
	case err != nil:
		return Me{}, err
	default:
		out.ConsentRequired = int(consent.RetentionDaysAccepted) != st.RetentionDays
	}
	if sub.Role == RoleDriver {
		v := p.ClientsEnabled
		out.ClientsEnabled = &v
	}
	return out, nil
}

// MeUpdate changes state, radio on/off or push mode; nil fields stay as they are.
type MeUpdate struct {
	Status   *string `json:"status"`
	RadioOn  *bool   `json:"radio_on"`
	PushMode *string `json:"push_mode"`
}

// UpdateMe applies MeUpdate and tells contacts and channels the new presence (FR-019).
func (s *Service) UpdateMe(ctx context.Context, userID uuid.UUID, in MeUpdate) (Me, error) {
	d, sub, st, err := s.access(ctx, userID)
	if err != nil {
		return Me{}, err
	}
	params := store.UpdateRadioPresenceParams{UserID: userID, Now: s.now()}
	if in.Status != nil {
		switch *in.Status {
		case StatusAvailable, StatusBusy, StatusListenOnly:
			params.Status = store.NullRadioPresenceStatus{RadioPresenceStatus: store.RadioPresenceStatus(*in.Status), Valid: true}
		default:
			return Me{}, ErrInvalid
		}
	}
	if in.PushMode != nil {
		if *in.PushMode != "hold" && *in.PushMode != "toggle" {
			return Me{}, ErrInvalid
		}
		params.PushMode = text(*in.PushMode)
	}
	if in.RadioOn != nil {
		params.RadioOn.Bool, params.RadioOn.Valid = *in.RadioOn, true
	}
	if _, err := s.Store.EnsureRadioPresence(ctx, store.EnsureRadioPresenceParams{UserID: userID, UpdatedAt: params.Now}); err != nil {
		return Me{}, err
	}
	p, err := s.Store.UpdateRadioPresence(ctx, params)
	if err != nil {
		return Me{}, err
	}
	if in.Status != nil || in.RadioOn != nil {
		s.announcePresence(ctx, userID, p)
	}
	return s.meView(ctx, userID, d, sub, st, p)
}

// Consent records that the user accepted the recording notice with the current retention
// (FR-013). A new retention asks again.
func (s *Service) Consent(ctx context.Context, userID uuid.UUID) error {
	st, err := s.settings(ctx)
	if err != nil {
		return err
	}
	return s.Store.UpsertRadioConsent(ctx, store.UpsertRadioConsentParams{
		UserID: userID, RetentionDaysAccepted: int32(st.RetentionDays), AcceptedAt: s.now(),
	})
}

// Heartbeat keeps the radio on (every 30 s, R5); a user that was offline is announced.
func (s *Service) Heartbeat(ctx context.Context, userID uuid.UUID) error {
	now := s.now()
	before, err := s.Store.EnsureRadioPresence(ctx, store.EnsureRadioPresenceParams{UserID: userID, UpdatedAt: now})
	if err != nil {
		return err
	}
	if _, err := s.Store.TouchRadioPresence(ctx, store.TouchRadioPresenceParams{UserID: userID, LastSeenAt: ts(now)}); err != nil {
		return err
	}
	wasOnline := before.RadioOn && before.LastSeenAt.Valid && now.Sub(before.LastSeenAt.Time) < OfflineAfter
	if !wasOnline {
		before.RadioOn = true
		s.announcePresence(ctx, userID, before)
	}
	return nil
}

// announcePresence tells every contact and channel member of userID their new state.
func (s *Service) announcePresence(ctx context.Context, userID uuid.UUID, p store.RadioPresence) {
	status := string(p.Status)
	if !p.RadioOn {
		status = StatusOffline
	}
	peers, err := s.Store.ListRadioConversationsOf(ctx, userID)
	if err != nil {
		s.logger().WarnContext(ctx, "list radio peers", "err", err)
		return
	}
	now := s.now()
	for _, peer := range peers {
		s.publish(ctx, peer, EventPresence, now, map[string]any{"user_id": userID, "status": status})
	}
}
