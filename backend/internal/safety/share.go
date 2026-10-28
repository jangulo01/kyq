package safety

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/store"
)

// Viaje compartido (US3): un enlace no adivinable que cualquiera abre sin cuenta y que solo
// muestra la posición, la placa, el nombre del conductor y el estado (FR-013..FR-015).

var (
	ErrShareUnavailable = errors.New("trip cannot be shared in its status")
	ErrShareExpired     = errors.New("shared link expired")
)

// ShareLink is the body of POST /v1/trips/{tripId}/share.
type ShareLink struct {
	Token string `json:"token"`
	URL   string `json:"url"`
}

// newShareToken returns 128 random bits in base64url (22 characters).
func newShareToken() (string, error) {
	var b [16]byte
	if _, err := rand.Read(b[:]); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(b[:]), nil
}

func (s *Service) shareURL(token string) string {
	return strings.TrimRight(s.PublicBaseURL, "/") + "/s/" + token
}

// shareLink returns the link of (trip, user), creating it the first time.
func (s *Service) shareLink(ctx context.Context, q *store.Queries, userID, tripID uuid.UUID) (ShareLink, error) {
	token, err := newShareToken()
	if err != nil {
		return ShareLink{}, err
	}
	token, err = q.UpsertShareLink(ctx, store.UpsertShareLinkParams{Token: token, TripID: tripID, CreatedBy: userID, CreatedAt: s.now()})
	if err != nil {
		return ShareLink{}, err
	}
	return ShareLink{Token: token, URL: s.shareURL(token)}, nil
}

// Share returns the caller's live link of an accepted, not finished trip (FR-013).
func (s *Service) Share(ctx context.Context, userID, tripID uuid.UUID) (ShareLink, error) {
	trip, err := s.Store.GetTripForSOS(ctx, tripID)
	if store.IsNotFound(err) {
		return ShareLink{}, ErrNotFound
	}
	if err != nil {
		return ShareLink{}, err
	}
	if _, err := role(trip, userID); err != nil {
		return ShareLink{}, err
	}
	switch trip.Status {
	case store.TripStatusACCEPTED, store.TripStatusARRIVED, store.TripStatusINPROGRESS:
	default:
		return ShareLink{}, ErrShareUnavailable
	}
	return s.shareLink(ctx, s.Store.Queries, userID, tripID)
}

// SharedTrip is the public view of GET /v1/share/{token} (contracts: SharedTrip). It never
// carries phones, documents or payment data (FR-015).
type SharedTrip struct {
	Status             string        `json:"status"`
	Finished           bool          `json:"finished"`
	DriverName         string        `json:"driver_name"`
	VehiclePlate       string        `json:"vehicle_plate"`
	VehicleDescription string        `json:"vehicle_description"`
	Location           *LocationView `json:"location"`
}

// Shared returns the live view of a link: the driver's position while the trip runs, "finished"
// without position once it ends, and ErrShareExpired 15 min later (FR-014).
func (s *Service) Shared(ctx context.Context, token string) (SharedTrip, error) {
	now := s.now()
	if len(token) < 22 || len(token) > 64 {
		return SharedTrip{}, ErrNotFound
	}
	r, err := s.Store.GetSharedTrip(ctx, token)
	if store.IsNotFound(err) {
		return SharedTrip{}, ErrNotFound
	}
	if err != nil {
		return SharedTrip{}, err
	}
	v := SharedTrip{Status: string(r.Status), DriverName: r.DriverName, VehiclePlate: r.VehiclePlate, VehicleDescription: r.VehicleDescription}
	var endedAt time.Time
	switch r.Status {
	case store.TripStatusCOMPLETED:
		endedAt = r.CompletedAt.Time
	case store.TripStatusCANCELLED:
		endedAt = r.CancelledAt.Time
	default:
		if r.LastLat.Valid && r.LastLng.Valid {
			loc := LocationView{Lat: r.LastLat.Float64, Lng: r.LastLng.Float64}
			if r.LastLocationAt.Valid {
				loc.At = r.LastLocationAt.Time
			}
			v.Location = &loc
		}
		return v, nil
	}
	if !now.Before(endedAt.Add(ShareGrace)) {
		return SharedTrip{}, ErrShareExpired
	}
	v.Status, v.Finished = "FINISHED", true
	return v, nil
}
