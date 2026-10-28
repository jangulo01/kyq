package ptt_test

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
	"github.com/kyq/backend/internal/ptt"
	"github.com/kyq/backend/internal/store"
)

// Pruebas de la pre-consulta de voz (RN-KYQ-010, specs/005-ptt-extras).

func (f *fixture) store() *store.Store { return f.ptt.Store }

// newPassenger crea un pasajero afiliado al conductor del fixture.
func (f *fixture) newPassenger(t *testing.T, phone, name string) uuid.UUID {
	ctx := context.Background()
	id := uuid.New()
	_, err := f.store().CreateUser(ctx, store.CreateUserParams{ID: id, PhoneE164: phone, Role: store.UserRolePassenger, DisplayName: name})
	require.NoError(t, err)
	require.NoError(t, f.store().InsertAffiliation(ctx, store.InsertAffiliationParams{PassengerID: id, DriverID: f.driver}))
	return id
}

func (f *fixture) acceptPreconsults(t *testing.T, on bool) {
	_, err := f.ptt.SetAcceptsPreconsults(context.Background(), f.driver, on)
	require.NoError(t, err)
}

func (f *fixture) setPresence(t *testing.T, p store.DriverPresence) {
	require.NoError(t, f.store().SetDriverPresence(context.Background(), store.SetDriverPresenceParams{UserID: f.driver, Presence: p}))
}

func (f *fixture) sweep(t *testing.T) int {
	n, err := f.ptt.ClosePreconsults(context.Background())
	require.NoError(t, err)
	return n
}

func TestIntegrationRNKYQ010OnlyAuthorizedClientsOfAFreeDriver(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	stranger := uuid.New()
	_, err := f.store().CreateUser(ctx, store.CreateUserParams{ID: stranger, PhoneE164: "+573200000009", Role: store.UserRolePassenger, DisplayName: "Eva"})
	require.NoError(t, err)

	_, _, err = f.ptt.OpenPreconsult(ctx, f.passenger, f.driver)
	assert.ErrorIs(t, err, ptt.ErrPreconsultsDisabled, "desactivadas por defecto (FR-001)")
	settings, err := f.ptt.PreconsultSettings(ctx, f.driver)
	require.NoError(t, err)
	assert.False(t, settings.AcceptsPreconsults)

	f.acceptPreconsults(t, true)
	_, _, err = f.ptt.OpenPreconsult(ctx, stranger, f.driver)
	assert.ErrorIs(t, err, ptt.ErrNotFound, "solo clientes afiliados")
	ids, err := f.ptt.PreconsultDrivers(ctx, f.passenger)
	require.NoError(t, err)
	assert.Equal(t, []uuid.UUID{f.driver}, ids)

	// Silenciar a un cliente (FR-002): no se le dice, solo deja de poder.
	require.NoError(t, f.ptt.SetPreconsultsBlocked(ctx, f.driver, f.passenger, true))
	_, _, err = f.ptt.OpenPreconsult(ctx, f.passenger, f.driver)
	assert.ErrorIs(t, err, ptt.ErrPreconsultsDisabled)
	ids, err = f.ptt.PreconsultDrivers(ctx, f.passenger)
	require.NoError(t, err)
	assert.Empty(t, ids)
	settings, err = f.ptt.PreconsultSettings(ctx, f.driver)
	require.NoError(t, err)
	assert.Equal(t, []uuid.UUID{f.passenger}, settings.BlockedPassengerIDs)
	assert.ErrorIs(t, f.ptt.SetPreconsultsBlocked(ctx, f.driver, stranger, true), ptt.ErrNotFound, "solo clientes propios")
	require.NoError(t, f.ptt.SetPreconsultsBlocked(ctx, f.driver, f.passenger, false))

	// Solo con el conductor libre (ONLINE y sin viaje).
	for _, p := range []store.DriverPresence{store.DriverPresenceOffline, store.DriverPresenceBusy} {
		f.setPresence(t, p)
		_, _, err = f.ptt.OpenPreconsult(ctx, f.passenger, f.driver)
		assert.ErrorIs(t, err, ptt.ErrDriverUnavailable, string(p))
	}
	f.setPresence(t, store.DriverPresenceFree)
	pre, created, err := f.ptt.OpenPreconsult(ctx, f.passenger, f.driver)
	require.NoError(t, err)
	assert.True(t, created)
	assert.Equal(t, "open", pre.Status)
	assert.Equal(t, "Ana", pre.PassengerName)
	assert.Equal(t, "Carlos", pre.DriverName)
	assert.Equal(t, f.clock.Add(ptt.PreconsultWindow), pre.ClosesAt.UTC())
	assert.Equal(t, f.clock.Add(ptt.PreconsultJoinTimeout), pre.JoinDeadline.UTC())
	assert.Equal(t, []string{"preconsult.opened"}, f.pub.msgs["user:"+f.driver.String()])

	again, created, err := f.ptt.OpenPreconsult(ctx, f.passenger, f.driver)
	require.NoError(t, err)
	assert.False(t, created, "se retoma la misma consulta")
	assert.Equal(t, pre.ID, again.ID)

	// Una abierta por conductor (FR-007).
	pedro := f.newPassenger(t, "+573200000003", "Pedro")
	_, _, err = f.ptt.OpenPreconsult(ctx, pedro, f.driver)
	assert.ErrorIs(t, err, ptt.ErrPreconsultBusy)

	// Una abierta por pasajero.
	other := uuid.New()
	_, err = f.store().CreateUser(ctx, store.CreateUserParams{ID: other, PhoneE164: "+573100000002", Role: store.UserRoleDriver, DisplayName: "Luis"})
	require.NoError(t, err)
	require.NoError(t, f.store().CreateDriver(ctx, store.CreateDriverParams{UserID: other, QrToken: "qr-luis-00000000", VehiclePlate: "KYQ002", VehicleDescription: "Renault"}))
	require.NoError(t, f.store().InsertAffiliation(ctx, store.InsertAffiliationParams{PassengerID: f.passenger, DriverID: other}))
	require.NoError(t, f.store().SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: other, Presence: store.DriverPresenceFree}))
	_, err = f.ptt.SetAcceptsPreconsults(ctx, other, true)
	require.NoError(t, err)
	_, _, err = f.ptt.OpenPreconsult(ctx, f.passenger, other)
	assert.ErrorIs(t, err, ptt.ErrPreconsultInProgress)
}

func TestIntegrationRNKYQ010RateLimits(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	f.acceptPreconsults(t, true)
	openAndEnd := func(passenger uuid.UUID) error {
		pre, _, err := f.ptt.OpenPreconsult(ctx, passenger, f.driver)
		if err != nil {
			return err
		}
		_, err = f.ptt.EndPreconsult(ctx, passenger, pre.ID)
		require.NoError(t, err)
		f.sweep(t)
		f.advance(time.Minute)
		return nil
	}
	for range ptt.PreconsultsPerHourPerDriver {
		require.NoError(t, openAndEnd(f.passenger))
	}
	assert.ErrorIs(t, openAndEnd(f.passenger), ptt.ErrRateLimited, "3 por hora al mismo conductor")
	f.advance(time.Hour)
	for range ptt.PreconsultsPerDay - ptt.PreconsultsPerHourPerDriver {
		require.NoError(t, openAndEnd(f.passenger))
	}
	f.advance(time.Hour)
	assert.ErrorIs(t, openAndEnd(f.passenger), ptt.ErrRateLimited, "6 por día en total")
	f.advance(24 * time.Hour)
	assert.NoError(t, openAndEnd(f.passenger), "al día siguiente vuelve a poder")
}

func TestIntegrationRNKYQ010VoiceOnlyAfterTheDriverJoins(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	f.acceptPreconsults(t, true)
	pre, _, err := f.ptt.OpenPreconsult(ctx, f.passenger, f.driver)
	require.NoError(t, err)
	room := "pre-" + pre.ID.String()

	creds, err := f.ptt.PreconsultToken(ctx, f.passenger, pre.ID)
	require.NoError(t, err)
	assert.Equal(t, room, creds.Room)
	require.NotNil(t, creds.ClosesAt)
	assert.Equal(t, pre.ClosesAt.Unix(), tokenExpiry(t, creds.Token), "el token no dura más que la consulta")
	_, err = f.ptt.TakePreconsultFloor(ctx, f.passenger, pre.ID)
	assert.ErrorIs(t, err, ptt.ErrPreconsultWaiting, "nadie habla a una sala sin el conductor (FR-005)")
	_, err = f.ptt.PreconsultToken(ctx, uuid.New(), pre.ID)
	assert.ErrorIs(t, err, ptt.ErrNotFound)

	_, err = f.ptt.PreconsultToken(ctx, f.driver, pre.ID)
	require.NoError(t, err)
	_, err = f.ptt.PreconsultToken(ctx, f.driver, pre.ID)
	require.NoError(t, err)
	assert.Equal(t, []string{"preconsult.joined"}, f.pub.msgs["user:"+f.passenger.String()], "se avisa una sola vez")

	// Turno de 15 s exclusivo (FR-004).
	expires, err := f.ptt.TakePreconsultFloor(ctx, f.passenger, pre.ID)
	require.NoError(t, err)
	assert.Equal(t, f.clock.Add(ptt.PreconsultFloorTTL), expires.UTC())
	assert.True(t, f.rooms.publishes(f.passenger))
	_, err = f.ptt.TakePreconsultFloor(ctx, f.driver, pre.ID)
	assert.ErrorIs(t, err, ptt.ErrBusy)
	f.advance(ptt.PreconsultFloorTTL + time.Second)
	n, err := f.ptt.ExpirePreconsultFloors(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, n, "a los 15 s se retira el permiso")
	assert.False(t, f.rooms.publishes(f.passenger))

	// Fail-closed como el viaje: sin retirada confirmada el turno no se libera.
	_, err = f.ptt.TakePreconsultFloor(ctx, f.driver, pre.ID)
	require.NoError(t, err)
	f.rooms.failRevoke = true
	assert.ErrorIs(t, f.ptt.ReleasePreconsultFloor(ctx, f.driver, pre.ID), ptt.ErrUnavailable)
	_, err = f.ptt.TakePreconsultFloor(ctx, f.passenger, pre.ID)
	assert.ErrorIs(t, err, ptt.ErrBusy)
	f.rooms.failRevoke = false
	require.NoError(t, f.ptt.ReleasePreconsultFloor(ctx, f.driver, pre.ID))
	view, err := f.ptt.GetPreconsult(ctx, f.passenger, pre.ID)
	require.NoError(t, err)
	assert.NotNil(t, view.AnsweredAt, "el conductor respondió")

	f.rooms.failGrant = true
	_, err = f.ptt.TakePreconsultFloor(ctx, f.passenger, pre.ID)
	assert.ErrorIs(t, err, ptt.ErrUnavailable)
	f.rooms.failGrant = false
	_, err = f.ptt.TakePreconsultFloor(ctx, f.driver, pre.ID)
	assert.NoError(t, err, "con el permiso retirado el turno se soltó")

	// A los 2 min se cierra (FR-006).
	f.advance(ptt.PreconsultWindow)
	_, err = f.ptt.TakePreconsultFloor(ctx, f.driver, pre.ID)
	assert.ErrorIs(t, err, ptt.ErrClosed)
	f.rooms.failDelete = true
	assert.Zero(t, f.sweep(t), "si LiveKit no borra la sala sigue pendiente")
	f.rooms.failDelete = false
	assert.Equal(t, 1, f.sweep(t))
	assert.Contains(t, f.rooms.deleted, room)
	view, err = f.ptt.GetPreconsult(ctx, f.driver, pre.ID)
	require.NoError(t, err)
	assert.Equal(t, "answered", view.Status)
	assert.Equal(t, ptt.ReasonExpired, *view.CloseReason)
	assert.Contains(t, f.pub.msgs["user:"+f.passenger.String()], "preconsult.closed")
	assert.Contains(t, f.pub.msgs["user:"+f.driver.String()], "preconsult.closed")
	_, err = f.ptt.PreconsultToken(ctx, f.passenger, pre.ID)
	assert.ErrorIs(t, err, ptt.ErrClosed)
}

func TestIntegrationRNKYQ010ClosingReasons(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	f.acceptPreconsults(t, true)
	reason := func(id uuid.UUID) (string, string) {
		v, err := f.ptt.GetPreconsult(ctx, f.driver, id)
		require.NoError(t, err)
		return v.Status, *v.CloseReason
	}
	open := func() uuid.UUID {
		// Separadas para no rozar el límite de 3 por hora y ordenar la bandeja.
		f.advance(21 * time.Minute)
		pre, _, err := f.ptt.OpenPreconsult(ctx, f.passenger, f.driver)
		require.NoError(t, err)
		return pre.ID
	}

	// El conductor no se une en 30 s: perdida.
	missed := open()
	f.advance(ptt.PreconsultJoinTimeout - time.Second)
	assert.Zero(t, f.sweep(t))
	f.advance(time.Second)
	_, err := f.ptt.PreconsultToken(ctx, f.driver, missed)
	assert.ErrorIs(t, err, ptt.ErrClosed, "tarde para unirse")
	assert.Equal(t, 1, f.sweep(t))
	status, why := reason(missed)
	assert.Equal(t, "missed", status)
	assert.Equal(t, ptt.ReasonMissed, why)

	// El pasajero termina.
	ended := open()
	_, err = f.ptt.PreconsultToken(ctx, f.driver, ended)
	require.NoError(t, err)
	_, err = f.ptt.EndPreconsult(ctx, f.passenger, ended)
	require.NoError(t, err)
	assert.Equal(t, 1, f.sweep(t))
	status, why = reason(ended)
	assert.Equal(t, "unanswered", status)
	assert.Equal(t, ptt.ReasonEndedByPassenger, why)

	// El conductor pasa a ocupado (acepta otro viaje).
	busy := open()
	f.setPresence(t, store.DriverPresenceBusy)
	assert.Equal(t, 1, f.sweep(t))
	_, why = reason(busy)
	assert.Equal(t, ptt.ReasonDriverUnavailable, why)
	f.setPresence(t, store.DriverPresenceFree)

	// Desactivar o silenciar cierra en el acto.
	disabled := open()
	f.acceptPreconsults(t, false)
	assert.Equal(t, 1, f.sweep(t))
	_, why = reason(disabled)
	assert.Equal(t, ptt.ReasonDisabled, why)

	// Bandeja del conductor: últimas 24 h, la más reciente primero.
	inbox, err := f.ptt.DriverPreconsults(ctx, f.driver)
	require.NoError(t, err)
	require.Len(t, inbox, 4)
	assert.Equal(t, disabled, inbox[0].ID)
	assert.Equal(t, missed, inbox[3].ID)
	f.advance(ptt.PreconsultInboxWindow)
	inbox, err = f.ptt.DriverPreconsults(ctx, f.driver)
	require.NoError(t, err)
	assert.Empty(t, inbox)

	// Los datos se borran a los 30 días (FR-008).
	f.advance(ptt.PreconsultRetention - ptt.PreconsultInboxWindow - 2*time.Hour)
	n, err := f.ptt.PurgePreconsults(ctx)
	require.NoError(t, err)
	assert.Zero(t, n)
	f.advance(3 * time.Hour)
	n, err = f.ptt.PurgePreconsults(ctx)
	require.NoError(t, err)
	assert.Equal(t, int64(4), n)
}

func TestIntegrationPreconsultHTTPStatuses(t *testing.T) {
	f := setup(t)
	tokens := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), func() time.Time { return *f.clock })
	mux := http.NewServeMux()
	(&ptt.Handlers{Service: f.ptt}).Register(mux, auth.RequireAuth(tokens))
	bearer := func(id uuid.UUID, role string) string {
		tok, err := tokens.IssueAccess(auth.Principal{UserID: id, Role: role})
		require.NoError(t, err)
		return tok
	}
	passenger, driver := bearer(f.passenger, auth.RolePassenger), bearer(f.driver, auth.RoleDriver)
	stranger := bearer(uuid.New(), auth.RolePassenger)
	call := func(method, path, token string, body any) (int, map[string]any) {
		var raw []byte
		if body != nil {
			raw, _ = json.Marshal(body)
		}
		req := httptest.NewRequest(method, path, bytes.NewReader(raw))
		req.Header.Set("Authorization", "Bearer "+token)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		var out map[string]any
		_ = json.Unmarshal(rec.Body.Bytes(), &out)
		return rec.Code, out
	}
	open := map[string]any{"driver_id": f.driver}

	code, out := call(http.MethodPost, "/v1/preconsults", passenger, open)
	assert.Equal(t, http.StatusForbidden, code)
	assert.Equal(t, "preconsults_disabled", out["code"])
	code, _ = call(http.MethodPut, "/v1/driver/preconsults/settings", passenger, map[string]any{"accepts_preconsults": true})
	assert.Equal(t, http.StatusForbidden, code, "solo conductores")
	code, _ = call(http.MethodPut, "/v1/driver/preconsults/settings", driver, map[string]any{})
	assert.Equal(t, http.StatusBadRequest, code)
	code, out = call(http.MethodPut, "/v1/driver/preconsults/settings", driver, map[string]any{"accepts_preconsults": true})
	assert.Equal(t, http.StatusOK, code)
	assert.Equal(t, true, out["accepts_preconsults"])
	code, _ = call(http.MethodPost, "/v1/preconsults", driver, open)
	assert.Equal(t, http.StatusForbidden, code, "solo pasajeros abren")
	code, _ = call(http.MethodPost, "/v1/preconsults", stranger, open)
	assert.Equal(t, http.StatusNotFound, code)

	code, out = call(http.MethodPost, "/v1/preconsults", passenger, open)
	require.Equal(t, http.StatusCreated, code)
	id := out["id"].(string)
	code, _ = call(http.MethodPost, "/v1/preconsults", passenger, open)
	assert.Equal(t, http.StatusOK, code)
	base := "/v1/preconsults/" + id
	code, out = call(http.MethodPost, base+"/ptt/floor", passenger, nil)
	assert.Equal(t, http.StatusConflict, code)
	assert.Equal(t, "preconsult_waiting", out["code"])
	code, _ = call(http.MethodPost, base+"/ptt/token", driver, nil)
	assert.Equal(t, http.StatusOK, code)
	code, _ = call(http.MethodPost, base+"/ptt/floor", passenger, nil)
	assert.Equal(t, http.StatusOK, code)
	code, out = call(http.MethodPost, base+"/ptt/floor", driver, nil)
	assert.Equal(t, http.StatusConflict, code)
	assert.Equal(t, "ptt_busy", out["code"])
	code, _ = call(http.MethodDelete, base+"/ptt/floor", passenger, nil)
	assert.Equal(t, http.StatusNoContent, code)
	code, _ = call(http.MethodGet, base, stranger, nil)
	assert.Equal(t, http.StatusNotFound, code)
	code, _ = call(http.MethodGet, "/v1/driver/preconsults", driver, nil)
	assert.Equal(t, http.StatusOK, code)
	code, _ = call(http.MethodPut, "/v1/driver/clients/"+uuid.NewString()+"/preconsults", driver, map[string]any{"blocked": true})
	assert.Equal(t, http.StatusNotFound, code)
	code, out = call(http.MethodPost, base+"/end", driver, nil)
	assert.Equal(t, http.StatusOK, code)
	assert.Equal(t, "ended_by_driver", out["close_reason"])
	f.sweep(t)
	code, out = call(http.MethodPost, base+"/ptt/token", passenger, nil)
	assert.Equal(t, http.StatusGone, code)
	assert.Equal(t, "ptt_closed", out["code"])
}
