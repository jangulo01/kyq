// Package reservations implements the agenda of spec 010 (US1): a passenger books a trip with
// one of his Chosen Drivers for later; the driver confirms it, both get a reminder and, at the
// time, the nominal request of 001 is created with the reserved fare.
package reservations

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/fares"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/trips"
)

// Plazos de la agenda (FR-001–FR-006).
const (
	MinLead      = 30 * time.Minute
	MaxLead      = 7 * 24 * time.Hour
	ExpireBefore = 15 * time.Minute
	RemindBefore = 30 * time.Minute
	// Si a la hora el pasajero sigue en otro viaje, se reintenta hasta este margen.
	RetryAfter = 30 * time.Minute
	MaxActive  = 3
	// Dos reservas del mismo conductor más cerca que esto se marcan como solapadas.
	OverlapWindow = 30 * time.Minute
	maxLabel      = 200
)

// Estados de una reserva (data-model.md).
const (
	StatusPending   = "pending"
	StatusConfirmed = "confirmed"
	StatusRejected  = "rejected"
	StatusCancelled = "cancelled"
	StatusExpired   = "expired"
	StatusFulfilled = "fulfilled"
	StatusMissed    = "missed"
)

// EventUpdated tells both parties that a reservation changed.
const EventUpdated = "reservation.updated"

var (
	// ErrInvalidTime: la hora debe estar entre 30 minutos y 7 días desde ahora.
	ErrInvalidTime = errors.New("invalid reservation time")
	// ErrTooMany: el pasajero ya tiene 3 reservas futuras activas.
	ErrTooMany = errors.New("too many reservations")
	// ErrNotAffiliated: solo se reserva con un Conductor Elegido.
	ErrNotAffiliated = errors.New("not one of the passenger's chosen drivers")
	// ErrNotFound: la reserva no existe o no es de quien la pide.
	ErrNotFound = errors.New("reservation not found")
	// ErrInvalidState: la reserva ya cambió (decidida, cancelada, pasada la hora).
	ErrInvalidState = errors.New("reservation can no longer change")
	// ErrInvalidLabel: dirección de más de 200 caracteres.
	ErrInvalidLabel = errors.New("invalid label")
)

// Trips is what the agenda needs from the trip module (trips.Service).
type Trips interface {
	Quote(ctx context.Context, pickup, dropoff trips.Point) (fares.Table, fares.Route, int64, error)
	Discount(ctx context.Context, passengerID, driverID uuid.UUID) (int, error)
	RequestWith(ctx context.Context, passengerID, driverID uuid.UUID, pickup, dropoff trips.Point, opts trips.RequestOptions) (*trips.Trip, error)
}

// PersonRef is a party of the reservation, without contact data.
type PersonRef struct {
	ID          uuid.UUID `json:"id"`
	DisplayName string    `json:"display_name"`
}

// Reservation is contracts: Reservation.
type Reservation struct {
	ID                      uuid.UUID   `json:"id"`
	Passenger               PersonRef   `json:"passenger"`
	Driver                  PersonRef   `json:"driver"`
	Pickup                  trips.Point `json:"pickup"`
	Dropoff                 trips.Point `json:"dropoff"`
	PickupLabel             *string     `json:"pickup_label"`
	DropoffLabel            *string     `json:"dropoff_label"`
	ScheduledAt             time.Time   `json:"scheduled_at"`
	DistanceM               int         `json:"distance_m"`
	DurationS               int         `json:"duration_s"`
	Currency                string      `json:"currency"`
	FareMinor               int64       `json:"fare_minor"`
	ListFareMinor           int64       `json:"list_fare_minor"`
	PreferentialDiscountPct int         `json:"preferential_discount_pct"`
	Status                  string      `json:"status"`
	CancelledByMe           bool        `json:"cancelled_by_me"`
	TripID                  *uuid.UUID  `json:"trip_id"`
	// Overlaps: otra reserva del mismo conductor a menos de 30 minutos (solo en la agenda).
	Overlaps bool `json:"overlaps"`
}

// NewReservation is the passenger's request (POST /v1/reservations).
type NewReservation struct {
	DriverID     uuid.UUID
	Pickup       trips.Point
	Dropoff      trips.Point
	PickupLabel  string
	DropoffLabel string
	ScheduledAt  time.Time
}

// Service implements the agenda.
type Service struct {
	Store     *store.Store
	Trips     Trips
	Notify    *notify.Service
	Publisher realtime.Publisher
	Now       func() time.Time
	Logger    *slog.Logger
}

func (s *Service) now() time.Time {
	if s.Now != nil {
		return s.Now()
	}
	return time.Now()
}

func (s *Service) logger() *slog.Logger {
	if s.Logger != nil {
		return s.Logger
	}
	return slog.Default()
}

func optLabel(v string) (pgtype.Text, error) {
	v = strings.TrimSpace(v)
	if utf8.RuneCountInString(v) > maxLabel {
		return pgtype.Text{}, ErrInvalidLabel
	}
	return pgtype.Text{String: v, Valid: v != ""}, nil
}

// Create books a trip with a Chosen Driver at the reserved fare of now (FR-001, FR-006).
func (s *Service) Create(ctx context.Context, passengerID uuid.UUID, in NewReservation) (Reservation, error) {
	now := s.now()
	lead := in.ScheduledAt.Sub(now)
	if lead < MinLead || lead > MaxLead {
		return Reservation{}, ErrInvalidTime
	}
	pickupLabel, err := optLabel(in.PickupLabel)
	if err != nil {
		return Reservation{}, err
	}
	dropoffLabel, err := optLabel(in.DropoffLabel)
	if err != nil {
		return Reservation{}, err
	}
	affiliated, err := s.Store.IsAffiliated(ctx, store.IsAffiliatedParams{PassengerID: passengerID, DriverID: in.DriverID})
	if err != nil {
		return Reservation{}, err
	}
	if !affiliated {
		return Reservation{}, ErrNotAffiliated
	}
	table, route, list, err := s.Trips.Quote(ctx, in.Pickup, in.Dropoff)
	if err != nil {
		return Reservation{}, err
	}
	pct, err := s.Trips.Discount(ctx, passengerID, in.DriverID)
	if err != nil {
		return Reservation{}, err
	}
	fare := list
	if pct > 0 {
		fare = table.WithDiscount(list, pct)
	}
	id := uuid.New()
	var notices []*store.Notice
	err = s.Store.WithTx(ctx, func(q *store.Queries) error {
		n, err := q.CountActiveReservationsForPassenger(ctx, store.CountActiveReservationsForPassengerParams{PassengerID: passengerID, Now: now})
		if err != nil {
			return err
		}
		if n >= MaxActive {
			return ErrTooMany
		}
		if err := q.InsertReservation(ctx, store.InsertReservationParams{
			ID: id, PassengerID: passengerID, DriverID: in.DriverID,
			PickupLat: in.Pickup.Lat, PickupLng: in.Pickup.Lng, DropoffLat: in.Dropoff.Lat, DropoffLng: in.Dropoff.Lng,
			PickupLabel: pickupLabel, DropoffLabel: dropoffLabel, ScheduledAt: in.ScheduledAt,
			DistanceM: int32(route.DistanceM), DurationS: int32(route.DurationS), Currency: table.Currency,
			FareMinor: fare, ListFareMinor: list, PreferentialDiscountPct: int16(pct), CreatedAt: now,
		}); err != nil {
			return err
		}
		name, err := q.GetUserDisplayName(ctx, passengerID)
		if err != nil {
			return err
		}
		n2, err := notify.Create(ctx, q, in.DriverID, now, notify.Notice{
			Kind: "reservation_requested", DedupKey: "reservation_requested:" + id.String(),
			Title: "Nueva reserva de " + name,
			Body:  name + " quiere reservar un viaje para el " + formatWhen(in.ScheduledAt) + ". Acéptala o recházala en tu Agenda.",
		})
		notices = append(notices, n2)
		return err
	})
	if err != nil {
		return Reservation{}, err
	}
	s.announce(ctx, id, passengerID, in.DriverID, StatusPending, notices...)
	return s.view(ctx, id, passengerID)
}

// PassengerList returns the passenger's upcoming reservations and those of the last day.
func (s *Service) PassengerList(ctx context.Context, passengerID uuid.UUID) ([]Reservation, error) {
	rows, err := s.Store.ListPassengerReservations(ctx, store.ListPassengerReservationsParams{
		PassengerID: passengerID, Since: s.now().Add(-24 * time.Hour),
	})
	if err != nil {
		return nil, err
	}
	out := make([]Reservation, len(rows))
	for i, r := range rows {
		out[i] = toView(r.Reservation, r.PassengerName, r.DriverName, passengerID)
	}
	return out, nil
}

// Agenda returns the driver's reservations from the last hour on, flagging overlaps (FR-002).
func (s *Service) Agenda(ctx context.Context, driverID uuid.UUID) ([]Reservation, error) {
	rows, err := s.Store.ListDriverAgenda(ctx, store.ListDriverAgendaParams{DriverID: driverID, Since: s.now().Add(-time.Hour)})
	if err != nil {
		return nil, err
	}
	out := make([]Reservation, len(rows))
	for i, r := range rows {
		out[i] = toView(r.Reservation, r.PassengerName, r.DriverName, driverID)
	}
	open := func(st string) bool { return st == StatusPending || st == StatusConfirmed }
	for i := range out {
		for j := range out {
			if i == j || !open(out[i].Status) || !open(out[j].Status) {
				continue
			}
			d := out[i].ScheduledAt.Sub(out[j].ScheduledAt)
			if d < OverlapWindow && d > -OverlapWindow {
				out[i].Overlaps = true
			}
		}
	}
	return out, nil
}

// Decide accepts or rejects a pending reservation of driverID (FR-002).
func (s *Service) Decide(ctx context.Context, driverID, id uuid.UUID, accept bool) (Reservation, error) {
	var r store.Reservation
	status := StatusRejected
	if accept {
		status = StatusConfirmed
	}
	err := s.change(ctx, id, func(q *store.Queries, row *store.Reservation, now time.Time) error {
		if row.DriverID != driverID {
			return ErrNotFound
		}
		if row.Status != store.ReservationStatusPending || !row.ScheduledAt.After(now) {
			return ErrInvalidState
		}
		row.Status = store.ReservationStatus(status)
		r = *row
		return nil
	})
	if err != nil {
		return Reservation{}, err
	}
	s.announce(ctx, id, r.PassengerID, r.DriverID, status)
	return s.view(ctx, id, driverID)
}

// Cancel cancels a pending or confirmed reservation before its time, by either party (FR-005).
func (s *Service) Cancel(ctx context.Context, userID, id uuid.UUID) (Reservation, error) {
	var r store.Reservation
	var notices []*store.Notice
	err := s.change(ctx, id, func(q *store.Queries, row *store.Reservation, now time.Time) error {
		if row.PassengerID != userID && row.DriverID != userID {
			return ErrNotFound
		}
		if (row.Status != store.ReservationStatusPending && row.Status != store.ReservationStatusConfirmed) || !row.ScheduledAt.After(now) {
			return ErrInvalidState
		}
		row.Status, row.CancelledBy = store.ReservationStatusCancelled, uuid.NullUUID{UUID: userID, Valid: true}
		r = *row
		if userID == row.PassengerID {
			n, err := notify.Create(ctx, q, row.DriverID, now, notify.Notice{
				Kind: "reservation_cancelled", DedupKey: "reservation_cancelled:" + id.String(),
				Title: "Reserva cancelada", Body: "El pasajero canceló la reserva del " + formatWhen(row.ScheduledAt) + ".",
			})
			notices = append(notices, n)
			return err
		}
		return nil
	})
	if err != nil {
		return Reservation{}, err
	}
	s.announce(ctx, id, r.PassengerID, r.DriverID, StatusCancelled, notices...)
	return s.view(ctx, id, userID)
}

// change locks the reservation, applies fn and saves the status fields.
func (s *Service) change(ctx context.Context, id uuid.UUID, fn func(q *store.Queries, r *store.Reservation, now time.Time) error) error {
	now := s.now()
	return s.Store.WithTx(ctx, func(q *store.Queries) error {
		r, err := q.LockReservation(ctx, id)
		if store.IsNotFound(err) {
			return ErrNotFound
		}
		if err != nil {
			return err
		}
		if err := fn(q, &r, now); err != nil {
			return err
		}
		return save(ctx, q, r, now)
	})
}

func save(ctx context.Context, q *store.Queries, r store.Reservation, now time.Time) error {
	return q.UpdateReservationStatus(ctx, store.UpdateReservationStatusParams{
		ID: r.ID, Status: r.Status, CancelledBy: r.CancelledBy, TripID: r.TripID, RemindedAt: r.RemindedAt, UpdatedAt: now,
	})
}

func (s *Service) view(ctx context.Context, id, viewer uuid.UUID) (Reservation, error) {
	row, err := s.Store.GetReservationView(ctx, id)
	if store.IsNotFound(err) {
		return Reservation{}, ErrNotFound
	}
	if err != nil {
		return Reservation{}, err
	}
	return toView(row.Reservation, row.PassengerName, row.DriverName, viewer), nil
}

func toView(r store.Reservation, passengerName, driverName string, viewer uuid.UUID) Reservation {
	v := Reservation{
		ID: r.ID, Passenger: PersonRef{ID: r.PassengerID, DisplayName: passengerName},
		Driver: PersonRef{ID: r.DriverID, DisplayName: driverName},
		Pickup: trips.Point{Lat: r.PickupLat, Lng: r.PickupLng}, Dropoff: trips.Point{Lat: r.DropoffLat, Lng: r.DropoffLng},
		ScheduledAt: r.ScheduledAt, DistanceM: int(r.DistanceM), DurationS: int(r.DurationS), Currency: r.Currency,
		FareMinor: r.FareMinor, ListFareMinor: r.ListFareMinor, PreferentialDiscountPct: int(r.PreferentialDiscountPct),
		Status: string(r.Status), CancelledByMe: r.CancelledBy.Valid && r.CancelledBy.UUID == viewer,
	}
	if r.PickupLabel.Valid {
		v.PickupLabel = &r.PickupLabel.String
	}
	if r.DropoffLabel.Valid {
		v.DropoffLabel = &r.DropoffLabel.String
	}
	if r.TripID.Valid {
		v.TripID = &r.TripID.UUID
	}
	return v
}

// announce publishes "reservation.updated" to both parties and, after commit, the driver's
// notices created in the transaction (only drivers have notices).
func (s *Service) announce(ctx context.Context, id, passengerID, driverID uuid.UUID, status string, notices ...*store.Notice) {
	for _, n := range notices {
		s.Notify.Announce(ctx, n)
	}
	if s.Publisher == nil {
		return
	}
	ev := realtime.Event{Type: EventUpdated, OccurredAt: s.now(), Data: map[string]any{"reservation_id": id, "status": status}}
	for _, u := range []uuid.UUID{passengerID, driverID} {
		if err := s.Publisher.Publish(ctx, "user:"+u.String(), ev); err != nil {
			s.logger().WarnContext(ctx, "publish reservation.updated", "err", err)
		}
	}
}

// bogota formats times for people (Colombia, UTC-5 without DST).
var bogota = time.FixedZone("COT", -5*3600)

func formatWhen(t time.Time) string {
	l := t.In(bogota)
	return fmt.Sprintf("%02d/%02d a las %02d:%02d", l.Day(), int(l.Month()), l.Hour(), l.Minute())
}
