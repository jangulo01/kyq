// Package httpapi wires the HTTP routes of every backend module.
package httpapi

import (
	"log/slog"
	"net/http"

	"github.com/kyq/backend/internal/admin"
	"github.com/kyq/backend/internal/affiliations"
	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/billing"
	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/kyc"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/ptt"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/telemetry"
	"github.com/kyq/backend/internal/trippay"
	"github.com/kyq/backend/internal/trips"
)

// Deps are the module handlers. Nil modules are not mounted.
type Deps struct {
	Logger   *slog.Logger
	Tokens   *auth.TokenIssuer
	Auth     *auth.Handlers
	Realtime *realtime.Handlers
	Admin    *admin.Handlers
	Affils   *affiliations.Handlers
	Drivers  *drivers.Handlers
	Presence *drivers.Presence
	Trips    *trips.Handlers
	PTT      *ptt.Handlers
	Usage    *telemetry.Handlers
	// 002: alta y KYC, suscripción y pagos (incluye el webhook público de Bold), avisos y costos.
	KYC     *kyc.Handlers
	Billing *billing.Handlers
	Notices *notify.Handlers
	Costs   *telemetry.CostHandlers
	// 004: pago del viaje con Bold o en efectivo, libro de liquidación y giros.
	TripPay *trippay.Handlers
	// LiveKitWebhook is public: LiveKit authenticates it with its own signature.
	LiveKitWebhook *telemetry.LiveKitWebhook
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
	if d.LiveKitWebhook != nil {
		d.LiveKitWebhook.Register(mux)
	}
	if d.Tokens != nil {
		requireAuth := auth.RequireAuth(d.Tokens)
		if d.Realtime != nil {
			d.Realtime.Register(mux, requireAuth)
		}
		if d.Admin != nil {
			d.Admin.Register(mux, requireAuth)
		}
		if d.Affils != nil {
			d.Affils.Register(mux, requireAuth)
		}
		if d.Drivers != nil {
			d.Drivers.Register(mux, requireAuth)
		}
		if d.Presence != nil {
			d.Presence.Register(mux, requireAuth)
		}
		if d.Trips != nil {
			d.Trips.Register(mux, requireAuth)
		}
		if d.PTT != nil {
			d.PTT.Register(mux, requireAuth)
		}
		if d.Usage != nil {
			d.Usage.Register(mux, requireAuth)
		}
		if d.KYC != nil {
			d.KYC.Register(mux, requireAuth)
		}
		if d.Billing != nil {
			d.Billing.Register(mux, requireAuth)
		}
		if d.Notices != nil {
			d.Notices.Register(mux, requireAuth)
		}
		if d.Costs != nil {
			d.Costs.Register(mux, requireAuth)
		}
		if d.TripPay != nil {
			d.TripPay.Register(mux, requireAuth)
		}
	}

	return Chain(mux, RequestID, Recover(logger), Logging(logger))
}
