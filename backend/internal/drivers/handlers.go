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
}

// Register mounts the routes on mux behind authMW and the driver role check.
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	mux.Handle("GET /v1/driver/me", authMW(auth.RequireRole(auth.RoleDriver)(http.HandlerFunc(h.me))))
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
	out := Me{DriverID: profile.UserID, QRToken: profile.QrToken, Presence: string(profile.Presence), Documents: []DocumentView{}}
	var paidUntil time.Time
	if profile.PaidUntil.Valid {
		paidUntil = profile.PaidUntil.Time
		out.PaidUntil = &paidUntil
	}
	gateDocs := make([]Document, 0, len(docs))
	for _, d := range docs {
		out.Documents = append(out.Documents, DocumentView{DocType: string(d.DocType), ExpiresAt: d.ExpiresAt.Format(time.DateOnly), Approved: d.Approved})
		gateDocs = append(gateDocs, Document{Type: string(d.DocType), ExpiresAt: d.ExpiresAt, Approved: d.Approved})
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
