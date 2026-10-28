package notify

import (
	"net/http"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
	"github.com/kyq/backend/internal/store"
)

// Handlers serves the driver notices.
type Handlers struct{ Service *Service }

// Register mounts the routes behind authMW and the driver role check.
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	driver := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleDriver)(f)) }
	mux.Handle("GET /v1/driver/notices", driver(h.list))
	mux.Handle("POST /v1/driver/notices/{noticeId}/read", driver(h.read))
}

func (h *Handlers) list(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	rows, err := h.Service.Store.ListNotices(r.Context(), p.UserID)
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	out := make([]View, len(rows))
	for i, n := range rows {
		out[i] = ToView(n)
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) read(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	id, err := uuid.Parse(r.PathValue("noticeId"))
	if err != nil {
		httpx.WriteError(w, http.StatusNotFound, "not_found", "aviso no encontrado")
		return
	}
	n, err := h.Service.Store.MarkNoticeRead(r.Context(), store.MarkNoticeReadParams{ID: id, DriverID: p.UserID, ReadAt: timestamptz(h.Service.now())})
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	if n == 0 {
		httpx.WriteError(w, http.StatusNotFound, "not_found", "aviso no encontrado")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
