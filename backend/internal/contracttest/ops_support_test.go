package contracttest

import (
	"context"
	"crypto/ed25519"
	"encoding/base64"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/control"
	"github.com/kyq/backend/internal/domains"
	"github.com/kyq/backend/internal/health"
	"github.com/kyq/backend/internal/hexgrid"
	"github.com/kyq/backend/internal/httpapi"
	"github.com/kyq/backend/internal/megaphone"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/support"
	"github.com/kyq/backend/internal/testdb"
	"github.com/kyq/backend/internal/trippay"
	"github.com/kyq/backend/internal/trips"
)

type silentVoice struct{}

func (silentVoice) CreateGroupRoom(context.Context, string, int) error { return nil }
func (silentVoice) DeleteRoom(context.Context, string) error           { return nil }
func (silentVoice) BroadcastToken(identity, _, _ string, _ bool, _ time.Time, _ time.Duration) (string, error) {
	return "tok-" + identity, nil
}

// TestIntegration009RoutesMatchContract walks the 009 routes through the real router against the
// merged contract: inspection from the tower, support with a payment dispute, the support-only
// session of a suspended user, the megaphone, crash-free sessions and mirror domains.
func TestIntegration009RoutesMatchContract(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	adminID, ana, luz, carlos := uuid.New(), uuid.New(), uuid.New(), uuid.New()
	for _, u := range []store.CreateUserParams{
		{ID: adminID, PhoneE164: "+573000000000", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: ana, PhoneE164: "+573200000001", Role: store.UserRolePassenger, DisplayName: "Ana"},
		{ID: luz, PhoneE164: "+573200000002", Role: store.UserRolePassenger, DisplayName: "Luz"},
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
	here := hexgrid.Point{Lat: 4.60, Lng: -74.08}
	require.NoError(t, st.SetDriverLocation(ctx, store.SetDriverLocationParams{Lat: here.Lat, Lng: here.Lng, RecordedAt: time.Now(), UserID: carlos}))
	require.NoError(t, st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: carlos, Presence: store.DriverPresenceFree}))

	pay := &trippay.Service{Store: st, Notify: &notify.Service{Store: st}}
	sup := &support.Service{Store: st, Payments: pay}
	pay.Cases = sup
	tripSvc := &trips.Service{Store: st, Routes: route5km{}, CityCode: "bogota", Payments: pay}
	run := func(steps ...func(*trips.Trip, trips.Party, time.Time) error) uuid.UUID {
		trip, err := tripSvc.Request(ctx, ana, carlos, trips.Point{Lat: 4.60, Lng: -74.08}, trips.Point{Lat: 4.65, Lng: -74.05})
		require.NoError(t, err)
		for _, step := range steps {
			_, err := tripSvc.Act(ctx, carlos, trip.ID, step)
			require.NoError(t, err)
		}
		return trip.ID
	}
	accept := func(t *trips.Trip, p trips.Party, now time.Time) error { return t.Accept(p, nil, now) }
	done := run(accept, (*trips.Trip).Arrive, (*trips.Trip).Start, (*trips.Trip).Complete)
	active := run(accept)

	seed := make([]byte, ed25519.SeedSize)
	signer, err := domains.NewSigner(base64.StdEncoding.EncodeToString(seed))
	require.NoError(t, err)
	tokens := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), nil)
	server := httpapi.NewRouter(httpapi.Deps{
		Tokens:    tokens,
		Auth:      auth.NewHandlers(auth.NewService(auth.NewPgRepo(st), auth.DevOTP{Code: "123456"}, tokens, nil)),
		Tower:     &control.Handlers{Store: st},
		Support:   &support.Handlers{Service: sup},
		Megaphone: &megaphone.Handlers{Service: &megaphone.Service{Store: st, Voice: silentVoice{}, VoiceURL: "wss://lk.test"}},
		Domains:   &domains.Handlers{Service: &domains.Service{Store: st, Signer: signer}},
		Health:    &health.Handlers{Checker: &health.Checker{}},
	})
	c := load(t, server)
	token := func(id uuid.UUID, role string) string {
		tk, err := tokens.IssueAccess(auth.Principal{UserID: id, Role: role})
		require.NoError(t, err)
		return tk
	}
	adminTk, anaTk, carlosTk := token(adminID, auth.RoleAdmin), token(ana, auth.RolePassenger), token(carlos, auth.RoleDriver)

	// US1: la torre lleva el viaje activo y el detalle se abre con un clic.
	snap := c.call(http.MethodGet, "/v1/admin/tower", adminTk, nil, http.StatusOK)
	drivers := snap["drivers"].([]any)
	require.Len(t, drivers, 1)
	assert.Equal(t, active.String(), drivers[0].(map[string]any)["active_trip_id"])
	detail := c.call(http.MethodGet, "/v1/admin/trips/"+active.String(), adminTk, nil, http.StatusOK)
	assert.Equal(t, true, detail["active"])
	c.call(http.MethodGet, "/v1/admin/trips/"+done.String(), adminTk, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/admin/trips/"+active.String(), anaTk, nil, http.StatusForbidden)
	c.call(http.MethodGet, "/v1/admin/trips/"+uuid.NewString(), adminTk, nil, http.StatusNotFound)

	// US2: caso del pasajero, conversación y bandeja.
	opened := c.call(http.MethodPost, "/v1/support/cases", anaTk, map[string]any{
		"topic": "lost_item", "description": "Dejé mi sombrilla roja en el carro", "trip_id": done,
	}, http.StatusCreated)
	caseID := opened["id"].(string)
	c.call(http.MethodPost, "/v1/support/cases", anaTk, map[string]any{"topic": "other", "description": "Hola, una consulta", "trip_id": uuid.New()}, http.StatusBadRequest)
	c.call(http.MethodGet, "/v1/support/cases", anaTk, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/support/trips", anaTk, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/support/cases/"+caseID, carlosTk, nil, http.StatusNotFound)
	c.call(http.MethodGet, "/v1/admin/support/cases?unanswered=true&topic=lost_item", adminTk, nil, http.StatusOK)
	c.call(http.MethodPost, "/v1/admin/support/cases/"+caseID+"/messages", adminTk, map[string]any{"body": "Nota", "internal": true}, http.StatusOK)
	c.call(http.MethodPost, "/v1/admin/support/cases/"+caseID+"/messages", adminTk, map[string]any{"body": "La tiene Carlos"}, http.StatusOK)
	c.call(http.MethodPost, "/v1/admin/support/cases/"+caseID+"/assign", adminTk, map[string]any{"admin_id": nil}, http.StatusOK)
	c.call(http.MethodPost, "/v1/admin/support/cases/"+caseID+"/assign", adminTk, map[string]any{"admin_id": adminID}, http.StatusOK)
	c.call(http.MethodGet, "/v1/admin/support/cases?assigned_to=me", adminTk, nil, http.StatusOK)
	c.call(http.MethodPost, "/v1/admin/support/cases/"+caseID+"/status", adminTk, map[string]any{"status": "closed"}, http.StatusOK)
	e := c.call(http.MethodPost, "/v1/support/cases/"+caseID+"/messages", anaTk, map[string]any{"body": "Gracias"}, http.StatusConflict)
	assert.Equal(t, "case_closed", e["code"])
	got := c.call(http.MethodGet, "/v1/support/cases/"+caseID, anaTk, nil, http.StatusOK)
	assert.Len(t, got["messages"], 2, "sin la nota interna")
	c.call(http.MethodGet, "/v1/admin/support/cases/"+caseID, adminTk, nil, http.StatusOK)

	// US2: la disputa de 004 aparece como caso de pago y se resuelve desde él.
	_, err = pay.Act(ctx, ana, done, trippay.ReportCash)
	require.NoError(t, err)
	_, err = pay.Act(ctx, carlos, done, trippay.DisputeCash)
	require.NoError(t, err)
	payCases, err := sup.UserCases(ctx, carlos)
	require.NoError(t, err)
	require.Len(t, payCases, 1)
	payCase := payCases[0].ID.String()
	c.call(http.MethodPost, "/v1/admin/support/cases/"+caseID+"/resolve-payment", adminTk, map[string]any{"outcome": "paid", "note": "x"}, http.StatusConflict)
	resolved := c.call(http.MethodPost, "/v1/admin/support/cases/"+payCase+"/resolve-payment", adminTk, map[string]any{"outcome": "paid", "note": "Encontró el billete"}, http.StatusOK)
	assert.Equal(t, "resolved", resolved["status"])

	// Suspendida: el 403 de 007 trae la sesión de solo soporte (FR-011).
	_, err = st.Pool.Exec(ctx, `UPDATE users SET suspended_at = now(), suspension_reason = 'prueba' WHERE id = $1`, luz)
	require.NoError(t, err)
	e = c.call(http.MethodPost, "/v1/auth/otp/verify", "", map[string]string{"phone_e164": "+573200000002", "code": "123456"}, http.StatusForbidden)
	assert.Equal(t, "account_suspended", e["code"])
	sess := e["support_session"].(map[string]any)
	assert.Equal(t, "support", sess["scope"])
	luzTk := sess["access_token"].(string)
	c.call(http.MethodPost, "/v1/support/cases", luzTk, map[string]any{"topic": "account", "description": "¿Por qué suspendieron mi cuenta?"}, http.StatusCreated)
	blocked := httptest.NewRequest(http.MethodGet, "/v1/admin/tower", nil)
	blocked.Header.Set("Authorization", "Bearer "+luzTk)
	rec := httptest.NewRecorder()
	server.ServeHTTP(rec, blocked)
	assert.Equal(t, http.StatusForbidden, rec.Code)
	assert.Contains(t, rec.Body.String(), "account_suspended")

	// US3: megáfono a la zona de Carlos.
	cell, err := hexgrid.CellAt(here, 8)
	require.NoError(t, err)
	started := c.call(http.MethodPost, "/v1/admin/megaphone", adminTk, map[string]any{"cells": []string{cell.String()}}, http.StatusCreated)
	assert.EqualValues(t, 1, started["recipients"])
	c.call(http.MethodPost, "/v1/admin/megaphone", adminTk, map[string]any{"cells": []string{cell.String()}}, http.StatusConflict)
	c.call(http.MethodPost, "/v1/admin/megaphone", adminTk, map[string]any{"cells": []string{"zz"}}, http.StatusBadRequest)
	c.call(http.MethodPost, "/v1/admin/megaphone/"+started["broadcast_id"].(string)+"/end", adminTk, nil, http.StatusNoContent)
	c.call(http.MethodPost, "/v1/admin/megaphone/"+started["broadcast_id"].(string)+"/end", adminTk, nil, http.StatusNotFound)
	c.call(http.MethodGet, "/v1/admin/megaphone?limit=10", adminTk, nil, http.StatusOK)
	c.call(http.MethodPost, "/v1/admin/megaphone", carlosTk, map[string]any{"cells": []string{cell.String()}}, http.StatusForbidden)

	// US4: sin Sentry configurado.
	s := c.call(http.MethodGet, "/v1/admin/health/sessions", adminTk, nil, http.StatusOK)
	assert.Equal(t, "not_configured", s["status"])

	// US5: dominios espejo y la lista firmada pública.
	a := c.call(http.MethodPost, "/v1/admin/domains", adminTk, map[string]any{"api_url": "https://api.kyq.co", "realtime_url": "wss://rt.kyq.co/connection/websocket", "active": true}, http.StatusCreated)
	b := c.call(http.MethodPost, "/v1/admin/domains", adminTk, map[string]any{"api_url": "https://espejo.kyq.co", "realtime_url": "wss://rt2.kyq.co/connection/websocket", "active": true}, http.StatusCreated)
	c.call(http.MethodPost, "/v1/admin/domains", adminTk, map[string]any{"api_url": "https://api.kyq.co", "realtime_url": "wss://x", "active": true}, http.StatusConflict)
	c.call(http.MethodPut, "/v1/admin/domains/order", adminTk, map[string]any{"ids": []any{b["id"], a["id"]}}, http.StatusOK)
	c.call(http.MethodPut, "/v1/admin/domains/"+b["id"].(string), adminTk, map[string]any{"api_url": "https://espejo.kyq.co", "realtime_url": "wss://rt2.kyq.co/connection/websocket", "active": false}, http.StatusOK)
	e = c.call(http.MethodPut, "/v1/admin/domains/"+a["id"].(string), adminTk, map[string]any{"api_url": "https://api.kyq.co", "realtime_url": "wss://rt.kyq.co/connection/websocket", "active": false}, http.StatusConflict)
	assert.Equal(t, "last_active_domain", e["code"])
	c.call(http.MethodDelete, "/v1/admin/domains/"+b["id"].(string), adminTk, nil, http.StatusNoContent)
	listing := c.call(http.MethodGet, "/v1/admin/domains", adminTk, nil, http.StatusOK)
	assert.Equal(t, true, listing["signing_configured"])
	signed := c.call(http.MethodGet, "/v1/domains", "", nil, http.StatusOK)
	p, err := domains.Verify(signer.PublicKey(), domains.Signed{Payload: signed["payload"].(string), Signature: signed["signature"].(string)})
	require.NoError(t, err)
	assert.Equal(t, []domains.Entry{{APIURL: "https://api.kyq.co", RealtimeURL: "wss://rt.kyq.co/connection/websocket"}}, p.Domains)
}
