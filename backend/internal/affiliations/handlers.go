package affiliations

import (
	"errors"
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
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	p, _ := auth.FromContext(r.Context())
	driver, created, err := h.Service.Affiliate(r.Context(), p.UserID, body.QRToken)
	if errors.Is(err, ErrDriverNotFound) {
		httpx.WriteError(w, http.StatusNotFound, "driver_not_found", "ese código no corresponde a un conductor Kyq")
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
