package drivers

import (
	"net/http"
	"strings"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/fares"
	"github.com/kyq/backend/internal/httpx"
	"github.com/kyq/backend/internal/store"
)

// DispatchSettings is contracts/api.yaml#DispatchSettings (008): whether the driver receives zone
// pool requests, his preferential discount for his clients (RN-KYQ-013) and the link he shares to
// gain clients without the QR.
type DispatchSettings struct {
	AcceptsZonePool         bool   `json:"accepts_zone_pool"`
	PreferentialDiscountPct int    `json:"preferential_discount_pct"`
	AffiliateLink           string `json:"affiliate_link"`
}

// AffiliateLink is the public page that leads a passenger to affiliate with the driver (008).
func AffiliateLink(publicBaseURL, qrToken string) string {
	return strings.TrimRight(publicBaseURL, "/") + "/a/" + qrToken
}

func (h *Handlers) settingsView(acceptsZonePool bool, pct int16, qrToken string) DispatchSettings {
	return DispatchSettings{
		AcceptsZonePool: acceptsZonePool, PreferentialDiscountPct: int(pct),
		AffiliateLink: AffiliateLink(h.PublicBaseURL, qrToken),
	}
}

func (h *Handlers) dispatchSettings(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	row, err := h.Store.GetDispatchSettings(r.Context(), p.UserID)
	if store.IsNotFound(err) {
		httpx.WriteError(w, http.StatusNotFound, "not_found", "conductor no encontrado")
		return
	}
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, h.settingsView(row.AcceptsZonePool, row.PreferentialDiscountPct, row.QrToken))
}

func (h *Handlers) putDispatchSettings(w http.ResponseWriter, r *http.Request) {
	var body struct {
		AcceptsZonePool         *bool `json:"accepts_zone_pool"`
		PreferentialDiscountPct *int  `json:"preferential_discount_pct"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	if body.AcceptsZonePool == nil || body.PreferentialDiscountPct == nil ||
		*body.PreferentialDiscountPct < 0 || *body.PreferentialDiscountPct > fares.MaxPreferentialDiscountPct {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_settings",
			"indica si recibes la bolsa zonal y un descuento entre 0 % y 30 %")
		return
	}
	p, _ := auth.FromContext(r.Context())
	row, err := h.Store.SetDispatchSettings(r.Context(), store.SetDispatchSettingsParams{
		AcceptsZonePool: *body.AcceptsZonePool, PreferentialDiscountPct: int16(*body.PreferentialDiscountPct), UserID: p.UserID,
	})
	if store.IsNotFound(err) {
		httpx.WriteError(w, http.StatusNotFound, "not_found", "conductor no encontrado")
		return
	}
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, h.settingsView(row.AcceptsZonePool, row.PreferentialDiscountPct, row.QrToken))
}
