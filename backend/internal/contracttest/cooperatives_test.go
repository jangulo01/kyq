package contracttest

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/getkin/kin-openapi/openapi3"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/affiliations"
	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/cooperatives"
	"github.com/kyq/backend/internal/fares"
	"github.com/kyq/backend/internal/httpapi"
	"github.com/kyq/backend/internal/ptt"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
	"github.com/kyq/backend/internal/trips"
)

type route5km struct{}

func (route5km) Route(context.Context, float64, float64, float64, float64) (fares.Route, error) {
	return fares.Route{DistanceM: 5200, DurationS: 900}, nil
}

// okRooms is a LiveKit that accepts everything.
type okRooms struct{}

func (okRooms) CreateRoom(context.Context, string) error                  { return nil }
func (okRooms) DeleteRoom(context.Context, string) error                  { return nil }
func (okRooms) SetCanPublish(context.Context, string, string, bool) error { return nil }
func (okRooms) CreateGroupRoom(context.Context, string, int) error        { return nil }
func (okRooms) RemoveParticipant(context.Context, string, string) error   { return nil }

// TestIntegration006RoutesMatchContract walks the 006 flow through the real router and checks
// every request and response against the merged contract: cooperatives in the admin panel,
// requests from the app, coordinator decisions, group channel, dispatch choice and delegation.
func TestIntegration006RoutesMatchContract(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	now := time.Now()
	adminID, passengerID := uuid.New(), uuid.New()
	chosen, coworker, applicant := uuid.New(), uuid.New(), uuid.New()
	for _, u := range []store.CreateUserParams{
		{ID: adminID, PhoneE164: "+573000000000", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: passengerID, PhoneE164: "+573200000002", Role: store.UserRolePassenger, DisplayName: "Ana"},
		{ID: chosen, PhoneE164: "+573100000001", Role: store.UserRoleDriver, DisplayName: "Carlos"},
		{ID: coworker, PhoneE164: "+573100000002", Role: store.UserRoleDriver, DisplayName: "Beto"},
		{ID: applicant, PhoneE164: "+573100000003", Role: store.UserRoleDriver, DisplayName: "Dani"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	for i, d := range []uuid.UUID{chosen, coworker, applicant} {
		require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{
			UserID: d, QrToken: "qr-contract-00000" + string(rune('1'+i)), VehiclePlate: "KYQ00" + string(rune('1'+i)), VehicleDescription: "Kia",
		}))
	}
	require.NoError(t, st.InsertAffiliation(ctx, store.InsertAffiliationParams{PassengerID: passengerID, DriverID: chosen}))
	require.NoError(t, st.UpsertFareTable(ctx, store.UpsertFareTableParams{
		CityCode: "bogota", Currency: "COP", BaseMinor: 400_000, PerKmMinor: 120_000, PerMinuteMinor: 30_000,
		MinimumMinor: 700_000, RoundingMinor: 10_000, UpdatedBy: adminID,
	}))

	tokens := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), nil)
	pttService := &ptt.Service{Store: st, LiveKit: ptt.LiveKit{APIKey: "k", APISecret: "s"}, Rooms: okRooms{}, Groups: okRooms{}, PublicURL: "ws://voice.test"}
	server := httpapi.NewRouter(httpapi.Deps{
		Tokens:       tokens,
		Affils:       &affiliations.Handlers{Service: affiliations.NewService(affiliations.NewPgRepo(st.Queries))},
		Trips:        &trips.Handlers{Service: &trips.Service{Store: st, Routes: route5km{}, CityCode: "bogota"}},
		Cooperatives: &cooperatives.Handlers{Service: &cooperatives.Service{Store: st, Group: pttService}},
		GroupPTT:     &ptt.GroupHandlers{Service: pttService},
	})
	c := load(t, server)
	bearer := func(id uuid.UUID, role string) string {
		tok, err := tokens.IssueAccess(auth.Principal{UserID: id, Role: role})
		require.NoError(t, err)
		return tok
	}
	asAdmin, asPassenger := bearer(adminID, auth.RoleAdmin), bearer(passengerID, auth.RolePassenger)
	asChosen, asCoworker, asApplicant := bearer(chosen, auth.RoleDriver), bearer(coworker, auth.RoleDriver), bearer(applicant, auth.RoleDriver)

	// Panel: alta y gestión (FR-001, FR-002, FR-006).
	created := c.call(http.MethodPost, "/v1/admin/cooperatives", asAdmin, map[string]any{"name": "Cooperativa Andina", "city_code": "bogota", "nit": "900123456"}, http.StatusCreated)
	coopID := created["id"].(string)
	c.call(http.MethodPost, "/v1/admin/cooperatives", asAdmin, map[string]any{"name": "cooperativa andina", "city_code": "bogota"}, http.StatusConflict)
	c.call(http.MethodPost, "/v1/admin/cooperatives", asAdmin, map[string]any{"name": "  AB   ", "city_code": "bogota"}, http.StatusBadRequest)
	c.call(http.MethodGet, "/v1/admin/cooperatives", asAdmin, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/admin/cooperatives/"+uuid.NewString(), asAdmin, nil, http.StatusNotFound)
	c.call(http.MethodPost, "/v1/admin/cooperatives/"+coopID+"/members", asAdmin, map[string]any{"driver_id": chosen.String(), "role": "coordinator"}, http.StatusCreated)
	c.call(http.MethodPost, "/v1/admin/cooperatives/"+coopID+"/members", asAdmin, map[string]any{"driver_id": chosen.String()}, http.StatusConflict)
	c.call(http.MethodPatch, "/v1/admin/cooperatives/"+coopID, asAdmin, map[string]any{"nit": nil, "name": "Cooperativa Andina Bogotá"}, http.StatusOK)

	// App: solicitud y decisión del coordinador (FR-004, FR-005).
	list := c.call(http.MethodGet, "/v1/cooperatives", asCoworker, nil, http.StatusOK)
	require.Len(t, list["cooperatives"], 1)
	req := c.call(http.MethodPost, "/v1/driver/cooperative/requests", asCoworker, map[string]any{"cooperative_id": coopID}, http.StatusCreated)
	c.call(http.MethodPost, "/v1/driver/cooperative/requests", asCoworker, map[string]any{"cooperative_id": coopID}, http.StatusConflict)
	c.call(http.MethodPost, "/v1/driver/cooperative/requests", asApplicant, map[string]any{"cooperative_id": uuid.NewString()}, http.StatusNotFound)
	app := c.call(http.MethodPost, "/v1/driver/cooperative/requests", asApplicant, map[string]any{"cooperative_id": coopID}, http.StatusCreated)
	c.call(http.MethodPost, "/v1/driver/cooperative/requests/"+req["id"].(string)+"/decision", asApplicant, map[string]any{"decision": "approve"}, http.StatusForbidden)
	mine := c.call(http.MethodGet, "/v1/driver/cooperative", asChosen, nil, http.StatusOK)
	assert.Len(t, mine["requests"], 2, "el coordinador ve las solicitudes")
	c.call(http.MethodPost, "/v1/driver/cooperative/requests/"+req["id"].(string)+"/decision", asChosen, map[string]any{"decision": "approve"}, http.StatusNoContent)
	c.call(http.MethodPost, "/v1/admin/memberships/"+app["id"].(string)+"/decision", asAdmin, map[string]any{"decision": "reject"}, http.StatusBadRequest)
	c.call(http.MethodPost, "/v1/admin/memberships/"+app["id"].(string)+"/decision", asAdmin, map[string]any{"decision": "reject", "reason": "Sin referencias"}, http.StatusNoContent)
	c.call(http.MethodPost, "/v1/admin/memberships/"+app["id"].(string)+"/decision", asAdmin, map[string]any{"decision": "approve"}, http.StatusConflict)
	rejected := c.call(http.MethodGet, "/v1/driver/cooperative", asApplicant, nil, http.StatusOK)
	assert.Equal(t, "rejected", rejected["membership"].(map[string]any)["status"])
	c.call(http.MethodDelete, "/v1/driver/cooperative/requests", asApplicant, nil, http.StatusNotFound)
	c.call(http.MethodPost, "/v1/driver/cooperative/requests", asApplicant, map[string]any{"cooperative_id": coopID}, http.StatusCreated)
	c.call(http.MethodDelete, "/v1/driver/cooperative/requests", asApplicant, nil, http.StatusNoContent)
	detail := c.call(http.MethodGet, "/v1/admin/cooperatives/"+coopID, asAdmin, nil, http.StatusOK)
	assert.Len(t, detail["members"], 2)

	// Canal de grupo (FR-022, FR-023).
	c.call(http.MethodPost, "/v1/driver/cooperative/ptt/token", asCoworker, nil, http.StatusOK)
	c.call(http.MethodPost, "/v1/driver/cooperative/ptt/token", asApplicant, nil, http.StatusNotFound)
	c.call(http.MethodPost, "/v1/driver/cooperative/ptt/floor", asCoworker, nil, http.StatusOK)
	c.call(http.MethodPost, "/v1/driver/cooperative/ptt/floor", asChosen, nil, http.StatusConflict)
	c.call(http.MethodDelete, "/v1/driver/cooperative/ptt/floor", asCoworker, nil, http.StatusNoContent)

	// Selector de despacho y delegación (FR-009–FR-015).
	drivers := c.callList(http.MethodGet, "/v1/affiliations", asPassenger)
	require.Len(t, drivers, 1)
	assert.Equal(t, coopID, drivers[0]["cooperative"].(map[string]any)["id"], "la lista trae la cooperativa del elegido")
	for _, d := range []uuid.UUID{chosen, coworker} {
		require.NoError(t, st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: d, Presence: store.DriverPresenceFree}))
		require.NoError(t, st.SetDriverLocation(ctx, store.SetDriverLocationParams{Lat: 4.601, Lng: -74.08, RecordedAt: now, UserID: d}))
	}
	route := map[string]any{"pickup": map[string]float64{"lat": 4.60, "lng": -74.08}, "dropoff": map[string]float64{"lat": 4.65, "lng": -74.05}}
	body := func(extra map[string]any) map[string]any {
		out := map[string]any{"driver_id": chosen.String()}
		for k, v := range route {
			out[k] = v
		}
		for k, v := range extra {
			out[k] = v
		}
		return out
	}
	trip := c.call(http.MethodPost, "/v1/trips", asPassenger, body(map[string]any{"allow_delegation": true}), http.StatusCreated)
	assert.Equal(t, true, trip["can_delegate"])
	assert.Equal(t, "Carlos", trip["driver_name"])
	tripID := trip["id"].(string)
	c.call(http.MethodPost, "/v1/trips/"+tripID+"/delegate", asPassenger, nil, http.StatusForbidden)
	passed := c.call(http.MethodPost, "/v1/trips/"+tripID+"/delegate", asChosen, nil, http.StatusOK)
	assert.Equal(t, coworker.String(), passed["driver_id"], "pasa al compañero libre")
	c.call(http.MethodPost, "/v1/trips/"+tripID+"/cancel", asPassenger, nil, http.StatusOK)

	c.call(http.MethodPost, "/v1/trips", asPassenger, body(map[string]any{"dispatch": "cooperative"}), http.StatusCreated)

	// Retiro y salida.
	c.call(http.MethodDelete, "/v1/driver/cooperative/members/"+chosen.String(), asCoworker, nil, http.StatusForbidden)
	c.call(http.MethodPut, "/v1/admin/cooperatives/"+coopID+"/members/"+coworker.String()+"/role", asAdmin, map[string]any{"role": "coordinator"}, http.StatusNoContent)
	c.call(http.MethodDelete, "/v1/admin/cooperatives/"+coopID+"/members/"+coworker.String(), asAdmin, nil, http.StatusNoContent)
	c.call(http.MethodDelete, "/v1/admin/cooperatives/"+coopID+"/members/"+coworker.String(), asAdmin, nil, http.StatusNotFound)
	c.call(http.MethodDelete, "/v1/driver/cooperative/membership", asChosen, nil, http.StatusNoContent)
	c.call(http.MethodDelete, "/v1/driver/cooperative/membership", asChosen, nil, http.StatusNotFound)
	c.call(http.MethodPatch, "/v1/admin/cooperatives/"+coopID, asAdmin, map[string]any{"status": "suspended"}, http.StatusOK)
}

// The 006 view of the contract stays a valid OpenAPI document (its routes are merged in specPath).
func TestContract006ViewIsValid(t *testing.T) {
	loader := openapi3.NewLoader()
	doc, err := loader.LoadFromFile("../../../specs/006-cooperatives-delegation/contracts/api.yaml")
	require.NoError(t, err)
	require.NoError(t, doc.Validate(loader.Context))
}

// callList is call for responses that are JSON arrays: it validates through call and returns
// the decoded items of a second identical request.
func (c *contract) callList(method, path, token string) []map[string]any {
	c.t.Helper()
	c.call(method, path, token, nil, http.StatusOK)
	req := httptest.NewRequest(method, "http://localhost:8080"+path, nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rec := httptest.NewRecorder()
	c.server.ServeHTTP(rec, req)
	var out []map[string]any
	require.NoError(c.t, json.Unmarshal(rec.Body.Bytes(), &out))
	return out
}
