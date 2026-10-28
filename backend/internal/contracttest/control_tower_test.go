package contracttest

import (
	"context"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/getkin/kin-openapi/openapi3"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/control"
	"github.com/kyq/backend/internal/crm"
	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/health"
	"github.com/kyq/backend/internal/httpapi"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/telemetry"
	"github.com/kyq/backend/internal/testdb"
)

// The 007 view of the contract stays a valid OpenAPI document (its routes are merged in specPath).
func TestContract007ViewIsValid(t *testing.T) {
	loader := openapi3.NewLoader()
	doc, err := loader.LoadFromFile("../../../specs/007-control-tower-crm/contracts/api.yaml")
	require.NoError(t, err)
	require.NoError(t, doc.Validate(loader.Context))
}

// T033/T034: todas las rutas de 007 contra el contrato principal, solo para admins; los cambios
// de 007 en auth, presencia y tiempo real (cuenta suspendida, canal admin:tower).
func TestIntegration007RoutesMatchContract(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	admin, ana, carlos := uuid.New(), uuid.New(), uuid.New()
	for _, u := range []store.CreateUserParams{
		{ID: admin, PhoneE164: "+573000000000", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: ana, PhoneE164: "+573200000001", Role: store.UserRolePassenger, DisplayName: "Ana"},
		{ID: carlos, PhoneE164: "+573100000001", Role: store.UserRoleDriver, DisplayName: "Carlos"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: carlos, QrToken: "qr-carlos", VehiclePlate: "KYQ001", VehicleDescription: "Kia"}))
	require.NoError(t, st.UpsertFareTable(ctx, store.UpsertFareTableParams{
		CityCode: "bogota", Currency: "COP", BaseMinor: 400_000, PerKmMinor: 120_000, PerMinuteMinor: 30_000,
		MinimumMinor: 700_000, RoundingMinor: 10_000, UpdatedBy: admin,
	}))
	require.NoError(t, st.SetDriverLocation(ctx, store.SetDriverLocationParams{Lat: 4.6097, Lng: -74.0817, RecordedAt: time.Now(), UserID: carlos}))
	require.NoError(t, st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: carlos, Presence: store.DriverPresenceFree}))
	_, err := st.Pool.Exec(ctx, `INSERT INTO affiliations (passenger_id, driver_id, source, created_at) VALUES ($1, $2, 'qr_scan', now() - interval '40 days')`, ana, carlos)
	require.NoError(t, err)
	require.NoError(t, st.InsertTrip(ctx, store.InsertTripParams{
		ID: uuid.New(), PassengerID: ana, DriverID: carlos, CityCode: "bogota", Currency: "COP", PickupLat: 4.62, PickupLng: -74.07,
		DropoffLat: 4.65, DropoffLng: -74.05, RouteDistanceM: 1000, RouteDurationS: 300, SuggestedFareMinor: 800_000,
		Status: store.TripStatusREQUESTED, CreatedAt: time.Now().Add(-10 * time.Minute),
	}))

	tokens := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), nil)
	pub := &wire{}
	okProbe := func(context.Context) (string, error) { return "disponible", nil }
	server := httpapi.NewRouter(httpapi.Deps{
		Tokens:   tokens,
		Auth:     auth.NewHandlers(auth.NewService(auth.NewPgRepo(st), auth.DevOTP{Code: "123456"}, tokens, nil)),
		Realtime: &realtime.Handlers{Tokens: realtime.Tokens{Secret: []byte("centrifugo-secret")}},
		Presence: &drivers.Presence{Store: st, Publisher: pub},
		Costs:    &telemetry.CostHandlers{Store: st, CityCode: "bogota"},
		Tower:    &control.Handlers{Store: st},
		CRM:      &crm.Handlers{Store: st, Moderation: &crm.Moderation{Store: st, Publisher: pub}},
		Health: &health.Handlers{Checker: &health.Checker{Probes: []health.Named{
			{Name: health.Database, Probe: health.DatabaseProbe(st.Pool)},
			{Name: health.OSRM, Probe: func(context.Context) (string, error) { return "sin conexión", context.DeadlineExceeded }},
			{Name: health.Bold, Probe: health.BoldProbe(nil, false, "", "")},
			{Name: health.Storage, Probe: okProbe},
		}}},
	})
	c := load(t, server)
	issue := func(id uuid.UUID, role string) string {
		tok, err := tokens.IssueAccess(auth.Principal{UserID: id, Role: role})
		require.NoError(t, err)
		return tok
	}
	adminTok, anaTok, carlosTok := issue(admin, auth.RoleAdmin), issue(ana, auth.RolePassenger), issue(carlos, auth.RoleDriver)

	// Torre.
	snap := c.call(http.MethodGet, "/v1/admin/tower", adminTok, nil, http.StatusOK)
	assert.Equal(t, float64(1), snap["totals"].(map[string]any)["online"])
	assert.NotEmpty(t, snap["cells"])
	c.call(http.MethodGet, "/v1/admin/tower?res=6", adminTok, nil, http.StatusOK)
	c.callRaw(http.MethodGet, "/v1/admin/tower?res=9", map[string]string{"Authorization": "Bearer " + adminTok}, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/admin/tower", anaTok, nil, http.StatusForbidden)
	c.call(http.MethodGet, "/v1/admin/tower", carlosTok, nil, http.StatusForbidden)
	c.call(http.MethodPost, "/v1/realtime/subscription-token", adminTok, map[string]string{"channel": "admin:tower"}, http.StatusOK)
	c.call(http.MethodPost, "/v1/realtime/subscription-token", anaTok, map[string]string{"channel": "admin:tower"}, http.StatusForbidden)

	// Finanzas, fidelización y salud.
	c.call(http.MethodGet, "/v1/admin/finance?months=2", adminTok, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/admin/finance", carlosTok, nil, http.StatusForbidden)
	rep := c.call(http.MethodGet, "/v1/admin/crm", adminTok, nil, http.StatusOK)
	assert.NotNil(t, rep["sc008"])
	c.call(http.MethodGet, "/v1/admin/crm?from=2026-10-27&to=2026-10-01", adminTok, nil, http.StatusBadRequest)
	h := c.call(http.MethodGet, "/v1/admin/health", adminTok, nil, http.StatusOK)
	assert.Equal(t, "degraded", h["status"])
	c.call(http.MethodGet, "/v1/admin/health", anaTok, nil, http.StatusForbidden)

	// Moderación y sus efectos en auth y presencia.
	session := c.call(http.MethodPost, "/v1/auth/otp/verify", "", map[string]string{"phone_e164": "+573100000001", "code": "123456"}, http.StatusOK)
	c.call(http.MethodGet, "/v1/admin/users?q=carl&role=driver&status=active", adminTok, nil, http.StatusOK)
	c.call(http.MethodPost, "/v1/admin/users/"+carlos.String()+"/suspend", adminTok, map[string]string{"reason": "x"}, http.StatusBadRequest)
	c.call(http.MethodPost, "/v1/admin/users/"+uuid.NewString()+"/suspend", adminTok, map[string]string{"reason": "fraude"}, http.StatusNotFound)
	c.call(http.MethodPost, "/v1/admin/users/"+admin.String()+"/suspend", adminTok, map[string]string{"reason": "fraude"}, http.StatusConflict)
	u := c.call(http.MethodPost, "/v1/admin/users/"+carlos.String()+"/suspend", adminTok, map[string]string{"reason": "documentos falsos"}, http.StatusOK)
	assert.Equal(t, "documentos falsos", u["suspension_reason"])
	c.call(http.MethodPost, "/v1/admin/users/"+carlos.String()+"/suspend", adminTok, map[string]string{"reason": "otra vez"}, http.StatusConflict)
	e := c.call(http.MethodPost, "/v1/auth/refresh", "", map[string]string{"refresh_token": session["refresh_token"].(string)}, http.StatusUnauthorized)
	assert.Equal(t, "invalid_refresh_token", e["code"], "las sesiones se revocaron al suspender")
	e = c.call(http.MethodPost, "/v1/auth/otp/verify", "", map[string]string{"phone_e164": "+573100000001", "code": "123456"}, http.StatusForbidden)
	assert.Equal(t, "account_suspended", e["code"])
	e = c.call(http.MethodPost, "/v1/driver/presence", carlosTok, map[string]bool{"online": true}, http.StatusConflict)
	assert.Equal(t, "account_suspended", e["code"])
	c.call(http.MethodGet, "/v1/admin/users/"+carlos.String()+"/moderation", adminTok, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/admin/users/"+uuid.NewString()+"/moderation", adminTok, nil, http.StatusNotFound)
	c.call(http.MethodPost, "/v1/admin/users/"+carlos.String()+"/reactivate", anaTok, map[string]string{"reason": "abc"}, http.StatusForbidden)
	c.call(http.MethodPost, "/v1/admin/users/"+carlos.String()+"/reactivate", adminTok, map[string]string{"reason": "aclarado"}, http.StatusOK)
	c.call(http.MethodPost, "/v1/admin/users/"+carlos.String()+"/reactivate", adminTok, map[string]string{"reason": "aclarado"}, http.StatusConflict)
	session = c.call(http.MethodPost, "/v1/auth/otp/verify", "", map[string]string{"phone_e164": "+573100000001", "code": "123456"}, http.StatusOK)

	// Un suspendido con un refresh vigente recibe 403 al renovar.
	c.call(http.MethodPost, "/v1/admin/users/"+carlos.String()+"/suspend", adminTok, map[string]string{"reason": "segunda vez"}, http.StatusOK)
	_, err = st.Pool.Exec(ctx, `UPDATE refresh_tokens SET rotated_at = NULL WHERE user_id = $1`, carlos)
	require.NoError(t, err)
	e = c.call(http.MethodPost, "/v1/auth/refresh", "", map[string]string{"refresh_token": session["refresh_token"].(string)}, http.StatusForbidden)
	assert.Equal(t, "account_suspended", e["code"])

	// FR-006: el aviso de la torre no lleva datos personales.
	pub.mu.Lock()
	defer pub.mu.Unlock()
	for _, ev := range pub.events {
		assert.False(t, strings.HasPrefix(ev, "admin:tower") && strings.Contains(ev, "Carlos"))
	}
}
