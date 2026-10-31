package reservations

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/trips"
)

// EventPassengerNotice carries a short message for the passenger, who has no notices list.
const EventPassengerNotice = "reservation.notice"

// Sweep handles the reservations due now: expires unconfirmed ones 15 minutes before, reminds
// confirmed ones 30 minutes before and, at the time, creates the nominal request (FR-003–FR-005).
// It returns how many it changed.
func (s *Service) Sweep(ctx context.Context) (int, error) {
	now := s.now()
	ids, err := s.Store.ListDueReservations(ctx, store.ListDueReservationsParams{
		ExpireBefore: now.Add(ExpireBefore), RemindBefore: now.Add(RemindBefore), Now: now,
	})
	if err != nil {
		return 0, err
	}
	n := 0
	for _, id := range ids {
		changed, err := s.process(ctx, id, now)
		if err != nil {
			s.logger().WarnContext(ctx, "process reservation", "reservation", id, "err", err)
			continue
		}
		if changed {
			n++
		}
	}
	return n, nil
}

// RunSweeper runs Sweep every interval until ctx ends.
func (s *Service) RunSweeper(ctx context.Context, every time.Duration) {
	t := time.NewTicker(every)
	defer t.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-t.C:
			if _, err := s.Sweep(ctx); err != nil && ctx.Err() == nil {
				s.logger().WarnContext(ctx, "sweep reservations", "err", err)
			}
		}
	}
}

type outcome struct {
	status          string
	notices         []*store.Notice
	passengerNotice string
}

func (s *Service) process(ctx context.Context, id uuid.UUID, now time.Time) (bool, error) {
	var r store.Reservation
	var out outcome
	err := s.Store.WithTx(ctx, func(q *store.Queries) error {
		var err error
		r, err = q.LockReservationSkipLocked(ctx, id)
		if store.IsNotFound(err) {
			return nil // otro barrido la está atendiendo
		}
		if err != nil {
			return err
		}
		when := formatWhen(r.ScheduledAt)
		driverNotice := func(kind, title, body string) error {
			n, err := notify.Create(ctx, q, r.DriverID, now, notify.Notice{
				Kind: kind, DedupKey: kind + ":" + r.ID.String(), Title: title, Body: body,
			})
			out.notices = append(out.notices, n)
			return err
		}
		switch {
		case r.Status == store.ReservationStatusPending && !r.ScheduledAt.After(now.Add(ExpireBefore)):
			// FR-005: sin confirmar 15 minutos antes, se cancela sola.
			r.Status, out.status = store.ReservationStatusExpired, StatusExpired
			out.passengerNotice = "Tu reserva del " + when + " no fue confirmada a tiempo y se canceló."
			if err := driverNotice("reservation_expired", "Reserva vencida", "La reserva del "+when+" venció sin respuesta."); err != nil {
				return err
			}
		case r.Status == store.ReservationStatusConfirmed && r.ScheduledAt.After(now):
			if r.RemindedAt.Valid || r.ScheduledAt.After(now.Add(RemindBefore)) {
				return nil
			}
			// FR-003: recordatorio 30 minutos antes.
			r.RemindedAt, out.status = pgtype.Timestamptz{Time: now, Valid: true}, StatusConfirmed
			out.passengerNotice = "Tu viaje reservado es a las " + when[len(when)-5:] + "."
			if err := driverNotice("reservation_reminder", "Reserva en 30 minutos", "Tienes una reserva el "+when+". Ponte ONLINE a tiempo."); err != nil {
				return err
			}
		case r.Status == store.ReservationStatusConfirmed:
			if err := s.fulfill(ctx, q, &r, now, &out); err != nil {
				return err
			}
		default:
			return nil
		}
		return save(ctx, q, r, now)
	})
	if err != nil || out.status == "" {
		return false, err
	}
	s.announce(ctx, r.ID, r.PassengerID, r.DriverID, out.status, out.notices...)
	if out.passengerNotice != "" && s.Publisher != nil {
		ev := realtime.Event{Type: EventPassengerNotice, OccurredAt: now, Data: map[string]any{
			"reservation_id": r.ID, "status": out.status, "message": out.passengerNotice,
		}}
		if err := s.Publisher.Publish(ctx, "user:"+r.PassengerID.String(), ev); err != nil {
			s.logger().WarnContext(ctx, "publish reservation.notice", "err", err)
		}
	}
	return true, nil
}

// fulfill creates the nominal request at the reserved fare (FR-004). The request runs in its own
// transaction: the reservation row stays locked meanwhile.
func (s *Service) fulfill(ctx context.Context, q *store.Queries, r *store.Reservation, now time.Time, out *outcome) error {
	trip, err := s.Trips.RequestWith(ctx, r.PassengerID, r.DriverID,
		trips.Point{Lat: r.PickupLat, Lng: r.PickupLng}, trips.Point{Lat: r.DropoffLat, Lng: r.DropoffLng},
		trips.RequestOptions{ReservedFare: r.FareMinor, Reservation: true})
	switch {
	case err == nil:
		r.Status, r.TripID, out.status = store.ReservationStatusFulfilled, uuid.NullUUID{UUID: trip.ID, Valid: true}, StatusFulfilled
	case errors.Is(err, trips.ErrDriverNotFree), errors.Is(err, trips.ErrNoDriverAvailable):
		r.Status, out.status = store.ReservationStatusMissed, StatusMissed
		out.passengerNotice = "Tu conductor no está disponible para la reserva. Puedes pedir a su cooperativa o a un conductor cercano."
	case errors.Is(err, trips.ErrPassengerHasTrip):
		// Edge case: el pasajero sigue en otro viaje; se reintenta hasta 30 minutos después.
		if now.Sub(r.ScheduledAt) < RetryAfter {
			return nil
		}
		r.Status, out.status = store.ReservationStatusExpired, StatusExpired
		out.passengerNotice = "No se pudo iniciar tu viaje reservado porque tenías otro viaje en curso."
	case errors.Is(err, trips.ErrNotAffiliated), errors.Is(err, trips.ErrAccountSuspended):
		r.Status, out.status = store.ReservationStatusCancelled, StatusCancelled
		out.passengerNotice = "Tu reserva se canceló: ese conductor ya no está en tus Conductores Elegidos."
	default:
		return err
	}
	return nil
}
