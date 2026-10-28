package ptt_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/ptt"
)

// 003 (research R4): la grabación SOS es un RoomCompositeEgress solo audio en OGG hacia el
// bucket por defecto del servicio egress.
func TestAudioEgressCalls(t *testing.T) {
	var paths []string
	var start map[string]any
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		paths = append(paths, r.URL.Path)
		claims := jwt.MapClaims{}
		_, err := jwt.ParseWithClaims(strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer "), claims,
			func(*jwt.Token) (any, error) { return []byte("secret"), nil })
		require.NoError(t, err)
		if strings.Contains(r.URL.Path, "livekit.Egress") {
			assert.Equal(t, true, claims["video"].(map[string]any)["roomRecord"], "permiso de grabación")
		}
		switch {
		case strings.HasSuffix(r.URL.Path, "/StartRoomCompositeEgress"):
			require.NoError(t, json.NewDecoder(r.Body).Decode(&start))
			_, _ = w.Write([]byte(`{"egress_id":"EG_1","room_name":"sos-1"}`))
		case strings.HasSuffix(r.URL.Path, "/StopEgress"):
			w.WriteHeader(http.StatusPreconditionFailed) // ya terminó
		case strings.HasSuffix(r.URL.Path, "/CreateRoom"):
			var body map[string]any
			require.NoError(t, json.NewDecoder(r.Body).Decode(&body))
			assert.EqualValues(t, ptt.SOSRoomMaxParticipants, body["max_participants"], "operadores y grabador caben")
			_, _ = w.Write([]byte(`{}`))
		}
	}))
	defer srv.Close()
	lk := ptt.LiveKit{APIURL: srv.URL, APIKey: "devkey", APISecret: "secret"}
	ctx := context.Background()

	require.NoError(t, lk.CreateSOSRoom(ctx, "sos-1"))
	id, err := lk.StartAudioEgress(ctx, "sos-1", "sos/1.ogg")
	require.NoError(t, err)
	assert.Equal(t, "EG_1", id)
	assert.Equal(t, true, start["audio_only"])
	assert.Equal(t, "sos-1", start["room_name"])
	out := start["file_outputs"].([]any)[0].(map[string]any)
	assert.Equal(t, "OGG", out["file_type"])
	assert.Equal(t, "sos/1.ogg", out["filepath"])
	assert.NoError(t, lk.StopEgress(ctx, "EG_1"), "una grabación ya terminada cuenta como detenida")
	assert.Equal(t, []string{
		"/twirp/livekit.RoomService/CreateRoom", "/twirp/livekit.Egress/StartRoomCompositeEgress", "/twirp/livekit.Egress/StopEgress",
	}, paths)
}
