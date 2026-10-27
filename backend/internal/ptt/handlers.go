package ptt

import (
	"errors"
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
)

// Handlers serves /v1/trips/{tripId}/ptt/*. Either party of the trip may call them.
type Handlers struct{ Service *Service }

func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	mux.Handle("POST /v1/trips/{tripId}/ptt/token", authMW(http.HandlerFunc(h.token)))
	mux.Handle("POST /v1/trips/{tripId}/ptt/floor", authMW(http.HandlerFunc(h.takeFloor)))
	mux.Handle("DELETE /v1/trips/{tripId}/ptt/floor", authMW(http.HandlerFunc(h.releaseFloor)))
}

func ids(w http.ResponseWriter, r *http.Request) (user, trip uuid.UUID, ok bool) {
	trip, err := uuid.Parse(r.PathValue("tripId"))
	if err != nil {
		httpx.WriteError(w, http.StatusNotFound, "not_found", "viaje no encontrado")
		return uuid.Nil, uuid.Nil, false
	}
	p, _ := auth.FromContext(r.Context())
	return p.UserID, trip, true
}

func (h *Handlers) token(w http.ResponseWriter, r *http.Request) {
	user, trip, ok := ids(w, r)
	if !ok {
		return
	}
	creds, err := h.Service.Token(r.Context(), user, trip)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, creds)
}

func (h *Handlers) takeFloor(w http.ResponseWriter, r *http.Request) {
	user, trip, ok := ids(w, r)
	if !ok {
		return
	}
	expires, err := h.Service.TakeFloor(r.Context(), user, trip)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, struct {
		ExpiresAt time.Time `json:"expires_at"`
	}{expires})
}

func (h *Handlers) releaseFloor(w http.ResponseWriter, r *http.Request) {
	user, trip, ok := ids(w, r)
	if !ok {
		return
	}
	if err := h.Service.ReleaseFloor(r.Context(), user, trip); err != nil {
		writeError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func writeError(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, ErrNotFound):
		httpx.WriteError(w, http.StatusNotFound, "not_found", "viaje no encontrado")
	case errors.Is(err, ErrNotOpen):
		httpx.WriteError(w, http.StatusConflict, "ptt_not_open", "el canal se abre cuando el conductor acepta")
	case errors.Is(err, ErrBusy):
		httpx.WriteError(w, http.StatusConflict, "ptt_busy", "la otra persona está hablando")
	case errors.Is(err, ErrUnavailable):
		httpx.WriteError(w, http.StatusServiceUnavailable, "ptt_unavailable", "el servidor de voz no responde, inténtalo de nuevo")
	case errors.Is(err, ErrClosed):
		httpx.WriteError(w, http.StatusGone, "ptt_closed", "el canal de voz de este viaje ya se cerró")
	default:
		httpx.InternalError(w, r, err)
	}
}
