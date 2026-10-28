package ptt

import (
	"errors"
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
)

// registerPreconsults monta las rutas de la pre-consulta (specs/005-ptt-extras/contracts).
func (h *Handlers) registerPreconsults(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	role := func(r string, f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(r)(f)) }
	party := func(f http.HandlerFunc) http.Handler { return authMW(f) }
	mux.Handle("GET /v1/driver/preconsults/settings", role(auth.RoleDriver, h.preconsultSettings))
	mux.Handle("PUT /v1/driver/preconsults/settings", role(auth.RoleDriver, h.setPreconsultSettings))
	mux.Handle("PUT /v1/driver/clients/{passengerId}/preconsults", role(auth.RoleDriver, h.setClientPreconsults))
	mux.Handle("GET /v1/driver/preconsults", role(auth.RoleDriver, h.driverPreconsults))
	mux.Handle("GET /v1/preconsults/drivers", role(auth.RolePassenger, h.preconsultDrivers))
	mux.Handle("POST /v1/preconsults", role(auth.RolePassenger, h.openPreconsult))
	mux.Handle("GET /v1/preconsults/{preconsultId}", party(h.getPreconsult))
	mux.Handle("POST /v1/preconsults/{preconsultId}/end", party(h.endPreconsult))
	mux.Handle("POST /v1/preconsults/{preconsultId}/ptt/token", party(h.preconsultToken))
	mux.Handle("POST /v1/preconsults/{preconsultId}/ptt/floor", party(h.takePreconsultFloor))
	mux.Handle("DELETE /v1/preconsults/{preconsultId}/ptt/floor", party(h.releasePreconsultFloor))
}

func userID(r *http.Request) uuid.UUID {
	p, _ := auth.FromContext(r.Context())
	return p.UserID
}

func preconsultID(w http.ResponseWriter, r *http.Request) (uuid.UUID, bool) {
	id, err := uuid.Parse(r.PathValue("preconsultId"))
	if err != nil {
		httpx.WriteError(w, http.StatusNotFound, "not_found", "consulta no encontrada")
		return uuid.Nil, false
	}
	return id, true
}

func (h *Handlers) preconsultSettings(w http.ResponseWriter, r *http.Request) {
	out, err := h.Service.PreconsultSettings(r.Context(), userID(r))
	if err != nil {
		writePreconsultError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) setPreconsultSettings(w http.ResponseWriter, r *http.Request) {
	var body struct {
		AcceptsPreconsults *bool `json:"accepts_preconsults"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	if body.AcceptsPreconsults == nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_body", "falta accepts_preconsults")
		return
	}
	out, err := h.Service.SetAcceptsPreconsults(r.Context(), userID(r), *body.AcceptsPreconsults)
	if err != nil {
		writePreconsultError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) setClientPreconsults(w http.ResponseWriter, r *http.Request) {
	passenger, err := uuid.Parse(r.PathValue("passengerId"))
	if err != nil {
		httpx.WriteError(w, http.StatusNotFound, "not_found", "cliente no encontrado")
		return
	}
	var body struct {
		Blocked *bool `json:"blocked"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	if body.Blocked == nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_body", "falta blocked")
		return
	}
	if err := h.Service.SetPreconsultsBlocked(r.Context(), userID(r), passenger, *body.Blocked); err != nil {
		if errors.Is(err, ErrNotFound) {
			httpx.WriteError(w, http.StatusNotFound, "not_found", "cliente no encontrado")
			return
		}
		writePreconsultError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handlers) driverPreconsults(w http.ResponseWriter, r *http.Request) {
	out, err := h.Service.DriverPreconsults(r.Context(), userID(r))
	if err != nil {
		writePreconsultError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) preconsultDrivers(w http.ResponseWriter, r *http.Request) {
	ids, err := h.Service.PreconsultDrivers(r.Context(), userID(r))
	if err != nil {
		writePreconsultError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, struct {
		DriverIDs []uuid.UUID `json:"driver_ids"`
	}{ids})
}

func (h *Handlers) openPreconsult(w http.ResponseWriter, r *http.Request) {
	var body struct {
		DriverID uuid.UUID `json:"driver_id"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	if body.DriverID == uuid.Nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_body", "falta driver_id")
		return
	}
	out, created, err := h.Service.OpenPreconsult(r.Context(), userID(r), body.DriverID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			httpx.WriteError(w, http.StatusNotFound, "not_found", "no tienes a este conductor en tu lista")
			return
		}
		writePreconsultError(w, r, err)
		return
	}
	status := http.StatusOK
	if created {
		status = http.StatusCreated
	}
	httpx.WriteJSON(w, status, out)
}

func (h *Handlers) getPreconsult(w http.ResponseWriter, r *http.Request) {
	id, ok := preconsultID(w, r)
	if !ok {
		return
	}
	out, err := h.Service.GetPreconsult(r.Context(), userID(r), id)
	if err != nil {
		writePreconsultError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) endPreconsult(w http.ResponseWriter, r *http.Request) {
	id, ok := preconsultID(w, r)
	if !ok {
		return
	}
	out, err := h.Service.EndPreconsult(r.Context(), userID(r), id)
	if err != nil {
		writePreconsultError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) preconsultToken(w http.ResponseWriter, r *http.Request) {
	id, ok := preconsultID(w, r)
	if !ok {
		return
	}
	creds, err := h.Service.PreconsultToken(r.Context(), userID(r), id)
	if err != nil {
		writePreconsultError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, creds)
}

func (h *Handlers) takePreconsultFloor(w http.ResponseWriter, r *http.Request) {
	id, ok := preconsultID(w, r)
	if !ok {
		return
	}
	expires, err := h.Service.TakePreconsultFloor(r.Context(), userID(r), id)
	if err != nil {
		writePreconsultError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, struct {
		ExpiresAt time.Time `json:"expires_at"`
	}{expires})
}

func (h *Handlers) releasePreconsultFloor(w http.ResponseWriter, r *http.Request) {
	id, ok := preconsultID(w, r)
	if !ok {
		return
	}
	if err := h.Service.ReleasePreconsultFloor(r.Context(), userID(r), id); err != nil {
		writePreconsultError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func writePreconsultError(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, ErrNotFound):
		httpx.WriteError(w, http.StatusNotFound, "not_found", "consulta no encontrada")
	case errors.Is(err, ErrPreconsultsDisabled):
		httpx.WriteError(w, http.StatusForbidden, "preconsults_disabled", "este conductor no recibe consultas de voz")
	case errors.Is(err, ErrDriverUnavailable):
		httpx.WriteError(w, http.StatusConflict, "driver_unavailable", "el conductor no está libre ahora")
	case errors.Is(err, ErrPreconsultBusy):
		httpx.WriteError(w, http.StatusConflict, "preconsult_busy", "el conductor está atendiendo otra consulta, inténtalo en un momento")
	case errors.Is(err, ErrPreconsultInProgress):
		httpx.WriteError(w, http.StatusConflict, "preconsult_in_progress", "ya tienes una consulta abierta con otro conductor")
	case errors.Is(err, ErrRateLimited):
		httpx.WriteError(w, http.StatusTooManyRequests, "rate_limited", "has hecho varias consultas seguidas, inténtalo más tarde")
	case errors.Is(err, ErrPreconsultWaiting):
		httpx.WriteError(w, http.StatusConflict, "preconsult_waiting", "espera a que el conductor se conecte")
	case errors.Is(err, ErrBusy):
		httpx.WriteError(w, http.StatusConflict, "ptt_busy", "la otra persona está hablando")
	case errors.Is(err, ErrUnavailable):
		httpx.WriteError(w, http.StatusServiceUnavailable, "ptt_unavailable", "el servidor de voz no responde, inténtalo de nuevo")
	case errors.Is(err, ErrClosed):
		httpx.WriteError(w, http.StatusGone, "ptt_closed", "la consulta ya terminó")
	default:
		httpx.InternalError(w, r, err)
	}
}
