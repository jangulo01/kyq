package trips

import (
	"context"
	"errors"
	"log/slog"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/fares"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/telemetry"
)

var (
	ErrNotFound              = errors.New("trip not found")
	ErrNotAffiliated         = errors.New("driver is not one of the passenger's chosen drivers")
	ErrDriverNotFree         = errors.New("driver is not free")
	ErrPassengerHasTrip      = errors.New("passenger already has an active trip")
	ErrCityNotConfigured     = errors.New("fare table not configured for city")
	ErrNoRoute               = fares.ErrNoRoute
	errUniqueActiveViolation = errors.New("unique active trip violation")
)

// Service runs trip use cases. Every change happens in a transaction that locks the trip row;
// events are published after commit.
type Service struct {
	Store     *store.Store
	Routes    fares.RouteEstimator
	Publisher realtime.Publisher
	Usage     telemetry.Usage
	// Payments opens the trip payment on COMPLETED (004); nil keeps 001's behaviour (paid
	// outside the app).
	Payments PaymentOpener
	CityCode string
	Now      func() time.Time
	Logger   *slog.Logger
}

// CompletedTrip is what the payment of a trip needs from it.
type CompletedTrip struct {
	ID          uuid.UUID
	PassengerID uuid.UUID
	DriverID    uuid.UUID
	FareMinor   int64
	Currency    string
}

// PaymentOpener opens the payment of a completed trip inside the transaction that completes it,
// so there is never a completed trip without its payment (004, research R5).
type PaymentOpener interface {
	OpenForTrip(ctx context.Context, q *store.Queries, trip CompletedTrip, now time.Time) error
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

// Quote returns the suggested fare for a route (FR-010).
func (s *Service) Quote(ctx context.Context, pickup, dropoff Point) (fares.Table, fares.Route, int64, error) {
	// La cotización previa no tiene conductor: cuenta como coste sin asignar (uuid nulo).
	return s.quote(ctx, uuid.Nil, pickup, dropoff)
}

func (s *Service) quote(ctx context.Context, driverID uuid.UUID, pickup, dropoff Point) (fares.Table, fares.Route, int64, error) {
	row, err := s.Store.GetFareTable(ctx, s.CityCode)
	if store.IsNotFound(err) {
		return fares.Table{}, fares.Route{}, 0, ErrCityNotConfigured
	}
	if err != nil {
		return fares.Table{}, fares.Route{}, 0, err
	}
	table := fares.Table{
		CityCode: row.CityCode, Currency: row.Currency, BaseMinor: row.BaseMinor, PerKmMinor: row.PerKmMinor,
		PerMinuteMinor: row.PerMinuteMinor, MinimumMinor: row.MinimumMinor, RoundingMinor: row.RoundingMinor,
	}
	telemetry.Add(s.Usage, driverID, telemetry.Routes, 1)
	route, err := s.Routes.Route(ctx, pickup.Lat, pickup.Lng, dropoff.Lat, dropoff.Lng)
	if err != nil {
		return fares.Table{}, fares.Route{}, 0, err
	}
	return table, route, table.Suggest(route.DistanceM, route.DurationS), nil
}

// Request creates a nominal trip to a chosen, free driver (FR-009, FR-011, FR-012).
func (s *Service) Request(ctx context.Context, passengerID, driverID uuid.UUID, pickup, dropoff Point) (*Trip, error) {
	return s.RequestWith(ctx, passengerID, driverID, pickup, dropoff, RequestOptions{Dispatch: DispatchChosenDriver})
}

// RequestWith creates a trip with the passenger's dispatch choice: to the chosen driver, with
// optional consent to pass it to his cooperative, or straight to that cooperative (006,
// RN-KYQ-008). The first offer goes to whoever the dispatch picks.
func (s *Service) RequestWith(ctx context.Context, passengerID, driverID uuid.UUID, pickup, dropoff Point, opts RequestOptions) (*Trip, error) {
	table, route, fare, err := s.quote(ctx, driverID, pickup, dropoff)
	if err != nil {
		return nil, err
	}
	id, err := uuid.NewV7()
	if err != nil {
		return nil, err
	}
	now := s.now()
	trip := NewTrip(id, passengerID, driverID, s.CityCode, table.Currency, pickup, dropoff,
		route.DistanceM, route.DurationS, fare, now)

	var passengerName string
	err = s.Store.WithTx(ctx, func(q *store.Queries) error {
		affiliated, err := q.IsAffiliated(ctx, store.IsAffiliatedParams{PassengerID: passengerID, DriverID: driverID})
		if err != nil {
			return err
		}
		if !affiliated {
			return ErrNotAffiliated
		}
		if _, err := q.GetActiveTripForPassenger(ctx, passengerID); err == nil {
			return ErrPassengerHasTrip
		} else if !store.IsNotFound(err) {
			return err
		}
		if err := dispatchNew(ctx, q, trip, opts, now); err != nil {
			return err
		}
		if trip.DriverID != driverID {
			// El compañero elegido ya quedó bloqueado por la búsqueda; se confirma que sigue libre.
			d, err := q.GetDriverForPresence(ctx, trip.DriverID)
			if err != nil {
				return err
			}
			if d.Presence != store.DriverPresenceFree || d.Suspended {
				return ErrNoDriverAvailable
			}
		}
		if passengerName, err = q.GetUserDisplayName(ctx, passengerID); err != nil {
			return err
		}
		if err := insertTrip(ctx, q, trip); err != nil {
			if isUniqueViolation(err) {
				return errUniqueActiveViolation
			}
			return err
		}
		if err := q.InsertTripOffer(ctx, store.InsertTripOfferParams{
			TripID: trip.ID, DriverID: trip.DriverID, OfferedAt: now, Handover: trip.Handovers > 0,
		}); err != nil {
			return err
		}
		if err := loadNames(ctx, q, trip); err != nil {
			return err
		}
		// La oferta reserva al conductor: nadie más puede pedirle viaje (FR-012).
		return q.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: trip.DriverID, Presence: store.DriverPresenceBusy})
	})
	if errors.Is(err, errUniqueActiveViolation) {
		if trip.DriverID != driverID {
			return nil, ErrNoDriverAvailable
		}
		return nil, ErrDriverNotFree
	}
	if err != nil {
		return nil, err
	}
	msgs := eventsFor("", nil, trip, true, passengerName, nil, now)
	msgs = append(msgs, presenceMessage(trip.DriverID, store.DriverPresenceBusy, nil, now))
	s.publish(ctx, msgs)
	telemetry.Add(s.Usage, trip.DriverID, telemetry.Events, int64(len(msgs)))
	return trip, nil
}

// Active returns the user's trip that has not ended yet, so an app that restarted can go back
// to it. ErrNotFound when there is none.
func (s *Service) Active(ctx context.Context, userID uuid.UUID, asDriver bool) (*Trip, error) {
	var row store.Trip
	var err error
	if asDriver {
		row, err = s.Store.GetActiveTripForDriver(ctx, userID)
	} else {
		row, err = s.Store.GetActiveTripForPassenger(ctx, userID)
	}
	if store.IsNotFound(err) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return s.Get(ctx, userID, row.ID)
}

// Get returns a trip the user takes part in.
func (s *Service) Get(ctx context.Context, userID, tripID uuid.UUID) (*Trip, error) {
	var trip *Trip
	err := s.Store.WithTx(ctx, func(q *store.Queries) error {
		var err error
		trip, err = s.loadAsParticipant(ctx, q, userID, tripID)
		return err
	})
	return trip, err
}

func (s *Service) loadAsParticipant(ctx context.Context, q *store.Queries, userID, tripID uuid.UUID) (*Trip, error) {
	trip, err := loadForUpdate(ctx, q, tripID)
	if store.IsNotFound(err) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if _, ok := trip.PartyOf(userID); !ok {
		return nil, ErrNotFound // no revela que el viaje existe
	}
	return trip, nil
}

// Act loads the trip as userID, applies op with the caller's party and saves the result.
func (s *Service) Act(ctx context.Context, userID, tripID uuid.UUID, op func(t *Trip, party Party, now time.Time) error) (*Trip, error) {
	now := s.now()
	var trip *Trip
	var msgs []Message
	err := s.Store.WithTx(ctx, func(q *store.Queries) error {
		var err error
		if trip, err = s.loadAsParticipant(ctx, q, userID, tripID); err != nil {
			return err
		}
		party, _ := trip.PartyOf(userID)
		before, beforeProposal := snapshot(trip)
		if err := op(trip, party, now); err != nil {
			return err
		}
		msgs, err = s.persist(ctx, q, trip, before, beforeProposal, now)
		return err
	})
	if err != nil {
		return nil, err
	}
	s.publish(ctx, msgs)
	telemetry.Add(s.Usage, trip.DriverID, telemetry.Events, int64(len(msgs)))
	return trip, nil
}

// ExpireDue applies every response deadline that has passed. The sweeper calls it each second.
func (s *Service) ExpireDue(ctx context.Context) (int, error) {
	now := s.now()
	var msgs []Message
	count := 0
	err := s.Store.WithTx(ctx, func(q *store.Queries) error {
		ids, err := q.ListDueTripIDs(ctx, pgtype.Timestamptz{Time: now, Valid: true})
		if err != nil {
			return err
		}
		for _, id := range ids {
			trip, err := loadForUpdate(ctx, q, id)
			if err != nil {
				return err
			}
			before, beforeProposal := snapshot(trip)
			if !trip.Expire(now) {
				continue
			}
			m, err := s.persist(ctx, q, trip, before, beforeProposal, now)
			if err != nil {
				return err
			}
			msgs = append(msgs, m...)
			telemetry.Add(s.Usage, trip.DriverID, telemetry.Events, int64(len(m)))
			count++
		}
		return nil
	})
	if err != nil {
		return 0, err
	}
	s.publish(ctx, msgs)
	return count, nil
}

func snapshot(t *Trip) (Status, *uuid.UUID) {
	if t.Proposal == nil {
		return t.Status, nil
	}
	id := t.Proposal.ID
	return t.Status, &id
}

// persist saves the trip, frees or reserves the driver and returns the events to publish.
func (s *Service) persist(ctx context.Context, q *store.Queries, t *Trip, before Status, beforeProposal *uuid.UUID, now time.Time) ([]Message, error) {
	// RN-KYQ-008: una oferta que terminó sin conductor pasa a un compañero o se da por perdida.
	if t.AwaitsHandOver(before) {
		if err := handOverOrGiveUp(ctx, q, t, now); err != nil {
			return nil, err
		}
	}
	if err := save(ctx, q, t); err != nil {
		return nil, err
	}
	if t.PreviousDriverID != nil {
		return afterHandOver(ctx, q, t, now)
	}
	if err := syncPTTChannel(ctx, q, t, before, now); err != nil {
		return nil, err
	}
	if s.Payments != nil && before != StatusCompleted && t.Status == StatusCompleted {
		if err := s.Payments.OpenForTrip(ctx, q, CompletedTrip{
			ID: t.ID, PassengerID: t.PassengerID, DriverID: t.DriverID, FareMinor: *t.DriverPayout, Currency: t.Currency,
		}, now); err != nil {
			return nil, err
		}
	}
	var msgs []Message
	switch {
	case before.Active() && !t.Status.Active():
		presence, err := releaseDriver(ctx, q, t.DriverID)
		if err != nil {
			return nil, err
		}
		msgs = append(msgs, presenceMessage(t.DriverID, presence, nil, now))
	case t.Status == StatusAccepted && before != StatusAccepted:
		// Estimación inicial: duración del viaje; se afina con la ubicación del conductor.
		until := now.Add(time.Duration(t.DurationS) * time.Second)
		if err := q.SetDriverPresence(ctx, store.SetDriverPresenceParams{
			UserID: t.DriverID, Presence: store.DriverPresenceBusy, BusyUntilEstimate: pgtype.Timestamptz{Time: until, Valid: true},
		}); err != nil {
			return nil, err
		}
		msgs = append(msgs, presenceMessage(t.DriverID, store.DriverPresenceBusy, &until, now))
	}

	var driver *DriverView
	if t.Status == StatusAccepted && before != StatusAccepted {
		d, err := q.GetDriverPublic(ctx, t.DriverID)
		if err != nil {
			return nil, err
		}
		driver = &DriverView{DisplayName: d.DisplayName, VehiclePlate: d.VehiclePlate, VehicleDescription: d.VehicleDescription}
	}
	passengerName := ""
	if t.Status == StatusRequested && before != StatusRequested {
		name, err := q.GetUserDisplayName(ctx, t.PassengerID)
		if err != nil {
			return nil, err
		}
		passengerName = name
	}
	return append(eventsFor(before, beforeProposal, t, false, passengerName, driver, now), msgs...), nil
}

// releaseDriver deja libre al conductor cuando termina su viaje u oferta, salvo que lo hayan
// suspendido mientras tanto (007, FR-016): entonces queda OFFLINE y no vuelve a recibir solicitudes.
func releaseDriver(ctx context.Context, q *store.Queries, driverID uuid.UUID) (store.DriverPresence, error) {
	suspended, err := q.IsUserSuspended(ctx, driverID)
	if err != nil {
		return "", err
	}
	presence := store.DriverPresenceFree
	if suspended {
		presence = store.DriverPresenceOffline
	}
	return presence, q.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: driverID, Presence: presence})
}

// PTTCloseDelay keeps the voice channel open after the trip ends, for forgotten objects and
// similar (RN-KYQ-014).
const PTTCloseDelay = 15 * time.Minute

// syncPTTChannel opens the trip's voice channel on ACCEPTED (RN-KYQ-009) and schedules its
// closing on COMPLETED or CANCELLED; package ptt closes it when due.
func syncPTTChannel(ctx context.Context, q *store.Queries, t *Trip, before Status, now time.Time) error {
	if before == t.Status {
		return nil
	}
	switch t.Status {
	case StatusAccepted:
		return q.OpenPTTChannel(ctx, store.OpenPTTChannelParams{TripID: t.ID, RoomName: "trip-" + t.ID.String(), OpenedAt: now})
	case StatusCompleted:
		return q.SchedulePTTClose(ctx, store.SchedulePTTCloseParams{
			TripID: t.ID, ClosesAt: pgtype.Timestamptz{Time: now.Add(PTTCloseDelay), Valid: true},
		})
	case StatusCancelled:
		// Sin fila si el viaje no llegó a aceptarse: el UPDATE no toca nada.
		return q.SchedulePTTClose(ctx, store.SchedulePTTCloseParams{TripID: t.ID, ClosesAt: pgtype.Timestamptz{Time: now, Valid: true}})
	}
	return nil
}

func presenceMessage(driverID uuid.UUID, presence store.DriverPresence, busyUntil *time.Time, now time.Time) Message {
	return Message{
		Channel: "driver_presence:" + driverID.String(),
		Event: realtime.Event{Type: "driver.presence", OccurredAt: now, Data: map[string]any{
			"driver_id": driverID, "presence": presence, "busy_until_estimate": busyUntil,
		}},
	}
}

// publish sends events best-effort: the state is already committed and clients recover it with
// GET /v1/trips/{id} after reconnecting.
func (s *Service) publish(ctx context.Context, msgs []Message) {
	if s.Publisher == nil {
		return
	}
	for _, m := range msgs {
		if err := s.Publisher.Publish(ctx, m.Channel, m.Event); err != nil {
			s.logger().WarnContext(ctx, "publish realtime event", "channel", m.Channel, "type", m.Event.Type, "err", err)
		}
	}
}

// ParticipantChecker implements realtime.TripParticipantChecker.
type ParticipantChecker struct{ Q *store.Queries }

func (c ParticipantChecker) IsParticipant(ctx context.Context, tripID, userID uuid.UUID) (bool, error) {
	return c.Q.IsTripParticipant(ctx, store.IsTripParticipantParams{ID: tripID, PassengerID: userID})
}

// RunSweeper expires due trips every interval until ctx ends.
func (s *Service) RunSweeper(ctx context.Context, interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			if n, err := s.ExpireDue(ctx); err != nil {
				s.logger().ErrorContext(ctx, "expire due trips", "err", err)
			} else if n > 0 {
				s.logger().InfoContext(ctx, "expired trips", "count", n)
			}
		}
	}
}
