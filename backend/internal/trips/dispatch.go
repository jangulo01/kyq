package trips

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
)

// Dispatch is how the passenger asked for the trip (006, FR-009). It matches trip_dispatch.
type Dispatch string

const (
	DispatchChosenDriver Dispatch = "chosen_driver"
	DispatchCooperative  Dispatch = "cooperative"
)

// Reglas de la delegación (RN-KYQ-008, FR-015, FR-017; research R2).
const (
	// MaxHandovers caps how many coworkers a request may pass to.
	MaxHandovers = 3
	// CandidateRadiusM is the straight-line distance from the pickup within which a coworker may
	// receive a delegated offer.
	CandidateRadiusM = 10_000
	// CandidateFreshness is how recent a coworker's location must be.
	CandidateFreshness = 5 * time.Minute
)

// HandoverDriverUnavailable is the hand-over reason when the chosen driver was busy or offline
// at request time and the offer went straight to a coworker.
const HandoverDriverUnavailable = "driver_unavailable"

var (
	ErrNoCooperative     = errors.New("chosen driver has no active cooperative")
	ErrNoDriverAvailable = errors.New("no free coworker near the pickup")
	errNoCandidate       = errors.New("no delegation candidate")
)

// RequestOptions are the passenger's dispatch choice and consent (FR-009, FR-010).
type RequestOptions struct {
	Dispatch        Dispatch
	AllowDelegation bool
}

// findCandidate returns the nearest free coworker of the trip's cooperative that has not had the
// offer yet, and locks his row (FR-015).
func findCandidate(ctx context.Context, q *store.Queries, t *Trip, now time.Time) (uuid.UUID, error) {
	if t.CooperativeID == nil {
		return uuid.Nil, errNoCandidate
	}
	row, err := q.FindDelegationCandidate(ctx, store.FindDelegationCandidateParams{
		Lng: t.Pickup.Lng, Lat: t.Pickup.Lat, CooperativeID: *t.CooperativeID,
		FreshSince: now.Add(-CandidateFreshness), RadiusM: CandidateRadiusM, TripID: t.ID,
	})
	if store.IsNotFound(err) {
		return uuid.Nil, errNoCandidate
	}
	if err != nil {
		return uuid.Nil, err
	}
	return row.DriverID, nil
}

// handOverOrGiveUp passes an offer that ended without a driver to the next coworker, or closes the
// request with no_driver_available (FR-012, FR-017).
func handOverOrGiveUp(ctx context.Context, q *store.Queries, t *Trip, now time.Time) error {
	if t.HasHandoversLeft() {
		next, err := findCandidate(ctx, q, t, now)
		switch {
		case err == nil:
			return t.HandOver(next, now)
		case !errors.Is(err, errNoCandidate):
			return err
		}
	}
	t.GiveUp()
	return nil
}

// afterHandOver reserves the new driver, frees the previous one, records the offer and returns the
// events: offer closed for the previous driver, new offer and trip.delegated for the passenger.
func afterHandOver(ctx context.Context, q *store.Queries, t *Trip, now time.Time) ([]Message, error) {
	prev := *t.PreviousDriverID
	if err := q.InsertTripOffer(ctx, store.InsertTripOfferParams{TripID: t.ID, DriverID: t.DriverID, OfferedAt: now, Handover: true}); err != nil {
		return nil, err
	}
	prevPresence, err := releaseDriver(ctx, q, prev)
	if err != nil {
		return nil, err
	}
	if err := q.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: t.DriverID, Presence: store.DriverPresenceBusy}); err != nil {
		return nil, err
	}
	if err := loadNames(ctx, q, t); err != nil {
		return nil, err
	}
	passengerName, err := q.GetUserDisplayName(ctx, t.PassengerID)
	if err != nil {
		return nil, err
	}
	ev := func(typ string, data any) realtime.Event {
		return realtime.Event{Type: typ, OccurredAt: now, Data: data}
	}
	return []Message{
		{userChannel(prev), ev("trip.offer_closed", map[string]any{"trip_id": t.ID, "reason": t.HandoverReason})},
		offerMessage(t, passengerName, now),
		delegatedMessage(t, t.HandoverReason, now),
		presenceMessage(prev, prevPresence, nil, now),
		presenceMessage(t.DriverID, store.DriverPresenceBusy, nil, now),
	}, nil
}

func delegatedMessage(t *Trip, reason string, now time.Time) Message {
	return Message{userChannel(t.PassengerID), realtime.Event{Type: "trip.delegated", OccurredAt: now, Data: map[string]any{
		"trip_id": t.ID, "cooperative_id": t.CooperativeID, "cooperative_name": t.CooperativeName,
		"reason": reason, "expires_at": t.RespondBy,
	}}}
}

// loadNames fills the read-only names of the view.
func loadNames(ctx context.Context, q *store.Queries, t *Trip) error {
	names, err := q.GetTripNames(ctx, t.ID)
	if err != nil {
		return err
	}
	t.DriverName = names.DriverName
	t.RequestedDriverName = names.RequestedDriverName
	t.CooperativeName = nil
	if names.CooperativeName.Valid {
		v := names.CooperativeName.String
		t.CooperativeName = &v
	}
	return nil
}

// dispatchNew applies the passenger's dispatch choice to a new trip inside the request
// transaction: it fixes the cooperative (FR-019) and picks who gets the first offer.
func dispatchNew(ctx context.Context, q *store.Queries, t *Trip, opts RequestOptions, now time.Time) error {
	coop, err := q.GetDriverCooperative(ctx, t.RequestedDriverID)
	hasCoop := err == nil
	if err != nil && !store.IsNotFound(err) {
		return err
	}
	if hasCoop {
		id := coop.ID
		t.CooperativeID = &id
		t.CooperativeName = &coop.Name
	}

	if opts.Dispatch == DispatchCooperative {
		if !hasCoop {
			return ErrNoCooperative
		}
		t.Dispatch = DispatchCooperative
		t.AllowDelegation = true
		next, err := findCandidate(ctx, q, t, now)
		if errors.Is(err, errNoCandidate) {
			return ErrNoDriverAvailable
		}
		if err != nil {
			return err
		}
		t.DriverID = next
		return nil
	}

	t.AllowDelegation = opts.AllowDelegation && hasCoop
	if !t.AllowDelegation {
		// Sin consentimiento la cooperativa no se usa: el viaje queda como en 001.
		t.CooperativeID, t.CooperativeName = nil, nil
	}
	driver, err := q.GetDriverForPresence(ctx, t.RequestedDriverID)
	if err != nil {
		return err
	}
	// Un conductor suspendido (007, FR-016) cuenta como no disponible aunque figure libre.
	if driver.Presence == store.DriverPresenceFree && !driver.Suspended {
		return nil
	}
	if !t.AllowDelegation {
		return ErrDriverNotFree
	}
	// FR-011: el elegido está ocupado o desconectado; va directo al compañero más cercano.
	next, err := findCandidate(ctx, q, t, now)
	if errors.Is(err, errNoCandidate) {
		return ErrNoDriverAvailable
	}
	if err != nil {
		return err
	}
	t.DriverID = next
	t.Handovers = 1
	t.HandoverReason = HandoverDriverUnavailable
	return nil
}

func nullUUID(id *uuid.UUID) uuid.NullUUID {
	if id == nil {
		return uuid.NullUUID{}
	}
	return uuid.NullUUID{UUID: *id, Valid: true}
}

func uuidPtr(id uuid.NullUUID) *uuid.UUID {
	if !id.Valid {
		return nil
	}
	v := id.UUID
	return &v
}
