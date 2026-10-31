package control

import (
	"context"
	"errors"
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
	"github.com/kyq/backend/internal/store"
)

// ErrTripNotFound means the trip of the inspection does not exist.
var ErrTripNotFound = errors.New("trip not found")

// TripStep is one step of the trip with its time (contracts: TripInspection.steps).
type TripStep struct {
	Status string    `json:"status"`
	At     time.Time `json:"at"`
}

// PersonRef is a participant without contact data (FR-002: no phones).
type PersonRef struct {
	ID          uuid.UUID `json:"id"`
	DisplayName string    `json:"display_name"`
}

// DriverPosition is the last known position of the driver.
type DriverPosition struct {
	Lat        float64   `json:"lat"`
	Lng        float64   `json:"lng"`
	LocationAt time.Time `json:"location_at"`
	Stale      bool      `json:"stale"`
}

// PaymentRef is the payment status of a completed trip (004).
type PaymentRef struct {
	Status string  `json:"status"`
	Method *string `json:"method"`
}

// SosRef is the open SOS alert of the trip (003), linked to the console.
type SosRef struct {
	ID     uuid.UUID `json:"id"`
	Status string    `json:"status"`
}

// Inspection is GET /v1/admin/trips/{tripId} (contracts: TripInspection).
type Inspection struct {
	TripID                  uuid.UUID       `json:"trip_id"`
	Status                  string          `json:"status"`
	Active                  bool            `json:"active"`
	CancelReason            *string         `json:"cancel_reason"`
	Dispatch                string          `json:"dispatch"`
	HandoverCount           int             `json:"handover_count"`
	CooperativeName         *string         `json:"cooperative_name"`
	Passenger               PersonRef       `json:"passenger"`
	Driver                  PersonRef       `json:"driver"`
	VehiclePlate            string          `json:"vehicle_plate"`
	VehicleDescription      string          `json:"vehicle_description"`
	Pickup                  Point           `json:"pickup"`
	Dropoff                 Point           `json:"dropoff"`
	DistanceM               int             `json:"distance_m"`
	DurationS               int             `json:"duration_s"`
	Currency                string          `json:"currency"`
	ListFareMinor           int64           `json:"list_fare_minor"`
	SuggestedFareMinor      int64           `json:"suggested_fare_minor"`
	AgreedFareMinor         *int64          `json:"agreed_fare_minor"`
	PreferentialDiscountPct int             `json:"preferential_discount_pct"`
	Steps                   []TripStep      `json:"steps"`
	DriverPosition          *DriverPosition `json:"driver_position"`
	Payment                 *PaymentRef     `json:"payment"`
	OpenSos                 *SosRef         `json:"open_sos"`
	GeneratedAt             time.Time       `json:"generated_at"`
}

var activeStatuses = map[store.TripStatus]bool{
	store.TripStatusACCEPTED: true, store.TripStatusARRIVED: true, store.TripStatusINPROGRESS: true,
}

// Inspect loads the detail of a trip for adminID and records the access (FR-002, FR-004).
func Inspect(ctx context.Context, q *store.Queries, adminID, tripID uuid.UUID, now time.Time) (Inspection, error) {
	t, err := q.GetTripForInspection(ctx, tripID)
	if store.IsNotFound(err) {
		return Inspection{}, ErrTripNotFound
	}
	if err != nil {
		return Inspection{}, err
	}
	if err := q.InsertTripInspection(ctx, store.InsertTripInspectionParams{AdminID: adminID, TripID: tripID, OpenedAt: now}); err != nil {
		return Inspection{}, err
	}
	out := Inspection{
		TripID: t.ID, Status: string(t.Status), Active: activeStatuses[t.Status], Dispatch: string(t.Dispatch),
		HandoverCount: int(t.HandoverCount), CooperativeName: textPtr(t.CooperativeName),
		Passenger:    PersonRef{ID: t.PassengerID, DisplayName: t.PassengerName},
		Driver:       PersonRef{ID: t.DriverID, DisplayName: t.DriverName},
		VehiclePlate: t.VehiclePlate, VehicleDescription: t.VehicleDescription,
		Pickup: Point{t.PickupLat, t.PickupLng}, Dropoff: Point{t.DropoffLat, t.DropoffLng},
		DistanceM: int(t.RouteDistanceM), DurationS: int(t.RouteDurationS), Currency: t.Currency,
		ListFareMinor: t.ListFareMinor, SuggestedFareMinor: t.SuggestedFareMinor,
		PreferentialDiscountPct: int(t.PreferentialDiscountPct), GeneratedAt: now,
		Steps: []TripStep{{Status: "REQUESTED", At: t.CreatedAt}},
	}
	if t.CancelReason.Valid {
		r := string(t.CancelReason.TripCancelReason)
		out.CancelReason = &r
	}
	if t.AgreedFareMinor.Valid {
		out.AgreedFareMinor = &t.AgreedFareMinor.Int64
	}
	for _, s := range []struct {
		status string
		at     pgtype.Timestamptz
	}{
		{"ACCEPTED", t.AcceptedAt}, {"ARRIVED", t.ArrivedAt}, {"IN_PROGRESS", t.StartedAt},
		{"COMPLETED", t.CompletedAt}, {"CANCELLED", t.CancelledAt},
	} {
		if s.at.Valid {
			out.Steps = append(out.Steps, TripStep{Status: s.status, At: s.at.Time})
		}
	}
	// La posición del conductor solo tiene sentido mientras el viaje está activo.
	if out.Active && t.LastLat.Valid && t.LastLng.Valid && t.LastLocationAt.Valid {
		out.DriverPosition = &DriverPosition{
			Lat: t.LastLat.Float64, Lng: t.LastLng.Float64, LocationAt: t.LastLocationAt.Time,
			Stale: now.Sub(t.LastLocationAt.Time) > StaleAfter,
		}
	}
	pay, err := q.GetTripPaymentStatusForInspection(ctx, tripID)
	switch {
	case err == nil:
		out.Payment = &PaymentRef{Status: pay.Status}
		if pay.Method != "" {
			out.Payment.Method = &pay.Method
		}
	case !store.IsNotFound(err):
		return Inspection{}, err
	}
	sos, err := q.GetOpenSosForTrip(ctx, tripID)
	switch {
	case err == nil:
		out.OpenSos = &SosRef{ID: sos.ID, Status: sos.Status}
	case !store.IsNotFound(err):
		return Inspection{}, err
	}
	return out, nil
}

func textPtr(t pgtype.Text) *string {
	if !t.Valid {
		return nil
	}
	return &t.String
}

func (h *Handlers) inspect(w http.ResponseWriter, r *http.Request) {
	tripID, err := uuid.Parse(r.PathValue("tripId"))
	if err != nil {
		httpx.WriteError(w, http.StatusNotFound, "trip_not_found", "viaje no encontrado")
		return
	}
	p, _ := auth.FromContext(r.Context())
	out, err := Inspect(r.Context(), h.Store.Queries, p.UserID, tripID, h.now())
	if errors.Is(err, ErrTripNotFound) {
		httpx.WriteError(w, http.StatusNotFound, "trip_not_found", "viaje no encontrado")
		return
	}
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}
