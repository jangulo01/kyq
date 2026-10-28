// Package httpapi wires the HTTP routes of every backend module.
package httpapi

import (
	"log/slog"
	"net/http"

	"github.com/kyq/backend/internal/admin"
	"github.com/kyq/backend/internal/affiliations"
	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/billing"
	"github.com/kyq/backend/internal/control"
	"github.com/kyq/backend/internal/cooperatives"
	"github.com/kyq/backend/internal/crm"
	"github.com/kyq/backend/internal/domains"
	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/health"
	"github.com/kyq/backend/internal/kyc"
	"github.com/kyq/backend/internal/megaphone"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/places"
	"github.com/kyq/backend/internal/ptt"
	"github.com/kyq/backend/internal/radio"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/reservations"
	"github.com/kyq/backend/internal/safety"
	"github.com/kyq/backend/internal/support"
	"github.com/kyq/backend/internal/telemetry"
	"github.com/kyq/backend/internal/trippay"
	"github.com/kyq/backend/internal/trips"
)

// Deps are the module handlers. Nil modules are not mounted.
type Deps struct {
	Logger *slog.Logger
	// CORSOrigins: orígenes del panel web que pueden llamar a la API (vacío: sin CORS).
	CORSOrigins []string
	Tokens      *auth.TokenIssuer
	Auth        *auth.Handlers
	Realtime    *realtime.Handlers
	Admin       *admin.Handlers
	Affils      *affiliations.Handlers
	Drivers     *drivers.Handlers
	Presence    *drivers.Presence
	Trips       *trips.Handlers
	PTT         *ptt.Handlers
	Usage       *telemetry.Handlers
	// 002: alta y KYC, suscripción y pagos (incluye el webhook público de Bold), avisos y costos.
	KYC     *kyc.Handlers
	Billing *billing.Handlers
	Notices *notify.Handlers
	Costs   *telemetry.CostHandlers
	// 007: torre de control, fidelización y moderación, y salud (solo admins).
	Tower  *control.Handlers
	CRM    *crm.Handlers
	Health *health.Handlers
	// 006: cooperativas, membresías y canal PTT de grupo.
	Cooperatives *cooperatives.Handlers
	GroupPTT     *ptt.GroupHandlers
	// 003: SOS, consola de emergencias, viaje compartido (incluye rutas públicas) y seguridad.
	Safety *safety.Handlers
	// 004: pago del viaje con Bold o en efectivo, libro de liquidación y giros.
	TripPay *trippay.Handlers
	// 009: centro de soporte y disputas (usuarios, también suspendidos, y panel).
	Support *support.Handlers
	// 009: megáfono de voz a zonas H3 (solo admins).
	Megaphone *megaphone.Handlers
	// 009: dominios espejo; la lista firmada GET /v1/domains es pública.
	Domains *domains.Handlers
	// 010: agenda de reservas y buscador de direcciones.
	Reservations *reservations.Handlers
	Places       *places.Handlers
	// 011: Radio Kyq (incluye la página pública /r/{code} de las invitaciones).
	Radio *radio.Handlers
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
		if d.Tower != nil {
			d.Tower.Register(mux, requireAuth)
		}
		if d.CRM != nil {
			d.CRM.Register(mux, requireAuth)
		}
		if d.Health != nil {
			d.Health.Register(mux, requireAuth)
		}
		if d.Cooperatives != nil {
			d.Cooperatives.Register(mux, requireAuth)
		}
		if d.GroupPTT != nil {
			d.GroupPTT.Register(mux, requireAuth)
		}
		if d.Safety != nil {
			d.Safety.Register(mux, requireAuth)
		}
		if d.TripPay != nil {
			d.TripPay.Register(mux, requireAuth)
		}
		if d.Support != nil {
			d.Support.Register(mux, requireAuth)
		}
		if d.Megaphone != nil {
			d.Megaphone.Register(mux, requireAuth)
		}
		if d.Domains != nil {
			d.Domains.Register(mux, requireAuth)
		}
		if d.Reservations != nil {
			d.Reservations.Register(mux, requireAuth)
		}
		if d.Places != nil {
			d.Places.Register(mux, requireAuth)
		}
		if d.Radio != nil {
			d.Radio.Register(mux, requireAuth)
		}
	}

	return Chain(mux, RequestID, Recover(logger), Logging(logger), CORS(d.CORSOrigins))
}
