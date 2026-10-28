// Package trips implements the nominal trip: request to a chosen driver, fare acceptance,
// editing or negotiation, and the trip lifecycle (FR-009..FR-015, RN-KYQ-001, RN-KYQ-007).
//
// Trip is an aggregate: every rule lives in its methods, which are pure and take the caller's
// role and the current time. The service loads it, calls one method and saves it.
package trips

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

// Status values match the trip_status enum and contracts/api.yaml#TripStatus.
type Status string

const (
	StatusRequested          Status = "REQUESTED"
	StatusFarePending        Status = "FARE_PENDING"
	StatusNegotiationPending Status = "NEGOTIATION_PENDING"
	StatusNegotiating        Status = "NEGOTIATING"
	StatusAccepted           Status = "ACCEPTED"
	StatusArrived            Status = "ARRIVED"
	StatusInProgress         Status = "IN_PROGRESS"
	StatusCompleted          Status = "COMPLETED"
	StatusCancelled          Status = "CANCELLED"
)

// Active reports whether the trip still holds the driver.
func (s Status) Active() bool { return s != StatusCompleted && s != StatusCancelled }

// Party is the caller's role in the trip.
type Party string

const (
	Driver    Party = "driver"
	Passenger Party = "passenger"
)

// Cancel reasons match trip_cancel_reason.
const (
	CancelByPassenger     = "passenger"
	CancelByDriver        = "driver"
	CancelOfferExpired    = "offer_expired"
	CancelOfferRejected   = "offer_rejected"
	CancelFareRejected    = "fare_rejected"
	CancelNegotiationFail = "negotiation_failed"
	// CancelNoDriver: la delegación no encontró compañero libre o agotó los pasos (RN-KYQ-008).
	CancelNoDriver = "no_driver_available"
	// CancelDelegated es transitorio: el conductor pasó la oferta y, en la misma transacción, el
	// viaje va a un compañero o queda en CancelNoDriver. Nunca se guarda.
	CancelDelegated = "delegated"
)

// Plazos de respuesta (RN-KYQ-007, FR-010a, FR-010c).
const (
	OfferWindow       = 25 * time.Second
	ResponseWindow    = 30 * time.Second
	NegotiationWindow = 3 * time.Minute
)

var (
	ErrInvalidTransition = errors.New("invalid transition for current status")
	ErrForbidden         = errors.New("action not allowed for this party")
	ErrExpired           = errors.New("response window expired")
	ErrNoOpenProposal    = errors.New("no open proposal with that id")
	ErrInvalidAmount     = errors.New("amount must be positive")
	ErrDelegationDenied  = errors.New("trip may not be passed to the cooperative")
)

// Point is a WGS84 coordinate.
type Point struct {
	Lat float64 `json:"lat"`
	Lng float64 `json:"lng"`
}

// ProposalStatus matches fare_proposal_status.
type ProposalStatus string

const (
	ProposalOpen       ProposalStatus = "open"
	ProposalAccepted   ProposalStatus = "accepted"
	ProposalRejected   ProposalStatus = "rejected"
	ProposalSuperseded ProposalStatus = "superseded"
	ProposalExpired    ProposalStatus = "expired"
)

// Proposal is a fare proposal (FR-010a, FR-010c).
type Proposal struct {
	ID         uuid.UUID
	ProposedBy Party
	Amount     int64
	Status     ProposalStatus
	CreatedAt  time.Time
	ExpiresAt  time.Time
}

// Trip is the trip aggregate.
type Trip struct {
	ID          uuid.UUID
	PassengerID uuid.UUID
	// DriverID is the driver holding the offer or the trip; it changes on every hand-over.
	DriverID  uuid.UUID
	CityCode  string
	Currency  string
	Pickup    Point
	Dropoff   Point
	DistanceM int32
	DurationS int32

	SuggestedFare int64
	AgreedFare    *int64
	DriverPayout  *int64
	// ListFare is the fare-table fare; SuggestedFare is what the current driver is offered, with
	// his preferential discount (DiscountPct) when the passenger is his client (008, RN-KYQ-013).
	ListFare    int64
	DiscountPct int

	Status       Status
	CancelReason *string

	// RespondBy is the deadline of the pending response: 25 s for the offer, 30 s for a fare
	// confirmation, negotiation answer or proposal.
	RespondBy            *time.Time
	NegotiationExpiresAt *time.Time

	CreatedAt   time.Time
	AcceptedAt  *time.Time
	ArrivedAt   *time.Time
	StartedAt   *time.Time
	CompletedAt *time.Time
	CancelledAt *time.Time

	// Despacho (006): conductor pedido, cooperativa fijada al pedir, consentimiento del pasajero y
	// pasos a compañeros (RN-KYQ-008).
	Dispatch          Dispatch
	RequestedDriverID uuid.UUID
	CooperativeID     *uuid.UUID
	AllowDelegation   bool
	Handovers         int
	// PreviousDriverID is set by HandOver for the service: it frees that driver and closes his
	// offer. Not persisted.
	PreviousDriverID *uuid.UUID
	// HandoverReason is why the previous offer ended (offer_rejected, offer_expired, delegated).
	HandoverReason string
	// DriverName and CooperativeName are read-only names for the view.
	DriverName          string
	RequestedDriverName string
	CooperativeName     *string

	// Offer is the context of the current offer for the driver's card (008). Not persisted.
	Offer OfferContext

	// Proposal is the open proposal, if any.
	Proposal *Proposal
	// ClosedProposals are proposals closed by the last operation; the repository persists them.
	ClosedProposals []Proposal
}

// NewTrip creates a nominal request; the driver has 25 s to answer (RN-KYQ-007).
func NewTrip(id, passengerID, driverID uuid.UUID, city, currency string, pickup, dropoff Point,
	distanceM, durationS int32, suggestedFare int64, now time.Time) *Trip {
	deadline := now.Add(OfferWindow)
	return &Trip{
		ID: id, PassengerID: passengerID, DriverID: driverID, CityCode: city, Currency: currency,
		Pickup: pickup, Dropoff: dropoff, DistanceM: distanceM, DurationS: durationS,
		SuggestedFare: suggestedFare, ListFare: suggestedFare, Status: StatusRequested, RespondBy: &deadline, CreatedAt: now,
		Dispatch: DispatchChosenDriver, RequestedDriverID: driverID,
	}
}

func ptr[T any](v T) *T { return &v }

func (t *Trip) require(party, want Party, statuses ...Status) error {
	if party != want {
		return ErrForbidden
	}
	return t.requireStatus(statuses...)
}

func (t *Trip) requireStatus(statuses ...Status) error {
	for _, s := range statuses {
		if t.Status == s {
			return nil
		}
	}
	return ErrInvalidTransition
}

func (t *Trip) withinDeadline(now time.Time) error {
	if t.RespondBy != nil && !now.Before(*t.RespondBy) {
		return ErrExpired
	}
	return nil
}

func (t *Trip) accept(amount int64, now time.Time) {
	t.Status = StatusAccepted
	t.AgreedFare = ptr(amount)
	t.AcceptedAt = ptr(now)
	t.RespondBy = nil
	t.NegotiationExpiresAt = nil
}

func (t *Trip) cancel(reason string, now time.Time) {
	t.closeProposal(ProposalExpired)
	t.Status = StatusCancelled
	t.CancelReason = ptr(reason)
	t.CancelledAt = ptr(now)
	t.RespondBy = nil
	t.NegotiationExpiresAt = nil
}

func (t *Trip) closeProposal(status ProposalStatus) {
	if t.Proposal == nil {
		return
	}
	p := *t.Proposal
	p.Status = status
	t.ClosedProposals = append(t.ClosedProposals, p)
	t.Proposal = nil
}

func (t *Trip) openProposal(by Party, amount int64, now time.Time) (*Proposal, error) {
	if amount <= 0 {
		return nil, ErrInvalidAmount
	}
	id, err := uuid.NewV7()
	if err != nil {
		return nil, err
	}
	t.closeProposal(ProposalSuperseded)
	t.Proposal = &Proposal{ID: id, ProposedBy: by, Amount: amount, Status: ProposalOpen, CreatedAt: now, ExpiresAt: now.Add(ResponseWindow)}
	deadline := t.Proposal.ExpiresAt
	if t.NegotiationExpiresAt != nil && t.NegotiationExpiresAt.Before(deadline) {
		deadline = *t.NegotiationExpiresAt
	}
	t.RespondBy = &deadline
	return t.Proposal, nil
}

// Accept is the driver accepting the offer. With fare nil or equal to the suggested fare the
// trip is ACCEPTED; with another fare the passenger must confirm it within 30 s (FR-010a).
func (t *Trip) Accept(party Party, fare *int64, now time.Time) error {
	if err := t.require(party, Driver, StatusRequested); err != nil {
		return err
	}
	if err := t.withinDeadline(now); err != nil {
		return err
	}
	if fare == nil || *fare == t.SuggestedFare {
		t.accept(t.SuggestedFare, now)
		return nil
	}
	if _, err := t.openProposal(Driver, *fare, now); err != nil {
		return err
	}
	t.Status = StatusFarePending
	return nil
}

// Reject is the driver declining the offer.
func (t *Trip) Reject(party Party, now time.Time) error {
	if err := t.require(party, Driver, StatusRequested); err != nil {
		return err
	}
	t.cancel(CancelOfferRejected, now)
	return nil
}

// RequestNegotiation is the driver proposing to negotiate; the passenger has 30 s to agree
// (FR-010c).
func (t *Trip) RequestNegotiation(party Party, now time.Time) error {
	if err := t.require(party, Driver, StatusRequested); err != nil {
		return err
	}
	if err := t.withinDeadline(now); err != nil {
		return err
	}
	t.Status = StatusNegotiationPending
	t.RespondBy = ptr(now.Add(ResponseWindow))
	return nil
}

// RespondNegotiation is the passenger agreeing to negotiate or not. Declining keeps the
// suggested fare and gives the driver a new 25 s window.
func (t *Trip) RespondNegotiation(party Party, accept bool, now time.Time) error {
	if err := t.require(party, Passenger, StatusNegotiationPending); err != nil {
		return err
	}
	if err := t.withinDeadline(now); err != nil {
		return err
	}
	if !accept {
		t.backToOffer(now)
		return nil
	}
	t.Status = StatusNegotiating
	t.NegotiationExpiresAt = ptr(now.Add(NegotiationWindow))
	t.RespondBy = ptr(now.Add(ResponseWindow)) // la primera propuesta debe llegar en 30 s
	return nil
}

func (t *Trip) backToOffer(now time.Time) {
	t.Status = StatusRequested
	t.RespondBy = ptr(now.Add(OfferWindow))
}

// Propose sends a proposal or counter-proposal while negotiating; it supersedes the open one.
func (t *Trip) Propose(party Party, amount int64, now time.Time) (*Proposal, error) {
	if err := t.requireStatus(StatusNegotiating); err != nil {
		return nil, err
	}
	if err := t.withinDeadline(now); err != nil {
		return nil, err
	}
	return t.openProposal(party, amount, now)
}

// DecideProposal is the other party accepting or rejecting the open proposal. Only the party
// that did not make it may decide.
func (t *Trip) DecideProposal(party Party, proposalID uuid.UUID, accept bool, now time.Time) error {
	if err := t.requireStatus(StatusFarePending, StatusNegotiating); err != nil {
		return err
	}
	if t.Proposal == nil || t.Proposal.ID != proposalID {
		return ErrNoOpenProposal
	}
	if t.Proposal.ProposedBy == party {
		return ErrForbidden
	}
	if err := t.withinDeadline(now); err != nil {
		return err
	}
	if accept {
		amount := t.Proposal.Amount
		t.closeProposal(ProposalAccepted)
		t.accept(amount, now)
		return nil
	}
	if t.Status == StatusFarePending {
		t.closeProposal(ProposalRejected)
		t.cancel(CancelFareRejected, now)
		return nil
	}
	// En negociación, rechazar no termina: la otra parte puede contraproponer en 30 s.
	t.closeProposal(ProposalRejected)
	deadline := now.Add(ResponseWindow)
	if t.NegotiationExpiresAt.Before(deadline) {
		deadline = *t.NegotiationExpiresAt
	}
	t.RespondBy = &deadline
	return nil
}

// Arrive, Start and Complete advance the trip; only the driver may do it (FR-013).
func (t *Trip) Arrive(party Party, now time.Time) error {
	if err := t.require(party, Driver, StatusAccepted); err != nil {
		return err
	}
	t.Status, t.ArrivedAt = StatusArrived, ptr(now)
	return nil
}

func (t *Trip) Start(party Party, now time.Time) error {
	if err := t.require(party, Driver, StatusArrived); err != nil {
		return err
	}
	t.Status, t.StartedAt = StatusInProgress, ptr(now)
	return nil
}

// Complete closes the trip: the driver receives 100 % of the agreed fare (RN-KYQ-001).
func (t *Trip) Complete(party Party, now time.Time) error {
	if err := t.require(party, Driver, StatusInProgress); err != nil {
		return err
	}
	t.Status, t.CompletedAt = StatusCompleted, ptr(now)
	t.DriverPayout = ptr(*t.AgreedFare)
	return nil
}

// Cancel lets either party cancel before IN_PROGRESS, without charge.
func (t *Trip) Cancel(party Party, now time.Time) error {
	if err := t.requireStatus(StatusRequested, StatusFarePending, StatusNegotiationPending, StatusNegotiating,
		StatusAccepted, StatusArrived); err != nil {
		return err
	}
	reason := CancelByPassenger
	if party == Driver {
		reason = CancelByDriver
	}
	t.cancel(reason, now)
	return nil
}

// Expire applies the pending deadline when it has passed. It returns false when nothing was
// due, so the sweeper can call it on any trip.
func (t *Trip) Expire(now time.Time) bool {
	if t.RespondBy == nil || now.Before(*t.RespondBy) {
		return false
	}
	switch t.Status {
	case StatusRequested:
		t.cancel(CancelOfferExpired, now)
	case StatusFarePending:
		t.cancel(CancelFareRejected, now)
	case StatusNegotiationPending:
		t.backToOffer(now) // sin respuesta del pasajero equivale a no negociar
	case StatusNegotiating:
		t.cancel(CancelNegotiationFail, now)
	default:
		return false
	}
	return true
}

// CanDelegate reports whether the current offer may still pass to a coworker: the passenger
// consented, the trip has a cooperative and the hand-over limit is not reached (FR-013, FR-017).
func (t *Trip) CanDelegate() bool {
	return t.Status == StatusRequested && t.AllowDelegation && t.CooperativeID != nil && t.Handovers < MaxHandovers
}

// Delegate is the driver passing the offer to his cooperative within his 25 s (FR-013). The
// service then hands it over or gives up in the same transaction.
func (t *Trip) Delegate(party Party, now time.Time) error {
	if err := t.require(party, Driver, StatusRequested); err != nil {
		return err
	}
	if err := t.withinDeadline(now); err != nil {
		return err
	}
	if !t.CanDelegate() {
		return ErrDelegationDenied
	}
	t.cancel(CancelDelegated, now)
	return nil
}

// AwaitsHandOver reports an offer that just ended without a driver in a trip that allows
// delegation: the service must hand it over (HandOver) or give up (GiveUp).
func (t *Trip) AwaitsHandOver(before Status) bool {
	if before != StatusRequested || t.Status != StatusCancelled || t.CancelReason == nil {
		return false
	}
	switch *t.CancelReason {
	case CancelOfferRejected, CancelOfferExpired:
		// 008: en la bolsa zonal la oferta pasa al siguiente conductor sin cooperativa.
		return t.Dispatch == DispatchZonePool || (t.AllowDelegation && t.CooperativeID != nil)
	case CancelDelegated:
		return t.AllowDelegation && t.CooperativeID != nil
	}
	return false
}

// HasHandoversLeft reports whether another coworker may receive the offer.
func (t *Trip) HasHandoversLeft() bool { return t.Handovers < MaxHandovers }

// HandOver gives the offer to the next coworker with a new 25 s window (FR-012, FR-016).
func (t *Trip) HandOver(next uuid.UUID, now time.Time) error {
	if !t.AwaitsHandOver(StatusRequested) || !t.HasHandoversLeft() {
		return ErrInvalidTransition
	}
	prev := t.DriverID
	t.PreviousDriverID = &prev
	t.HandoverReason = *t.CancelReason
	t.DriverID = next
	t.Handovers++
	t.Status = StatusRequested
	t.CancelReason = nil
	t.CancelledAt = nil
	t.RespondBy = ptr(now.Add(OfferWindow))
	return nil
}

// GiveUp closes a delegated request without coworkers left (FR-017).
func (t *Trip) GiveUp() {
	if t.Status == StatusCancelled {
		t.CancelReason = ptr(CancelNoDriver)
	}
}

// OfferContext is what the driver's offer card shows besides the trip (008): where the offer
// comes from, whether the passenger is his client, their completed trips together and the
// straight-line distance to the pickup.
type OfferContext struct {
	Origin         Dispatch
	LoyalClient    bool
	TripsTogether  int
	PickupDistance *int
	// 010: la oferta cumple una reserva de la agenda.
	Reservation bool
	// 010: nota privada del conductor sobre el cliente; solo va en su oferta (FR-008).
	ClientNote *string
}

// PartyOf returns the caller's role, or false when the user is not part of the trip.
func (t *Trip) PartyOf(userID uuid.UUID) (Party, bool) {
	switch userID {
	case t.DriverID:
		return Driver, true
	case t.PassengerID:
		return Passenger, true
	}
	return "", false
}
