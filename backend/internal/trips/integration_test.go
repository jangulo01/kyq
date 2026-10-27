package trips

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/fares"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
)

type fixedRoute struct{}

func (fixedRoute) Route(context.Context, float64, float64, float64, float64) (fares.Route, error) {
	return fares.Route{DistanceM: 5200, DurationS: 900}, nil
}

type recorder struct {
	mu   sync.Mutex
	msgs []Message
}

func (r *recorder) Publish(_ context.Context, channel string, ev realtime.Event) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.msgs = append(r.msgs, Message{Channel: channel, Event: ev})
	return nil
}

func (r *recorder) types(channel string) []string {
	r.mu.Lock()
	defer r.mu.Unlock()
	var out []string
	for _, m := range r.msgs {
		if m.Channel == channel {
			out = append(out, m.Event.Type)
		}
	}
	return out
}

type fixture struct {
	svc       *Service
	pub       *recorder
	clock     *time.Time
	driver    uuid.UUID
	passenger uuid.UUID
	st        *store.Store
}

var pickup, dropoff = Point{Lat: 4.60, Lng: -74.08}, Point{Lat: 4.65, Lng: -74.05}

func setup(t *testing.T) *fixture {
	st := testdb.New(t)
	ctx := context.Background()
	f := &fixture{pub: &recorder{}, driver: uuid.New(), passenger: uuid.New(), st: st}
	now := time.Date(2026, 10, 27, 12, 0, 0, 0, time.UTC)
	f.clock = &now
	admin := uuid.New()
	mustUser := func(id uuid.UUID, phone string, role store.UserRole, name string) {
		_, err := st.CreateUser(ctx, store.CreateUserParams{ID: id, PhoneE164: phone, Role: role, DisplayName: name})
		require.NoError(t, err)
	}
	mustUser(admin, "+573000000001", store.UserRoleAdmin, "Admin")
	mustUser(f.driver, "+573100000001", store.UserRoleDriver, "Carlos")
	mustUser(f.passenger, "+573200000002", store.UserRolePassenger, "Ana")
	require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: f.driver, QrToken: "qr-carlos-0000000", VehiclePlate: "KYQ001", VehicleDescription: "Kia"}))
	require.NoError(t, st.InsertAffiliation(ctx, store.InsertAffiliationParams{PassengerID: f.passenger, DriverID: f.driver}))
	require.NoError(t, st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: f.driver, Presence: store.DriverPresenceFree}))
	require.NoError(t, st.UpsertFareTable(ctx, store.UpsertFareTableParams{
		CityCode: "bogota", Currency: "COP", BaseMinor: 400_000, PerKmMinor: 120_000, PerMinuteMinor: 30_000,
		MinimumMinor: 700_000, RoundingMinor: 10_000, UpdatedBy: admin,
	}))
	f.svc = &Service{Store: st, Routes: fixedRoute{}, Publisher: f.pub, CityCode: "bogota", Now: func() time.Time { return *f.clock }}
	return f
}

func (f *fixture) advance(d time.Duration) { *f.clock = f.clock.Add(d) }

func (f *fixture) presence(t *testing.T) store.DriverPresence {
	d, err := f.st.GetDriverForPresence(context.Background(), f.driver)
	require.NoError(t, err)
	return d.Presence
}

func TestIntegrationTripLifecycle(t *testing.T) {
	f := setup(t)
	ctx := context.Background()

	trip, err := f.svc.Request(ctx, f.passenger, f.driver, pickup, dropoff)
	require.NoError(t, err)
	assert.Equal(t, int64(1_470_000), trip.SuggestedFare, "tarifa de la tabla con la ruta de OSRM")
	assert.Equal(t, store.DriverPresenceBusy, f.presence(t), "la oferta reserva al conductor")
	assert.Contains(t, f.pub.types("user:"+f.driver.String()), "trip.offer")

	_, err = f.svc.Get(ctx, uuid.New(), trip.ID)
	assert.ErrorIs(t, err, ErrNotFound, "terceros no ven el viaje")

	f.advance(5 * time.Second)
	for _, step := range []func(*Trip, Party, time.Time) error{
		func(t *Trip, p Party, now time.Time) error { return t.Accept(p, nil, now) },
		(*Trip).Arrive, (*Trip).Start, (*Trip).Complete,
	} {
		_, err := f.svc.Act(ctx, f.driver, trip.ID, step)
		require.NoError(t, err)
	}
	_, err = f.svc.Act(ctx, f.passenger, trip.ID, (*Trip).Arrive)
	assert.ErrorIs(t, err, ErrForbidden)

	done, err := f.svc.Get(ctx, f.passenger, trip.ID)
	require.NoError(t, err)
	assert.Equal(t, StatusCompleted, done.Status)
	assert.Equal(t, done.SuggestedFare, *done.DriverPayout, "RN-KYQ-001: 100 % para el conductor")
	assert.Equal(t, store.DriverPresenceFree, f.presence(t), "al terminar vuelve a estar libre")
}

func TestIntegrationOfferExpiresAndFreesDriver(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	trip, err := f.svc.Request(ctx, f.passenger, f.driver, pickup, dropoff)
	require.NoError(t, err)

	f.advance(24 * time.Second)
	n, err := f.svc.ExpireDue(ctx)
	require.NoError(t, err)
	assert.Zero(t, n)

	f.advance(2 * time.Second)
	n, err = f.svc.ExpireDue(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, n)

	got, err := f.svc.Get(ctx, f.passenger, trip.ID)
	require.NoError(t, err)
	assert.Equal(t, CancelOfferExpired, *got.CancelReason)
	assert.Equal(t, store.DriverPresenceFree, f.presence(t))
	assert.Contains(t, f.pub.types("user:"+f.driver.String()), "trip.offer_closed")
}

func TestIntegrationNegotiationPersistsProposals(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	trip, err := f.svc.Request(ctx, f.passenger, f.driver, pickup, dropoff)
	require.NoError(t, err)

	_, err = f.svc.Act(ctx, f.driver, trip.ID, (*Trip).RequestNegotiation)
	require.NoError(t, err)
	_, err = f.svc.Act(ctx, f.passenger, trip.ID, func(t *Trip, p Party, now time.Time) error { return t.RespondNegotiation(p, true, now) })
	require.NoError(t, err)
	var first, counter *Proposal
	_, err = f.svc.Act(ctx, f.driver, trip.ID, func(t *Trip, p Party, now time.Time) error {
		first, err = t.Propose(p, 1_600_000, now)
		return err
	})
	require.NoError(t, err)
	_, err = f.svc.Act(ctx, f.passenger, trip.ID, func(t *Trip, p Party, now time.Time) error {
		counter, err = t.Propose(p, 1_400_000, now)
		return err
	})
	require.NoError(t, err, "la contrapropuesta reemplaza la abierta sin violar el índice")
	assert.NotEqual(t, first.ID, counter.ID)

	got, err := f.svc.Act(ctx, f.driver, trip.ID, func(t *Trip, p Party, now time.Time) error {
		return t.DecideProposal(p, counter.ID, true, now)
	})
	require.NoError(t, err)
	assert.Equal(t, int64(1_400_000), *got.AgreedFare)
	assert.Contains(t, f.pub.types("user:"+f.driver.String()), "trip.fare_proposal")
	assert.Contains(t, f.pub.types("user:"+f.passenger.String()), "trip.negotiation_requested")
}

// FR-012: dos pasajeros piden al mismo conductor a la vez; solo uno obtiene la oferta.
func TestIntegrationConcurrentRequestsOneOffer(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	other := uuid.New()
	_, err := f.st.CreateUser(ctx, store.CreateUserParams{ID: other, PhoneE164: "+573200000003", Role: store.UserRolePassenger, DisplayName: "Luis"})
	require.NoError(t, err)
	require.NoError(t, f.st.InsertAffiliation(ctx, store.InsertAffiliationParams{PassengerID: other, DriverID: f.driver}))

	var wg sync.WaitGroup
	errs := make([]error, 2)
	for i, p := range []uuid.UUID{f.passenger, other} {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, errs[i] = f.svc.Request(ctx, p, f.driver, pickup, dropoff)
		}()
	}
	wg.Wait()
	okCount := 0
	for _, err := range errs {
		if err == nil {
			okCount++
		} else {
			assert.True(t, errors.Is(err, ErrDriverNotFree), "el otro recibe conductor ocupado: %v", err)
		}
	}
	assert.Equal(t, 1, okCount)
}

func TestIntegrationRequestRequiresAffiliation(t *testing.T) {
	f := setup(t)
	stranger := uuid.New()
	_, err := f.st.CreateUser(context.Background(), store.CreateUserParams{ID: stranger, PhoneE164: "+573200000009", Role: store.UserRolePassenger, DisplayName: "Eva"})
	require.NoError(t, err)
	_, err = f.svc.Request(context.Background(), stranger, f.driver, pickup, dropoff)
	assert.ErrorIs(t, err, ErrNotAffiliated)
}
