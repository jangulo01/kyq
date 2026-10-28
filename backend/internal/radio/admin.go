package radio

import (
	"context"
	"encoding/json"
	"math"
	"strconv"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/store"
)

// Retention options of the panel (FR-040) and the storage rate unit.
var retentionOptions = []int{7, 30, 90}

// costCurrency is the currency of the cost estimate (cost_rates de 007).
const costCurrency = "COP"

// SettingsView is GET /v1/admin/radio/settings: the settings and what each retention would cost
// per month with the audio stored in the last 30 days (contracts: RadioSettings).
type SettingsView struct {
	Settings
	EstimatedMonthlyCostMinor map[string]int64 `json:"estimated_monthly_cost_minor"`
}

// SettingsInput is PUT /v1/admin/radio/settings; nil fields stay as they are.
type SettingsInput struct {
	TrialPolicy          *string `json:"trial_policy"`
	TrialDays            *int    `json:"trial_days"`
	PassengersInChannels *string `json:"passengers_in_channels"`
	RetentionDays        *int    `json:"retention_days"`
}

// AdminSettings returns the settings with the cost estimate (FR-040).
func (s *Service) AdminSettings(ctx context.Context) (SettingsView, error) {
	s.forgetSettings()
	st, err := s.settings(ctx)
	if err != nil {
		return SettingsView{}, err
	}
	cost, err := s.retentionCost(ctx)
	if err != nil {
		return SettingsView{}, err
	}
	return SettingsView{Settings: st, EstimatedMonthlyCostMinor: cost}, nil
}

// retentionCost estimates the monthly storage cost of each retention: what Radio stored per day
// in the last 30 days, kept that many days, at the `radio_storage` rate per GB-mes.
func (s *Service) retentionCost(ctx context.Context) (map[string]int64, error) {
	now := s.now()
	bytes, err := s.Store.SumRadioStorageBytes(ctx, now.AddDate(0, 0, -30))
	if err != nil {
		return nil, err
	}
	rate, err := s.Store.GetCostRateAt(ctx, store.GetCostRateAtParams{
		Concept: store.CostConceptRadioStorage, Currency: costCurrency, Day: now,
	})
	if store.IsNotFound(err) {
		rate, err = 0, nil
	}
	if err != nil {
		return nil, err
	}
	perDay := float64(bytes) / 30
	out := map[string]int64{}
	for _, days := range retentionOptions {
		gb := perDay * float64(days) / 1e9
		out[strconv.Itoa(days)] = int64(math.Round(gb * float64(rate) / 1e6))
	}
	return out, nil
}

// UpdateSettings changes the settings from the panel (FR-040): it is written to the audit log,
// the cache is dropped, users are told (`radio.settings`) and, if passengers are restricted,
// those already in channels are moved or taken out. A new retention asks everybody to accept
// the notice again (consent stores the retention accepted) and is applied to the stored messages.
func (s *Service) UpdateSettings(ctx context.Context, adminID uuid.UUID, in SettingsInput) (SettingsView, error) {
	s.forgetSettings()
	before, err := s.settings(ctx)
	if err != nil {
		return SettingsView{}, err
	}
	after := before
	if in.TrialPolicy != nil {
		switch *in.TrialPolicy {
		case PolicyTrial, PolicySubscriptionOnly, PolicyListenOnly:
			after.TrialPolicy = *in.TrialPolicy
		default:
			return SettingsView{}, ErrInvalid
		}
	}
	if in.TrialDays != nil {
		if *in.TrialDays < 1 || *in.TrialDays > 90 {
			return SettingsView{}, ErrInvalid
		}
		after.TrialDays = *in.TrialDays
	}
	if in.PassengersInChannels != nil {
		switch *in.PassengersInChannels {
		case PassengersNone, PassengersListenOnly, PassengersAllRoles:
			after.PassengersInChannels = *in.PassengersInChannels
		default:
			return SettingsView{}, ErrInvalid
		}
	}
	if in.RetentionDays != nil {
		ok := false
		for _, d := range retentionOptions {
			ok = ok || d == *in.RetentionDays
		}
		if !ok {
			return SettingsView{}, ErrInvalid
		}
		after.RetentionDays = *in.RetentionDays
	}
	now := s.now()
	audit := func(st Settings) []byte {
		b, _ := json.Marshal(map[string]any{
			"trial_policy": st.TrialPolicy, "trial_days": st.TrialDays,
			"passengers_in_channels": st.PassengersInChannels, "retention_days": st.RetentionDays,
		})
		return b
	}
	id, err := newID()
	if err != nil {
		return SettingsView{}, err
	}
	if err := s.Store.WithTx(ctx, func(q *store.Queries) error {
		if err := q.UpdateRadioSettings(ctx, store.UpdateRadioSettingsParams{
			TrialPolicy: store.RadioTrialPolicy(after.TrialPolicy), TrialDays: int32(after.TrialDays),
			PassengersInChannels: store.RadioPassengerPolicy(after.PassengersInChannels),
			RetentionDays:        int32(after.RetentionDays), UpdatedBy: nullID(adminID), UpdatedAt: now,
		}); err != nil {
			return err
		}
		return q.InsertRadioSettingsAudit(ctx, store.InsertRadioSettingsAuditParams{
			ID: id, AdminID: adminID, Before: audit(before), After: audit(after), At: now,
		})
	}); err != nil {
		return SettingsView{}, err
	}
	s.forgetSettings()
	if after.PassengersInChannels != before.PassengersInChannels {
		if err := s.ApplyPassengerPolicy(ctx); err != nil {
			return SettingsView{}, err
		}
	}
	if after.RetentionDays != before.RetentionDays {
		s.background(ctx, func(ctx context.Context) {
			if _, err := s.Retain(ctx); err != nil {
				s.logger().ErrorContext(ctx, "apply radio retention", "err", err)
			}
		})
	}
	s.background(ctx, func(ctx context.Context) { s.announceSettings(ctx, after, after.RetentionDays != before.RetentionDays) })
	return s.AdminSettings(ctx)
}

// announceSettings tells every Radio user that the policy changed, so the apps reload their
// access and, with a new retention, show the notice again.
func (s *Service) announceSettings(ctx context.Context, st Settings, consentAgain bool) {
	users, err := s.Store.ListRadioUsers(ctx)
	if err != nil {
		s.logger().WarnContext(ctx, "list radio users", "err", err)
		return
	}
	now := s.now()
	for _, u := range users {
		s.publish(ctx, u, EventSettings, now, map[string]any{
			"retention_days": st.RetentionDays, "consent_required": consentAgain,
		})
	}
}
