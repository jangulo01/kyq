// Package radio implements Radio Kyq (011): a permanent walkie-talkie between drivers and with
// their clients, live first and recorded to replay on demand (RN-KYQ-017).
package radio

import (
	"context"
	"sync"
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/store"
)

// Level is what a user may do in Radio (FR-005).
type Level string

const (
	Full   Level = "full"
	Listen Level = "listen"
	None   Level = "none"
)

// Reasons why access is limited, as GET /v1/radio/me shows them.
const (
	ReasonSuspended      = "suspended"
	ReasonNoSubscription = "no_subscription"
	ReasonTrialEnded     = "trial_ended"
	// ReasonNotAllowed: roles without Radio (administradores).
	ReasonNotAllowed = "not_allowed"
)

// Roles that use Radio.
const (
	RoleDriver    = "driver"
	RolePassenger = "passenger"
)

// Access policies for drivers without subscription (FR-005, research R8).
const (
	PolicyTrial            = "trial"
	PolicySubscriptionOnly = "subscription_only"
	PolicyListenOnly       = "listen_only"
)

// Passenger policies for channels (FR-017).
const (
	PassengersNone       = "none"
	PassengersListenOnly = "listen_only"
	PassengersAllRoles   = "all_roles"
)

// Settings is the single row of radio_settings (FR-040).
type Settings struct {
	TrialPolicy          string    `json:"trial_policy"`
	TrialDays            int       `json:"trial_days"`
	PassengersInChannels string    `json:"passengers_in_channels"`
	RetentionDays        int       `json:"retention_days"`
	UpdatedAt            time.Time `json:"updated_at"`
	UpdatedByName        string    `json:"updated_by_name"`
}

// Subject is what decides a user's access.
type Subject struct {
	Role      string
	Name      string
	Suspended bool
	CreatedAt time.Time
	// PaidUntil is nil when the driver never had a subscription.
	PaidUntil *time.Time
}

// Decision is the effective access of a user.
type Decision struct {
	Level  Level
	Reason string
	// TrialDaysLeft is set while a driver without subscription uses the trial.
	TrialDaysLeft *int
}

// Evaluate is the only place that decides Radio access (FR-005, data-model §Acceso):
//  1. suspended (007) → none;
//  2. passenger → full (each conversation still checks the client relationship);
//  3. driver with subscription ACTIVE or GRACE_PERIOD (RN-KYQ-002/003) → full;
//  4. otherwise the panel policy: trial for TrialDays since sign-up (then none), subscription only
//     (none) or listen only (listen).
func Evaluate(sub Subject, st Settings, now time.Time) Decision {
	if sub.Suspended {
		return Decision{Level: None, Reason: ReasonSuspended}
	}
	switch sub.Role {
	case RolePassenger:
		return Decision{Level: Full}
	case RoleDriver:
	default:
		return Decision{Level: None, Reason: ReasonNotAllowed}
	}
	if sub.PaidUntil != nil && drivers.SubscriptionStatusAt(*sub.PaidUntil, now) != drivers.SubscriptionSuspended {
		return Decision{Level: Full}
	}
	switch st.TrialPolicy {
	case PolicyListenOnly:
		return Decision{Level: Listen, Reason: ReasonNoSubscription}
	case PolicySubscriptionOnly:
		return Decision{Level: None, Reason: ReasonNoSubscription}
	}
	ends := sub.CreatedAt.Add(time.Duration(st.TrialDays) * 24 * time.Hour)
	if !now.Before(ends) {
		return Decision{Level: None, Reason: ReasonTrialEnded}
	}
	// Días que quedan, redondeando hacia arriba: el último día cuenta como 1.
	left := int((ends.Sub(now) + 24*time.Hour - time.Nanosecond) / (24 * time.Hour))
	return Decision{Level: Full, TrialDaysLeft: &left}
}

// settingsTTL is how long the service trusts its cached settings (research R8).
const settingsTTL = 30 * time.Second

type settingsCache struct {
	mu     sync.Mutex
	value  Settings
	loaded time.Time
}

// settings returns radio_settings, read at most every settingsTTL.
func (s *Service) settings(ctx context.Context) (Settings, error) {
	now := s.now()
	s.cache.mu.Lock()
	defer s.cache.mu.Unlock()
	if !s.cache.loaded.IsZero() && now.Sub(s.cache.loaded) < settingsTTL {
		return s.cache.value, nil
	}
	row, err := s.Store.GetRadioSettings(ctx)
	if err != nil {
		return Settings{}, err
	}
	s.cache.value = Settings{
		TrialPolicy: string(row.TrialPolicy), TrialDays: int(row.TrialDays),
		PassengersInChannels: string(row.PassengersInChannels), RetentionDays: int(row.RetentionDays),
		UpdatedAt: row.UpdatedAt, UpdatedByName: row.UpdatedByName,
	}
	s.cache.loaded = now
	return s.cache.value, nil
}

// forgetSettings drops the cache after a change from the panel.
func (s *Service) forgetSettings() {
	s.cache.mu.Lock()
	s.cache.loaded = time.Time{}
	s.cache.mu.Unlock()
}

// access loads the user and decides their access with the current settings.
func (s *Service) access(ctx context.Context, userID uuid.UUID) (Decision, Subject, Settings, error) {
	st, err := s.settings(ctx)
	if err != nil {
		return Decision{}, Subject{}, Settings{}, err
	}
	row, err := s.Store.GetRadioSubject(ctx, userID)
	if store.IsNotFound(err) {
		return Decision{Level: None, Reason: ReasonNotAllowed}, Subject{}, st, nil
	}
	if err != nil {
		return Decision{}, Subject{}, Settings{}, err
	}
	sub := Subject{Role: string(row.Role), Name: row.DisplayName, Suspended: row.Suspended, CreatedAt: row.CreatedAt}
	if row.HasSubscription {
		paid := row.PaidUntil
		sub.PaidUntil = &paid
	}
	return Evaluate(sub, st, s.now()), sub, st, nil
}

// allowed is access for an operation: none is ErrAccessDenied.
func (s *Service) allowed(ctx context.Context, userID uuid.UUID) (Decision, Subject, Settings, error) {
	d, sub, st, err := s.access(ctx, userID)
	if err != nil {
		return d, sub, st, err
	}
	if d.Level == None {
		return d, sub, st, ErrAccessDenied
	}
	return d, sub, st, nil
}
