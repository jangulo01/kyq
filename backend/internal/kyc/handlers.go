package kyc

import (
	"errors"
	"net/http"
	"strings"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
)

// Handlers serves the onboarding routes of drivers and the KYC review routes of admins.
type Handlers struct{ Service *Service }

// Register mounts the routes behind authMW and the role checks.
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	driver := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleDriver)(f)) }
	admin := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleAdmin)(f)) }
	mux.Handle("PUT /v1/driver/vehicle", driver(h.putVehicle))
	mux.Handle("GET /v1/driver/onboarding", driver(h.onboarding))
	mux.Handle("POST /v1/driver/documents", driver(h.createDocument))
	mux.Handle("POST /v1/driver/documents/{documentId}/submit", driver(h.submit))
	mux.Handle("GET /v1/admin/kyc/queue", admin(h.queue))
	mux.Handle("GET /v1/admin/kyc/drivers/{driverId}", admin(h.file))
	mux.Handle("POST /v1/admin/kyc/documents/{documentId}/review", admin(h.review))
}

func (h *Handlers) putVehicle(w http.ResponseWriter, r *http.Request) {
	var body Vehicle
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	p, _ := auth.FromContext(r.Context())
	v, err := h.Service.SetVehicle(r.Context(), p.UserID, body)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, v)
}

func (h *Handlers) onboarding(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.Onboarding(r.Context(), p.UserID)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) createDocument(w http.ResponseWriter, r *http.Request) {
	var body NewDocument
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	p, _ := auth.FromContext(r.Context())
	doc, uploads, err := h.Service.CreateDocument(r.Context(), p.UserID, body)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, map[string]any{"document": doc, "uploads": uploads})
}

func (h *Handlers) submit(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "documentId")
	if !ok {
		return
	}
	p, _ := auth.FromContext(r.Context())
	doc, err := h.Service.Submit(r.Context(), p.UserID, id)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, doc)
}

func (h *Handlers) queue(w http.ResponseWriter, r *http.Request) {
	out, err := h.Service.Queue(r.Context())
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) file(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "driverId")
	if !ok {
		return
	}
	out, err := h.Service.File(r.Context(), id)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) review(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "documentId")
	if !ok {
		return
	}
	var body Review
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	p, _ := auth.FromContext(r.Context())
	doc, err := h.Service.ReviewDocument(r.Context(), p.UserID, id, body)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, doc)
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
	case errors.Is(err, ErrInvalidVehicle):
		httpx.WriteError(w, http.StatusBadRequest, "invalid_vehicle", strings.TrimPrefix(err.Error(), ErrInvalidVehicle.Error()+": "))
	case errors.Is(err, ErrVehicleRequired):
		httpx.WriteError(w, http.StatusConflict, "vehicle_required", "completa los datos de tu vehículo antes de enviar documentos")
	case errors.Is(err, ErrInvalidDocType):
		httpx.WriteError(w, http.StatusBadRequest, "invalid_doc_type", "tipo de documento desconocido")
	case errors.Is(err, ErrInvalidNumber):
		httpx.WriteError(w, http.StatusBadRequest, "invalid_number", "indica el número del documento (letras, números, puntos o guiones)")
	case errors.Is(err, ErrExpiresRequired):
		httpx.WriteError(w, http.StatusBadRequest, "expires_at_required", "indica la fecha de vencimiento en AAAA-MM-DD")
	case errors.Is(err, ErrAlreadyExpired):
		httpx.WriteError(w, http.StatusBadRequest, "document_expired", "el documento ya está vencido; envía uno vigente")
	case errors.Is(err, ErrInvalidSides):
		httpx.WriteError(w, http.StatusBadRequest, "invalid_sides", "indica las fotos: front y, si aplica, back")
	case errors.Is(err, ErrDocumentInReview):
		httpx.WriteError(w, http.StatusConflict, "document_in_review", "ya enviaste este documento y está en revisión")
	case errors.Is(err, ErrNotUploading):
		httpx.WriteError(w, http.StatusConflict, "invalid_state", "el documento ya fue enviado")
	case errors.Is(err, ErrPhotosMissing):
		httpx.WriteError(w, http.StatusConflict, "photos_missing", "faltan fotos por subir")
	case errors.Is(err, ErrPhotoInvalid):
		httpx.WriteError(w, http.StatusConflict, "photo_invalid", "cada foto debe ser JPEG de máximo 2 MB; vuelve a subirla")
	case errors.Is(err, ErrNotSubmitted):
		httpx.WriteError(w, http.StatusConflict, "invalid_state", "el documento no está en revisión")
	case errors.Is(err, ErrInvalidDecision):
		httpx.WriteError(w, http.StatusBadRequest, "invalid_decision", "decision debe ser approve o reject")
	case errors.Is(err, ErrReasonRequired):
		httpx.WriteError(w, http.StatusBadRequest, "reason_required", "indica el motivo del rechazo (máximo 200 caracteres)")
	case errors.Is(err, ErrExemptNotAllowed):
		httpx.WriteError(w, http.StatusBadRequest, "invalid_exempt_until", "exempt_until solo aplica a la revisión técnico-mecánica")
	default:
		httpx.InternalError(w, r, err)
	}
}
