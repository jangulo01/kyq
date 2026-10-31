package health

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// fakeSentry answers the sessions API like Sentry (research R6).
func fakeSentry(t *testing.T, calls *atomic.Int32, fail bool) *httptest.Server {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		calls.Add(1)
		if r.Header.Get("Authorization") != "Bearer secreto" || r.URL.Path != "/api/0/organizations/kyq/sessions/" {
			w.WriteHeader(http.StatusForbidden)
			return
		}
		if fail {
			w.WriteHeader(http.StatusBadGateway)
			return
		}
		q := r.URL.Query()
		var body any
		switch {
		case q.Get("groupBy") == "release":
			body = map[string]any{"groups": []any{map[string]any{"by": map[string]any{"release": "kyq-driver@1.4.0+12"}, "totals": map[string]any{"sum(session)": 340}}}}
		case q.Get("project") == "1" && q.Get("statsPeriod") == "24h":
			body = map[string]any{"groups": []any{map[string]any{"by": map[string]any{}, "totals": map[string]any{crashFreeField: 0.985}}}}
		case q.Get("project") == "1":
			body = map[string]any{"groups": []any{map[string]any{"by": map[string]any{}, "totals": map[string]any{crashFreeField: 0.996}}}}
		default:
			body = map[string]any{"groups": []any{map[string]any{"by": map[string]any{}, "totals": map[string]any{crashFreeField: nil}}}}
		}
		_ = json.NewEncoder(w).Encode(body)
	}))
	t.Cleanup(srv.Close)
	return srv
}

// US4, FR-017, FR-018: porcentajes por app, resaltado bajo el 99 % y estados sin datos.
func TestSessionsReport(t *testing.T) {
	ctx := context.Background()
	assert.Equal(t, SessionsNotConfigured, (&Sessions{}).Report(ctx).Status)

	var calls atomic.Int32
	srv := fakeSentry(t, &calls, false)
	now := time.Date(2026, 10, 28, 12, 0, 0, 0, time.UTC)
	s := &Sessions{APIURL: srv.URL, Token: "secreto", Org: "kyq", Projects: map[string]string{"driver": "1", "rider": "2"}, Now: func() time.Time { return now }}
	r := s.Report(ctx)
	require.Equal(t, SessionsOK, r.Status)
	require.Len(t, r.Apps, 2)
	d := r.Apps[0]
	assert.Equal(t, "driver", d.App)
	assert.InDelta(t, 0.985, *d.CrashFree24h, 1e-9)
	assert.InDelta(t, 0.996, *d.CrashFree7d, 1e-9)
	assert.True(t, d.BelowTarget, "98,5 % < 99 %")
	assert.Equal(t, "kyq-driver@1.4.0+12", *d.TopRelease)
	assert.Contains(t, d.Link, "/organizations/kyq/releases/?project=1")
	assert.Nil(t, r.Apps[1].CrashFree24h, "sin sesiones no se inventa (edge case)")
	assert.False(t, r.Apps[1].BelowTarget)

	before := calls.Load()
	now = now.Add(time.Minute)
	s.Report(ctx)
	assert.Equal(t, before, calls.Load(), "caché de 5 min")

	var failing atomic.Int32
	down := &Sessions{APIURL: fakeSentry(t, &failing, true).URL, Token: "secreto", Org: "kyq", Projects: map[string]string{"admin": "3"}}
	r = down.Report(ctx)
	assert.Equal(t, SessionsUnavailable, r.Status)
	raw, err := json.Marshal(r)
	require.NoError(t, err)
	assert.NotContains(t, string(raw), "secreto", "FR-018: sin credenciales")

	p, err := ParseProjects(" driver=1, rider=2 ,admin=3")
	require.NoError(t, err)
	assert.Equal(t, map[string]string{"driver": "1", "rider": "2", "admin": "3"}, p)
	_, err = ParseProjects("driver")
	assert.Error(t, err)
}
