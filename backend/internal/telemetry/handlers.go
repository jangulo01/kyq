package telemetry

import (
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
	"github.com/kyq/backend/internal/store"
)

// Handlers serves GET /v1/admin/usage.
type Handlers struct{ Store *store.Store }

func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	mux.Handle("GET /v1/admin/usage", authMW(auth.RequireRole(auth.RoleAdmin)(http.HandlerFunc(h.usage))))
}

// DriverUsage is one row of contracts/api.yaml#DriverUsage.
type DriverUsage struct {
	DriverID       *uuid.UUID `json:"driver_id"` // null: cotizaciones sin conductor elegido
	DisplayName    string     `json:"display_name"`
	VoiceMinutes   float64    `json:"voice_minutes"`
	RealtimeEvents int64      `json:"realtime_events"`
	RouteRequests  int64      `json:"route_requests"`
	// 011: Radio Kyq.
	RadioVoiceMinutes float64 `json:"radio_voice_minutes"`
	RadioMessages     int64   `json:"radio_messages"`
	RadioStorageMB    float64 `json:"radio_storage_mb"`
}

func (h *Handlers) usage(w http.ResponseWriter, r *http.Request) {
	day := func(name string, fallback time.Time) (time.Time, bool) {
		v := r.URL.Query().Get(name)
		if v == "" {
			return fallback, true
		}
		t, err := time.Parse(time.DateOnly, v)
		return t, err == nil
	}
	today := time.Now().UTC().Truncate(24 * time.Hour)
	from, ok1 := day("from", today.AddDate(0, 0, -30))
	to, ok2 := day("to", today)
	if !ok1 || !ok2 || to.Before(from) {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_range", "fechas en formato AAAA-MM-DD y from <= to")
		return
	}
	rows, err := h.Store.ListDriverUsage(r.Context(), store.ListDriverUsageParams{FromDay: from, ToDay: to})
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	out := make([]DriverUsage, 0, len(rows))
	for _, row := range rows {
		u := DriverUsage{
			DisplayName: row.DisplayName, VoiceMinutes: float64(row.VoiceParticipantSeconds) / 60,
			RealtimeEvents: row.RealtimeEvents, RouteRequests: row.RouteRequests,
			RadioVoiceMinutes: round2(float64(row.RadioVoiceSeconds) / 60), RadioMessages: row.RadioMessages,
			RadioStorageMB: round2(float64(row.RadioStorageBytes) / 1e6),
		}
		if row.DriverID != uuid.Nil {
			id := row.DriverID
			u.DriverID = &id
		}
		out = append(out, u)
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}
