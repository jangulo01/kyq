// Package affiliations links passengers to their chosen drivers by QR (FR-005..FR-007,
// RN-KYQ-005).
package affiliations

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
)

var (
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
	Insert(ctx context.Context, passengerID, driverID uuid.UUID) error
	Reactivate(ctx context.Context, passengerID, driverID uuid.UUID) error
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

// Affiliate links passengerID to the driver owning qrToken. created is false when the link was
// already active; re-scanning after removal reactivates it.
func (s *Service) Affiliate(ctx context.Context, passengerID uuid.UUID, qrToken string) (driver ChosenDriver, created bool, err error) {
	driver, err = s.repo.DriverByQRToken(ctx, qrToken)
	if err != nil {
		return ChosenDriver{}, false, err
	}
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
		err = s.repo.Reactivate(ctx, passengerID, driver.DriverID)
	default:
		err = s.repo.Insert(ctx, passengerID, driver.DriverID)
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
