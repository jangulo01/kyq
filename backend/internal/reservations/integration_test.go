package reservations

import (
	"context"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/affiliations"
	"github.com/kyq/backend/internal/fares"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
	"github.com/kyq/backend/internal/trips"
)

type recorder struct {
	mu   sync.Mutex
	sent []string
	data []map[string]any
}

func (r *recorder) Publish(_ context.Context, channel string, ev realtime.Event) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.sent = append(r.sent, channel+" "+ev.Type)
	d, _ := ev.Data.(map[string]any)
	r.data = append(r.data, d)
	return nil
}

func (r *recorder) has(entry string) bool {
	r.mu.Lock()
	defer r.mu.Unlock()
	for _, s := range r.sent {
		if s == entry {
			return true
		}
	}
	return false
}

type fixedRoute struct{}

func (fixedRoute) Route(context.Context, float64, float64, float64, float64) (fares.Route, error) {
	return fares.Route{DistanceM: 5200, DurationS: 900}, nil
}

var (
	pickup  = trips.Point{Lat: 4.60, Lng: -74.08}
	dropoff = trips.Point{Lat: 4.65, Lng: -74.05}
)

// fare is the suggested fare of fixedRoute with the Bogotá table: 14 700 COP.
const fare = 1_470_000

type fixture struct {
	st                     *store.Store
	svc                    *Service
	pub                    *recorder
	clock                  *time.Time
	ana, luz, carlos, beto uuid.UUID
}

func setup(t *testing.T) *fixture {
	st := testdb.New(t)
	ctx := context.Background()
	now := time.Date(2026, 10, 28, 12, 0, 0, 0, time.UTC)
	f := &fixture{st: st, pub: &recorder{}, clock: &now, ana: uuid.New(), luz: uuid.New(), carlos: uuid.New(), beto: uuid.New()}
	admin := uuid.New()
	for _, u := range []store.CreateUserParams{
		{ID: admin, PhoneE164: "+573000000001", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: f.ana, PhoneE164: "+573200000001", Role: store.UserRolePassenger, DisplayName: "Ana"},
		{ID: f.luz, PhoneE164: "+573200000002", Role: store.UserRolePassenger, DisplayName: "Luz"},
		{ID: f.carlos, PhoneE164: "+573100000001", Role: store.UserRoleDriver, DisplayName: "Carlos"},
		{ID: f.beto, PhoneE164: "+573100000002", Role: store.UserRoleDriver, DisplayName: "Beto"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	for i, d := range []uuid.UUID{f.carlos, f.beto} {
		require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: d, QrToken: "qr-agenda-00000" + string(rune('1'+i)), VehiclePlate: "KYQ00" + string(rune('1'+i)), VehicleDescription: "Kia"}))
	}
	require.NoError(t, st.InsertAffiliation(ctx, store.InsertAffiliationParams{PassengerID: f.ana, DriverID: f.carlos}))
	require.NoError(t, st.UpsertFareTable(ctx, store.UpsertFareTableParams{
		CityCode: "bogota", Currency: "COP", BaseMinor: 400_000, PerKmMinor: 120_000, PerMinuteMinor: 30_000,
		MinimumMinor: 700_000, RoundingMinor: 10_000, UpdatedBy: admin,
	}))
	clock := func() time.Time { return *f.clock }
	tripSvc := &trips.Service{Store: st, Routes: fixedRoute{}, Publisher: f.pub, CityCode: "bogota", Now: clock}
	f.svc = &Service{Store: st, Trips: tripSvc, Notify: &notify.Service{Store: st, Publisher: f.pub, Now: clock}, Publisher: f.pub, Now: clock}
	return f
}

func (f *fixture) at(d time.Duration) time.Time { return f.clock.Add(d) }

func (f *fixture) book(t *testing.T, passenger uuid.UUID, in time.Duration) Reservation {
	r, err := f.svc.Create(context.Background(), passenger, NewReservation{
		DriverID: f.carlos, Pickup: pickup, Dropoff: dropoff, DropoffLabel: "Centro Comercial Andino", ScheduledAt: f.at(in),
	})
	require.NoError(t, err)
	return r
}

func (f *fixture) noticeKinds(t *testing.T) []string {
	rows, err := f.st.ListNotices(context.Background(), f.carlos)
	require.NoError(t, err)
	out := make([]string, len(rows))
	for i, n := range rows {
		out[i] = n.Kind
	}
	return out
}

// US1: reservar, confirmar, recordar y, a la hora, la oferta nominal con la tarifa reservada.
func TestIntegrationReservationLifecycle(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	in := func(d time.Duration) NewReservation {
		return NewReservation{DriverID: f.carlos, Pickup: pickup, Dropoff: dropoff, ScheduledAt: f.at(d)}
	}
	for _, d := range []time.Duration{29 * time.Minute, 8 * 24 * time.Hour} {
		_, err := f.svc.Create(ctx, f.ana, in(d))
		assert.ErrorIs(t, err, ErrInvalidTime, d)
	}
	_, err := f.svc.Create(ctx, f.luz, in(2*time.Hour))
	assert.ErrorIs(t, err, ErrNotAffiliated, "solo con un Conductor Elegido")

	// La tarifa preferencial de 008 queda reservada.
	_, err = f.st.SetDispatchSettings(ctx, store.SetDispatchSettingsParams{PreferentialDiscountPct: 10, UserID: f.carlos})
	require.NoError(t, err)
	r := f.book(t, f.ana, 2*time.Hour)
	assert.Equal(t, StatusPending, r.Status)
	assert.Equal(t, int64(1_320_000), r.FareMinor)
	assert.Equal(t, int64(fare), r.ListFareMinor)
	assert.Equal(t, "Centro Comercial Andino", *r.DropoffLabel)
	assert.Contains(t, f.noticeKinds(t), "reservation_requested")
	assert.True(t, f.pub.has("user:"+f.ana.String()+" reservation.updated"))
	_, err = f.st.SetDispatchSettings(ctx, store.SetDispatchSettingsParams{PreferentialDiscountPct: 0, UserID: f.carlos})
	require.NoError(t, err)

	_, err = f.svc.Decide(ctx, f.beto, r.ID, true)
	assert.ErrorIs(t, err, ErrNotFound, "solo su conductor")
	r, err = f.svc.Decide(ctx, f.carlos, r.ID, true)
	require.NoError(t, err)
	assert.Equal(t, StatusConfirmed, r.Status)
	_, err = f.svc.Decide(ctx, f.carlos, r.ID, false)
	assert.ErrorIs(t, err, ErrInvalidState)

	// Solape en la agenda: otra reserva a 20 minutos.
	other := f.book(t, f.ana, 2*time.Hour+20*time.Minute)
	agenda, err := f.svc.Agenda(ctx, f.carlos)
	require.NoError(t, err)
	require.Len(t, agenda, 2)
	assert.True(t, agenda[0].Overlaps)
	assert.True(t, agenda[1].Overlaps)
	f.book(t, f.ana, 3*time.Hour)
	_, err = f.svc.Create(ctx, f.ana, in(4*time.Hour))
	assert.ErrorIs(t, err, ErrTooMany, "FR-006: máximo 3")

	// FR-003: recordatorio 30 minutos antes.
	*f.clock = f.at(90 * time.Minute)
	n, err := f.svc.Sweep(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, n)
	assert.Contains(t, f.noticeKinds(t), "reservation_reminder")
	assert.True(t, f.pub.has("user:"+f.ana.String()+" reservation.notice"))
	n, err = f.svc.Sweep(ctx)
	require.NoError(t, err)
	assert.Zero(t, n, "el recordatorio no se repite")

	// FR-005: la otra, pendiente, vence 15 minutos antes de su hora (14:20 − 15 min); en el mismo
	// barrido llega la hora de la confirmada (14:00) con el conductor libre.
	require.NoError(t, f.st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: f.carlos, Presence: store.DriverPresenceFree}))
	*f.clock = f.at(35 * time.Minute) // 14:05
	_, err = f.svc.Sweep(ctx)
	require.NoError(t, err)
	list, err := f.svc.PassengerList(ctx, f.ana)
	require.NoError(t, err)
	byID := map[uuid.UUID]Reservation{}
	for _, x := range list {
		byID[x.ID] = x
	}
	assert.Equal(t, StatusExpired, byID[other.ID].Status)

	// FR-004: a la hora, con el conductor libre, la oferta nominal con la tarifa reservada.
	done := byID[r.ID]
	require.Equal(t, StatusFulfilled, done.Status)
	require.NotNil(t, done.TripID)
	trip, err := f.st.GetTrip(ctx, *done.TripID)
	require.NoError(t, err)
	assert.Equal(t, int64(1_320_000), trip.SuggestedFareMinor, "la tarifa con la que se reservó")
	assert.Equal(t, store.TripStatusREQUESTED, trip.Status)
	assert.True(t, f.pub.has("user:"+f.carlos.String()+" trip.offer"))
}

// US1 (FR-004, FR-005): conductor no libre a la hora, cancelación y afiliación eliminada.
func TestIntegrationReservationMissedAndCancelled(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	missed := f.book(t, f.ana, time.Hour)
	_, err := f.svc.Decide(ctx, f.carlos, missed.ID, true)
	require.NoError(t, err)
	*f.clock = missed.ScheduledAt // Carlos sigue OFFLINE
	_, err = f.svc.Sweep(ctx)
	require.NoError(t, err)
	list, err := f.svc.PassengerList(ctx, f.ana)
	require.NoError(t, err)
	require.Len(t, list, 1)
	assert.Equal(t, StatusMissed, list[0].Status)
	assert.True(t, f.pub.has("user:"+f.ana.String()+" reservation.notice"), "el pasajero puede pedir por otra vía")

	c := f.book(t, f.ana, time.Hour)
	_, err = f.svc.Cancel(ctx, f.luz, c.ID)
	assert.ErrorIs(t, err, ErrNotFound)
	got, err := f.svc.Cancel(ctx, f.ana, c.ID)
	require.NoError(t, err)
	assert.Equal(t, StatusCancelled, got.Status)
	assert.True(t, got.CancelledByMe)
	assert.Contains(t, f.noticeKinds(t), "reservation_cancelled")
	_, err = f.svc.Cancel(ctx, f.carlos, c.ID)
	assert.ErrorIs(t, err, ErrInvalidState)

	// Quitar al conductor cancela sus reservas abiertas y borra la nota (FR-009).
	open := f.book(t, f.ana, 2*time.Hour)
	require.NoError(t, f.st.UpsertClientNote(ctx, store.UpsertClientNoteParams{DriverID: f.carlos, PassengerID: f.ana, Body: "Portería 2", UpdatedAt: *f.clock}))
	require.NoError(t, affiliations.NewService(affiliations.NewPgRepo(f.st.Queries)).Remove(ctx, f.ana, f.carlos))
	list, err = f.svc.PassengerList(ctx, f.ana)
	require.NoError(t, err)
	for _, x := range list {
		if x.ID == open.ID {
			assert.Equal(t, StatusCancelled, x.Status)
		}
	}
	_, err = f.st.GetClientNote(ctx, store.GetClientNoteParams{DriverID: f.carlos, PassengerID: f.ana})
	assert.True(t, store.IsNotFound(err), "la nota se borra")
}
