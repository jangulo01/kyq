package radio

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"regexp"
	"strings"
	"sync"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/ptt"
)

// twirpRecorder is a LiveKit stand-in that keeps the body of every CreateRoom.
type twirpRecorder struct {
	mu     sync.Mutex
	bodies []map[string]any
}

func (t *twirpRecorder) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	raw, _ := io.ReadAll(r.Body)
	if strings.HasSuffix(r.URL.Path, "/CreateRoom") {
		var body map[string]any
		_ = json.Unmarshal(raw, &body)
		t.mu.Lock()
		t.bodies = append(t.bodies, body)
		t.mu.Unlock()
	}
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write([]byte(`{}`))
}

// RN-KYQ-017: Radio graba sus mensajes, pero el canal del viaje (001 FR-021) y la consulta previa
// (005 FR-008), que usan CreateRoom, nunca piden grabación a LiveKit.
func TestRN017TripAndPreconsultRoomsAreNotRecorded(t *testing.T) {
	rec := &twirpRecorder{}
	srv := httptest.NewServer(rec)
	defer srv.Close()
	lk := ptt.LiveKit{APIURL: srv.URL, APIKey: "devkey", APISecret: "secret"}
	ctx := context.Background()

	require.NoError(t, lk.CreateRoom(ctx, "trip-"+uuid.NewString()))
	require.NoError(t, lk.CreateRoom(ctx, "pre-"+uuid.NewString()))
	rooms := ptt.RadioRooms{LiveKit: lk, S3: ptt.RadioS3{Bucket: "kyq-radio"}}
	require.NoError(t, rooms.CreateRadioRoom(ctx, "radio-"+uuid.NewString()+"-abc", 2, true))

	require.Len(t, rec.bodies, 3)
	for _, b := range rec.bodies[:2] {
		assert.NotContains(t, b, "egress", "la sala %v no debe grabarse", b["name"])
	}
	egress, ok := rec.bodies[2]["egress"].(map[string]any)
	require.True(t, ok, "Radio sí registra cada mensaje")
	tracks := egress["tracks"].(map[string]any)
	assert.Equal(t, ptt.RadioFilepath, tracks["filepath"])
	assert.Equal(t, "kyq-radio", tracks["s3"].(map[string]any)["bucket"])
}

var phonePattern = regexp.MustCompile(`\+?57\s?3\d{2}\s?\d{3}\s?\d{4}|\+[1-9]\d{9,14}`)

// RN-KYQ-017 y FR-004: ninguna respuesta de /v1/radio/* trae el teléfono de nadie.
func TestIntegrationRN017NoPhonesInRadioResponses(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	conv := f.contact(t, f.carlos, f.jonathan)
	f.consent(t, f.carlos, f.jonathan)
	f.voice(t, f.carlos, conv, 2_000_000_000)
	ch, err := f.svc.CreateChannel(ctx, f.jonathan, ChannelInput{Name: ptr("Taxistas Norte")})
	require.NoError(t, err)

	mux := http.NewServeMux()
	as := func(user uuid.UUID, role string) func(http.Handler) http.Handler {
		return func(next http.Handler) http.Handler {
			return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				next.ServeHTTP(w, r.WithContext(auth.WithPrincipal(r.Context(), auth.Principal{UserID: user, Role: role})))
			})
		}
	}
	(&Handlers{Service: f.svc}).Register(mux, as(f.carlos, auth.RoleDriver))
	inv, err := f.svc.ChannelInvite(ctx, f.jonathan, ch.ID)
	require.NoError(t, err)
	for _, path := range []string{
		"/v1/radio/me",
		"/v1/radio/conversations",
		"/v1/radio/conversations/" + conv.String(),
		"/v1/radio/conversations/" + conv.String() + "/messages",
		"/v1/radio/invites/" + inv.Code,
		"/r/" + inv.Code,
	} {
		w := httptest.NewRecorder()
		mux.ServeHTTP(w, httptest.NewRequest(http.MethodGet, path, nil))
		require.Less(t, w.Code, 300, path)
		assert.False(t, phonePattern.MatchString(w.Body.String()), "%s contiene un teléfono: %s", path, w.Body.String())
	}
}
