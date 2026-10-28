package crm

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
)

type recorder struct {
	mu     sync.Mutex
	events []string
}

func (r *recorder) Publish(_ context.Context, channel string, ev realtime.Event) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	data, _ := json.Marshal(ev.Data)
	r.events = append(r.events, channel+" "+ev.Type+" "+string(data))
	return nil
}

func TestNormalizeReasonAndLikePattern(t *testing.T) {
	r, err := NormalizeReason("  fraude con QR  ")
	require.NoError(t, err)
	assert.Equal(t, "fraude con QR", r)
	for _, bad := range []string{"", "  ", "ab", string(bytes.Repeat([]byte("x"), 501))} {
		_, err := NormalizeReason(bad)
		assert.ErrorIs(t, err, ErrInvalidReason, "%q", bad)
	}
	assert.Equal(t, `50\% \_x\\`, likePattern(`50% _x\`))
}

// T025, US4: buscar, suspender con motivo y efectos, reactivar e historial.
func TestIntegrationModeration(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	admin, admin2, ana, carlos, diana := uuid.New(), uuid.New(), uuid.New(), uuid.New(), uuid.New()
	for _, u := range []store.CreateUserParams{
		{ID: admin, PhoneE164: "+573000000000", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: admin2, PhoneE164: "+573000000001", Role: store.UserRoleAdmin, DisplayName: "Otra admin"},
		{ID: ana, PhoneE164: "+573200000001", Role: store.UserRolePassenger, DisplayName: "Ana María"},
		{ID: carlos, PhoneE164: "+573100000001", Role: store.UserRoleDriver, DisplayName: "Carlos"},
		{ID: diana, PhoneE164: "+573100000002", Role: store.UserRoleDriver, DisplayName: "Diana"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	for _, d := range []uuid.UUID{carlos, diana} {
		require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: d, QrToken: "qr-" + d.String()}))
	}
	require.NoError(t, st.UpsertFareTable(ctx, store.UpsertFareTableParams{
		CityCode: "bogota", Currency: "COP", BaseMinor: 1, PerKmMinor: 1, PerMinuteMinor: 1, MinimumMinor: 1, RoundingMinor: 1, UpdatedBy: admin,
	}))
	require.NoError(t, st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: carlos, Presence: store.DriverPresenceFree}))
	require.NoError(t, st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: diana, Presence: store.DriverPresenceBusy}))
	require.NoError(t, st.InsertTrip(ctx, store.InsertTripParams{
		ID: uuid.New(), PassengerID: ana, DriverID: diana, CityCode: "bogota", Currency: "COP", PickupLat: 4.6, PickupLng: -74.08,
		DropoffLat: 4.65, DropoffLng: -74.05, RouteDistanceM: 1000, RouteDurationS: 300, SuggestedFareMinor: 800_000,
		Status: store.TripStatusINPROGRESS, CreatedAt: time.Now(),
	}))
	for _, u := range []uuid.UUID{ana, carlos} {
		require.NoError(t, st.InsertRefreshToken(ctx, store.InsertRefreshTokenParams{
			ID: uuid.New(), UserID: u, TokenHash: []byte(u.String()), ExpiresAt: time.Now().Add(time.Hour),
		}))
	}

	pub := &recorder{}
	issuer := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), nil)
	mux := http.NewServeMux()
	requireAuth := auth.RequireAuth(issuer)
	(&Handlers{Store: st, Moderation: &Moderation{Store: st, Publisher: pub}}).Register(mux, requireAuth)
	(&drivers.Presence{Store: st}).Register(mux, requireAuth)
	call := func(id uuid.UUID, role, method, path string, body any, out any) int {
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
		if out != nil {
			require.NoError(t, json.NewDecoder(rec.Body).Decode(out))
		}
		return rec.Code
	}
	suspend := func(id uuid.UUID, reason string, out any) int {
		return call(admin, auth.RoleAdmin, http.MethodPost, "/v1/admin/users/"+id.String()+"/suspend", map[string]string{"reason": reason}, out)
	}
	reactivate := func(id uuid.UUID, reason string, out any) int {
		return call(admin, auth.RoleAdmin, http.MethodPost, "/v1/admin/users/"+id.String()+"/reactivate", map[string]string{"reason": reason}, out)
	}

	// FR-014: búsqueda por nombre (sin distinguir mayúsculas), teléfono, rol y estado.
	var found []ModeratedUser
	require.Equal(t, http.StatusOK, call(admin, auth.RoleAdmin, http.MethodGet, "/v1/admin/users?q=ana%20mar", nil, &found))
	require.Len(t, found, 1)
	assert.Equal(t, ana, found[0].UserID)
	require.Equal(t, http.StatusOK, call(admin, auth.RoleAdmin, http.MethodGet, "/v1/admin/users?q=31000000&role=driver", nil, &found))
	assert.Len(t, found, 2)
	require.Equal(t, http.StatusOK, call(admin, auth.RoleAdmin, http.MethodGet, "/v1/admin/users?q=%25", nil, &found))
	assert.Empty(t, found, "el comodín % se busca literal")
	assert.Equal(t, http.StatusBadRequest, call(admin, auth.RoleAdmin, http.MethodGet, "/v1/admin/users?status=banned", nil, nil))
	assert.Equal(t, http.StatusBadRequest, call(admin, auth.RoleAdmin, http.MethodGet, "/v1/admin/users?role=root", nil, nil))

	// FR-015: motivo obligatorio; no a administradores; usuario desconocido.
	assert.Equal(t, http.StatusBadRequest, suspend(ana, " ", nil))
	assert.Equal(t, http.StatusConflict, suspend(admin2, "no se puede", nil))
	assert.Equal(t, http.StatusNotFound, suspend(uuid.New(), "no existe", nil))
	assert.Equal(t, http.StatusNotFound, call(admin, auth.RoleAdmin, http.MethodPost, "/v1/admin/users/x/suspend", map[string]string{"reason": "abc"}, nil))

	// FR-016: suspender a la pasajera revoca sus sesiones.
	var u ModeratedUser
	require.Equal(t, http.StatusOK, suspend(ana, "  acoso a conductores  ", &u))
	require.NotNil(t, u.SuspendedAt)
	assert.Equal(t, "acoso a conductores", *u.SuspensionReason)
	tok, err := st.GetRefreshTokenByHash(ctx, []byte(ana.String()))
	require.NoError(t, err)
	assert.True(t, tok.RotatedAt.Valid, "refresh revocado")
	assert.Equal(t, http.StatusConflict, suspend(ana, "otra vez", nil), "ya suspendida")

	// Conductor libre: pasa a OFFLINE y se avisa a sus afiliados.
	require.Equal(t, http.StatusOK, suspend(carlos, "documentos falsos", nil))
	d, err := st.GetDriverForPresence(ctx, carlos)
	require.NoError(t, err)
	assert.Equal(t, store.DriverPresenceOffline, d.Presence)
	require.Len(t, pub.events, 1)
	assert.Contains(t, pub.events[0], "driver_presence:"+carlos.String()+" driver.presence")
	assert.Contains(t, pub.events[0], `"presence":"offline"`)
	// Con la sesión aún válida no puede volver a ONLINE.
	var errBody struct{ Code string }
	assert.Equal(t, http.StatusConflict, call(carlos, auth.RoleDriver, http.MethodPost, "/v1/driver/presence", map[string]bool{"online": true}, &errBody))
	assert.Equal(t, "account_suspended", errBody.Code)

	// Conductora en un viaje: el viaje sigue; queda ocupada hasta terminarlo.
	require.Equal(t, http.StatusOK, suspend(diana, "quejas reiteradas", nil))
	d, err = st.GetDriverForPresence(ctx, diana)
	require.NoError(t, err)
	assert.Equal(t, store.DriverPresenceBusy, d.Presence)
	assert.Len(t, pub.events, 1)

	require.Equal(t, http.StatusOK, call(admin, auth.RoleAdmin, http.MethodGet, "/v1/admin/users?status=suspended", nil, &found))
	assert.Len(t, found, 3)

	// Reactivar y el historial (FR-017).
	require.Equal(t, http.StatusOK, reactivate(ana, "aclarado con la pasajera", &u))
	assert.Nil(t, u.SuspendedAt)
	assert.Nil(t, u.SuspensionReason)
	assert.Equal(t, http.StatusConflict, reactivate(ana, "de nuevo", nil), "ya activa")
	var history []Action
	require.Equal(t, http.StatusOK, call(admin, auth.RoleAdmin, http.MethodGet, "/v1/admin/users/"+ana.String()+"/moderation", nil, &history))
	require.Len(t, history, 2)
	assert.Equal(t, "reactivate", history[0].Action)
	assert.Equal(t, "suspend", history[1].Action)
	assert.Equal(t, "acoso a conductores", history[1].Reason)
	assert.Equal(t, admin, history[1].ActorID)
	assert.Equal(t, "Admin", history[1].ActorName)
	assert.Equal(t, http.StatusNotFound, call(admin, auth.RoleAdmin, http.MethodGet, "/v1/admin/users/"+uuid.NewString()+"/moderation", nil, nil))

	// Login real (PgRepo): la conductora suspendida no obtiene sesión; la pasajera reactivada sí.
	svc := auth.NewService(auth.NewPgRepo(st), auth.DevOTP{Code: "123456"}, issuer, nil)
	_, err = svc.VerifyOTP(ctx, "+573100000002", "123456", "", "")
	assert.ErrorIs(t, err, auth.ErrAccountSuspended)
	_, err = svc.VerifyOTP(ctx, "+573200000001", "123456", "", "")
	assert.NoError(t, err)

	// Solo admins.
	assert.Equal(t, http.StatusForbidden, call(carlos, auth.RoleDriver, http.MethodGet, "/v1/admin/users", nil, nil))
	assert.Equal(t, http.StatusForbidden, call(ana, auth.RolePassenger, http.MethodPost, "/v1/admin/users/"+carlos.String()+"/reactivate", map[string]string{"reason": "abc"}, nil))
}

// T006: la migración 00012 añade la suspensión sin tocar a los usuarios existentes y su tabla de
// auditoría exige motivo.
func TestIntegrationMigration012(t *testing.T) {
	st, migrateTo := testdb.NewAt(t, 7)
	ctx := context.Background()
	admin, ana := uuid.New(), uuid.New()
	_, err := st.Pool.Exec(ctx, `INSERT INTO users (id, phone_e164, role, display_name) VALUES
	    ($1, '+573000000000', 'admin', 'Admin'), ($2, '+573200000001', 'passenger', 'Ana')`, admin, ana)
	require.NoError(t, err)
	migrateTo(12)

	u, err := st.GetUserByID(ctx, ana)
	require.NoError(t, err)
	assert.False(t, u.SuspendedAt.Valid, "los usuarios existentes quedan activos")
	_, err = st.Pool.Exec(ctx, `UPDATE users SET suspended_at = now() WHERE id = $1`, ana)
	assert.Error(t, err, "suspensión sin motivo")
	_, err = st.Pool.Exec(ctx, `INSERT INTO moderation_actions (id, user_id, action, reason, actor_id) VALUES ($1, $2, 'suspend', ' a ', $3)`, uuid.New(), ana, admin)
	assert.Error(t, err, "motivo de menos de 3 caracteres")
	_, err = st.Pool.Exec(ctx, `INSERT INTO moderation_actions (id, user_id, action, reason, actor_id) VALUES ($1, $2, 'suspend', 'fraude', $3)`, uuid.New(), ana, admin)
	assert.NoError(t, err)
}
