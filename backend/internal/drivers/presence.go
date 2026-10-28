package drivers

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/fares"
	"github.com/kyq/backend/internal/httpx"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/telemetry"
)

// etaRefresh limits OSRM calls per busy driver (research R7).
const etaRefresh = 30 * time.Second

// Presence serves POST /v1/driver/presence and /v1/driver/location (FR-002, FR-003, FR-008,
// FR-014).
type Presence struct {
	Store     *store.Store
	Routes    fares.RouteEstimator
	Publisher realtime.Publisher
	Usage     telemetry.Usage
	Now       func() time.Time
	Logger    *slog.Logger
}

// Register mounts the routes behind authMW and the driver role check.
func (p *Presence) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	driver := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleDriver)(f)) }
	mux.Handle("POST /v1/driver/presence", driver(p.setPresence))
	mux.Handle("POST /v1/driver/location", driver(p.location))
}

func (p *Presence) now() time.Time {
	if p.Now != nil {
		return p.Now()
	}
	return time.Now()
}

func (p *Presence) logger() *slog.Logger {
	if p.Logger != nil {
		return p.Logger
	}
	return slog.Default()
}

var (
	errTripInProgress = errors.New("trip in progress")
	errBlocked        = errors.New("blocked")
	errOffline        = errors.New("driver offline")
	errSuspended      = errors.New("account suspended")
)

func (p *Presence) setPresence(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Online *bool `json:"online"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	if body.Online == nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_body", "indica online true o false")
		return
	}
	principal, _ := auth.FromContext(r.Context())
	now := p.now()
	var result store.DriverPresence
	var reason BlockReason
	var problems []DocumentProblem
	err := p.Store.WithTx(r.Context(), func(q *store.Queries) error {
		driver, err := q.GetDriverForPresence(r.Context(), principal.UserID)
		if err != nil {
			return err
		}
		_, err = q.GetActiveTripForDriver(r.Context(), principal.UserID)
		hasTrip := err == nil
		if err != nil && !store.IsNotFound(err) {
			return err
		}
		if !*body.Online {
			// RN-KYQ-003: no se abandona un viaje en curso desconectándose.
			if hasTrip {
				return errTripInProgress
			}
			result = store.DriverPresenceOffline
			return q.SetDriverPresence(r.Context(), store.SetDriverPresenceParams{UserID: principal.UserID, Presence: result})
		}
		// 007 (FR-016): la sesión vigente de un suspendido no le deja volver a ONLINE.
		suspended, err := q.IsUserSuspended(r.Context(), principal.UserID)
		if err != nil {
			return err
		}
		if suspended {
			return errSuspended
		}
		docs, err := q.ListDocumentsForDrivers(r.Context(), []uuid.UUID{principal.UserID})
		if err != nil {
			return err
		}
		var paidUntil time.Time
		if driver.PaidUntil.Valid {
			paidUntil = driver.PaidUntil.Time
		}
		gateDocs := GateDocuments(docs)
		if reason = EvaluateOnline(paidUntil, gateDocs, hasTrip, now); reason != BlockNone {
			problems = DocumentProblems(gateDocs, now)
			return errBlocked
		}
		if hasTrip || driver.Presence == store.DriverPresenceBusy {
			result = store.DriverPresenceBusy
			return nil // ya ocupado: no se toca la estimación
		}
		result = store.DriverPresenceFree
		return q.SetDriverPresence(r.Context(), store.SetDriverPresenceParams{UserID: principal.UserID, Presence: result})
	})
	switch {
	case errors.Is(err, errTripInProgress):
		httpx.WriteError(w, http.StatusConflict, "trip_in_progress", "termina tu viaje antes de desconectarte")
		return
	case errors.Is(err, errSuspended):
		httpx.WriteError(w, http.StatusConflict, "account_suspended", "tu cuenta está suspendida; comunícate con el soporte de Kyq")
		return
	case errors.Is(err, errBlocked):
		httpx.WriteError(w, http.StatusConflict, string(reason), blockMessage(reason, problems))
		return
	case err != nil:
		httpx.InternalError(w, r, err)
		return
	}
	p.publishPresence(r.Context(), principal.UserID, result, nil, now)
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"presence": result})
}

func blockMessage(r BlockReason, problems []DocumentProblem) string {
	if r == BlockSubscriptionSuspended {
		return "tu suscripción está suspendida; paga la mensualidad para trabajar"
	}
	if len(problems) > 0 {
		return problems[0].Message()
	}
	return "algún documento obligatorio falta o venció"
}

func (p *Presence) location(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Lat        *float64   `json:"lat"`
		Lng        *float64   `json:"lng"`
		Heading    *float64   `json:"heading"`
		SpeedMps   *float64   `json:"speed_mps"`
		RecordedAt *time.Time `json:"recorded_at"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	if body.Lat == nil || body.Lng == nil || *body.Lat < -90 || *body.Lat > 90 || *body.Lng < -180 || *body.Lng > 180 {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_location", "coordenadas inválidas")
		return
	}
	principal, _ := auth.FromContext(r.Context())
	now := p.now()
	recorded := now
	if body.RecordedAt != nil && body.RecordedAt.Before(now) && now.Sub(*body.RecordedAt) < time.Minute {
		recorded = *body.RecordedAt
	}

	var trip *store.Trip
	var refreshETA bool
	err := p.Store.WithTx(r.Context(), func(q *store.Queries) error {
		driver, err := q.GetDriverForPresence(r.Context(), principal.UserID)
		if err != nil {
			return err
		}
		if driver.Presence == store.DriverPresenceOffline {
			return errOffline
		}
		if err := q.SetDriverLocation(r.Context(), store.SetDriverLocationParams{
			Lat: *body.Lat, Lng: *body.Lng, RecordedAt: recorded, UserID: principal.UserID,
		}); err != nil {
			return err
		}
		t, err := q.GetActiveTripForDriver(r.Context(), principal.UserID)
		if store.IsNotFound(err) {
			return nil
		}
		if err != nil {
			return err
		}
		trip = &t
		refreshETA = !driver.BusyEstimateUpdatedAt.Valid || now.Sub(driver.BusyEstimateUpdatedAt.Time) >= etaRefresh
		return nil
	})
	if errors.Is(err, errOffline) {
		httpx.WriteError(w, http.StatusConflict, "offline", "ponte ONLINE para compartir tu ubicación")
		return
	}
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)

	if trip == nil {
		return
	}
	switch store.TripStatus(trip.Status) {
	case store.TripStatusACCEPTED, store.TripStatusARRIVED, store.TripStatusINPROGRESS:
	default:
		return
	}
	// Tras responder: publicar y recalcular la ETA no debe retrasar al cliente.
	ctx := context.WithoutCancel(r.Context())
	data := map[string]any{"lat": *body.Lat, "lng": *body.Lng, "heading": body.Heading, "speed_mps": body.SpeedMps}
	if p.Publisher != nil {
		if err := p.Publisher.Publish(ctx, "trip:"+trip.ID.String(), realtime.Event{Type: "trip.location", OccurredAt: now, Data: data}); err != nil {
			p.logger().WarnContext(ctx, "publish trip.location", "err", err)
		}
		telemetry.Add(p.Usage, principal.UserID, telemetry.Events, 1)
	}
	if refreshETA {
		p.refreshBusyUntil(ctx, principal.UserID, *trip, *body.Lat, *body.Lng, now)
	}
}

// refreshBusyUntil updates the minutes until the driver is free (FR-008): before pickup it is the
// road time to the pickup plus the trip; during the trip, the road time to the dropoff.
func (p *Presence) refreshBusyUntil(ctx context.Context, driverID uuid.UUID, trip store.Trip, lat, lng float64, now time.Time) {
	if p.Routes == nil {
		return
	}
	var remaining time.Duration
	telemetry.Add(p.Usage, driverID, telemetry.Routes, 1)
	if store.TripStatus(trip.Status) == store.TripStatusINPROGRESS {
		route, err := p.Routes.Route(ctx, lat, lng, trip.DropoffLat, trip.DropoffLng)
		if err != nil {
			p.logger().WarnContext(ctx, "eta to dropoff", "err", err)
			return
		}
		remaining = time.Duration(route.DurationS) * time.Second
	} else {
		route, err := p.Routes.Route(ctx, lat, lng, trip.PickupLat, trip.PickupLng)
		if err != nil {
			p.logger().WarnContext(ctx, "eta to pickup", "err", err)
			return
		}
		remaining = time.Duration(route.DurationS+trip.RouteDurationS) * time.Second
	}
	until := now.Add(remaining)
	err := p.Store.SetDriverPresence(ctx, store.SetDriverPresenceParams{
		UserID: driverID, Presence: store.DriverPresenceBusy, BusyUntilEstimate: pgtype.Timestamptz{Time: until, Valid: true},
	})
	if err != nil {
		p.logger().WarnContext(ctx, "save busy_until_estimate", "err", err)
		return
	}
	p.publishPresence(ctx, driverID, store.DriverPresenceBusy, &until, now)
}

func (p *Presence) publishPresence(ctx context.Context, driverID uuid.UUID, presence store.DriverPresence, busyUntil *time.Time, now time.Time) {
	if p.Publisher == nil {
		return
	}
	err := p.Publisher.Publish(ctx, "driver_presence:"+driverID.String(), realtime.Event{
		Type: "driver.presence", OccurredAt: now,
		Data: map[string]any{"driver_id": driverID, "presence": presence, "busy_until_estimate": busyUntil},
	})
	if err != nil {
		p.logger().WarnContext(ctx, "publish driver.presence", "err", err)
	}
	telemetry.Add(p.Usage, driverID, telemetry.Events, 1)
}
