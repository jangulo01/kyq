package radio

import (
	"context"
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/store"
)

// FR-040: configuración de Radio desde el panel, con bitácora, costo estimado por retención y
// aviso de registro de nuevo al cambiar la retención.
func TestIntegrationAdminSettings(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	f.consent(t, f.carlos)
	_, err := f.svc.Me(ctx, f.jonathan) // usó Radio: recibe radio.settings
	require.NoError(t, err)

	// 30 GB guardados en los últimos 30 días a 200 COP por GB-mes.
	require.NoError(t, f.st.AddDriverUsage(ctx, store.AddDriverUsageParams{
		DriverID: f.carlos, Day: f.clock.AddDate(0, 0, -3), RadioStorageBytes: 30e9,
	}))
	require.NoError(t, f.st.UpsertCostRate(ctx, store.UpsertCostRateParams{
		Concept: store.CostConceptRadioStorage, Currency: "COP", UnitCostMicro: 200e6, EffectiveFrom: f.clock.AddDate(0, -1, 0),
	}))

	v, err := f.svc.AdminSettings(ctx)
	require.NoError(t, err)
	assert.Equal(t, PolicyTrial, v.TrialPolicy)
	assert.Equal(t, 30, v.RetentionDays)
	assert.Equal(t, PassengersNone, v.PassengersInChannels)
	assert.Equal(t, map[string]int64{"7": 1400, "30": 6000, "90": 18000}, v.EstimatedMonthlyCostMinor)

	_, err = f.svc.UpdateSettings(ctx, f.admin, SettingsInput{RetentionDays: ptr(15)})
	assert.ErrorIs(t, err, ErrInvalid)
	_, err = f.svc.UpdateSettings(ctx, f.admin, SettingsInput{TrialPolicy: ptr("gratis")})
	assert.ErrorIs(t, err, ErrInvalid)

	v, err = f.svc.UpdateSettings(ctx, f.admin, SettingsInput{RetentionDays: ptr(90), TrialPolicy: ptr(PolicyListenOnly)})
	require.NoError(t, err)
	assert.Equal(t, 90, v.RetentionDays)
	assert.Equal(t, "Admin", v.UpdatedByName)

	// Bitácora con el antes y el después.
	var before, after []byte
	require.NoError(t, f.st.Pool.QueryRow(ctx, `SELECT before, after FROM radio_settings_audit WHERE admin_id = $1`, f.admin).Scan(&before, &after))
	var b, a map[string]any
	require.NoError(t, json.Unmarshal(before, &b))
	require.NoError(t, json.Unmarshal(after, &a))
	assert.EqualValues(t, 30, b["retention_days"])
	assert.EqualValues(t, 90, a["retention_days"])
	assert.Equal(t, PolicyListenOnly, a["trial_policy"])

	// Nueva retención: se pide aceptar el aviso otra vez y se avisa a quienes usan Radio.
	me, err := f.svc.Me(ctx, f.carlos)
	require.NoError(t, err)
	assert.True(t, me.ConsentRequired)
	events := f.pub.events(f.jonathan, EventSettings)
	require.Len(t, events, 1)
	assert.Equal(t, true, events[0]["consent_required"])

	// Solo escucha para quien no paga: Pedro oye pero no transmite (FR-005).
	pedro, err := f.svc.Me(ctx, f.pedro)
	require.NoError(t, err)
	assert.Equal(t, Listen, pedro.Access)
}
