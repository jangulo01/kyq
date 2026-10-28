package crm

import (
	"errors"
	"net/http"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
	"github.com/kyq/backend/internal/store"
)

// Periodo por defecto y máximo del informe de fidelización (FR-010).
const (
	DefaultPeriod = 12 * 7 * 24 * time.Hour
	MaxPeriodDays = 366
)

// Handlers serves the loyalty report and the moderation routes (admin only).
type Handlers struct {
	Store      *store.Store
	Moderation *Moderation
	Now        func() time.Time
}

func (h *Handlers) now() time.Time {
	if h.Now != nil {
		return h.Now()
	}
	return time.Now()
}

// Register mounts the routes behind authMW and the admin role check.
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	admin := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleAdmin)(f)) }
	mux.Handle("GET /v1/admin/crm", admin(h.report))
	mux.Handle("GET /v1/admin/users", admin(h.searchUsers))
	mux.Handle("POST /v1/admin/users/{userId}/suspend", admin(h.suspend))
	mux.Handle("POST /v1/admin/users/{userId}/reactivate", admin(h.reactivate))
	mux.Handle("GET /v1/admin/users/{userId}/moderation", admin(h.history))
}

func (h *Handlers) report(w http.ResponseWriter, r *http.Request) {
	now := h.now().UTC()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	day := func(name string, fallback time.Time) (time.Time, bool) {
		v := r.URL.Query().Get(name)
		if v == "" {
			return fallback, true
		}
		t, err := time.Parse(time.DateOnly, v)
		return t, err == nil
	}
	to, ok1 := day("to", today)
	from, ok2 := day("from", to.Add(-DefaultPeriod).AddDate(0, 0, 1))
	if !ok1 || !ok2 || to.Before(from) || to.Sub(from) >= MaxPeriodDays*24*time.Hour {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_range", "fechas AAAA-MM-DD, from <= to y como máximo 366 días")
		return
	}
	rep, err := BuildReport(r.Context(), h.Store.Queries, from, to, now)
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, rep)
}

func (h *Handlers) searchUsers(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	role, status := q.Get("role"), q.Get("status")
	switch {
	case utf8.RuneCountInString(q.Get("q")) > 60:
		httpx.WriteError(w, http.StatusBadRequest, "invalid_query", "q admite como máximo 60 caracteres")
		return
	case role != "" && role != auth.RolePassenger && role != auth.RoleDriver && role != auth.RoleAdmin:
		httpx.WriteError(w, http.StatusBadRequest, "invalid_role", "role debe ser passenger, driver o admin")
		return
	case status != "" && status != "active" && status != "suspended":
		httpx.WriteError(w, http.StatusBadRequest, "invalid_status", "status debe ser active o suspended")
		return
	}
	users, err := h.Moderation.Search(r.Context(), q.Get("q"), role, status)
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, users)
}

func (h *Handlers) suspend(w http.ResponseWriter, r *http.Request) { h.moderate(w, r, true) }

func (h *Handlers) reactivate(w http.ResponseWriter, r *http.Request) { h.moderate(w, r, false) }

func (h *Handlers) moderate(w http.ResponseWriter, r *http.Request, suspend bool) {
	userID, err := uuid.Parse(r.PathValue("userId"))
	if err != nil {
		httpx.WriteError(w, http.StatusNotFound, "not_found", "usuario no encontrado")
		return
	}
	var body struct {
		Reason string `json:"reason"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	p, _ := auth.FromContext(r.Context())
	var user ModeratedUser
	if suspend {
		user, err = h.Moderation.Suspend(r.Context(), userID, p.UserID, body.Reason)
	} else {
		user, err = h.Moderation.Reactivate(r.Context(), userID, p.UserID, body.Reason)
	}
	if writeModerationError(w, r, err) {
		return
	}
	httpx.WriteJSON(w, http.StatusOK, user)
}

func (h *Handlers) history(w http.ResponseWriter, r *http.Request) {
	userID, err := uuid.Parse(r.PathValue("userId"))
	if err != nil {
		httpx.WriteError(w, http.StatusNotFound, "not_found", "usuario no encontrado")
		return
	}
	actions, err := h.Moderation.History(r.Context(), userID)
	if writeModerationError(w, r, err) {
		return
	}
	httpx.WriteJSON(w, http.StatusOK, actions)
}

// writeModerationError writes the response for err and reports whether there was one.
func writeModerationError(w http.ResponseWriter, r *http.Request, err error) bool {
	switch {
	case err == nil:
		return false
	case errors.Is(err, ErrInvalidReason):
		httpx.WriteError(w, http.StatusBadRequest, "invalid_reason", "indica un motivo de 3 a 500 caracteres")
	case errors.Is(err, ErrUserNotFound):
		httpx.WriteError(w, http.StatusNotFound, "not_found", "usuario no encontrado")
	case errors.Is(err, ErrCannotModerate):
		httpx.WriteError(w, http.StatusConflict, "cannot_moderate_admin", "no se puede suspender a un administrador")
	case errors.Is(err, ErrAlreadySuspended):
		httpx.WriteError(w, http.StatusConflict, "already_suspended", "el usuario ya está suspendido")
	case errors.Is(err, ErrNotSuspended):
		httpx.WriteError(w, http.StatusConflict, "not_suspended", "el usuario no está suspendido")
	default:
		httpx.InternalError(w, r, err)
	}
	return true
}
