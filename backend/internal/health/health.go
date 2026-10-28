// Package health implements the Healthline page of the admin panel (spec 007, US5): the state
// and latency of every dependency, checked in parallel.
package health

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
)

// Timeout is the limit of each check (FR-018).
const Timeout = 3 * time.Second

// Estados de una comprobación y global.
const (
	StatusOK       = "ok"
	StatusDown     = "down"
	StatusDisabled = "disabled"
	StatusDegraded = "degraded"
)

// Nombres de las dependencias.
const (
	Database   = "database"
	Centrifugo = "centrifugo"
	LiveKit    = "livekit"
	OSRM       = "osrm"
	Storage    = "storage"
	Bold       = "bold"
)

// ErrDisabled marks a dependency turned off by configuration (not a failure).
var ErrDisabled = errors.New("disabled")

// Probe checks one dependency. It returns a short detail for the panel (never a raw error,
// which may hold internal URLs) and an error when the dependency is down.
type Probe func(ctx context.Context) (detail string, err error)

// Check is one dependency in the report (contracts: HealthCheck).
type Check struct {
	Name      string `json:"name"`
	Status    string `json:"status"`
	LatencyMs *int64 `json:"latency_ms"`
	Detail    string `json:"detail"`
}

// Report is GET /v1/admin/health (contracts: HealthReport).
type Report struct {
	Status    string    `json:"status"`
	CheckedAt time.Time `json:"checked_at"`
	Checks    []Check   `json:"checks"`
}

// Named is a probe with its dependency name, in display order.
type Named struct {
	Name  string
	Probe Probe
}

// Checker runs the probes.
type Checker struct {
	Probes  []Named
	Timeout time.Duration
	Now     func() time.Time
}

func (c *Checker) now() time.Time {
	if c.Now != nil {
		return c.Now()
	}
	return time.Now()
}

// Run checks every dependency in parallel, each with its own time limit.
func (c *Checker) Run(ctx context.Context) Report {
	timeout := c.Timeout
	if timeout == 0 {
		timeout = Timeout
	}
	checks := make([]Check, len(c.Probes))
	var wg sync.WaitGroup
	for i, p := range c.Probes {
		wg.Go(func() {
			checks[i] = runOne(ctx, p, timeout)
		})
	}
	wg.Wait()
	return Report{Status: Overall(checks), CheckedAt: c.now().UTC(), Checks: checks}
}

func runOne(ctx context.Context, p Named, timeout time.Duration) Check {
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	start := time.Now()
	type result struct {
		detail string
		err    error
	}
	done := make(chan result, 1)
	go func() {
		d, err := p.Probe(ctx)
		done <- result{d, err}
	}()
	var res result
	select {
	case res = <-done:
	case <-ctx.Done():
		res = result{err: ctx.Err()}
	}
	ms := time.Since(start).Milliseconds()
	switch {
	case errors.Is(res.err, ErrDisabled):
		return Check{Name: p.Name, Status: StatusDisabled, Detail: orDefault(res.detail, "desactivado en la configuración")}
	case errors.Is(res.err, context.DeadlineExceeded):
		return Check{Name: p.Name, Status: StatusDown, LatencyMs: &ms, Detail: fmt.Sprintf("sin respuesta en %d s", int(timeout.Seconds()))}
	case res.err != nil:
		return Check{Name: p.Name, Status: StatusDown, LatencyMs: &ms, Detail: orDefault(res.detail, "no disponible")}
	default:
		return Check{Name: p.Name, Status: StatusOK, LatencyMs: &ms, Detail: orDefault(res.detail, "disponible")}
	}
}

func orDefault(s, d string) string {
	if strings.TrimSpace(s) == "" {
		return d
	}
	return s
}

// Overall is down when the database is down, degraded when any other dependency is down and ok
// otherwise (FR-019).
func Overall(checks []Check) string {
	status := StatusOK
	for _, c := range checks {
		if c.Status != StatusDown {
			continue
		}
		if c.Name == Database {
			return StatusDown
		}
		status = StatusDegraded
	}
	return status
}

// Handlers serves GET /v1/admin/health and, with Sessions, GET /v1/admin/health/sessions (admin
// only).
type Handlers struct {
	Checker  *Checker
	Sessions *Sessions
}

// Register mounts the routes behind authMW and the admin role check.
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	mux.Handle("GET /v1/admin/health", authMW(auth.RequireRole(auth.RoleAdmin)(http.HandlerFunc(h.health))))
	mux.Handle("GET /v1/admin/health/sessions", authMW(auth.RequireRole(auth.RoleAdmin)(http.HandlerFunc(h.sessions))))
}

// sessions is the crash-free rate per app (009, US4).
func (h *Handlers) sessions(w http.ResponseWriter, r *http.Request) {
	s := h.Sessions
	if s == nil {
		s = &Sessions{}
	}
	httpx.WriteJSON(w, http.StatusOK, s.Report(r.Context()))
}

func (h *Handlers) health(w http.ResponseWriter, r *http.Request) {
	httpx.WriteJSON(w, http.StatusOK, h.Checker.Run(r.Context()))
}
