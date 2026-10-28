package domains

import (
	"errors"
	"net/http"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
)

// Handlers serves /v1/admin/domains (admins) and the public signed list GET /v1/domains.
type Handlers struct{ Service *Service }

// Register mounts the routes; GET /v1/domains is public (the apps call it before logging in).
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	admin := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleAdmin)(f)) }
	mux.HandleFunc("GET /v1/domains", h.signed)
	mux.Handle("GET /v1/admin/domains", admin(h.list))
	mux.Handle("POST /v1/admin/domains", admin(h.create))
	mux.Handle("PUT /v1/admin/domains/order", admin(h.reorder))
	mux.Handle("PUT /v1/admin/domains/{domainId}", admin(h.update))
	mux.Handle("DELETE /v1/admin/domains/{domainId}", admin(h.delete))
}

type domainBody struct {
	APIURL      string `json:"api_url"`
	RealtimeURL string `json:"realtime_url"`
	Active      bool   `json:"active"`
}

func (h *Handlers) signed(w http.ResponseWriter, r *http.Request) {
	out, err := h.Service.SignedList(r.Context())
	if err != nil {
		writeError(w, r, err)
		return
	}
	w.Header().Set("Cache-Control", "no-store")
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) list(w http.ResponseWriter, r *http.Request) {
	out, err := h.Service.List(r.Context())
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) create(w http.ResponseWriter, r *http.Request) {
	var body domainBody
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	out, err := h.Service.Create(r.Context(), body.APIURL, body.RealtimeURL, body.Active)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, out)
}

func (h *Handlers) update(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(r.PathValue("domainId"))
	if err != nil {
		writeError(w, r, ErrNotFound)
		return
	}
	var body domainBody
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	out, err := h.Service.Update(r.Context(), id, body.APIURL, body.RealtimeURL, body.Active)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) delete(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(r.PathValue("domainId"))
	if err != nil {
		writeError(w, r, ErrNotFound)
		return
	}
	if err := h.Service.Delete(r.Context(), id); err != nil {
		writeError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handlers) reorder(w http.ResponseWriter, r *http.Request) {
	var body struct {
		IDs []uuid.UUID `json:"ids"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	if err := h.Service.Reorder(r.Context(), body.IDs); err != nil {
		writeError(w, r, err)
		return
	}
	h.list(w, r)
}

func writeError(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, ErrInvalidURL):
		httpx.WriteError(w, http.StatusBadRequest, "invalid_url", "API: https://dominio sin ruta; tiempo real: wss://dominio/…")
	case errors.Is(err, ErrDuplicate):
		httpx.WriteError(w, http.StatusConflict, "duplicate_domain", "ese dominio ya está en la lista")
	case errors.Is(err, ErrLastActive):
		httpx.WriteError(w, http.StatusConflict, "last_active_domain", "debe quedar al menos un dominio activo")
	case errors.Is(err, ErrNotFound):
		httpx.WriteError(w, http.StatusNotFound, "domain_not_found", "dominio no encontrado")
	case errors.Is(err, ErrInvalidOrder):
		httpx.WriteError(w, http.StatusBadRequest, "invalid_order", "el orden debe incluir cada dominio una vez")
	case errors.Is(err, ErrNotConfigured):
		httpx.WriteError(w, http.StatusServiceUnavailable, "domains_unavailable", "la lista de dominios no está configurada")
	default:
		httpx.InternalError(w, r, err)
	}
}
