package contracttest

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/affiliations"
	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/crm"
	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/httpapi"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
	"github.com/kyq/backend/internal/trips"
)

// TestIntegration008RoutesMatchContract walks the 008 flow through the real router against the
// merged contract: dispatch settings, zone pool request without a chosen driver, preferential
// quote, affiliation after the trip and by link, the public link page and the CRM by source.
func TestIntegration008RoutesMatchContract(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	now := time.Now()
	adminID, rider, client := uuid.New(), uuid.New(), uuid.New()
	pooled, chosen := uuid.New(), uuid.New()
	for _, u := range []store.CreateUserParams{
		{ID: adminID, PhoneE164: "+573000000000", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: rider, PhoneE164: "+573200000002", Role: store.UserRolePassenger, DisplayName: "Sofía"},
		{ID: client, PhoneE164: "+573200000003", Role: store.UserRolePassenger, DisplayName: "Ana"},
		{ID: pooled, PhoneE164: "+573100000001", Role: store.UserRoleDriver, DisplayName: "Beto"},
		{ID: chosen, PhoneE164: "+573100000002", Role: store.UserRoleDriver, DisplayName: "Carlos"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	for i, d := range []uuid.UUID{pooled, chosen} {
		require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{
			UserID: d, QrToken: "qr-pool-00000" + string(rune('1'+i)), VehiclePlate: "KYQ10" + string(rune('1'+i)), VehicleDescription: "Kia",
		}))
	}
	require.NoError(t, st.InsertAffiliation(ctx, store.InsertAffiliationParams{PassengerID: client, DriverID: chosen}))
	require.NoError(t, st.UpsertFareTable(ctx, store.UpsertFareTableParams{
		CityCode: "bogota", Currency: "COP", BaseMinor: 400_000, PerKmMinor: 120_000, PerMinuteMinor: 30_000,
		MinimumMinor: 700_000, RoundingMinor: 10_000, UpdatedBy: adminID,
	}))
	require.NoError(t, st.SetDriverLocation(ctx, store.SetDriverLocationParams{Lat: 4.609, Lng: -74.08, RecordedAt: now, UserID: pooled}))
	require.NoError(t, st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: pooled, Presence: store.DriverPresenceFree}))

	tokens := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), nil)
	server := httpapi.NewRouter(httpapi.Deps{
		Tokens:  tokens,
		Affils:  &affiliations.Handlers{Service: affiliations.NewService(affiliations.NewPgRepo(st.Queries))},
		Drivers: &drivers.Handlers{Store: st, PublicBaseURL: "https://kyq.test/"},
		Trips:   &trips.Handlers{Service: &trips.Service{Store: st, Routes: route5km{}, CityCode: "bogota"}},
		CRM:     &crm.Handlers{Store: st},
	})
	c := load(t, server)
	token := func(id uuid.UUID, role string) string {
		tk, err := tokens.IssueAccess(auth.Principal{UserID: id, Role: role})
		require.NoError(t, err)
		return tk
	}
	riderTk, clientTk := token(rider, auth.RolePassenger), token(client, auth.RolePassenger)
	pooledTk, chosenTk, adminTk := token(pooled, auth.RoleDriver), token(chosen, auth.RoleDriver), token(adminID, auth.RoleAdmin)

	// Preferencias de despacho: la bolsa desactivada por defecto (FR-008).
	settings := c.call(http.MethodGet, "/v1/driver/dispatch-settings", pooledTk, nil, http.StatusOK)
	assert.Equal(t, false, settings["accepts_zone_pool"])
	assert.Equal(t, "https://kyq.test/a/qr-pool-000001", settings["affiliate_link"])
	c.call(http.MethodPut, "/v1/driver/dispatch-settings", pooledTk, map[string]any{"accepts_zone_pool": true, "preferential_discount_pct": 0}, http.StatusOK)
	// Fuera de 0–30 % (inválido por contrato): el servidor también lo rechaza.
	bad := httptest.NewRequest(http.MethodPut, "/v1/driver/dispatch-settings",
		strings.NewReader(`{"accepts_zone_pool":false,"preferential_discount_pct":31}`))
	bad.Header.Set("Authorization", "Bearer "+chosenTk)
	rec := httptest.NewRecorder()
	server.ServeHTTP(rec, bad)
	assert.Equal(t, http.StatusBadRequest, rec.Code)
	c.call(http.MethodPut, "/v1/driver/dispatch-settings", chosenTk, map[string]any{"accepts_zone_pool": false, "preferential_discount_pct": 10}, http.StatusOK)

	route := map[string]any{"pickup": map[string]any{"lat": 4.60, "lng": -74.08}, "dropoff": map[string]any{"lat": 4.65, "lng": -74.05}}
	with := func(extra map[string]any) map[string]any {
		out := map[string]any{}
		for k, v := range route {
			out[k] = v
		}
		for k, v := range extra {
			out[k] = v
		}
		return out
	}

	// Tarifa preferencial en la cotización (RN-KYQ-013).
	q := c.call(http.MethodPost, "/v1/fares/quote", clientTk, with(map[string]any{"driver_id": chosen}), http.StatusOK)
	assert.EqualValues(t, 10, q["preferential_discount_pct"])
	assert.EqualValues(t, 1_320_000, q["suggested_fare_minor"])
	assert.EqualValues(t, 1_470_000, q["list_fare_minor"])

	// Bolsa zonal sin Conductor Elegido (FR-001, FR-002).
	trip := c.call(http.MethodPost, "/v1/trips", riderTk, with(map[string]any{"dispatch": "zone_pool"}), http.StatusCreated)
	assert.Equal(t, "zone_pool", trip["dispatch"])
	assert.Equal(t, pooled.String(), trip["driver_id"])
	c.call(http.MethodPost, "/v1/trips", riderTk, route, http.StatusBadRequest)
	tripID := trip["id"].(string)
	for _, step := range []string{"accept", "arrive", "start", "complete"} {
		c.call(http.MethodPost, "/v1/trips/"+tripID+"/"+step, pooledTk, nil, http.StatusOK)
	}

	// Afiliación después del viaje y por enlace (FR-014–FR-016).
	c.call(http.MethodPost, "/v1/affiliations", clientTk, map[string]any{"trip_id": tripID}, http.StatusNotFound)
	c.call(http.MethodPost, "/v1/affiliations", riderTk, map[string]any{"trip_id": tripID}, http.StatusCreated)
	c.call(http.MethodPost, "/v1/affiliations", riderTk, map[string]any{"qr_token": "qr-pool-000002", "source": "link"}, http.StatusCreated)
	c.call(http.MethodGet, "/v1/driver/clients", pooledTk, nil, http.StatusOK)

	// Página pública del enlace (FR-015, FR-017).
	page := func(token string) *httptest.ResponseRecorder {
		rec := httptest.NewRecorder()
		server.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/a/"+token, nil))
		return rec
	}
	ok := page("qr-pool-000001")
	assert.Equal(t, http.StatusOK, ok.Code)
	assert.Contains(t, ok.Header().Get("Content-Type"), "text/html")
	assert.Contains(t, ok.Body.String(), "Beto te invita a Kyq")
	assert.Contains(t, ok.Body.String(), `href="kyq://affiliate/qr-pool-000001"`)
	assert.NotContains(t, ok.Body.String(), "+5731", "sin teléfono (FR-017)")
	assert.NotContains(t, ok.Body.String(), "KYQ10", "sin placa (FR-017)")
	assert.Equal(t, http.StatusNotFound, page("no-existe").Code)

	report := c.call(http.MethodGet, "/v1/admin/crm", adminTk, nil, http.StatusOK)
	bySource := report["affiliations"].(map[string]any)["created_by_source"].(map[string]any)
	assert.EqualValues(t, 1, bySource["post_trip"])
	assert.EqualValues(t, 1, bySource["link"])
}
