package trippay

import (
	"errors"
	"net/http"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/billing"
	"github.com/kyq/backend/internal/httpx"
)

// Handlers serves the trip payment routes of passengers, drivers and admins
// (specs/004-trip-payment-cash/contracts/api.yaml).
type Handlers struct{ Service *Service }

// Register mounts the routes. Party checks per action live in Transition; non-participants get
// 404.
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	authed := func(f http.HandlerFunc) http.Handler { return authMW(f) }
	passenger := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RolePassenger)(f)) }
	driver := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleDriver)(f)) }
	admin := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleAdmin)(f)) }

	mux.Handle("GET /v1/trips/{tripId}/payment", authed(h.get))
	mux.Handle("POST /v1/trips/{tripId}/payment/bold", authed(h.bold))
	mux.Handle("POST /v1/trips/{tripId}/payment/refresh", authed(h.refresh))
	mux.Handle("POST /v1/trips/{tripId}/payment/cash", authed(h.act(ReportCash)))
	mux.Handle("POST /v1/trips/{tripId}/payment/cash-received", authed(h.act(ConfirmCash)))
	mux.Handle("POST /v1/trips/{tripId}/payment/cash-dispute", authed(h.act(DisputeCash)))
	mux.Handle("POST /v1/trips/{tripId}/payment/unpaid", authed(h.act(MarkUnpaid)))
	mux.Handle("GET /v1/trip-payments/pending", passenger(h.pending))
	mux.Handle("GET /v1/driver/payment-methods", driver(h.methods))
	mux.Handle("PUT /v1/driver/payment-methods", driver(h.setMethods))
	mux.Handle("GET /v1/driver/settlement", driver(h.driverSettlement))
	mux.Handle("GET /v1/admin/trip-payments", admin(h.adminList))
	mux.Handle("POST /v1/admin/trip-payments/{tripPaymentId}/resolve", admin(h.resolve))
	mux.Handle("POST /v1/admin/trip-payments/{tripPaymentId}/void", admin(h.void))
	mux.Handle("GET /v1/admin/settlements", admin(h.settlements))
	mux.Handle("GET /v1/admin/drivers/{driverId}/settlement", admin(h.adminSettlement))
	mux.Handle("POST /v1/admin/drivers/{driverId}/payouts", admin(h.payout))
}

func (h *Handlers) get(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "tripId")
	if !ok {
		return
	}
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.Get(r.Context(), p.UserID, id)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) bold(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "tripId")
	if !ok {
		return
	}
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.PayWithBold(r.Context(), p.UserID, id)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) refresh(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "tripId")
	if !ok {
		return
	}
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.Refresh(r.Context(), p.UserID, id)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) act(a Action) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, ok := pathID(w, r, "tripId")
		if !ok {
			return
		}
		p, _ := auth.FromContext(r.Context())
		out, err := h.Service.Act(r.Context(), p.UserID, id, a)
		respond(w, r, http.StatusOK, out, err)
	}
}

func (h *Handlers) pending(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.PendingForPassenger(r.Context(), p.UserID)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) methods(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.Methods(r.Context(), p.UserID)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) setMethods(w http.ResponseWriter, r *http.Request) {
	var body struct {
		AcceptsCash *bool `json:"accepts_cash"`
		AcceptsBold *bool `json:"accepts_bold"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	if body.AcceptsCash == nil || body.AcceptsBold == nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_body", "indica accepts_cash y accepts_bold")
		return
	}
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.SetMethods(r.Context(), p.UserID, *body.AcceptsCash, *body.AcceptsBold)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) driverSettlement(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.Settlement(r.Context(), p.UserID)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) adminList(w http.ResponseWriter, r *http.Request) {
	status := r.URL.Query().Get("status")
	if !ValidAdminStatus(status) {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_status", "estado de pago desconocido")
		return
	}
	out, err := h.Service.AdminList(r.Context(), status)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) resolve(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "tripPaymentId")
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
	admin, _ := auth.FromContext(r.Context())
	out, err := h.Service.Resolve(r.Context(), admin.UserID, id, body.Outcome, body.Note)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) void(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "tripPaymentId")
	if !ok {
		return
	}
	var body struct {
		Reason string `json:"reason"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	admin, _ := auth.FromContext(r.Context())
	out, err := h.Service.Void(r.Context(), admin.UserID, id, body.Reason)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) settlements(w http.ResponseWriter, r *http.Request) {
	out, err := h.Service.Settlements(r.Context())
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) adminSettlement(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "driverId")
	if !ok {
		return
	}
	out, err := h.Service.Settlement(r.Context(), id)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) payout(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "driverId")
	if !ok {
		return
	}
	var body NewPayout
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	admin, _ := auth.FromContext(r.Context())
	out, err := h.Service.RegisterPayout(r.Context(), admin.UserID, id, body)
	respond(w, r, http.StatusCreated, out, err)
}

func pathID(w http.ResponseWriter, r *http.Request, name string) (uuid.UUID, bool) {
	id, err := uuid.Parse(r.PathValue(name))
	if err != nil {
		httpx.WriteError(w, http.StatusNotFound, "not_found", "pago no encontrado")
		return uuid.Nil, false
	}
	return id, true
}

func respond(w http.ResponseWriter, r *http.Request, status int, out any, err error) {
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, status, out)
}

func writeError(w http.ResponseWriter, r *http.Request, err error) {
	type mapping struct {
		status        int
		code, message string
	}
	known := []struct {
		target error
		m      mapping
	}{
		{ErrNotFound, mapping{http.StatusNotFound, "not_found", "pago no encontrado"}},
		{ErrForbidden, mapping{http.StatusForbidden, "forbidden", "tu papel en el viaje no permite esta acción"}},
		{ErrInvalidState, mapping{http.StatusConflict, "invalid_state", "el pago ya cambió de estado"}},
		{ErrBoldInProgress, mapping{http.StatusConflict, "bold_in_progress", "hay un pago con Bold en curso; espera su resultado"}},
		{ErrMethodNotAccepted, mapping{http.StatusConflict, "method_not_accepted", "el conductor no acepta ese medio de pago"}},
		{ErrNoMethod, mapping{http.StatusBadRequest, "no_method", "debes aceptar al menos un medio de pago"}},
		{ErrNoteRequired, mapping{http.StatusBadRequest, "note_required", "escribe una nota (máximo 200 caracteres)"}},
		{ErrInvalidOutcome, mapping{http.StatusBadRequest, "invalid_outcome", "outcome: paid o unpaid"}},
		{ErrReasonRequired, mapping{http.StatusBadRequest, "reason_required", "indica el motivo (máximo 200 caracteres)"}},
		{ErrInvalidPayout, mapping{http.StatusBadRequest, "invalid_payout", "valor positivo, moneda de 3 letras y referencia (máx. 80)"}},
		{ErrExceedsBalance, mapping{http.StatusConflict, "exceeds_balance", "el giro supera el saldo por girar"}},
		{billing.ErrBoldUnavailable, mapping{http.StatusServiceUnavailable, "bold_unavailable", "el pago con Bold no está disponible; intenta más tarde"}},
	}
	for _, k := range known {
		if errors.Is(err, k.target) {
			httpx.WriteError(w, k.m.status, k.m.code, k.m.message)
			return
		}
	}
	httpx.InternalError(w, r, err)
}
