package contracttest

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpapi"
	"github.com/kyq/backend/internal/ptt"
	"github.com/kyq/backend/internal/safety"
	"github.com/kyq/backend/internal/storage"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
	"github.com/kyq/backend/internal/trips"
)

// sosVoice is a LiveKit that always answers.
type sosVoice struct{ noRooms }

func (sosVoice) CreateSOSRoom(context.Context, string) error { return nil }
func (sosVoice) StartAudioEgress(_ context.Context, room, _ string) (string, error) {
	return "EG_" + room, nil
}
func (sosVoice) StopEgress(context.Context, string) error { return nil }

type safetyFixture struct {
	st                                  *store.Store
	server                              http.Handler
	tripService                         *trips.Service
	operator, admin, driver, passenger  uuid.UUID
	asOperator, asAdmin, asDriver, asPx string
}

func newSafetyFixture(t *testing.T, pub *wire) *safetyFixture {
	t.Helper()
	st := testdb.New(t)
	ctx := context.Background()
	f := &safetyFixture{st: st, operator: uuid.New(), admin: uuid.New(), driver: uuid.New(), passenger: uuid.New()}
	for _, u := range []store.CreateUserParams{
		{ID: f.operator, PhoneE164: "+573000000011", Role: store.UserRoleAdmin, DisplayName: "Operadora"},
		{ID: f.admin, PhoneE164: "+573000000001", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: f.driver, PhoneE164: "+573100000001", Role: store.UserRoleDriver, DisplayName: "Carlos"},
		{ID: f.passenger, PhoneE164: "+573200000002", Role: store.UserRolePassenger, DisplayName: "Ana"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	require.NoError(t, st.GrantEmergencyOperator(ctx, store.GrantEmergencyOperatorParams{UserID: f.operator, OnDuty: true}))
	require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: f.driver, QrToken: "qr-carlos-0000000", VehiclePlate: "KYQ001", VehicleDescription: "Kia"}))
	require.NoError(t, st.InsertAffiliation(ctx, store.InsertAffiliationParams{PassengerID: f.passenger, DriverID: f.driver}))
	require.NoError(t, st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: f.driver, Presence: store.DriverPresenceFree}))
	require.NoError(t, st.UpsertFareTable(ctx, store.UpsertFareTableParams{
		CityCode: "bogota", Currency: "COP", BaseMinor: 400_000, PerKmMinor: 120_000, PerMinuteMinor: 30_000,
		MinimumMinor: 700_000, RoundingMinor: 10_000, UpdatedBy: f.admin,
	}))
	tokens := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), nil)
	f.tripService = &trips.Service{Store: st, Routes: fixedRoute{}, Publisher: pub, CityCode: "bogota"}
	f.server = httpapi.NewRouter(httpapi.Deps{
		Tokens: tokens,
		Trips:  &trips.Handlers{Service: f.tripService},
		Safety: &safety.Handlers{Service: &safety.Service{
			Store: st, LiveKit: ptt.LiveKit{APIKey: "devkey", APISecret: "secret"}, Voice: sosVoice{}, VoiceURL: "ws://voice.test",
			Publisher: pub, Recordings: storage.NewMemory(), Record: true, PublicBaseURL: "http://localhost:8080",
			Go: func(fn func()) { fn() },
		}},
	})
	bearer := func(id uuid.UUID, role string) string {
		tok, err := tokens.IssueAccess(auth.Principal{UserID: id, Role: role})
		require.NoError(t, err)
		return tok
	}
	f.asOperator, f.asAdmin = bearer(f.operator, auth.RoleAdmin), bearer(f.admin, auth.RoleAdmin)
	f.asDriver, f.asPx = bearer(f.driver, auth.RoleDriver), bearer(f.passenger, auth.RolePassenger)
	return f
}

// acceptedTrip returns a trip the driver accepted.
func (f *safetyFixture) acceptedTrip(t *testing.T) uuid.UUID {
	t.Helper()
	ctx := context.Background()
	trip, err := f.tripService.Request(ctx, f.passenger, f.driver, trips.Point{Lat: 4.60, Lng: -74.08}, trips.Point{Lat: 4.65, Lng: -74.05})
	require.NoError(t, err)
	_, err = f.tripService.Act(ctx, f.driver, trip.ID, func(tr *trips.Trip, p trips.Party, now time.Time) error { return tr.Accept(p, nil, now) })
	require.NoError(t, err)
	return trip.ID
}

// TestIntegration003RoutesMatchContract walks SOS, console, shared trip and safety profile
// through the real router and checks every request and response against the merged contract.
func TestIntegration003RoutesMatchContract(t *testing.T) {
	f := newSafetyFixture(t, &wire{})
	c := load(t, f.server)
	tripID := f.acceptedTrip(t).String()

	// Perfil de seguridad (US4).
	c.call(http.MethodGet, "/v1/me/emergency-contacts", f.asPx, nil, http.StatusOK)
	c.call(http.MethodPut, "/v1/me/emergency-contacts", f.asPx, map[string]any{"contacts": []map[string]string{
		{"name": "Mamá", "phone_e164": "+573001110001"},
	}}, http.StatusOK)
	c.call(http.MethodPut, "/v1/me/emergency-contacts", f.asPx, map[string]any{"contacts": []map[string]string{
		{"name": "Mamá", "phone_e164": "300"},
	}}, http.StatusBadRequest)
	c.call(http.MethodGet, "/v1/me/safety-pin", f.asPx, nil, http.StatusOK)
	c.call(http.MethodPut, "/v1/me/safety-pin", f.asPx, map[string]any{"pin": "12"}, http.StatusBadRequest)
	c.call(http.MethodPut, "/v1/me/safety-pin", f.asPx, map[string]any{"pin": "2468"}, http.StatusNoContent)
	c.call(http.MethodPut, "/v1/me/safety-pin", f.asPx, map[string]any{"pin": "1357"}, http.StatusForbidden)
	c.call(http.MethodGet, "/v1/me/safety-pin", f.asOperator, nil, http.StatusForbidden)

	// Viaje compartido (US3).
	link := c.call(http.MethodPost, "/v1/trips/"+tripID+"/share", f.asPx, nil, http.StatusOK)
	token := link["token"].(string)
	shared := c.call(http.MethodGet, "/v1/share/"+token, "", nil, http.StatusOK)
	assert.Equal(t, "ACCEPTED", shared["status"])
	c.call(http.MethodGet, "/v1/share/AAAAAAAAAAAAAAAAAAAAAA", "", nil, http.StatusNotFound)
	// La página HTML no es JSON: se comprueba que la ruta está en el contrato y que responde.
	pageReq := httptest.NewRequest(http.MethodGet, "http://localhost:8080/s/"+token, nil)
	_, _, err := c.router.FindRoute(pageReq)
	require.NoError(t, err, "ruta /s/{token} en el contrato")
	page := httptest.NewRecorder()
	f.server.ServeHTTP(page, pageReq)
	assert.Equal(t, http.StatusOK, page.Code)
	assert.Contains(t, page.Header().Get("Content-Type"), "text/html")
	c.call(http.MethodPost, "/v1/trips/"+uuid.NewString()+"/share", f.asPx, nil, http.StatusNotFound)

	// SOS (US1).
	raised := c.call(http.MethodPost, "/v1/trips/"+tripID+"/sos", f.asPx, map[string]any{
		"location": map[string]any{"lat": 4.61, "lng": -74.07, "accuracy_m": 12.5, "recorded_at": time.Now().UTC().Format(time.RFC3339)},
	}, http.StatusCreated)
	alertID := raised["alert"].(map[string]any)["id"].(string)
	c.call(http.MethodPost, "/v1/trips/"+tripID+"/sos", f.asPx, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/sos/active", f.asPx, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/sos/active", f.asDriver, nil, http.StatusNoContent)
	c.call(http.MethodPost, "/v1/sos/"+alertID+"/locations", f.asPx, map[string]any{"points": []map[string]any{
		{"lat": 4.611, "lng": -74.071, "recorded_at": time.Now().UTC().Format(time.RFC3339)},
	}}, http.StatusOK)
	c.call(http.MethodPost, "/v1/sos/"+alertID+"/locations", f.asDriver, map[string]any{"points": []map[string]any{
		{"lat": 4.611, "lng": -74.071},
	}}, http.StatusNotFound)
	c.call(http.MethodGet, "/v1/sos/"+alertID+"/token", f.asPx, nil, http.StatusOK)
	c.call(http.MethodPost, "/v1/sos/"+alertID+"/cancel", f.asPx, map[string]string{"pin": "0000"}, http.StatusForbidden)

	// Consola (US2).
	c.call(http.MethodGet, "/v1/ops/sos", f.asAdmin, nil, http.StatusForbidden)
	c.call(http.MethodGet, "/v1/ops/sos", f.asPx, nil, http.StatusForbidden)
	c.call(http.MethodGet, "/v1/ops/sos", f.asOperator, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/ops/sos?view=history&from=2026-01-01&outcome=false_alarm", f.asOperator, nil, http.StatusOK)
	detail := c.call(http.MethodGet, "/v1/ops/sos/"+alertID, f.asOperator, nil, http.StatusOK)
	assert.Equal(t, true, detail["cancel_without_pin"])
	c.call(http.MethodPost, "/v1/ops/sos/"+alertID+"/token", f.asOperator, nil, http.StatusOK)
	c.call(http.MethodPost, "/v1/ops/sos/"+alertID+"/close", f.asOperator, map[string]string{"outcome": "resolved"}, http.StatusConflict)
	c.call(http.MethodPost, "/v1/ops/sos/"+alertID+"/claim", f.asOperator, nil, http.StatusOK)
	c.call(http.MethodPost, "/v1/ops/sos/"+alertID+"/notes", f.asOperator, map[string]string{"body": "Llamé a la pasajera"}, http.StatusCreated)
	c.call(http.MethodPost, "/v1/ops/sos/"+alertID+"/release", f.asOperator, nil, http.StatusNoContent)
	c.call(http.MethodPost, "/v1/ops/sos/"+alertID+"/release", f.asOperator, nil, http.StatusConflict)
	c.call(http.MethodPost, "/v1/ops/sos/"+alertID+"/claim", f.asOperator, nil, http.StatusOK)
	c.call(http.MethodPost, "/v1/ops/sos/"+alertID+"/close", f.asOperator, map[string]string{"outcome": "maybe"}, http.StatusBadRequest)
	c.call(http.MethodPost, "/v1/ops/sos/"+alertID+"/close", f.asOperator, map[string]string{"outcome": "false_alarm"}, http.StatusNoContent)
	c.call(http.MethodPost, "/v1/ops/sos/"+alertID+"/claim", f.asOperator, nil, http.StatusGone)
	c.call(http.MethodGet, "/v1/ops/sos/"+uuid.NewString(), f.asOperator, nil, http.StatusNotFound)
	c.call(http.MethodGet, "/v1/ops/duty", f.asOperator, nil, http.StatusOK)
	c.call(http.MethodPut, "/v1/ops/duty", f.asOperator, map[string]bool{"on_duty": false}, http.StatusOK)
	c.call(http.MethodGet, "/v1/ops/duty", f.asAdmin, nil, http.StatusForbidden)

	// Tras el cierre la app deja de enviar.
	c.call(http.MethodPost, "/v1/sos/"+alertID+"/locations", f.asPx, map[string]any{"points": []map[string]any{
		{"lat": 4.611, "lng": -74.071},
	}}, http.StatusGone)
	c.call(http.MethodPost, "/v1/sos/"+alertID+"/cancel", f.asPx, map[string]string{"pin": "2468"}, http.StatusGone)
	c.call(http.MethodGet, "/v1/sos/active", f.asPx, nil, http.StatusNoContent)
}
