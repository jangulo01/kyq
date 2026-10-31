package reservations

import (
	"errors"
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
	"github.com/kyq/backend/internal/trips"
)

// Handlers serves /v1/reservations (passengers) and /v1/driver/reservations (drivers).
type Handlers struct{ Service *Service }

// Register mounts the routes behind authMW and the role checks.
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	passenger := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RolePassenger)(f)) }
	driver := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleDriver)(f)) }
	mux.Handle("POST /v1/reservations", passenger(h.create))
	mux.Handle("GET /v1/reservations", passenger(h.list))
	mux.Handle("POST /v1/reservations/{reservationId}/cancel", passenger(h.cancel))
	mux.Handle("GET /v1/driver/reservations", driver(h.agenda))
	mux.Handle("POST /v1/driver/reservations/{reservationId}/accept", driver(h.decide(true)))
	mux.Handle("POST /v1/driver/reservations/{reservationId}/reject", driver(h.decide(false)))
	mux.Handle("POST /v1/driver/reservations/{reservationId}/cancel", driver(h.cancel))
}

func (h *Handlers) create(w http.ResponseWriter, r *http.Request) {
	var body struct {
		DriverID     uuid.UUID    `json:"driver_id"`
		Pickup       *trips.Point `json:"pickup"`
		Dropoff      *trips.Point `json:"dropoff"`
		PickupLabel  string       `json:"pickup_label"`
		DropoffLabel string       `json:"dropoff_label"`
		ScheduledAt  time.Time    `json:"scheduled_at"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	if body.DriverID == uuid.Nil || body.Pickup == nil || body.Dropoff == nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_reservation", "indica conductor, origen, destino y hora")
		return
	}
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.Create(r.Context(), p.UserID, NewReservation{
		DriverID: body.DriverID, Pickup: *body.Pickup, Dropoff: *body.Dropoff,
		PickupLabel: body.PickupLabel, DropoffLabel: body.DropoffLabel, ScheduledAt: body.ScheduledAt,
	})
	respond(w, r, http.StatusCreated, out, err)
}

func (h *Handlers) list(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.PassengerList(r.Context(), p.UserID)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) agenda(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.Agenda(r.Context(), p.UserID)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) decide(accept bool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, err := uuid.Parse(r.PathValue("reservationId"))
		if err != nil {
			writeError(w, r, ErrNotFound)
			return
		}
		p, _ := auth.FromContext(r.Context())
		out, err := h.Service.Decide(r.Context(), p.UserID, id, accept)
		respond(w, r, http.StatusOK, out, err)
	}
}

func (h *Handlers) cancel(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(r.PathValue("reservationId"))
	if err != nil {
		writeError(w, r, ErrNotFound)
		return
	}
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.Cancel(r.Context(), p.UserID, id)
	respond(w, r, http.StatusOK, out, err)
}

func respond(w http.ResponseWriter, r *http.Request, status int, out any, err error) {
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, status, out)
}

func writeError(w http.ResponseWriter, r *http.Request, err error) {
	known := []struct {
		target        error
		status        int
		code, message string
	}{
		{ErrInvalidTime, http.StatusBadRequest, "invalid_time", "reserva entre 30 minutos y 7 días desde ahora"},
		{ErrInvalidLabel, http.StatusBadRequest, "invalid_reservation", "dirección de hasta 200 caracteres"},
		{ErrTooMany, http.StatusConflict, "too_many_reservations", "ya tienes 3 reservas activas"},
		{ErrNotAffiliated, http.StatusForbidden, "not_affiliated", "solo puedes reservar con tus Conductores Elegidos"},
		{ErrNotFound, http.StatusNotFound, "reservation_not_found", "reserva no encontrada"},
		{ErrInvalidState, http.StatusConflict, "invalid_state", "la reserva ya cambió"},
		{trips.ErrCityNotConfigured, http.StatusServiceUnavailable, "city_not_configured", "la ciudad aún no tiene tarifas"},
		{trips.ErrNoRoute, http.StatusUnprocessableEntity, "no_route", "no encontramos una ruta por carretera"},
	}
	for _, k := range known {
		if errors.Is(err, k.target) {
			httpx.WriteError(w, k.status, k.code, k.message)
			return
		}
	}
	httpx.InternalError(w, r, err)
}
