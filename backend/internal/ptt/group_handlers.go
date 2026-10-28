package ptt

import (
	"errors"
	"net/http"
	"time"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
)

// GroupHandlers serves /v1/driver/cooperative/ptt/*: the group channel of the caller's
// cooperative (COOP_GROUP, 006).
type GroupHandlers struct{ Service *Service }

func (h *GroupHandlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	driver := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleDriver)(f)) }
	mux.Handle("POST /v1/driver/cooperative/ptt/token", driver(h.token))
	mux.Handle("POST /v1/driver/cooperative/ptt/floor", driver(h.takeFloor))
	mux.Handle("DELETE /v1/driver/cooperative/ptt/floor", driver(h.releaseFloor))
}

func (h *GroupHandlers) token(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	creds, err := h.Service.GroupToken(r.Context(), p.UserID)
	if err != nil {
		writeGroupError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, creds)
}

func (h *GroupHandlers) takeFloor(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	expires, err := h.Service.TakeGroupFloor(r.Context(), p.UserID)
	if err != nil {
		writeGroupError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, struct {
		ExpiresAt time.Time `json:"expires_at"`
	}{expires})
}

func (h *GroupHandlers) releaseFloor(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	if err := h.Service.ReleaseGroupFloor(r.Context(), p.UserID); err != nil {
		writeGroupError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func writeGroupError(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, ErrNoCooperative):
		httpx.WriteError(w, http.StatusNotFound, "no_cooperative", "no perteneces a una cooperativa activa")
	case errors.Is(err, ErrBusy):
		httpx.WriteError(w, http.StatusConflict, "ptt_busy", "otro compañero está hablando")
	case errors.Is(err, ErrUnavailable):
		httpx.WriteError(w, http.StatusServiceUnavailable, "ptt_unavailable", "el servidor de voz no responde, inténtalo de nuevo")
	default:
		httpx.InternalError(w, r, err)
	}
}
