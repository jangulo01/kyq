package megaphone

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
)

// Handlers serves /v1/admin/megaphone (admins only).
type Handlers struct{ Service *Service }

// Register mounts the routes behind authMW and the admin role check.
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	admin := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleAdmin)(f)) }
	mux.Handle("POST /v1/admin/megaphone", admin(h.start))
	mux.Handle("POST /v1/admin/megaphone/{broadcastId}/end", admin(h.end))
	mux.Handle("GET /v1/admin/megaphone", admin(h.list))
}

func (h *Handlers) start(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Cells []string `json:"cells"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.Start(r.Context(), p.UserID, body.Cells)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, out)
}

func (h *Handlers) end(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(r.PathValue("broadcastId"))
	if err != nil {
		writeError(w, r, ErrNotFound)
		return
	}
	if err := h.Service.End(r.Context(), id); err != nil {
		writeError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handlers) list(w http.ResponseWriter, r *http.Request) {
	limit := 50
	if v := r.URL.Query().Get("limit"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil || n < 1 || n > 200 {
			httpx.WriteError(w, http.StatusBadRequest, "invalid_limit", "limit de 1 a 200")
			return
		}
		limit = n
	}
	out, err := h.Service.List(r.Context(), limit)
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func writeError(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, ErrInvalidCells):
		httpx.WriteError(w, http.StatusBadRequest, "invalid_cells", "elige de 1 a 50 hexágonos de la misma resolución (6 a 9)")
	case errors.Is(err, ErrOnAir):
		httpx.WriteError(w, http.StatusConflict, "on_air", "ya tienes un comunicado en curso")
	case errors.Is(err, ErrNoRecipients):
		httpx.WriteError(w, http.StatusConflict, "no_recipients", "no hay conductores conectados en esas zonas")
	case errors.Is(err, ErrNotFound):
		httpx.WriteError(w, http.StatusNotFound, "broadcast_not_found", "comunicado no encontrado o ya terminado")
	default:
		httpx.InternalError(w, r, err)
	}
}
