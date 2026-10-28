package trips

import (
	"context"
	"errors"
	"math"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/store"
)

// Llegada automática a la recogida (010, FR-010, research R3).
const (
	ArrivalRadiusM     = 60.0
	ArrivalDwell       = 10 * time.Second
	ArrivalMaxAccuracy = 50.0
)

// DistanceM is the great-circle distance in meters between two points.
func DistanceM(a, b Point) float64 {
	const earthRadiusM = 6_371_000.0
	rad := math.Pi / 180
	dLat := (b.Lat - a.Lat) * rad
	dLng := (b.Lng - a.Lng) * rad
	h := math.Sin(dLat/2)*math.Sin(dLat/2) + math.Cos(a.Lat*rad)*math.Cos(b.Lat*rad)*math.Sin(dLng/2)*math.Sin(dLng/2)
	return 2 * earthRadiusM * math.Asin(math.Min(1, math.Sqrt(h)))
}

// ObserveArrival evaluates one location of the driver of an ACCEPTED trip: after 10 s in a row
// within 60 m of the pickup, with fixes of 50 m accuracy or better, the trip becomes ARRIVED as
// if the driver had tapped "Llegué". An imprecise fix neither counts nor resets the streak.
// It reports whether the trip arrived.
func (s *Service) ObserveArrival(ctx context.Context, driverID, tripID uuid.UUID, lat, lng float64, accuracyM *float64, recordedAt time.Time) (bool, error) {
	at := Point{Lat: lat, Lng: lng}
	if accuracyM == nil || *accuracyM > ArrivalMaxAccuracy {
		return false, nil
	}
	t, err := s.Store.GetArrivalCheck(ctx, tripID)
	if store.IsNotFound(err) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	if t.DriverID != driverID || t.Status != store.TripStatusACCEPTED {
		return false, nil
	}
	near := DistanceM(Point{Lat: t.PickupLat, Lng: t.PickupLng}, at) < ArrivalRadiusM
	switch {
	case !near:
		if t.NearPickupSince.Valid {
			return false, s.Store.SetNearPickupSince(ctx, store.SetNearPickupSinceParams{ID: tripID})
		}
		return false, nil
	case !t.NearPickupSince.Valid || recordedAt.Before(t.NearPickupSince.Time):
		return false, s.Store.SetNearPickupSince(ctx, store.SetNearPickupSinceParams{
			ID: tripID, NearPickupSince: pgtype.Timestamptz{Time: recordedAt, Valid: true},
		})
	case recordedAt.Sub(t.NearPickupSince.Time) < ArrivalDwell:
		return false, nil
	}
	_, err = s.Act(ctx, driverID, tripID, (*Trip).Arrive)
	if errors.Is(err, ErrInvalidTransition) {
		// Ya llegó a mano (FR-011) o el viaje cambió: no se repite.
		return false, nil
	}
	return err == nil, err
}
