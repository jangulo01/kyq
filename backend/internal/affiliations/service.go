// Package affiliations links passengers to their chosen drivers by QR (FR-005..FR-007,
// RN-KYQ-005).
package affiliations

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/hexgrid"
)

// Source is where an affiliation comes from (008, FR-016): the QR in the vehicle, the summary of
// a trip with a driver who was not yet chosen, or the link the driver shares.
type Source string

const (
	SourceQRScan   Source = "qr_scan"
	SourcePostTrip Source = "post_trip"
	SourceLink     Source = "link"
)

var (
	// ErrTripNotFound: the trip is not a completed trip of the passenger (008).
	ErrTripNotFound   = errors.New("completed trip not found")
	ErrDriverNotFound = errors.New("driver not found for qr token")
	ErrNotAffiliated  = errors.New("not affiliated")
	// ErrDriverNotAvailable: the driver may not take new clients until their documents and
	// subscription allow them to work (FR-004 of 002).
	ErrDriverNotAvailable = errors.New("driver cannot take new clients")
)

// Eligibility tells whether a driver may take new clients.
type Eligibility interface {
	CanWork(ctx context.Context, driverID uuid.UUID) (bool, error)
}

// ChosenDriver is a driver as the passenger sees it (contracts/api.yaml#ChosenDriver).
type ChosenDriver struct {
	DriverID           uuid.UUID  `json:"driver_id"`
	DisplayName        string     `json:"display_name"`
	VehicleDescription string     `json:"vehicle_description"`
	Presence           string     `json:"presence"`
	BusyUntilEstimate  *time.Time `json:"busy_until_estimate"`
	// Cooperative is the driver's active cooperative, if any (006: selector de despacho).
	Cooperative *CooperativeRef `json:"cooperative"`
	// Zone is the approximate area of a free driver for the golden pin (010, FR-018): the center
	// of his H3 hexagon of resolution 8, never his position.
	Zone *Zone `json:"zone"`
}

// Zone is contracts: DriverZone.
type Zone struct {
	Cell string  `json:"cell"`
	Lat  float64 `json:"lat"`
	Lng  float64 `json:"lng"`
}

// Parámetros de la zona aproximada (010, research R6).
const (
	ZoneResolution = 8
	ZoneFreshness  = 5 * time.Minute
)

// ZoneOf returns the approximate zone of a location recorded at, or nil when it is stale or
// cannot be indexed.
func ZoneOf(lat, lng float64, at, now time.Time) *Zone {
	if now.Sub(at) > ZoneFreshness {
		return nil
	}
	c, err := hexgrid.CellAt(hexgrid.Point{Lat: lat, Lng: lng}, ZoneResolution)
	if err != nil {
		return nil
	}
	center := c.Center()
	return &Zone{Cell: c.String(), Lat: center.Lat, Lng: center.Lng}
}

// CooperativeRef is contracts/api.yaml#CooperativeRef.
type CooperativeRef struct {
	ID   uuid.UUID `json:"id"`
	Name string    `json:"name"`
}

// Client is a passenger in the driver's portfolio.
type Client struct {
	PassengerID  uuid.UUID `json:"passenger_id"`
	DisplayName  string    `json:"display_name"`
	AffiliatedAt time.Time `json:"affiliated_at"`
	// Source is how the passenger joined the portfolio (008).
	Source Source `json:"source"`
}

// AffiliationState is the stored link between a passenger and a driver.
type AffiliationState int

const (
	StateNone AffiliationState = iota
	StateActive
	StateRemoved
)

// Repo persists affiliations.
type Repo interface {
	DriverByQRToken(ctx context.Context, token string) (ChosenDriver, error) // ErrDriverNotFound
	State(ctx context.Context, passengerID, driverID uuid.UUID) (AffiliationState, error)
	Insert(ctx context.Context, passengerID, driverID uuid.UUID, source Source) error
	Reactivate(ctx context.Context, passengerID, driverID uuid.UUID, source Source) error
	// CompletedTripDriver returns the driver of a completed trip of the passenger (ErrTripNotFound).
	CompletedTripDriver(ctx context.Context, passengerID, tripID uuid.UUID) (ChosenDriver, error)
	// PublicName returns the driver owning qrToken for the public link page (ErrDriverNotFound).
	PublicName(ctx context.Context, qrToken string) (driverID uuid.UUID, name string, err error)
	// Remove returns false when there was no active affiliation.
	Remove(ctx context.Context, passengerID, driverID uuid.UUID) (bool, error)
	ChosenDrivers(ctx context.Context, passengerID uuid.UUID) ([]ChosenDriver, error)
	Clients(ctx context.Context, driverID uuid.UUID) ([]Client, error)
}

// Service implements the affiliation use cases.
type Service struct {
	repo Repo
	// Eligibility, when set, blocks new affiliations to drivers who cannot work yet.
	Eligibility Eligibility
}

// NewService returns a service over repo.
func NewService(repo Repo) *Service { return &Service{repo: repo} }

// Affiliate links passengerID to the driver owning qrToken by scanning his QR. created is false
// when the link was already active; re-scanning after removal reactivates it.
func (s *Service) Affiliate(ctx context.Context, passengerID uuid.UUID, qrToken string) (driver ChosenDriver, created bool, err error) {
	return s.AffiliateFrom(ctx, passengerID, qrToken, SourceQRScan)
}

// AffiliateFrom is Affiliate with the QR token reached from source (QR or shared link, 008).
func (s *Service) AffiliateFrom(ctx context.Context, passengerID uuid.UUID, qrToken string, source Source) (driver ChosenDriver, created bool, err error) {
	driver, err = s.repo.DriverByQRToken(ctx, qrToken)
	if err != nil {
		return ChosenDriver{}, false, err
	}
	return s.link(ctx, passengerID, driver, source)
}

// AffiliateAfterTrip adds the driver of a completed trip as chosen driver from its summary (008,
// FR-014).
func (s *Service) AffiliateAfterTrip(ctx context.Context, passengerID, tripID uuid.UUID) (ChosenDriver, bool, error) {
	driver, err := s.repo.CompletedTripDriver(ctx, passengerID, tripID)
	if err != nil {
		return ChosenDriver{}, false, err
	}
	return s.link(ctx, passengerID, driver, SourcePostTrip)
}

// PublicDriver returns the name for the public page of a driver's link: only drivers who may take
// new clients (documents, subscription, not suspended) are shown (008, FR-017).
func (s *Service) PublicDriver(ctx context.Context, qrToken string) (string, error) {
	id, name, err := s.repo.PublicName(ctx, qrToken)
	if err != nil {
		return "", err
	}
	if s.Eligibility != nil {
		ok, err := s.Eligibility.CanWork(ctx, id)
		if err != nil {
			return "", err
		}
		if !ok {
			return "", ErrDriverNotAvailable
		}
	}
	return name, nil
}

func (s *Service) link(ctx context.Context, passengerID uuid.UUID, driver ChosenDriver, source Source) (ChosenDriver, bool, error) {
	state, err := s.repo.State(ctx, passengerID, driver.DriverID)
	if err != nil {
		return ChosenDriver{}, false, fmt.Errorf("affiliation state: %w", err)
	}
	if state == StateActive {
		return driver, false, nil
	}
	if s.Eligibility != nil {
		ok, err := s.Eligibility.CanWork(ctx, driver.DriverID)
		if err != nil {
			return ChosenDriver{}, false, fmt.Errorf("driver eligibility: %w", err)
		}
		if !ok {
			return ChosenDriver{}, false, ErrDriverNotAvailable
		}
	}
	switch state {
	case StateRemoved:
		err = s.repo.Reactivate(ctx, passengerID, driver.DriverID, source)
	default:
		err = s.repo.Insert(ctx, passengerID, driver.DriverID, source)
	}
	if err != nil {
		return ChosenDriver{}, false, fmt.Errorf("save affiliation: %w", err)
	}
	return driver, true, nil
}

// Remove unlinks a chosen driver.
func (s *Service) Remove(ctx context.Context, passengerID, driverID uuid.UUID) error {
	ok, err := s.repo.Remove(ctx, passengerID, driverID)
	if err != nil {
		return err
	}
	if !ok {
		return ErrNotAffiliated
	}
	return nil
}

// ChosenDrivers lists the passenger's active chosen drivers.
func (s *Service) ChosenDrivers(ctx context.Context, passengerID uuid.UUID) ([]ChosenDriver, error) {
	return s.repo.ChosenDrivers(ctx, passengerID)
}

// Clients lists the driver's affiliated passengers.
func (s *Service) Clients(ctx context.Context, driverID uuid.UUID) ([]Client, error) {
	return s.repo.Clients(ctx, driverID)
}

// IsAffiliated implements realtime.AffiliationChecker.
func (s *Service) IsAffiliated(ctx context.Context, passengerID, driverID uuid.UUID) (bool, error) {
	state, err := s.repo.State(ctx, passengerID, driverID)
	return state == StateActive, err
}
