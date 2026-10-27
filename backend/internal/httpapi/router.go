// Package httpapi wires the HTTP routes of every backend module.
package httpapi

import (
	"log/slog"
	"net/http"

	"github.com/kyq/backend/internal/admin"
	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/realtime"
)

// Deps are the module handlers. Nil modules are not mounted.
type Deps struct {
	Logger   *slog.Logger
	Tokens   *auth.TokenIssuer
	Auth     *auth.Handlers
	Realtime *realtime.Handlers
	Admin    *admin.Handlers
}

// NewRouter returns the root handler with every module mounted and the common middleware.
func NewRouter(d Deps) http.Handler {
	logger := d.Logger
	if logger == nil {
		logger = slog.Default()
	}
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"status":"ok"}`))
	})

	if d.Auth != nil {
		d.Auth.Register(mux)
	}
	if d.Tokens != nil {
		requireAuth := auth.RequireAuth(d.Tokens)
		if d.Realtime != nil {
			d.Realtime.Register(mux, requireAuth)
		}
		if d.Admin != nil {
			d.Admin.Register(mux, requireAuth)
		}
	}

	return Chain(mux, RequestID, Recover(logger), Logging(logger))
}
