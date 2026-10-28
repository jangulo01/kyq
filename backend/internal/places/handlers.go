package places

import (
	"errors"
	"net/http"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
)

// Handlers serves GET /v1/places (passengers and drivers).
type Handlers struct{ Service *Service }

// Register mounts the route behind authMW and the role check.
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	mux.Handle("GET /v1/places", authMW(auth.RequireRole(auth.RolePassenger, auth.RoleDriver)(http.HandlerFunc(h.search))))
}

func (h *Handlers) search(w http.ResponseWriter, r *http.Request) {
	out, err := h.Service.Search(r.Context(), r.URL.Query().Get("q"))
	switch {
	case errors.Is(err, ErrQueryTooShort):
		httpx.WriteError(w, http.StatusBadRequest, "query_too_short", "escribe al menos 3 caracteres")
	case errors.Is(err, ErrUnavailable):
		httpx.WriteError(w, http.StatusServiceUnavailable, "places_unavailable", "el buscador de direcciones no está disponible; marca el punto en el mapa")
	case err != nil:
		httpx.InternalError(w, r, err)
	default:
		httpx.WriteJSON(w, http.StatusOK, out)
	}
}
