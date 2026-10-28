package affiliations

import (
	"errors"
	"html/template"
	"net/http"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
)

// Handlers serves /v1/affiliations (passengers) and /v1/driver/clients (drivers).
type Handlers struct{ Service *Service }

// Register mounts the routes on mux behind authMW and the role checks.
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	passenger := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RolePassenger)(f)) }
	driver := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleDriver)(f)) }
	mux.Handle("GET /v1/affiliations", passenger(h.list))
	mux.Handle("POST /v1/affiliations", passenger(h.create))
	mux.Handle("DELETE /v1/affiliations/{driverId}", passenger(h.remove))
	mux.Handle("GET /v1/driver/clients", driver(h.clients))
	// 008: página pública del enlace de un conductor (sin datos de contacto).
	mux.HandleFunc("GET /a/{token}", h.linkPage)
}

func (h *Handlers) list(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.ChosenDrivers(r.Context(), p.UserID)
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) create(w http.ResponseWriter, r *http.Request) {
	var body struct {
		QRToken string `json:"qr_token"`
		// 008: qr_scan (por defecto) o link; con trip_id, después del viaje.
		Source Source    `json:"source"`
		TripID uuid.UUID `json:"trip_id"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	p, _ := auth.FromContext(r.Context())
	var driver ChosenDriver
	var created bool
	var err error
	switch {
	case body.TripID != uuid.Nil:
		driver, created, err = h.Service.AffiliateAfterTrip(r.Context(), p.UserID, body.TripID)
	case body.Source == "" || body.Source == SourceQRScan || body.Source == SourceLink:
		if body.Source == "" {
			body.Source = SourceQRScan
		}
		driver, created, err = h.Service.AffiliateFrom(r.Context(), p.UserID, body.QRToken, body.Source)
	default:
		httpx.WriteError(w, http.StatusBadRequest, "invalid_source", "origen inválido: qr_scan o link")
		return
	}
	if errors.Is(err, ErrTripNotFound) {
		httpx.WriteError(w, http.StatusNotFound, "trip_not_found", "no encontramos ese viaje terminado")
		return
	}
	if errors.Is(err, ErrDriverNotFound) {
		httpx.WriteError(w, http.StatusNotFound, "driver_not_found", "ese código no corresponde a un conductor Kyq")
		return
	}
	if errors.Is(err, ErrDriverNotAvailable) {
		httpx.WriteError(w, http.StatusConflict, "driver_not_available",
			"este conductor aún no puede recibir clientes: tiene documentos o suscripción pendientes")
		return
	}
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	status := http.StatusOK
	if created {
		status = http.StatusCreated
	}
	httpx.WriteJSON(w, status, driver)
}

func (h *Handlers) remove(w http.ResponseWriter, r *http.Request) {
	driverID, err := uuid.Parse(r.PathValue("driverId"))
	if err != nil {
		httpx.WriteError(w, http.StatusNotFound, "not_found", "conductor no encontrado en tu lista")
		return
	}
	p, _ := auth.FromContext(r.Context())
	err = h.Service.Remove(r.Context(), p.UserID, driverID)
	if errors.Is(err, ErrNotAffiliated) {
		httpx.WriteError(w, http.StatusNotFound, "not_found", "conductor no encontrado en tu lista")
		return
	}
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handlers) clients(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.Clients(r.Context(), p.UserID)
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

// linkPageTemplate is the public page of a driver's link (008, FR-015). It only shows the name:
// no phone, photo or plate (FR-017).
var linkPageTemplate = template.Must(template.New("link").Parse(`<!doctype html>
<html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Kyq</title>
<style>body{font-family:system-ui,sans-serif;max-width:28rem;margin:3rem auto;padding:0 1rem;color:#1f2933}
a.btn{display:block;text-align:center;background:#1565c0;color:#fff;padding:.9rem;border-radius:.5rem;text-decoration:none;margin:1.5rem 0}</style>
</head><body>
{{if .Name}}<h1>{{.Name}} te invita a Kyq</h1>
<p>Guárdalo como tu Conductor Elegido: verás cuándo está libre y le pedirás viajes directamente.</p>
<a class="btn" href="kyq://affiliate/{{.Token}}">Abrir en Kyq Pasajero</a>
<p>¿Aún no tienes Kyq Pasajero? Instálalo y vuelve a abrir este enlace.</p>
{{else}}<h1>Este conductor no está disponible</h1>
<p>El enlace no corresponde a un conductor que pueda recibir clientes ahora.</p>{{end}}
</body></html>`))

func (h *Handlers) linkPage(w http.ResponseWriter, r *http.Request) {
	token := r.PathValue("token")
	name, err := h.Service.PublicDriver(r.Context(), token)
	status := http.StatusOK
	switch {
	case errors.Is(err, ErrDriverNotFound) || errors.Is(err, ErrDriverNotAvailable):
		name, status = "", http.StatusNotFound
	case err != nil:
		httpx.InternalError(w, r, err)
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(status)
	_ = linkPageTemplate.Execute(w, struct{ Name, Token string }{name, token})
}
