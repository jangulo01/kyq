package telemetry

import (
	"bytes"
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

func day(d int) time.Time { return time.Date(2026, 10, d, 0, 0, 0, 0, time.UTC) }

// Tarifas de ejemplo en millonésimas de centavo: minuto de voz 0,40 COP (40 centavos), evento
// 0,002 COP, ruta 0,05 COP, fijo mensual 8 000 COP.
var exampleRates = []Rate{
	{Concept: ConceptVoiceMinute, Currency: "COP", UnitCostMicro: 40_000_000, EffectiveFrom: day(1)},
	{Concept: ConceptRealtimeEvent, Currency: "COP", UnitCostMicro: 200_000, EffectiveFrom: day(1)},
	{Concept: ConceptRouteRequest, Currency: "COP", UnitCostMicro: 5_000_000, EffectiveFrom: day(1)},
	{Concept: ConceptFixedMonthly, Currency: "COP", UnitCostMicro: 800_000_000_000, EffectiveFrom: day(1)},
}

// RN-KYQ-004, escenario US4-1: costo = Σ uso diario × tarifa vigente ese día + fijo; margen =
// pagado − costo.
func TestRN004CostBreakdown(t *testing.T) {
	days := []DayUsage{
		{Day: day(3), VoiceSeconds: 60 * 60, Events: 1000, Routes: 100},
		{Day: day(20), VoiceSeconds: 60 * 60, Events: 2000, Routes: 100},
	}
	b := ComputeCosts(day(1), "COP", exampleRates, days, 5_000_000, day(31))
	assert.Equal(t, "2026-10", b.Month)
	assert.Equal(t, []CostItem{
		{Concept: ConceptVoiceMinute, Usage: 120, CostMinor: 4800},
		{Concept: ConceptRealtimeEvent, Usage: 3000, CostMinor: 600},
		{Concept: ConceptRouteRequest, Usage: 200, CostMinor: 1000},
		{Concept: ConceptFixedMonthly, Usage: 1, CostMinor: 800_000},
	}, b.Items)
	assert.Equal(t, 806_400.0, b.TotalCostMinor)
	assert.Equal(t, 5_000_000-806_400.0, b.MarginMinor)

	// US4-3: tarifa nueva desde el día 15: el uso anterior sigue con la vieja.
	withChange := append([]Rate{{Concept: ConceptVoiceMinute, Currency: "COP", UnitCostMicro: 80_000_000, EffectiveFrom: day(15)}}, exampleRates...)
	b = ComputeCosts(day(1), "COP", withChange, days, 0, day(31))
	assert.Equal(t, 60*40.0+60*80.0, b.Items[0].CostMinor)
	assert.Negative(t, b.MarginMinor, "sin pago el margen es negativo")

	none := ComputeCosts(day(1), "PEN", exampleRates, days, 0, day(31))
	assert.Zero(t, none.TotalCostMinor, "sin tarifas en esa moneda no hay costo")
}

// RN-KYQ-004, FR-025/FR-026: el conductor y el panel ven el mismo costo; el panel destaca el
// margen negativo.
func TestIntegrationCostRoutes(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	admin, paying, free := uuid.New(), uuid.New(), uuid.New()
	for _, u := range []store.CreateUserParams{
		{ID: admin, PhoneE164: "+573000000000", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: paying, PhoneE164: "+573100000001", Role: store.UserRoleDriver, DisplayName: "Carlos"},
		{ID: free, PhoneE164: "+573100000002", Role: store.UserRoleDriver, DisplayName: "Diana"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	for _, d := range []uuid.UUID{paying, free} {
		require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: d, QrToken: "qr-" + d.String()}))
		require.NoError(t, st.AddDriverUsage(ctx, store.AddDriverUsageParams{DriverID: d, Day: day(3), VoiceParticipantSeconds: 7200, RealtimeEvents: 3000, RouteRequests: 200}))
	}
	_, err := st.InsertPayment(ctx, store.InsertPaymentParams{
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
	do := func(id uuid.UUID, role, method, path string, body any) *httptest.ResponseRecorder {
		tok, err := issuer.IssueAccess(auth.Principal{UserID: id, Role: role})
		require.NoError(t, err)
		var buf bytes.Buffer
		if body != nil {
			require.NoError(t, json.NewEncoder(&buf).Encode(body))
		}
		req := httptest.NewRequest(method, path, &buf)
		req.Header.Set("Authorization", "Bearer "+tok)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		return rec
	}
	for _, r := range exampleRates {
		rec := do(admin, auth.RoleAdmin, http.MethodPut, "/v1/admin/cost-rates", map[string]any{
			"concept": r.Concept, "currency": "COP", "unit_cost_micro": r.UnitCostMicro, "effective_from": "2026-10-01",
		})
		require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())
	}
	assert.Equal(t, http.StatusBadRequest, do(admin, auth.RoleAdmin, http.MethodPut, "/v1/admin/cost-rates", map[string]any{
		"concept": "gasolina", "currency": "COP", "unit_cost_micro": 1, "effective_from": "2026-10-01",
	}).Code)
	rec := do(admin, auth.RoleAdmin, http.MethodGet, "/v1/admin/cost-rates", nil)
	require.Equal(t, http.StatusOK, rec.Code)
	var rates []RateView
	require.NoError(t, json.NewDecoder(rec.Body).Decode(&rates))
	assert.Len(t, rates, 4)

	rec = do(paying, auth.RoleDriver, http.MethodGet, "/v1/driver/costs?month=2026-10", nil)
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())
	var mine Breakdown
	require.NoError(t, json.NewDecoder(rec.Body).Decode(&mine))
	assert.Equal(t, int64(5_000_000), mine.PaidMinor)
	assert.Equal(t, 806_400.0, mine.TotalCostMinor)

	assert.Equal(t, http.StatusBadRequest, do(admin, auth.RoleAdmin, http.MethodGet, "/v1/admin/costs", nil).Code, "month obligatorio")
	rec = do(admin, auth.RoleAdmin, http.MethodGet, "/v1/admin/costs?month=2026-10", nil)
	require.Equal(t, http.StatusOK, rec.Code)
	var rows []DriverCost
	require.NoError(t, json.NewDecoder(rec.Body).Decode(&rows))
	require.Len(t, rows, 2)
	byID := map[uuid.UUID]DriverCost{}
	for _, r := range rows {
		byID[r.DriverID] = r
	}
	assert.Equal(t, mine.TotalCostMinor, byID[paying].TotalCostMinor, "mismo número en la app y el panel")
	assert.False(t, byID[paying].NegativeMargin)
	assert.True(t, byID[free].NegativeMargin, "costo sin pago: destacado")

	assert.Equal(t, http.StatusForbidden, do(paying, auth.RoleDriver, http.MethodGet, "/v1/admin/costs?month=2026-10", nil).Code)
}
