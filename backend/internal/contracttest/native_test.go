package contracttest

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

	"github.com/kyq/backend/internal/affiliations"
	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/httpapi"
	"github.com/kyq/backend/internal/places"
	"github.com/kyq/backend/internal/reservations"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
	"github.com/kyq/backend/internal/trips"
)

// TestIntegration010RoutesMatchContract walks the 010 routes through the real router against the
// merged contract: reservations, client card and note, places, the zone of a Chosen Driver and the
// automatic arrival through the driver location.
func TestIntegration010RoutesMatchContract(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	adminID, ana, carlos := uuid.New(), uuid.New(), uuid.New()
	for _, u := range []store.CreateUserParams{
		{ID: adminID, PhoneE164: "+573000000000", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: ana, PhoneE164: "+573200000001", Role: store.UserRolePassenger, DisplayName: "Ana"},
		{ID: carlos, PhoneE164: "+573100000001", Role: store.UserRoleDriver, DisplayName: "Carlos"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: carlos, QrToken: "qr-carlos-0000000", VehiclePlate: "KYQ001", VehicleDescription: "Kia"}))
	require.NoError(t, st.InsertAffiliation(ctx, store.InsertAffiliationParams{PassengerID: ana, DriverID: carlos}))
	require.NoError(t, st.UpsertFareTable(ctx, store.UpsertFareTableParams{
		CityCode: "bogota", Currency: "COP", BaseMinor: 400_000, PerKmMinor: 120_000, PerMinuteMinor: 30_000,
		MinimumMinor: 700_000, RoundingMinor: 10_000, UpdatedBy: adminID,
	}))
	require.NoError(t, st.SetDriverLocation(ctx, store.SetDriverLocationParams{Lat: 4.609, Lng: -74.08, RecordedAt: time.Now(), UserID: carlos}))
	require.NoError(t, st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: carlos, Presence: store.DriverPresenceFree}))

	photon := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]any{"features": []any{
			map[string]any{"geometry": map[string]any{"coordinates": []float64{-74.053, 4.666}}, "properties": map[string]any{"name": "Centro Comercial Andino", "city": "Bogotá"}},
		}})
	}))
	t.Cleanup(photon.Close)

	tripSvc := &trips.Service{Store: st, Routes: route5km{}, CityCode: "bogota"}
	tokens := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), nil)
	server := httpapi.NewRouter(httpapi.Deps{
		Tokens:       tokens,
		Affils:       &affiliations.Handlers{Service: affiliations.NewService(affiliations.NewPgRepo(st.Queries))},
		Drivers:      &drivers.Handlers{Store: st},
		Presence:     &drivers.Presence{Store: st, Arrivals: tripSvc},
		Trips:        &trips.Handlers{Service: tripSvc},
		Reservations: &reservations.Handlers{Service: &reservations.Service{Store: st, Trips: tripSvc}},
		Places:       &places.Handlers{Service: &places.Service{URL: photon.URL, BBox: places.Bogota}},
	})
	c := load(t, server)
	token := func(id uuid.UUID, role string) string {
		tk, err := tokens.IssueAccess(auth.Principal{UserID: id, Role: role})
		require.NoError(t, err)
		return tk
	}
	anaTk, carlosTk := token(ana, auth.RolePassenger), token(carlos, auth.RoleDriver)

	// US6: la zona aproximada del Conductor Elegido libre (FR-018).
	resp := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/v1/affiliations", nil)
	req.Header.Set("Authorization", "Bearer "+anaTk)
	server.ServeHTTP(resp, req)
	require.Equal(t, http.StatusOK, resp.Code)
	assert.Contains(t, resp.Body.String(), `"zone":{"cell":"88`)
	assert.NotContains(t, resp.Body.String(), "4.609", "nunca la posición exacta")
	c.call(http.MethodGet, "/v1/affiliations", anaTk, nil, http.StatusOK)

	// US1: reservar, aceptar y cancelar.
	route := map[string]any{"pickup": map[string]any{"lat": 4.60, "lng": -74.08}, "dropoff": map[string]any{"lat": 4.65, "lng": -74.05}}
	body := func(extra map[string]any) map[string]any {
		out := map[string]any{"driver_id": carlos}
		for k, v := range route {
			out[k] = v
		}
		for k, v := range extra {
			out[k] = v
		}
		return out
	}
	r := c.call(http.MethodPost, "/v1/reservations", anaTk, body(map[string]any{
		"scheduled_at": time.Now().Add(2 * time.Hour).UTC().Format(time.RFC3339), "dropoff_label": "Centro Comercial Andino",
	}), http.StatusCreated)
	c.call(http.MethodPost, "/v1/reservations", anaTk, body(map[string]any{"scheduled_at": time.Now().Add(10 * time.Minute).UTC().Format(time.RFC3339)}), http.StatusBadRequest)
	id := r["id"].(string)
	c.call(http.MethodGet, "/v1/reservations", anaTk, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/driver/reservations", carlosTk, nil, http.StatusOK)
	accepted := c.call(http.MethodPost, "/v1/driver/reservations/"+id+"/accept", carlosTk, nil, http.StatusOK)
	assert.Equal(t, "confirmed", accepted["status"])
	c.call(http.MethodPost, "/v1/driver/reservations/"+id+"/reject", carlosTk, nil, http.StatusConflict)
	c.call(http.MethodPost, "/v1/reservations/"+id+"/cancel", anaTk, nil, http.StatusOK)
	other := c.call(http.MethodPost, "/v1/reservations", anaTk, body(map[string]any{"scheduled_at": time.Now().Add(3 * time.Hour).UTC().Format(time.RFC3339)}), http.StatusCreated)
	c.call(http.MethodPost, "/v1/driver/reservations/"+other["id"].(string)+"/cancel", carlosTk, nil, http.StatusOK)
	c.call(http.MethodPost, "/v1/driver/reservations/"+uuid.NewString()+"/accept", carlosTk, nil, http.StatusNotFound)

	// US2: ficha y nota del cliente.
	card := c.call(http.MethodPut, "/v1/driver/clients/"+ana.String()+"/note", carlosTk, map[string]any{"body": "Recoger en la portería 2"}, http.StatusOK)
	assert.Equal(t, "Recoger en la portería 2", card["note"])
	c.call(http.MethodGet, "/v1/driver/clients/"+ana.String(), carlosTk, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/driver/clients/"+uuid.NewString(), carlosTk, nil, http.StatusNotFound)

	// US5: direcciones.
	c.call(http.MethodGet, "/v1/places?q=Andino", anaTk, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/places?q=an", anaTk, nil, http.StatusBadRequest)

	// US3: llegada automática por la ubicación con precisión.
	trip := c.call(http.MethodPost, "/v1/trips", anaTk, map[string]any{"driver_id": carlos, "pickup": route["pickup"], "dropoff": route["dropoff"]}, http.StatusCreated)
	tripID := trip["id"].(string)
	c.call(http.MethodPost, "/v1/trips/"+tripID+"/accept", carlosTk, nil, http.StatusOK)
	near := map[string]any{"lat": 4.6002, "lng": -74.08, "accuracy_m": 8}
	start := time.Now().UTC()
	for _, d := range []time.Duration{0, 11 * time.Second} {
		fix := map[string]any{"recorded_at": start.Add(d - 20*time.Second).Format(time.RFC3339)}
		for k, v := range near {
			fix[k] = v
		}
		c.call(http.MethodPost, "/v1/driver/location", carlosTk, fix, http.StatusNoContent)
	}
	got := c.call(http.MethodGet, "/v1/trips/"+tripID, anaTk, nil, http.StatusOK)
	assert.Equal(t, "ARRIVED", got["status"], "FR-010: llegó sin tocar la pantalla")
}
