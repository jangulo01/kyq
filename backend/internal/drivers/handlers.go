package drivers

import (
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
	"github.com/kyq/backend/internal/store"
)

// Handlers serves /v1/driver/* for the authenticated driver.
type Handlers struct {
	Store *store.Store
	Now   func() time.Time
	// PublicBaseURL builds the affiliate link of each driver (008).
	PublicBaseURL string
}

// Register mounts the routes on mux behind authMW and the driver role check.
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	driver := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleDriver)(f)) }
	mux.Handle("GET /v1/driver/me", driver(h.me))
	// 008: bolsa zonal, tarifa preferencial y enlace de afiliación.
	mux.Handle("GET /v1/driver/dispatch-settings", driver(h.dispatchSettings))
	mux.Handle("PUT /v1/driver/dispatch-settings", driver(h.putDispatchSettings))
	// 010: ficha del cliente con su nota privada.
	mux.Handle("GET /v1/driver/clients/{passengerId}", driver(h.clientCard))
	mux.Handle("PUT /v1/driver/clients/{passengerId}/note", driver(h.putNote))
}

func (h *Handlers) now() time.Time {
	if h.Now != nil {
		return h.Now()
	}
	return time.Now()
}

// DocumentView is one entry of DriverMe.documents.
type DocumentView struct {
	DocType   string `json:"doc_type"`
	ExpiresAt string `json:"expires_at"`
	Approved  bool   `json:"approved"`
}

// Me is the body of GET /v1/driver/me (contracts/api.yaml#DriverMe).
type Me struct {
	DriverID           uuid.UUID      `json:"driver_id"`
	QRToken            string         `json:"qr_token"`
	Presence           string         `json:"presence"`
	SubscriptionStatus string         `json:"subscription_status"`
	PaidUntil          *time.Time     `json:"paid_until"`
	CanGoOnline        bool           `json:"can_go_online"`
	BlockReason        *string        `json:"block_reason"`
	Documents          []DocumentView `json:"documents"`
	// Motivo de bloqueo por documento (002); vacío si los documentos están al día.
	BlockedDocuments []DocumentProblem `json:"blocked_documents"`
}

func (h *Handlers) me(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	profile, err := h.Store.GetDriverProfile(r.Context(), p.UserID)
	if store.IsNotFound(err) {
		httpx.WriteError(w, http.StatusNotFound, "not_found", "perfil de conductor no encontrado")
		return
	}
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	docs, err := h.Store.ListDocumentsForDrivers(r.Context(), []uuid.UUID{p.UserID})
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}

	now := h.now()
	out := Me{
		DriverID: profile.UserID, QRToken: profile.QrToken, Presence: string(profile.Presence),
		Documents: LegacyDocumentViews(docs), BlockedDocuments: []DocumentProblem{},
	}
	var paidUntil time.Time
	if profile.PaidUntil.Valid {
		paidUntil = profile.PaidUntil.Time
		out.PaidUntil = &paidUntil
	}
	gateDocs := GateDocuments(docs)
	if problems := DocumentProblems(gateDocs, now); problems != nil {
		out.BlockedDocuments = problems
	}
	out.SubscriptionStatus = string(SubscriptionStatusAt(paidUntil, now))
	// Sin viajes todavía (US2): nunca hay viaje en curso.
	if reason := EvaluateOnline(paidUntil, gateDocs, false, now); reason == BlockNone {
		out.CanGoOnline = true
	} else {
		s := string(reason)
		out.BlockReason = &s
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

// LegacyDocumentViews is the 001 shape of the approved documents (DriverMe.documents and the
// admin driver list): only the 001 types with an expiry date, so 001 clients keep parsing it.
// The full detail is in GET /v1/driver/onboarding and GET /v1/admin/kyc/drivers/{id}.
func LegacyDocumentViews(rows []store.ListDocumentsForDriversRow) []DocumentView {
	out := []DocumentView{}
	for _, d := range rows {
		switch string(d.DocType) {
		case DocLicense, DocMandatoryInsurance, DocVehicleRegistration:
		default:
			continue
		}
		if !d.ExpiresAt.Valid {
			continue
		}
		out = append(out, DocumentView{DocType: string(d.DocType), ExpiresAt: d.ExpiresAt.Time.Format(time.DateOnly), Approved: true})
	}
	return out
}
