package telemetry_test

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/telemetry"
	"github.com/kyq/backend/internal/testdb"
)

// signed builds a request the way LiveKit signs its webhooks.
func signed(t *testing.T, secret string, body []byte) *http.Request {
	t.Helper()
	sum := sha256.Sum256(body)
	tok, err := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"iss": "devkey", "exp": time.Now().Add(time.Minute).Unix(), "sha256": base64.StdEncoding.EncodeToString(sum[:]),
	}).SignedString([]byte(secret))
	require.NoError(t, err)
	req := httptest.NewRequest(http.MethodPost, "/v1/livekit/webhook", bytes.NewReader(body))
	req.Header.Set("Authorization", tok)
	return req
}

func participantLeft(room string, joined, left int64) []byte {
	raw, _ := json.Marshal(map[string]any{
		"event": "participant_left", "createdAt": json.Number(itoa(left)),
		"room":        map[string]any{"name": room},
		"participant": map[string]any{"identity": "u1", "joinedAt": itoa(joined)}, // protojson: int64 como texto
	})
	return raw
}

func itoa(n int64) string { b, _ := json.Marshal(n); return string(b) }

func TestIntegrationVoiceMinutesFromLiveKitWebhook(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	driver, passenger, admin := uuid.New(), uuid.New(), uuid.New()
	for _, u := range []store.CreateUserParams{
		{ID: admin, PhoneE164: "+573000000001", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: driver, PhoneE164: "+573100000001", Role: store.UserRoleDriver, DisplayName: "Carlos"},
		{ID: passenger, PhoneE164: "+573200000002", Role: store.UserRolePassenger, DisplayName: "Ana"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: driver, QrToken: "qr-carlos-0000000", VehiclePlate: "KYQ001", VehicleDescription: "Kia"}))
	require.NoError(t, st.UpsertFareTable(ctx, store.UpsertFareTableParams{
		CityCode: "bogota", Currency: "COP", BaseMinor: 1, PerKmMinor: 1, PerMinuteMinor: 1, MinimumMinor: 1, RoundingMinor: 1, UpdatedBy: admin,
	}))
	tripID := uuid.New()
	require.NoError(t, st.InsertTrip(ctx, store.InsertTripParams{
		ID: tripID, PassengerID: passenger, DriverID: driver, CityCode: "bogota", Currency: "COP",
		PickupLat: 4.6, PickupLng: -74.08, DropoffLat: 4.65, DropoffLng: -74.05, RouteDistanceM: 1, RouteDurationS: 1,
		SuggestedFareMinor: 1, Status: store.TripStatusACCEPTED, CreatedAt: time.Now(),
	}))

	rec := &telemetry.Recorder{Store: st}
	hook := &telemetry.LiveKitWebhook{APIKey: "devkey", APISecret: "secret", Store: st, Usage: rec}
	mux := http.NewServeMux()
	hook.Register(mux)
	send := func(req *http.Request) int {
		w := httptest.NewRecorder()
		mux.ServeHTTP(w, req)
		return w.Code
	}

	room := "trip-" + tripID.String()
	assert.Equal(t, http.StatusUnauthorized, send(signed(t, "otro-secreto", participantLeft(room, 1000, 1090))), "firma de LiveKit obligatoria")
	tampered := signed(t, "secret", participantLeft(room, 1000, 1090))
	tampered.Body = http.NoBody
	assert.Equal(t, http.StatusUnauthorized, send(tampered), "el cuerpo debe coincidir con el sha256 firmado")

	// Las dos partes salen de la sala: LiveKit factura minutos de participante, ambos van al conductor.
	assert.Equal(t, http.StatusOK, send(signed(t, "secret", participantLeft(room, 1000, 1090))))
	assert.Equal(t, http.StatusOK, send(signed(t, "secret", participantLeft(room, 1000, 1030))))
	// 003: la voz de una sala SOS también cuenta en el conductor del viaje.
	alertID := uuid.New()
	_, err := st.InsertSOSAlert(ctx, store.InsertSOSAlertParams{
		ID: alertID, TripID: tripID, RaisedBy: passenger, RaisedRole: store.SosRolePassenger,
		RoomName: "sos-" + alertID.String(), CreatedAt: time.Now(),
	})
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, send(signed(t, "secret", participantLeft("sos-"+alertID.String(), 1000, 1060))))
	rec.Add(driver, telemetry.Events, 5)
	rec.Add(uuid.Nil, telemetry.Routes, 2)
	require.NoError(t, rec.Flush(ctx))
	rec.Add(driver, telemetry.Events, 1)
	require.NoError(t, rec.Flush(ctx), "un segundo vaciado suma, no reemplaza")

	tokens := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), nil)
	adminMux := http.NewServeMux()
	(&telemetry.Handlers{Store: st}).Register(adminMux, auth.RequireAuth(tokens))
	call := func(role string) *httptest.ResponseRecorder {
		tok, err := tokens.IssueAccess(auth.Principal{UserID: admin, Role: role})
		require.NoError(t, err)
		req := httptest.NewRequest(http.MethodGet, "/v1/admin/usage", nil)
		req.Header.Set("Authorization", "Bearer "+tok)
		w := httptest.NewRecorder()
		adminMux.ServeHTTP(w, req)
		return w
	}
	assert.Equal(t, http.StatusForbidden, call(auth.RoleDriver).Code)
	w := call(auth.RoleAdmin)
	require.Equal(t, http.StatusOK, w.Code)
	var rows []telemetry.DriverUsage
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &rows))
	require.Len(t, rows, 2)
	assert.Equal(t, driver, *rows[0].DriverID)
	assert.Equal(t, "Carlos", rows[0].DisplayName)
	assert.InDelta(t, 3.0, rows[0].VoiceMinutes, 0.001, "90 s + 30 s del PTT + 60 s del SOS")
	assert.Equal(t, int64(6), rows[0].RealtimeEvents)
	assert.Nil(t, rows[1].DriverID, "cotizaciones sin conductor")
	assert.Equal(t, int64(2), rows[1].RouteRequests)
}
