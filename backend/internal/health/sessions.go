package health

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"
)

// Parámetros de las sesiones sin fallos (009, US4).
const (
	CrashFreeTarget  = 0.99
	SessionsCacheTTL = 5 * time.Minute
	SessionsTimeout  = 5 * time.Second
)

// Estados del informe de sesiones.
const (
	SessionsOK            = "ok"
	SessionsNotConfigured = "not_configured"
	SessionsUnavailable   = "unavailable"
)

// Apps de Kyq en orden de presentación.
var sessionApps = []string{"driver", "rider", "admin"}

// AppSessions is the crash-free rate of one app (contracts: AppSessions).
type AppSessions struct {
	App          string   `json:"app"`
	CrashFree24h *float64 `json:"crash_free_24h"`
	CrashFree7d  *float64 `json:"crash_free_7d"`
	TopRelease   *string  `json:"top_release"`
	// BelowTarget: algún porcentaje por debajo del 99 % (FR-017).
	BelowTarget bool   `json:"below_target"`
	Link        string `json:"link"`
}

// SessionsReport is GET /v1/admin/health/sessions (contracts: SessionsReport).
type SessionsReport struct {
	Status    string        `json:"status"`
	CheckedAt time.Time     `json:"checked_at"`
	Target    float64       `json:"target"`
	Apps      []AppSessions `json:"apps"`
}

// ParseProjects reads KYQ_SENTRY_PROJECTS: "driver=ID,rider=ID,admin=ID".
func ParseProjects(raw string) (map[string]string, error) {
	out := map[string]string{}
	for _, part := range strings.Split(raw, ",") {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		app, id, ok := strings.Cut(part, "=")
		if !ok || strings.TrimSpace(id) == "" {
			return nil, fmt.Errorf("KYQ_SENTRY_PROJECTS: %q no es app=id", part)
		}
		out[strings.TrimSpace(app)] = strings.TrimSpace(id)
	}
	return out, nil
}

// Sessions reads the crash-free rate of each app from the Sentry sessions API (research R6),
// with a cache. Without token or projects it reports "not_configured"; on any error,
// "unavailable" and never the raw error (FR-018).
type Sessions struct {
	APIURL   string
	Token    string
	Org      string
	Projects map[string]string
	HTTP     *http.Client
	Now      func() time.Time

	mu     sync.Mutex
	cached *SessionsReport
}

func (s *Sessions) now() time.Time {
	if s.Now != nil {
		return s.Now()
	}
	return time.Now()
}

// Report returns the cached report or reads it again.
func (s *Sessions) Report(ctx context.Context) SessionsReport {
	now := s.now()
	if s.Token == "" || s.Org == "" || len(s.Projects) == 0 {
		return SessionsReport{Status: SessionsNotConfigured, CheckedAt: now, Target: CrashFreeTarget, Apps: []AppSessions{}}
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.cached != nil && now.Sub(s.cached.CheckedAt) < SessionsCacheTTL {
		return *s.cached
	}
	ctx, cancel := context.WithTimeout(ctx, SessionsTimeout)
	defer cancel()
	report := SessionsReport{Status: SessionsOK, CheckedAt: now, Target: CrashFreeTarget, Apps: []AppSessions{}}
	for _, app := range sessionApps {
		project, ok := s.Projects[app]
		if !ok {
			continue
		}
		a, err := s.app(ctx, app, project)
		if err != nil {
			return SessionsReport{Status: SessionsUnavailable, CheckedAt: now, Target: CrashFreeTarget, Apps: []AppSessions{}}
		}
		report.Apps = append(report.Apps, a)
	}
	s.cached = &report
	return report
}

func (s *Sessions) app(ctx context.Context, app, project string) (AppSessions, error) {
	out := AppSessions{App: app, Link: strings.TrimRight(s.APIURL, "/") + "/organizations/" + url.PathEscape(s.Org) + "/releases/?project=" + url.QueryEscape(project)}
	for _, period := range []string{"24h", "7d"} {
		rate, err := s.crashFree(ctx, project, period)
		if err != nil {
			return AppSessions{}, err
		}
		if period == "24h" {
			out.CrashFree24h = rate
		} else {
			out.CrashFree7d = rate
		}
		if rate != nil && *rate < CrashFreeTarget {
			out.BelowTarget = true
		}
	}
	release, err := s.topRelease(ctx, project)
	if err != nil {
		return AppSessions{}, err
	}
	out.TopRelease = release
	return out, nil
}

type sessionsResponse struct {
	Groups []struct {
		By     map[string]any      `json:"by"`
		Totals map[string]*float64 `json:"totals"`
	} `json:"groups"`
}

func (s *Sessions) query(ctx context.Context, params url.Values) (sessionsResponse, error) {
	u := strings.TrimRight(s.APIURL, "/") + "/api/0/organizations/" + url.PathEscape(s.Org) + "/sessions/?" + params.Encode()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u, nil)
	if err != nil {
		return sessionsResponse{}, err
	}
	req.Header.Set("Authorization", "Bearer "+s.Token)
	client := s.HTTP
	if client == nil {
		client = http.DefaultClient
	}
	res, err := client.Do(req)
	if err != nil {
		return sessionsResponse{}, err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		return sessionsResponse{}, errors.New("sentry sessions: " + res.Status)
	}
	var out sessionsResponse
	return out, json.NewDecoder(res.Body).Decode(&out)
}

const crashFreeField = "crash_free_rate(session)"

func (s *Sessions) crashFree(ctx context.Context, project, period string) (*float64, error) {
	res, err := s.query(ctx, url.Values{"project": {project}, "field": {crashFreeField}, "statsPeriod": {period}, "interval": {"1d"}})
	if err != nil {
		return nil, err
	}
	if len(res.Groups) == 0 {
		return nil, nil
	}
	return res.Groups[0].Totals[crashFreeField], nil
}

func (s *Sessions) topRelease(ctx context.Context, project string) (*string, error) {
	res, err := s.query(ctx, url.Values{
		"project": {project}, "field": {"sum(session)"}, "groupBy": {"release"}, "orderBy": {"-sum(session)"},
		"per_page": {"1"}, "statsPeriod": {"7d"}, "interval": {"1d"},
	})
	if err != nil {
		return nil, err
	}
	if len(res.Groups) == 0 {
		return nil, nil
	}
	if r, ok := res.Groups[0].By["release"].(string); ok && r != "" {
		return &r, nil
	}
	return nil, nil
}
