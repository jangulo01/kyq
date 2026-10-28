package health

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/auth"
)

const secret = "llave-super-secreta"

// fakeServers answers like each dependency; status by path lets a test break one.
func fakeServer(t *testing.T, status map[string]int, delay time.Duration) *httptest.Server {
	t.Helper()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if delay > 0 {
			time.Sleep(delay)
		}
		code := http.StatusOK
		for prefix, c := range status {
			if strings.HasPrefix(r.URL.Path, prefix) {
				code = c
			}
		}
		if r.URL.Path == "/api/info" && r.Header.Get("X-API-Key") != secret {
			code = http.StatusUnauthorized
		}
		if strings.HasPrefix(r.URL.Path, "/online/") && r.Header.Get("Authorization") != "x-api-key "+secret {
			code = http.StatusForbidden
		}
		w.WriteHeader(code)
		_, _ = w.Write([]byte(`{}`))
	}))
	t.Cleanup(srv.Close)
	return srv
}

type pinger struct{ err error }

func (p pinger) Ping(context.Context) error { return p.err }

func probes(srv *httptest.Server, db Probe, storage Pinger, boldOn bool) []Named {
	c := srv.Client()
	return []Named{
		{Name: Database, Probe: db},
		{Name: Centrifugo, Probe: CentrifugoProbe(c, srv.URL+"/api", secret)},
		{Name: LiveKit, Probe: LiveKitProbe(c, srv.URL)},
		{Name: OSRM, Probe: OSRMProbe(c, srv.URL, 4.6, -74.08)},
		{Name: Storage, Probe: StorageProbe(storage)},
		{Name: Bold, Probe: BoldProbe(c, boldOn, srv.URL, secret)},
	}
}

func okDB(context.Context) (string, error) { return "disponible", nil }

func byName(r Report) map[string]Check {
	out := map[string]Check{}
	for _, c := range r.Checks {
		out[c.Name] = c
	}
	return out
}

// US5-1 y US5-3: todo disponible; Bold desactivado no cuenta como fallo.
func TestAllUp(t *testing.T) {
	srv := fakeServer(t, nil, 0)
	r := (&Checker{Probes: probes(srv, okDB, pinger{}, false)}).Run(context.Background())
	assert.Equal(t, StatusOK, r.Status)
	require.Len(t, r.Checks, 6)
	for _, c := range r.Checks {
		if c.Name == Bold {
			assert.Equal(t, StatusDisabled, c.Status)
			assert.Nil(t, c.LatencyMs)
			continue
		}
		assert.Equal(t, StatusOK, c.Status, c.Name)
		require.NotNil(t, c.LatencyMs, c.Name)
		assert.GreaterOrEqual(t, *c.LatencyMs, int64(0))
	}
	assert.Equal(t, []string{Database, Centrifugo, LiveKit, OSRM, Storage, Bold}, []string{
		r.Checks[0].Name, r.Checks[1].Name, r.Checks[2].Name, r.Checks[3].Name, r.Checks[4].Name, r.Checks[5].Name,
	}, "el orden de las comprobaciones se conserva")

	r = (&Checker{Probes: probes(srv, okDB, pinger{}, true)}).Run(context.Background())
	assert.Equal(t, StatusOK, byName(r)[Bold].Status, "Bold activo y llave aceptada")
}

// US5-2: una dependencia caída degrada; OSRM fuera de cobertura (400) sigue disponible.
func TestDegradedAndDetails(t *testing.T) {
	srv := fakeServer(t, map[string]int{"/route/": http.StatusBadRequest, "/api/info": http.StatusServiceUnavailable}, 0)
	r := (&Checker{Probes: probes(srv, okDB, pinger{errors.New("dial tcp minio:9000: " + secret)}, true)}).Run(context.Background())
	checks := byName(r)
	assert.Equal(t, StatusDegraded, r.Status)
	assert.Equal(t, StatusDown, checks[Centrifugo].Status)
	assert.Equal(t, "HTTP 503", checks[Centrifugo].Detail)
	assert.Equal(t, StatusOK, checks[OSRM].Status, "400 fuera de cobertura: el servicio responde")
	assert.Equal(t, StatusDown, checks[Storage].Status)
	assert.Equal(t, "bucket no disponible", checks[Storage].Detail)

	// FR-020: ningún secreto ni URL en la respuesta.
	raw, err := json.Marshal(r)
	require.NoError(t, err)
	assert.NotContains(t, string(raw), secret)
	assert.NotContains(t, string(raw), srv.URL)
	assert.NotContains(t, string(raw), "minio")
}

func TestBoldKeyRejectedAndUnreachable(t *testing.T) {
	srv := fakeServer(t, nil, 0)
	c := srv.Client()
	r := (&Checker{Probes: []Named{
		{Name: Bold, Probe: BoldProbe(c, true, srv.URL, "otra")},
		{Name: LiveKit, Probe: LiveKitProbe(c, "http://127.0.0.1:1")},
		{Name: OSRM, Probe: OSRMProbe(c, "", 0, 0)},
	}}).Run(context.Background())
	checks := byName(r)
	assert.Equal(t, "llave rechazada", checks[Bold].Detail)
	assert.Equal(t, StatusDown, checks[LiveKit].Status)
	assert.Equal(t, "sin conexión", checks[LiveKit].Detail)
	assert.Equal(t, StatusDisabled, checks[OSRM].Status, "sin URL configurada")
	assert.Equal(t, StatusDegraded, r.Status)
}

// FR-018: cada comprobación se corta a su límite y se informa como caída por tiempo.
func TestTimeout(t *testing.T) {
	srv := fakeServer(t, nil, 300*time.Millisecond)
	start := time.Now()
	r := (&Checker{Timeout: 50 * time.Millisecond, Probes: []Named{
		{Name: LiveKit, Probe: LiveKitProbe(srv.Client(), srv.URL)},
		{Name: Centrifugo, Probe: CentrifugoProbe(srv.Client(), srv.URL+"/api", secret)},
		{Name: Storage, Probe: func(ctx context.Context) (string, error) { <-ctx.Done(); return "", ctx.Err() }},
	}}).Run(context.Background())
	assert.Less(t, time.Since(start), 250*time.Millisecond, "en paralelo y cortadas al límite")
	for _, c := range r.Checks {
		assert.Equal(t, StatusDown, c.Status, c.Name)
		assert.Equal(t, "sin respuesta en 0 s", c.Detail, c.Name)
	}
}

// FR-019: la base de datos caída tumba el estado global.
func TestOverall(t *testing.T) {
	assert.Equal(t, StatusOK, Overall([]Check{{Name: Database, Status: StatusOK}, {Name: Bold, Status: StatusDisabled}}))
	assert.Equal(t, StatusDegraded, Overall([]Check{{Name: Database, Status: StatusOK}, {Name: OSRM, Status: StatusDown}}))
	assert.Equal(t, StatusDown, Overall([]Check{{Name: OSRM, Status: StatusDown}, {Name: Database, Status: StatusDown}}))
}

func TestHandlerAdminOnly(t *testing.T) {
	issuer := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), nil)
	mux := http.NewServeMux()
	(&Handlers{Checker: &Checker{Probes: []Named{{Name: Database, Probe: okDB}}}}).Register(mux, auth.RequireAuth(issuer))
	get := func(role string) *httptest.ResponseRecorder {
		tok, err := issuer.IssueAccess(auth.Principal{UserID: uuid.New(), Role: role})
		require.NoError(t, err)
		req := httptest.NewRequest(http.MethodGet, "/v1/admin/health", nil)
		req.Header.Set("Authorization", "Bearer "+tok)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		return rec
	}
	rec := get(auth.RoleAdmin)
	require.Equal(t, http.StatusOK, rec.Code)
	var r Report
	require.NoError(t, json.NewDecoder(rec.Body).Decode(&r))
	assert.Equal(t, StatusOK, r.Status)
	assert.Equal(t, http.StatusForbidden, get(auth.RoleDriver).Code)
}

func TestCityCenter(t *testing.T) {
	lat, lng := CityCenter("lima")
	assert.Less(t, lat, 0.0)
	assert.Less(t, lng, -70.0)
	lat, _ = CityCenter("desconocida")
	assert.Greater(t, lat, 4.0, "Bogotá por defecto")
}
