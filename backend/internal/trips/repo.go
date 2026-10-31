package trips

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/store"
)

func tsPtr(t pgtype.Timestamptz) *time.Time {
	if !t.Valid {
		return nil
	}
	v := t.Time
	return &v
}

func ts(t *time.Time) pgtype.Timestamptz {
	if t == nil {
		return pgtype.Timestamptz{}
	}
	return pgtype.Timestamptz{Time: *t, Valid: true}
}

func int8Ptr(v pgtype.Int8) *int64 {
	if !v.Valid {
		return nil
	}
	n := v.Int64
	return &n
}

func int8(v *int64) pgtype.Int8 {
	if v == nil {
		return pgtype.Int8{}
	}
	return pgtype.Int8{Int64: *v, Valid: true}
}

func fromRow(r store.Trip) *Trip {
	t := &Trip{
		ID: r.ID, PassengerID: r.PassengerID, DriverID: r.DriverID, CityCode: r.CityCode, Currency: r.Currency,
		Pickup: Point{Lat: r.PickupLat, Lng: r.PickupLng}, Dropoff: Point{Lat: r.DropoffLat, Lng: r.DropoffLng},
		DistanceM: r.RouteDistanceM, DurationS: r.RouteDurationS,
		SuggestedFare: r.SuggestedFareMinor, AgreedFare: int8Ptr(r.AgreedFareMinor), DriverPayout: int8Ptr(r.DriverPayoutMinor),
		Status: Status(r.Status), RespondBy: tsPtr(r.RespondBy), NegotiationExpiresAt: tsPtr(r.NegotiationExpiresAt),
		CreatedAt: r.CreatedAt, AcceptedAt: tsPtr(r.AcceptedAt), ArrivedAt: tsPtr(r.ArrivedAt), StartedAt: tsPtr(r.StartedAt),
		CompletedAt: tsPtr(r.CompletedAt), CancelledAt: tsPtr(r.CancelledAt),
		Dispatch: Dispatch(r.Dispatch), RequestedDriverID: r.RequestedDriverID, CooperativeID: uuidPtr(r.CooperativeID),
		AllowDelegation: r.AllowDelegation, Handovers: int(r.HandoverCount),
		ListFare: r.ListFareMinor, DiscountPct: int(r.PreferentialDiscountPct),
	}
	if r.CancelReason.Valid {
		reason := string(r.CancelReason.TripCancelReason)
		t.CancelReason = &reason
	}
	return t
}

// loadForUpdate locks the trip row and loads its open proposal.
func loadForUpdate(ctx context.Context, q *store.Queries, id uuid.UUID) (*Trip, error) {
	row, err := q.GetTripForUpdate(ctx, id)
	if err != nil {
		return nil, err
	}
	t := fromRow(row)
	if err := loadNames(ctx, q, t); err != nil {
		return nil, err
	}
	p, err := q.GetOpenProposal(ctx, id)
	if err == nil {
		t.Proposal = &Proposal{
			ID: p.ID, ProposedBy: Party(p.ProposedBy), Amount: p.AmountMinor, Status: ProposalStatus(p.Status),
			CreatedAt: p.CreatedAt, ExpiresAt: p.ExpiresAt,
		}
	} else if !store.IsNotFound(err) {
		return nil, err
	}
	return t, nil
}

func insertTrip(ctx context.Context, q *store.Queries, t *Trip) error {
	return q.InsertTrip(ctx, store.InsertTripParams{
		ID: t.ID, PassengerID: t.PassengerID, DriverID: t.DriverID, CityCode: t.CityCode, Currency: t.Currency,
		PickupLat: t.Pickup.Lat, PickupLng: t.Pickup.Lng, DropoffLat: t.Dropoff.Lat, DropoffLng: t.Dropoff.Lng,
		RouteDistanceM: t.DistanceM, RouteDurationS: t.DurationS, SuggestedFareMinor: t.SuggestedFare,
		Status: store.TripStatus(t.Status), RespondBy: ts(t.RespondBy), CreatedAt: t.CreatedAt,
		Dispatch: string(t.Dispatch), RequestedDriverID: t.RequestedDriverID,
		CooperativeID: nullUUID(t.CooperativeID), AllowDelegation: t.AllowDelegation, HandoverCount: int16(t.Handovers),
		ListFareMinor: t.ListFare, PreferentialDiscountPct: int16(t.DiscountPct),
	})
}

// save persists the mutable trip fields and every proposal touched by the last operation.
func save(ctx context.Context, q *store.Queries, t *Trip) error {
	var reason store.NullTripCancelReason
	if t.CancelReason != nil {
		reason = store.NullTripCancelReason{TripCancelReason: store.TripCancelReason(*t.CancelReason), Valid: true}
	}
	// Las propuestas cerradas primero: el índice permite una sola abierta por viaje.
	for _, p := range t.ClosedProposals {
		if err := upsertProposal(ctx, q, t.ID, p); err != nil {
			return err
		}
	}
	t.ClosedProposals = nil
	if t.Proposal != nil {
		if err := upsertProposal(ctx, q, t.ID, *t.Proposal); err != nil {
			return err
		}
	}
	return q.UpdateTrip(ctx, store.UpdateTripParams{
		ID: t.ID, Status: store.TripStatus(t.Status), AgreedFareMinor: int8(t.AgreedFare), DriverPayoutMinor: int8(t.DriverPayout),
		CancelReason: reason, RespondBy: ts(t.RespondBy), NegotiationExpiresAt: ts(t.NegotiationExpiresAt),
		AcceptedAt: ts(t.AcceptedAt), ArrivedAt: ts(t.ArrivedAt), StartedAt: ts(t.StartedAt),
		CompletedAt: ts(t.CompletedAt), CancelledAt: ts(t.CancelledAt),
		DriverID: t.DriverID, HandoverCount: int16(t.Handovers),
		SuggestedFareMinor: t.SuggestedFare, PreferentialDiscountPct: int16(t.DiscountPct),
	})
}

func upsertProposal(ctx context.Context, q *store.Queries, tripID uuid.UUID, p Proposal) error {
	return q.UpsertProposal(ctx, store.UpsertProposalParams{
		ID: p.ID, TripID: tripID, ProposedBy: store.FareParty(p.ProposedBy), AmountMinor: p.Amount,
		Status: store.FareProposalStatus(p.Status), CreatedAt: p.CreatedAt, ExpiresAt: p.ExpiresAt,
	})
}

// isUniqueViolation reports a PostgreSQL unique_violation (23505).
func isUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23505"
}
