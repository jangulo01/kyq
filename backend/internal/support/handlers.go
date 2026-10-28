package support

import (
	"errors"
	"net/http"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
	"github.com/kyq/backend/internal/trippay"
)

// Handlers serves /v1/support/* (passengers and drivers, also suspended ones) and
// /v1/admin/support/* (admins).
type Handlers struct{ Service *Service }

// Register mounts the routes behind authMW and the role checks.
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	user := func(f http.HandlerFunc) http.Handler {
		return authMW(auth.RequireRole(auth.RolePassenger, auth.RoleDriver)(f))
	}
	admin := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleAdmin)(f)) }
	mux.Handle("GET /v1/support/cases", user(h.list))
	mux.Handle("POST /v1/support/cases", user(h.open))
	mux.Handle("GET /v1/support/cases/{caseId}", user(h.get))
	mux.Handle("POST /v1/support/cases/{caseId}/messages", user(h.reply))
	mux.Handle("GET /v1/support/trips", user(h.trips))
	mux.Handle("GET /v1/admin/support/cases", admin(h.inbox))
	mux.Handle("GET /v1/admin/support/cases/{caseId}", admin(h.adminGet))
	mux.Handle("POST /v1/admin/support/cases/{caseId}/messages", admin(h.adminReply))
	mux.Handle("POST /v1/admin/support/cases/{caseId}/status", admin(h.status))
	mux.Handle("POST /v1/admin/support/cases/{caseId}/assign", admin(h.assign))
	mux.Handle("POST /v1/admin/support/cases/{caseId}/resolve-payment", admin(h.resolvePayment))
}

func caseID(w http.ResponseWriter, r *http.Request) (uuid.UUID, bool) {
	id, err := uuid.Parse(r.PathValue("caseId"))
	if err != nil {
		writeError(w, r, ErrNotFound)
		return uuid.Nil, false
	}
	return id, true
}

func (h *Handlers) list(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.UserCases(r.Context(), p.UserID)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) open(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Topic       string     `json:"topic"`
		Description string     `json:"description"`
		TripID      *uuid.UUID `json:"trip_id"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.Open(r.Context(), p.UserID, body.Topic, body.Description, body.TripID)
	respond(w, r, http.StatusCreated, out, err)
}

func (h *Handlers) get(w http.ResponseWriter, r *http.Request) {
	id, ok := caseID(w, r)
	if !ok {
		return
	}
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.UserCase(r.Context(), p.UserID, id)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) reply(w http.ResponseWriter, r *http.Request) {
	id, ok := caseID(w, r)
	if !ok {
		return
	}
	var body struct {
		Body string `json:"body"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.UserReply(r.Context(), p.UserID, id, body.Body)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) trips(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.RecentTrips(r.Context(), p.UserID)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) inbox(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	f := Filter{
		Status: q.Get("status"), Topic: q.Get("topic"),
		Unanswered: q.Get("unanswered") == "true", IncludeClosed: q.Get("include_closed") == "true",
	}
	switch v := q.Get("assigned_to"); v {
	case "":
	case "me":
		p, _ := auth.FromContext(r.Context())
		f.AssignedTo = p.UserID
	default:
		id, err := uuid.Parse(v)
		if err != nil {
			httpx.WriteError(w, http.StatusBadRequest, "invalid_filter", "assigned_to: me o el id de un administrador")
			return
		}
		f.AssignedTo = id
	}
	out, err := h.Service.Inbox(r.Context(), f)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) adminGet(w http.ResponseWriter, r *http.Request) {
	id, ok := caseID(w, r)
	if !ok {
		return
	}
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.AdminCase(r.Context(), p.UserID, id)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) adminReply(w http.ResponseWriter, r *http.Request) {
	id, ok := caseID(w, r)
	if !ok {
		return
	}
	var body struct {
		Body     string `json:"body"`
		Internal bool   `json:"internal"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.AdminReply(r.Context(), p.UserID, id, body.Body, body.Internal)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) status(w http.ResponseWriter, r *http.Request) {
	id, ok := caseID(w, r)
	if !ok {
		return
	}
	var body struct {
		Status string `json:"status"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.SetStatus(r.Context(), p.UserID, id, body.Status)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) assign(w http.ResponseWriter, r *http.Request) {
	id, ok := caseID(w, r)
	if !ok {
		return
	}
	var body struct {
		AdminID *uuid.UUID `json:"admin_id"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	assignee := uuid.Nil
	if body.AdminID != nil {
		assignee = *body.AdminID
	}
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.Assign(r.Context(), p.UserID, id, assignee)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) resolvePayment(w http.ResponseWriter, r *http.Request) {
	id, ok := caseID(w, r)
	if !ok {
		return
	}
	var body struct {
		Outcome string `json:"outcome"`
		Note    string `json:"note"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.ResolvePayment(r.Context(), p.UserID, id, body.Outcome, body.Note)
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
		{ErrNotFound, http.StatusNotFound, "case_not_found", "caso no encontrado"},
		{ErrInvalidTopic, http.StatusBadRequest, "invalid_topic", "tema: trip, payment, lost_item, safety, account u other"},
		{ErrInvalidText, http.StatusBadRequest, "invalid_text", "escribe de 10 a 2 000 caracteres al abrir y hasta 2 000 en cada mensaje"},
		{ErrInvalidTrip, http.StatusBadRequest, "invalid_trip", "elige uno de tus viajes de los últimos 30 días"},
		{ErrCaseClosed, http.StatusConflict, "case_closed", "el caso está cerrado; abre uno nuevo"},
		{ErrInvalidStatus, http.StatusBadRequest, "invalid_status", "estado: open, in_progress, waiting_user, resolved o closed"},
		{ErrInvalidAssignee, http.StatusBadRequest, "invalid_assignee", "solo se asigna a administradores"},
		{ErrNotPaymentCase, http.StatusConflict, "not_payment_case", "el caso no está vinculado a un pago de viaje"},
		{trippay.ErrInvalidState, http.StatusConflict, "invalid_state", "el pago ya cambió de estado"},
		{trippay.ErrNoteRequired, http.StatusBadRequest, "note_required", "escribe una nota (máximo 200 caracteres)"},
		{trippay.ErrInvalidOutcome, http.StatusBadRequest, "invalid_outcome", "outcome: paid o unpaid"},
	}
	for _, k := range known {
		if errors.Is(err, k.target) {
			httpx.WriteError(w, k.status, k.code, k.message)
			return
		}
	}
	httpx.InternalError(w, r, err)
}
