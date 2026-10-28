package control

import (
	"context"
	"net/http"
	"strconv"
	"time"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/hexgrid"
	"github.com/kyq/backend/internal/httpx"
	"github.com/kyq/backend/internal/store"
)

// Handlers serves GET /v1/admin/tower (admin only).
type Handlers struct {
	Store *store.Store
	Now   func() time.Time
}

func (h *Handlers) now() time.Time {
	if h.Now != nil {
		return h.Now()
	}
	return time.Now()
}

// Register mounts the routes behind authMW and the admin role check.
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	mux.Handle("GET /v1/admin/tower", authMW(auth.RequireRole(auth.RoleAdmin)(http.HandlerFunc(h.tower))))
}

func (h *Handlers) tower(w http.ResponseWriter, r *http.Request) {
	res := hexgrid.DefaultResolution
	if v := r.URL.Query().Get("res"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil || n < hexgrid.MinResolution || n > hexgrid.MaxResolution {
			httpx.WriteError(w, http.StatusBadRequest, "invalid_resolution", "res debe ser un entero de 6 a 9")
			return
		}
		res = n
	}
	snap, err := LoadSnapshot(r.Context(), h.Store.Queries, res, h.now())
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, snap)
}

// Motivos de cancelación que cuentan como demanda no atendida (research R2).
var unservedReasons = map[store.TripCancelReason]bool{
	store.TripCancelReasonOfferExpired:      true,
	store.TripCancelReasonOfferRejected:     true,
	store.TripCancelReasonNegotiationFailed: true,
}

// LoadSnapshot reads drivers ONLINE, active trips and the requests of the window and aggregates
// them at resolution res.
func LoadSnapshot(ctx context.Context, q *store.Queries, res int, now time.Time) (Snapshot, error) {
	driverRows, err := q.ListOnlineDriversForTower(ctx)
	if err != nil {
		return Snapshot{}, err
	}
	tripRows, err := q.ListActiveTripsForTower(ctx)
	if err != nil {
		return Snapshot{}, err
	}
	requestRows, err := q.ListRecentRequestsForTower(ctx, now.Add(-RequestWindow))
	if err != nil {
		return Snapshot{}, err
	}
	drivers := make([]DriverInput, len(driverRows))
	for i, d := range driverRows {
		drivers[i] = DriverInput{ID: d.DriverID, Name: d.DisplayName, Presence: string(d.Presence)}
		if d.LastLat.Valid && d.LastLng.Valid && d.LastLocationAt.Valid {
			drivers[i].Position = &hexgrid.Point{Lat: d.LastLat.Float64, Lng: d.LastLng.Float64}
			drivers[i].LocationAt = d.LastLocationAt.Time
		}
	}
	trips := make([]TripInput, len(tripRows))
	for i, t := range tripRows {
		trips[i] = TripInput{DriverID: t.DriverID, Pickup: hexgrid.Point{Lat: t.PickupLat, Lng: t.PickupLng}}
	}
	requests := make([]RequestInput, len(requestRows))
	for i, rq := range requestRows {
		requests[i] = RequestInput{
			Pickup:   hexgrid.Point{Lat: rq.PickupLat, Lng: rq.PickupLng},
			Unserved: rq.CancelReason.Valid && unservedReasons[rq.CancelReason.TripCancelReason],
		}
	}
	return Aggregate(res, now, drivers, trips, requests), nil
}
