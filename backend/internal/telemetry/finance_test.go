package telemetry

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
)

// FR-007: agregado de un mes a partir de los desgloses por conductor de 002.
func TestSummarizeMonth(t *testing.T) {
	paying := ComputeCosts(day(1), "COP", exampleRates, []DayUsage{{Day: day(3), VoiceSeconds: 3600, Events: 1000, Routes: 100}}, 5_000_000, day(31))
	idle := ComputeCosts(day(1), "COP", exampleRates, nil, 0, day(31))
	m := SummarizeMonth("2026-10", []DriverMonth{{Breakdown: paying, Active: true}, {Breakdown: idle}}, false)

	assert.Equal(t, "2026-10", m.Month)
	assert.Equal(t, int64(5_000_000), m.RevenueMinor)
	assert.Equal(t, round2(paying.TotalCostMinor+idle.TotalCostMinor), m.InfraCostMinor)
	assert.Equal(t, round2(5_000_000-m.InfraCostMinor), m.MarginMinor)
	require.NotNil(t, m.MarginPct)
	assert.InDelta(t, m.MarginMinor/5_000_000*100, *m.MarginPct, 0.01)
	assert.Equal(t, 2, m.Drivers)
	assert.Equal(t, 1, m.ActiveDrivers)
	assert.Equal(t, 1, m.PayingDrivers)
	assert.Equal(t, 1, m.NegativeMarginDrivers, "el conductor sin pago tiene margen negativo")
	require.NotNil(t, m.CostPerActiveDriverMinor)
	assert.Equal(t, m.InfraCostMinor, *m.CostPerActiveDriverMinor)
	require.NotNil(t, m.RevenuePerPayingDriverMinor)
	assert.Equal(t, 5_000_000.0, *m.RevenuePerPayingDriverMinor)
	require.Len(t, m.CostByConcept, len(Concepts), "011: también almacenamiento de Radio y SMS de invitación")
	assert.Equal(t, ConceptRadioStorage, m.CostByConcept[4].Concept)
	assert.Equal(t, ConceptFixedMonthly, m.CostByConcept[3].Concept)
	assert.Equal(t, 1_600_000.0, m.CostByConcept[3].CostMinor, "fijo de los dos conductores")

	empty := SummarizeMonth("2026-09", nil, true)
	assert.Nil(t, empty.MarginPct, "sin ingresos no hay porcentaje")
	assert.Nil(t, empty.CostPerActiveDriverMinor)
	assert.Nil(t, empty.RevenuePerPayingDriverMinor)
	assert.True(t, empty.RatesMissing)
	assert.Len(t, empty.CostByConcept, len(Concepts))

	tot := SummarizeTotals([]FinanceMonth{m, empty})
	assert.Equal(t, m.RevenueMinor, tot.RevenueMinor)
	assert.Equal(t, m.MarginMinor, tot.MarginMinor)
}

func TestRatesMissing(t *testing.T) {
	assert.True(t, ratesMissing(exampleRates, "COP", time.Date(2026, 9, 1, 0, 0, 0, 0, time.UTC)), "tarifas desde octubre")
	assert.False(t, ratesMissing(exampleRates, "COP", day(1)))
	assert.False(t, ratesMissing(exampleRates, "COP", time.Date(2026, 11, 1, 0, 0, 0, 0, time.UTC)), "siguen vigentes")
	assert.True(t, ratesMissing(exampleRates, "PEN", day(1)))
}

// FR-008, SC-003: el total de Finanzas de un mes = la suma de las filas de GET /v1/admin/costs
// del mismo mes; los conductores creados después del mes no cuentan.
func TestIntegrationFinanceMatchesCosts(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	admin, paying, idle, late := uuid.New(), uuid.New(), uuid.New(), uuid.New()
	for _, u := range []store.CreateUserParams{
		{ID: admin, PhoneE164: "+573000000000", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: paying, PhoneE164: "+573100000001", Role: store.UserRoleDriver, DisplayName: "Carlos"},
		{ID: idle, PhoneE164: "+573100000002", Role: store.UserRoleDriver, DisplayName: "Diana"},
		{ID: late, PhoneE164: "+573100000003", Role: store.UserRoleDriver, DisplayName: "Elkin"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	for _, d := range []uuid.UUID{paying, idle, late} {
		require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: d, QrToken: "qr-" + d.String()}))
	}
	_, err := st.Pool.Exec(ctx, `UPDATE users SET created_at = $1 WHERE id <> $2`, time.Date(2026, 9, 10, 0, 0, 0, 0, time.UTC), late)
	require.NoError(t, err)
	_, err = st.Pool.Exec(ctx, `UPDATE users SET created_at = $1 WHERE id = $2`, day(15), late)
	require.NoError(t, err)
	for _, r := range exampleRates {
		require.NoError(t, st.UpsertCostRate(ctx, store.UpsertCostRateParams{
			Concept: store.CostConcept(r.Concept), Currency: r.Currency, UnitCostMicro: r.UnitCostMicro, EffectiveFrom: r.EffectiveFrom,
		}))
	}
	require.NoError(t, st.AddDriverUsage(ctx, store.AddDriverUsageParams{DriverID: paying, Day: day(3), VoiceParticipantSeconds: 7200, RealtimeEvents: 3000, RouteRequests: 200}))
	require.NoError(t, st.AddDriverUsage(ctx, store.AddDriverUsageParams{DriverID: late, Day: day(20), VoiceParticipantSeconds: 600, RealtimeEvents: 100, RouteRequests: 10}))
	_, err = st.InsertPayment(ctx, store.InsertPaymentParams{
		ID: uuid.New(), DriverID: paying, AmountMinor: 5_000_000, Currency: "COP", Method: store.PaymentMethodManual,
		Status: store.PaymentStatusCreated, CreatedBy: admin, CreatedAt: day(2),
	})
	require.NoError(t, err)
	_, err = st.Pool.Exec(ctx, `UPDATE payments SET status = 'approved', covers_from = $1, covers_until = $2`, day(2), day(2).AddDate(0, 1, 0))
	require.NoError(t, err)

	now := time.Date(2026, 10, 27, 12, 0, 0, 0, time.UTC)
	issuer := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), func() time.Time { return now })
	mux := http.NewServeMux()
	(&CostHandlers{Store: st, CityCode: "bogota", Now: func() time.Time { return now }}).Register(mux, auth.RequireAuth(issuer))
	get := func(id uuid.UUID, role, path string, out any) int {
		tok, err := issuer.IssueAccess(auth.Principal{UserID: id, Role: role})
		require.NoError(t, err)
		req := httptest.NewRequest(http.MethodGet, path, nil)
		req.Header.Set("Authorization", "Bearer "+tok)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if out != nil && rec.Code == http.StatusOK {
			require.NoError(t, json.NewDecoder(rec.Body).Decode(out))
		}
		return rec.Code
	}

	var rep FinanceReport
	require.Equal(t, http.StatusOK, get(admin, auth.RoleAdmin, "/v1/admin/finance?months=2", &rep))
	assert.Equal(t, "COP", rep.Currency)
	require.Len(t, rep.Months, 2)
	sep, oct := rep.Months[0], rep.Months[1]
	assert.Equal(t, "2026-09", sep.Month)
	assert.Equal(t, "2026-10", oct.Month)
	assert.True(t, sep.RatesMissing, "las tarifas empiezan en octubre")
	assert.Zero(t, sep.InfraCostMinor)
	assert.Equal(t, 2, sep.Drivers, "Elkin aún no existía en septiembre")
	assert.Equal(t, 3, oct.Drivers)
	assert.Equal(t, 2, oct.ActiveDrivers, "uso o pago en el mes")
	assert.Equal(t, 1, oct.PayingDrivers)
	assert.Equal(t, int64(5_000_000), oct.RevenueMinor)

	for _, month := range []FinanceMonth{sep, oct} {
		var rows []DriverCost
		require.Equal(t, http.StatusOK, get(admin, auth.RoleAdmin, "/v1/admin/costs?month="+month.Month, &rows))
		var revenue int64
		var cost float64
		for _, r := range rows {
			revenue += r.PaidMinor
			cost += r.TotalCostMinor
		}
		assert.Len(t, rows, month.Drivers, month.Month)
		assert.Equal(t, month.RevenueMinor, revenue, month.Month)
		assert.Equal(t, month.InfraCostMinor, round2(cost), "SC-003 en %s", month.Month)
	}
	assert.Equal(t, round2(sep.InfraCostMinor+oct.InfraCostMinor), rep.Totals.InfraCostMinor)

	assert.Equal(t, http.StatusOK, get(admin, auth.RoleAdmin, "/v1/admin/finance", &rep))
	assert.Len(t, rep.Months, 6, "6 meses por defecto")
	assert.Equal(t, "2026-10", rep.Months[5].Month, "termina en el mes actual")
	for _, bad := range []string{"?months=0", "?months=25", "?to=2026-13", "?to=octubre"} {
		assert.Equal(t, http.StatusBadRequest, get(admin, auth.RoleAdmin, "/v1/admin/finance"+bad, nil), bad)
	}
	assert.Equal(t, http.StatusForbidden, get(paying, auth.RoleDriver, "/v1/admin/finance", nil))
}
