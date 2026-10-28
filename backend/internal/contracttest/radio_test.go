package contracttest

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/getkin/kin-openapi/openapi3"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpapi"
	"github.com/kyq/backend/internal/ptt"
	"github.com/kyq/backend/internal/radio"
	"github.com/kyq/backend/internal/storage"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
)

func TestContract011ViewIsValid(t *testing.T) {
	loader := openapi3.NewLoader()
	loader.IsExternalRefsAllowed = true
	doc, err := loader.LoadFromFile("../../../specs/011-radio-kyq/contracts/api.yaml")
	require.NoError(t, err)
	require.NoError(t, doc.Validate(loader.Context))
}

// radioRooms is a LiveKit stand-in for Radio: every call succeeds.
type radioRooms struct{}

func (radioRooms) CreateRadioRoom(context.Context, string, int, bool) error  { return nil }
func (radioRooms) DeleteRoom(context.Context, string) error                  { return nil }
func (radioRooms) SetCanPublish(context.Context, string, string, bool) error { return nil }
func (radioRooms) RemoveParticipant(context.Context, string, string) error   { return nil }

// radioServer is the real router with Radio over a migrated schema: Carlos and Jonathan are
// drivers with subscription and Ana is a passenger.
type radioServer struct {
	st                     *store.Store
	svc                    *radio.Service
	c                      *contract
	carlos, jonathan, ana  uuid.UUID
	carlosTk, jonTk, anaTk string
	adminTk                string
	admin                  uuid.UUID
}

func newRadioServer(t *testing.T) *radioServer {
	t.Helper()
	st := testdb.New(t)
	ctx := context.Background()
	s := &radioServer{st: st, admin: uuid.New(), carlos: uuid.New(), jonathan: uuid.New(), ana: uuid.New()}
	for _, u := range []store.CreateUserParams{
		{ID: s.admin, PhoneE164: "+573000000000", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: s.carlos, PhoneE164: "+573100000001", Role: store.UserRoleDriver, DisplayName: "Carlos"},
		{ID: s.jonathan, PhoneE164: "+573100000002", Role: store.UserRoleDriver, DisplayName: "Jonathan"},
		{ID: s.ana, PhoneE164: "+573200000001", Role: store.UserRolePassenger, DisplayName: "Ana"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	for i, d := range []uuid.UUID{s.carlos, s.jonathan} {
		require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: d, QrToken: "qr-radio-c-00" + string(rune('1'+i)), VehiclePlate: "KYQ20" + string(rune('1'+i)), VehicleDescription: "Kia"}))
		require.NoError(t, st.UpsertSubscription(ctx, store.UpsertSubscriptionParams{DriverID: d, PaidUntil: time.Now().Add(30 * 24 * time.Hour), UpdatedBy: uuid.NullUUID{UUID: s.admin, Valid: true}}))
	}
	media, saved := storage.NewMemory(), storage.NewMemory()
	s.svc = &radio.Service{
		Store: st, LiveKit: ptt.LiveKit{APIKey: "devkey", APISecret: "secret"}, Rooms: radioRooms{}, VoiceURL: "ws://livekit.test",
		Media: radio.MemoryMedia{Memory: media, SavedBucket: saved}, Saved: saved, Record: false,
		PublicBaseURL: "https://kyq.test", PlayDriverURL: "https://play.test/d", PlayRiderURL: "https://play.test/r",
		Go: func(fn func()) { fn() },
	}
	tokens := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), nil)
	server := httpapi.NewRouter(httpapi.Deps{Tokens: tokens, Radio: &radio.Handlers{Service: s.svc}})
	s.c = load(t, server)
	tk := func(id uuid.UUID, role string) string {
		v, err := tokens.IssueAccess(auth.Principal{UserID: id, Role: role})
		require.NoError(t, err)
		return v
	}
	s.carlosTk, s.jonTk, s.anaTk = tk(s.carlos, auth.RoleDriver), tk(s.jonathan, auth.RoleDriver), tk(s.ana, auth.RolePassenger)
	s.adminTk = tk(s.admin, auth.RoleAdmin)
	return s
}

// T012–T020: Radio 1 a 1 por el router real contra el contrato fusionado.
func TestIntegration011RadioRoutesMatchContract(t *testing.T) {
	s := newRadioServer(t)
	c := s.c

	me := c.call(http.MethodGet, "/v1/radio/me", s.carlosTk, nil, http.StatusOK)
	assert.Equal(t, "full", me["access"])
	assert.Equal(t, true, me["consent_required"])
	c.call(http.MethodPost, "/v1/radio/me/consent", s.carlosTk, nil, http.StatusNoContent)
	c.call(http.MethodPost, "/v1/radio/me/consent", s.jonTk, nil, http.StatusNoContent)
	c.call(http.MethodPut, "/v1/radio/me", s.carlosTk, map[string]any{"status": "busy", "radio_on": true, "push_mode": "toggle"}, http.StatusOK)
	c.call(http.MethodPut, "/v1/radio/me", s.carlosTk, map[string]any{"status": "available"}, http.StatusOK)
	c.call(http.MethodPost, "/v1/radio/me/heartbeat", s.jonTk, nil, http.StatusNoContent)
	c.call(http.MethodPut, "/v1/radio/me/quiet-hours", s.carlosTk, []map[string]any{
		{"weekdays": []int{1, 2, 3, 4, 5}, "starts": "22:00", "ends": "06:00", "enabled": true},
	}, http.StatusNoContent)
	c.call(http.MethodGet, "/v1/radio/me/quiet-hours", s.carlosTk, nil, http.StatusOK)

	// Contacto por QR (FR-002) y por teléfono (202 sin revelar la cuenta).
	inv := c.call(http.MethodPost, "/v1/radio/contacts/invites", s.carlosTk, map[string]any{}, http.StatusCreated)
	code := inv["code"].(string)
	c.call(http.MethodPost, "/v1/radio/contacts/invites", s.carlosTk, map[string]any{"phone_e164": "+573005550001"}, http.StatusAccepted)
	c.call(http.MethodPost, "/v1/radio/contacts/invites", s.anaTk, map[string]any{}, http.StatusForbidden)
	c.call(http.MethodGet, "/v1/radio/invites/"+code, "", nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/radio/invites/ZZZZZZZZZZ", "", nil, http.StatusNotFound)
	conv := c.call(http.MethodPost, "/v1/radio/invites/"+code+"/accept", s.jonTk, nil, http.StatusOK)
	convID := conv["id"].(string)
	c.call(http.MethodGet, "/v1/radio/conversations", s.carlosTk, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/radio/conversations/"+convID, s.carlosTk, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/radio/conversations/"+convID, s.anaTk, nil, http.StatusNotFound)
	c.call(http.MethodPut, "/v1/radio/conversations/"+convID+"/listening", s.carlosTk, map[string]any{"listening": false}, http.StatusNoContent)

	// Voz: token, turno, ocupado y mensaje (sin registro: listo al soltar con su duración).
	cred := c.call(http.MethodPost, "/v1/radio/conversations/"+convID+"/ptt/token", s.carlosTk, nil, http.StatusOK)
	assert.True(t, strings.HasPrefix(cred["room"].(string), "radio-"))
	floor := c.call(http.MethodPost, "/v1/radio/conversations/"+convID+"/ptt/floor", s.carlosTk, nil, http.StatusOK)
	busy := c.call(http.MethodPost, "/v1/radio/conversations/"+convID+"/ptt/floor", s.jonTk, nil, http.StatusConflict)
	assert.Equal(t, "floor_busy", busy["code"])
	assert.Equal(t, "Carlos", busy["holder_name"])
	s.svc.TrackPublished(context.Background(), cred["room"].(string), s.carlos.String())
	c.call(http.MethodDelete, "/v1/radio/conversations/"+convID+"/ptt/floor", s.carlosTk, nil, http.StatusNoContent)
	_ = floor

	// Texto, ubicación, alerta y límites (FR-022, FR-023).
	text := c.call(http.MethodPost, "/v1/radio/conversations/"+convID+"/messages", s.jonTk, map[string]any{"kind": "text", "body": "voy tarde 10 min"}, http.StatusCreated)
	c.call(http.MethodPost, "/v1/radio/conversations/"+convID+"/messages", s.jonTk, map[string]any{"kind": "location", "lat": 4.65, "lng": -74.05}, http.StatusCreated)
	for range 3 {
		c.call(http.MethodPost, "/v1/radio/conversations/"+convID+"/messages", s.jonTk, map[string]any{"kind": "alert", "body": "llámame"}, http.StatusCreated)
	}
	c.call(http.MethodPost, "/v1/radio/conversations/"+convID+"/messages", s.jonTk, map[string]any{"kind": "alert"}, http.StatusTooManyRequests)
	c.call(http.MethodPost, "/v1/radio/conversations/"+convID+"/messages", s.jonTk, map[string]any{"kind": "text", "body": ""}, http.StatusBadRequest)

	c.call(http.MethodGet, "/v1/radio/conversations/"+convID+"/messages?limit=10", s.carlosTk, nil, http.StatusOK)
	msgID := text["id"].(string)
	c.call(http.MethodPut, "/v1/radio/messages/"+msgID+"/receipt", s.carlosTk, map[string]any{"heard": true, "saved": true}, http.StatusNoContent)
	c.call(http.MethodGet, "/v1/radio/messages/"+msgID+"/media", s.carlosTk, nil, http.StatusNotFound)

	// Página del enlace (R9): HTML con el enlace profundo y la tienda, sin teléfonos.
	inv2 := c.call(http.MethodPost, "/v1/radio/contacts/invites", s.carlosTk, map[string]any{}, http.StatusCreated)
	rec := httptest.NewRecorder()
	c.server.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/r/"+inv2["code"].(string), nil))
	require.Equal(t, http.StatusOK, rec.Code)
	assert.Contains(t, rec.Body.String(), "kyq://radio/"+inv2["code"].(string))
	assert.Contains(t, rec.Body.String(), "referrer=radio%3D"+inv2["code"].(string))

	// Radio con mis clientes (FR-003).
	require.NoError(t, s.st.InsertAffiliation(context.Background(), store.InsertAffiliationParams{PassengerID: s.ana, DriverID: s.carlos}))
	c.call(http.MethodPut, "/v1/radio/clients", s.carlosTk, map[string]any{"enabled": true}, http.StatusNoContent)
	c.call(http.MethodPut, "/v1/radio/clients", s.anaTk, map[string]any{"enabled": true}, http.StatusForbidden)
	c.call(http.MethodPut, "/v1/radio/clients/"+s.ana.String(), s.carlosTk, map[string]any{"muted": true}, http.StatusNoContent)
	c.call(http.MethodPut, "/v1/radio/clients/"+s.jonathan.String(), s.carlosTk, map[string]any{"blocked": true}, http.StatusNotFound)

	// Borrar el contacto (FR-002).
	c.call(http.MethodDelete, "/v1/radio/conversations/"+convID, s.carlosTk, nil, http.StatusNoContent)
	c.call(http.MethodGet, "/v1/radio/conversations/"+convID, s.jonTk, nil, http.StatusNotFound)
	c.call(http.MethodGet, "/v1/radio/me", s.adminTk, nil, http.StatusForbidden)
}
