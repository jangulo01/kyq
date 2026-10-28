package contracttest

import (
	"context"
	"net/http"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpapi"
	"github.com/kyq/backend/internal/ptt"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
)

// TestIntegration005RoutesMatchContract recorre la pre-consulta de voz (specs/005-ptt-extras)
// por el router real y valida cada petición y respuesta contra el contrato fusionado.
func TestIntegration005RoutesMatchContract(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	driver, passenger := uuid.New(), uuid.New()
	for _, u := range []store.CreateUserParams{
		{ID: driver, PhoneE164: "+573100000001", Role: store.UserRoleDriver, DisplayName: "Carlos"},
		{ID: passenger, PhoneE164: "+573200000002", Role: store.UserRolePassenger, DisplayName: "Ana"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: driver, QrToken: "qr-carlos-0000000", VehiclePlate: "KYQ001", VehicleDescription: "Kia"}))
	require.NoError(t, st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: driver, Presence: store.DriverPresenceFree}))
	require.NoError(t, st.InsertAffiliation(ctx, store.InsertAffiliationParams{PassengerID: passenger, DriverID: driver}))

	tokens := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), nil)
	service := &ptt.Service{Store: st, LiveKit: ptt.LiveKit{APIKey: "devkey", APISecret: "secret"}, Rooms: noRooms{}, Publisher: &wire{}}
	c := load(t, httpapi.NewRouter(httpapi.Deps{Tokens: tokens, PTT: &ptt.Handlers{Service: service}}))
	bearer := func(id uuid.UUID, role string) string {
		tok, err := tokens.IssueAccess(auth.Principal{UserID: id, Role: role})
		require.NoError(t, err)
		return tok
	}
	asDriver, asPassenger := bearer(driver, auth.RoleDriver), bearer(passenger, auth.RolePassenger)

	settings := c.call(http.MethodGet, "/v1/driver/preconsults/settings", asDriver, nil, http.StatusOK)
	assert.Equal(t, false, settings["accepts_preconsults"])
	c.call(http.MethodPost, "/v1/preconsults", asPassenger, map[string]any{"driver_id": driver}, http.StatusForbidden)
	c.call(http.MethodPut, "/v1/driver/preconsults/settings", asDriver, map[string]any{"accepts_preconsults": true}, http.StatusOK)
	c.call(http.MethodPut, "/v1/driver/clients/"+passenger.String()+"/preconsults", asDriver, map[string]any{"blocked": false}, http.StatusNoContent)
	drivers := c.call(http.MethodGet, "/v1/preconsults/drivers", asPassenger, nil, http.StatusOK)
	assert.Equal(t, []any{driver.String()}, drivers["driver_ids"])

	pre := c.call(http.MethodPost, "/v1/preconsults", asPassenger, map[string]any{"driver_id": driver}, http.StatusCreated)
	id := pre["id"].(string)
	base := "/v1/preconsults/" + id
	c.call(http.MethodPost, "/v1/preconsults", asPassenger, map[string]any{"driver_id": driver}, http.StatusOK)
	c.call(http.MethodGet, base, asDriver, nil, http.StatusOK)
	c.call(http.MethodPost, base+"/ptt/token", asPassenger, nil, http.StatusOK)
	c.call(http.MethodPost, base+"/ptt/token", asDriver, nil, http.StatusOK)
	c.call(http.MethodPost, base+"/ptt/floor", asDriver, nil, http.StatusOK)
	c.call(http.MethodPost, base+"/ptt/floor", asPassenger, nil, http.StatusConflict)
	c.call(http.MethodDelete, base+"/ptt/floor", asDriver, nil, http.StatusNoContent)
	c.call(http.MethodGet, "/v1/driver/preconsults", asDriver, nil, http.StatusOK)
	ended := c.call(http.MethodPost, base+"/end", asPassenger, nil, http.StatusOK)
	assert.Equal(t, "ended_by_passenger", ended["close_reason"])
	_, err := service.ClosePreconsults(ctx)
	require.NoError(t, err)
	closed := c.call(http.MethodGet, base, asPassenger, nil, http.StatusOK)
	assert.Equal(t, "answered", closed["status"])
	c.call(http.MethodPost, base+"/ptt/token", asPassenger, nil, http.StatusGone)
	c.call(http.MethodGet, "/v1/preconsults/"+uuid.NewString(), asPassenger, nil, http.StatusNotFound)
}
