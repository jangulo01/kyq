package trips

import (
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/realtime"
)

// Message is one event to publish on one channel.
type Message struct {
	Channel string
	Event   realtime.Event
}

func userChannel(id uuid.UUID) string { return "user:" + id.String() }

// DriverView is the driver shown to the passenger once the trip is accepted.
type DriverView struct {
	DisplayName        string `json:"display_name"`
	VehiclePlate       string `json:"vehicle_plate"`
	VehicleDescription string `json:"vehicle_description"`
}

// offerMessage is trip.offer for the driver holding the offer. 006 adds whether it was
// delegated, whether he may pass it on and the cooperative (contracts/realtime.md).
func offerMessage(t *Trip, passengerName string, now time.Time) Message {
	delegated := t.DriverID != t.RequestedDriverID
	var requestedName any
	if delegated {
		requestedName = t.RequestedDriverName
	}
	return Message{userChannel(t.DriverID), realtime.Event{Type: "trip.offer", OccurredAt: now, Data: map[string]any{
		"trip_id": t.ID, "passenger_name": passengerName, "pickup": t.Pickup, "dropoff": t.Dropoff,
		"distance_m": t.DistanceM, "duration_s": t.DurationS, "suggested_fare_minor": t.SuggestedFare,
		"currency": t.Currency, "expires_at": t.RespondBy,
		"delegated": delegated, "can_delegate": t.CanDelegate(), "cooperative_name": t.CooperativeName,
		"requested_driver_name": requestedName,
		// 008: origen de la oferta, Prioridad Oro de la cartera y distancia a la recogida.
		"origin": t.Offer.Origin, "loyal_client": t.Offer.LoyalClient, "trips_together": t.Offer.TripsTogether,
		"pickup_distance_m": t.Offer.PickupDistance, "preferential_discount_pct": t.DiscountPct,
	}}}
}

// eventsFor returns the realtime messages for a change from before to t
// (contracts/realtime.md). created marks a brand new trip.
func eventsFor(before Status, beforeProposal *uuid.UUID, t *Trip, created bool, passengerName string, driver *DriverView, now time.Time) []Message {
	var out []Message
	ev := func(typ string, data any) realtime.Event {
		return realtime.Event{Type: typ, OccurredAt: now, Data: data}
	}

	if created || (t.Status == StatusRequested && before != StatusRequested) {
		out = append(out, offerMessage(t, passengerName, now))
	}
	if created {
		return out
	}

	if before == StatusRequested && t.Status == StatusCancelled {
		out = append(out, Message{userChannel(t.DriverID), ev("trip.offer_closed", map[string]any{
			"trip_id": t.ID, "reason": *t.CancelReason,
		})})
	}
	if t.Status == StatusNegotiationPending && before != StatusNegotiationPending {
		out = append(out, Message{userChannel(t.PassengerID), ev("trip.negotiation_requested", map[string]any{
			"trip_id": t.ID, "expires_at": t.RespondBy,
		})})
	}
	if t.Proposal != nil && (beforeProposal == nil || *beforeProposal != t.Proposal.ID) {
		other := t.DriverID
		if t.Proposal.ProposedBy == Driver {
			other = t.PassengerID
		}
		out = append(out, Message{userChannel(other), ev("trip.fare_proposal", map[string]any{
			"trip_id": t.ID, "proposal_id": t.Proposal.ID, "proposed_by": t.Proposal.ProposedBy,
			"amount_minor": t.Proposal.Amount, "expires_at": t.Proposal.ExpiresAt,
		})})
	}
	if t.Status != before {
		data := map[string]any{"trip_id": t.ID, "status": t.Status}
		if t.AgreedFare != nil {
			data["agreed_fare_minor"] = *t.AgreedFare
		}
		if t.CancelReason != nil {
			data["cancel_reason"] = *t.CancelReason
		}
		if driver != nil && t.Status == StatusAccepted {
			data["driver"] = driver
		}
		e := ev("trip.status", data)
		out = append(out, Message{userChannel(t.PassengerID), e}, Message{userChannel(t.DriverID), e})
	}
	return out
}
