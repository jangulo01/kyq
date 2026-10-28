package billing

import (
	"errors"
	"io"
	"net/http"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/httpx"
)

// maxWebhookBytes bounds the Bold notification body.
const maxWebhookBytes = 64 << 10

// Handlers serves the subscription routes of drivers and admins and the Bold webhook.
type Handlers struct {
	Service *Service
	// WebhookEnabled mounts POST /v1/billing/bold/webhook (only when Bold is configured: in the
	// sandbox the signing key is empty, so it must never be open without Bold).
	WebhookEnabled bool
}

// Register mounts the routes behind authMW and the role checks; the webhook is public.
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	driver := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleDriver)(f)) }
	admin := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleAdmin)(f)) }
	mux.Handle("GET /v1/driver/subscription", driver(h.subscription))
	mux.Handle("POST /v1/driver/payments", driver(h.createPayment))
	mux.Handle("POST /v1/driver/payments/{paymentId}/refresh", driver(h.refresh))
	mux.Handle("GET /v1/admin/subscriptions", admin(h.subscriptions))
	mux.Handle("GET /v1/admin/drivers/{driverId}/payments", admin(h.driverPayments))
	mux.Handle("POST /v1/admin/drivers/{driverId}/payments", admin(h.manualPayment))
	mux.Handle("POST /v1/admin/payments/{paymentId}/void", admin(h.void))
	mux.Handle("PUT /v1/admin/subscription-prices/{cityCode}", admin(h.setPrice))
	if h.WebhookEnabled {
		mux.HandleFunc("POST /v1/billing/bold/webhook", h.webhook)
	}
}

func (h *Handlers) subscription(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.View(r.Context(), p.UserID)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) createPayment(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.CreatePayment(r.Context(), p.UserID)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, out)
}

func (h *Handlers) refresh(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "paymentId")
	if !ok {
		return
	}
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.Refresh(r.Context(), p.UserID, id)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) subscriptions(w http.ResponseWriter, r *http.Request) {
	status := r.URL.Query().Get("status")
	switch status {
	case "", drivers.BillingActive, drivers.BillingGrace, drivers.BillingSuspended, drivers.BillingUnpaid:
	default:
		httpx.WriteError(w, http.StatusBadRequest, "invalid_status", "status: active, grace, suspended o unpaid")
		return
	}
	out, err := h.Service.Subscriptions(r.Context(), status)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) driverPayments(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "driverId")
	if !ok {
		return
	}
	out, err := h.Service.DriverPayments(r.Context(), id)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) manualPayment(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "driverId")
	if !ok {
		return
	}
	var body ManualPayment
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	admin, _ := auth.FromContext(r.Context())
	out, err := h.Service.RegisterManualPayment(r.Context(), admin.UserID, id, body)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, out)
}

func (h *Handlers) void(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "paymentId")
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
	out, err := h.Service.VoidPayment(r.Context(), admin.UserID, id, body.Reason)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) setPrice(w http.ResponseWriter, r *http.Request) {
	var body NewPrice
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	admin, _ := auth.FromContext(r.Context())
	out, err := h.Service.SetPrice(r.Context(), admin.UserID, r.PathValue("cityCode"), body)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

// webhook answers fast (Bold expects 200 within 2 s and retries up to 5 times): processing is
// a couple of queries.
func (h *Handlers) webhook(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, maxWebhookBytes))
	if err != nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_body", "cuerpo inválido")
		return
	}
	err = h.Service.HandleWebhook(r.Context(), body, r.Header.Get("x-bold-signature"))
	switch {
	case errors.Is(err, ErrInvalidSignature):
		h.Service.logger().WarnContext(r.Context(), "bold webhook with invalid signature", "remote", r.RemoteAddr)
		httpx.WriteError(w, http.StatusUnauthorized, "invalid_signature", "firma inválida")
	case err != nil:
		httpx.InternalError(w, r, err)
	default:
		httpx.WriteJSON(w, http.StatusOK, map[string]string{"status": "ok"})
	}
}

func pathID(w http.ResponseWriter, r *http.Request, name string) (uuid.UUID, bool) {
	id, err := uuid.Parse(r.PathValue(name))
	if err != nil {
		httpx.WriteError(w, http.StatusNotFound, "not_found", "no encontrado")
		return uuid.Nil, false
	}
	return id, true
}

func writeError(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, ErrNotFound):
		httpx.WriteError(w, http.StatusNotFound, "not_found", "no encontrado")
	case errors.Is(err, ErrDocumentsNotOK):
		httpx.WriteError(w, http.StatusConflict, "documents_not_ok", "tus documentos deben estar aprobados y vigentes antes de pagar")
	case errors.Is(err, ErrPaymentInProgress):
		httpx.WriteError(w, http.StatusConflict, "payment_in_progress", "ya tienes un pago en curso; termínalo o espera a que caduque")
	case errors.Is(err, ErrPriceNotSet):
		httpx.WriteError(w, http.StatusConflict, "price_not_set", "aún no hay precio de suscripción para tu ciudad")
	case errors.Is(err, ErrBoldUnavailable):
		httpx.WriteError(w, http.StatusServiceUnavailable, "bold_unavailable", "el pago con Bold no está disponible; intenta más tarde")
	case errors.Is(err, ErrNotApproved):
		httpx.WriteError(w, http.StatusConflict, "not_approved", "solo se anulan pagos aprobados")
	case errors.Is(err, ErrReasonRequired):
		httpx.WriteError(w, http.StatusBadRequest, "reason_required", "indica el motivo (máximo 200 caracteres)")
	case errors.Is(err, ErrInvalidManual):
		httpx.WriteError(w, http.StatusBadRequest, "invalid_manual_payment", "indica medio (máx. 40) y referencia (máx. 80)")
	case errors.Is(err, ErrInvalidPrice):
		httpx.WriteError(w, http.StatusBadRequest, "invalid_price", "moneda de 3 letras y valor positivo (COP sin centavos)")
	default:
		httpx.InternalError(w, r, err)
	}
}
