package trips

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/store"
)

// Pruebas de integración de RN-KYQ-008 (T015): delegación inteligente a la cooperativa.

type coopFixture struct {
	*fixture
	coop uuid.UUID
	n    int
}

func setupCoop(t *testing.T) *coopFixture {
	f := setup(t)
	ctx := context.Background()
	admin := uuid.New()
	_, err := f.st.CreateUser(ctx, store.CreateUserParams{ID: admin, PhoneE164: "+573000009999", Role: store.UserRoleAdmin, DisplayName: "Admin Coop"})
	require.NoError(t, err)
	c := &coopFixture{fixture: f}
	c.coop = c.newCoop(t, admin, "Cooperativa Andina")
	c.join(t, c.coop, f.driver)
	return c
}

func (c *coopFixture) newCoop(t *testing.T, admin uuid.UUID, name string) uuid.UUID {
	id := uuid.New()
	_, err := c.st.CreateCooperative(context.Background(), store.CreateCooperativeParams{ID: id, Name: name, CityCode: "bogota", CreatedBy: admin})
	require.NoError(t, err)
	return id
}

func (c *coopFixture) join(t *testing.T, coop, driver uuid.UUID) {
	_, err := c.st.InsertMembership(context.Background(), store.InsertMembershipParams{
		ID: uuid.New(), CooperativeID: coop, DriverID: driver, Role: store.CooperativeRoleMember,
		Status: store.MembershipStatusActive, RequestedAt: *c.clock,
	})
	require.NoError(t, err)
}

// coworker creates a free member of coop at lat/lng with a location recorded age ago.
func (c *coopFixture) coworker(t *testing.T, coop uuid.UUID, name string, lat, lng float64, age time.Duration) uuid.UUID {
	ctx := context.Background()
	c.n++
	id := uuid.New()
	_, err := c.st.CreateUser(ctx, store.CreateUserParams{ID: id, PhoneE164: fmt.Sprintf("+57310100%04d", c.n), Role: store.UserRoleDriver, DisplayName: name})
	require.NoError(t, err)
	require.NoError(t, c.st.CreateDriver(ctx, store.CreateDriverParams{UserID: id, QrToken: fmt.Sprintf("qr-coworker-%08d", c.n), VehiclePlate: fmt.Sprintf("KYQ%03d", c.n), VehicleDescription: "Renault"}))
	require.NoError(t, c.st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: id, Presence: store.DriverPresenceFree}))
	require.NoError(t, c.st.SetDriverLocation(ctx, store.SetDriverLocationParams{Lat: lat, Lng: lng, RecordedAt: c.clock.Add(-age), UserID: id}))
	if coop != uuid.Nil {
		c.join(t, coop, id)
	}
	return id
}

func (c *coopFixture) presenceOf(t *testing.T, id uuid.UUID) store.DriverPresence {
	d, err := c.st.GetDriverForPresence(context.Background(), id)
	require.NoError(t, err)
	return d.Presence
}

func (c *coopFixture) setBusy(t *testing.T, id uuid.UUID) {
	require.NoError(t, c.st.SetDriverPresence(context.Background(), store.SetDriverPresenceParams{UserID: id, Presence: store.DriverPresenceBusy}))
}

func reject(t *Trip, p Party, now time.Time) error { return t.Reject(p, now) }

func withConsent() RequestOptions {
	return RequestOptions{Dispatch: DispatchChosenDriver, AllowDelegation: true}
}

// Recogida en (4.60, -74.08): ~1 km, ~5 km y ~20 km al norte.
const (
	near = 4.609
	mid  = 4.645
	far  = 4.78
)

func TestIntegrationDelegationWhenChosenBusy(t *testing.T) {
	c := setupCoop(t)
	ctx := context.Background()
	b := c.coworker(t, c.coop, "Beto", near, -74.08, time.Minute)
	c.coworker(t, c.coop, "Cami", mid, -74.08, time.Minute)
	c.setBusy(t, c.driver)

	_, err := c.svc.Request(ctx, c.passenger, c.driver, pickup, dropoff)
	assert.ErrorIs(t, err, ErrDriverNotFree, "sin consentimiento, como en 001")

	trip, err := c.svc.RequestWith(ctx, c.passenger, c.driver, pickup, dropoff, withConsent())
	require.NoError(t, err)
	assert.Equal(t, b, trip.DriverID, "FR-011: va directo al compañero libre más cercano")
	assert.Equal(t, c.driver, trip.RequestedDriverID)
	assert.Equal(t, 1, trip.Handovers)
	assert.Equal(t, "Beto", trip.DriverName)
	require.NotNil(t, trip.CooperativeName)
	assert.Equal(t, "Cooperativa Andina", *trip.CooperativeName)
	assert.Equal(t, store.DriverPresenceBusy, c.presenceOf(t, b), "la oferta reserva al compañero")
	assert.Contains(t, c.pub.types("user:"+b.String()), "trip.offer")
	assert.Equal(t, t0OfferDeadline(c), *trip.RespondBy, "RN-KYQ-007: 25 s")
}

func t0OfferDeadline(c *coopFixture) time.Time { return c.clock.Add(OfferWindow) }

func TestIntegrationDelegationOnRejectAndExpiry(t *testing.T) {
	c := setupCoop(t)
	ctx := context.Background()
	b := c.coworker(t, c.coop, "Beto", near, -74.08, time.Minute)
	cc := c.coworker(t, c.coop, "Cami", mid, -74.08, time.Minute)

	trip, err := c.svc.RequestWith(ctx, c.passenger, c.driver, pickup, dropoff, withConsent())
	require.NoError(t, err)
	assert.Equal(t, c.driver, trip.DriverID, "el elegido libre recibe la oferta primero")
	assert.True(t, trip.CanDelegate())

	got, err := c.svc.Act(ctx, c.driver, trip.ID, reject)
	require.NoError(t, err)
	assert.Equal(t, StatusRequested, got.Status, "FR-012: al rechazar pasa a un compañero")
	assert.Equal(t, b, got.DriverID)
	assert.Equal(t, store.DriverPresenceFree, c.presenceOf(t, c.driver), "el elegido queda libre")
	assert.Equal(t, store.DriverPresenceBusy, c.presenceOf(t, b))
	assert.Contains(t, c.pub.types("user:"+c.driver.String()), "trip.offer_closed")
	assert.Contains(t, c.pub.types("user:"+b.String()), "trip.offer")
	assert.Contains(t, c.pub.types("user:"+c.passenger.String()), "trip.delegated")
	_, err = c.svc.Get(ctx, c.driver, trip.ID)
	assert.ErrorIs(t, err, ErrNotFound, "el conductor anterior ya no ve el viaje")

	c.advance(OfferWindow + time.Second)
	n, err := c.svc.ExpireDue(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, n)
	got, err = c.svc.Get(ctx, c.passenger, trip.ID)
	require.NoError(t, err)
	assert.Equal(t, cc, got.DriverID, "al vencer pasa al siguiente más cercano")
	assert.Equal(t, 2, got.Handovers)
	assert.Equal(t, store.DriverPresenceFree, c.presenceOf(t, b))
}

func TestIntegrationDriverPassesToCooperative(t *testing.T) {
	c := setupCoop(t)
	ctx := context.Background()
	b := c.coworker(t, c.coop, "Beto", near, -74.08, time.Minute)

	trip, err := c.svc.RequestWith(ctx, c.passenger, c.driver, pickup, dropoff, withConsent())
	require.NoError(t, err)
	_, err = c.svc.Act(ctx, c.passenger, trip.ID, (*Trip).Delegate)
	assert.ErrorIs(t, err, ErrForbidden, "el pasajero no pasa la oferta")

	got, err := c.svc.Act(ctx, c.driver, trip.ID, (*Trip).Delegate)
	require.NoError(t, err)
	assert.Equal(t, b, got.DriverID, "FR-013: el conductor pasa la oferta a su cooperativa")
}

func TestIntegrationWithoutConsentBehavesLike001(t *testing.T) {
	c := setupCoop(t)
	ctx := context.Background()
	c.coworker(t, c.coop, "Beto", near, -74.08, time.Minute)

	trip, err := c.svc.Request(ctx, c.passenger, c.driver, pickup, dropoff)
	require.NoError(t, err)
	assert.Nil(t, trip.CooperativeID, "sin consentimiento no se fija cooperativa")
	_, err = c.svc.Act(ctx, c.driver, trip.ID, (*Trip).Delegate)
	assert.ErrorIs(t, err, ErrDelegationDenied)
	got, err := c.svc.Act(ctx, c.driver, trip.ID, reject)
	require.NoError(t, err)
	assert.Equal(t, StatusCancelled, got.Status)
	assert.Equal(t, CancelOfferRejected, *got.CancelReason)
}

func TestIntegrationCandidateFilters(t *testing.T) {
	c := setupCoop(t)
	ctx := context.Background()
	admin := uuid.New()
	_, err := c.st.CreateUser(ctx, store.CreateUserParams{ID: admin, PhoneE164: "+573000009998", Role: store.UserRoleAdmin, DisplayName: "Otro Admin"})
	require.NoError(t, err)
	other := c.newCoop(t, admin, "Cooperativa Sur")
	c.coworker(t, c.coop, "Lejano", far, -74.08, time.Minute)                    // fuera de 10 km
	c.coworker(t, c.coop, "Viejo", near, -74.08, CandidateFreshness+time.Minute) // ubicación vieja
	c.coworker(t, other, "Ajeno", near, -74.08, time.Minute)                     // otra cooperativa
	c.coworker(t, uuid.Nil, "Suelto", near, -74.08, time.Minute)                 // sin cooperativa
	busy := c.coworker(t, c.coop, "Ocupado", near, -74.08, time.Minute)
	c.setBusy(t, busy)
	c.setBusy(t, c.driver)

	_, err = c.svc.RequestWith(ctx, c.passenger, c.driver, pickup, dropoff, withConsent())
	assert.ErrorIs(t, err, ErrNoDriverAvailable, "FR-015: ningún candidato válido")

	// Una cooperativa suspendida no recibe delegaciones y deja al conductor sin cooperativa.
	c.coworker(t, c.coop, "Cerca", near, -74.08, time.Minute)
	_, err = c.st.UpdateCooperative(ctx, store.UpdateCooperativeParams{ID: c.coop, Name: "Cooperativa Andina", CityCode: "bogota", Status: store.CooperativeStatusSuspended})
	require.NoError(t, err)
	_, err = c.svc.RequestWith(ctx, c.passenger, c.driver, pickup, dropoff, withConsent())
	assert.ErrorIs(t, err, ErrDriverNotFree, "sin cooperativa activa la casilla no aplica")
	_, err = c.svc.RequestWith(ctx, c.passenger, c.driver, pickup, dropoff, RequestOptions{Dispatch: DispatchCooperative})
	assert.ErrorIs(t, err, ErrNoCooperative)
}

func TestIntegrationHandoverLimit(t *testing.T) {
	c := setupCoop(t)
	ctx := context.Background()
	for i := range MaxHandovers + 1 {
		c.coworker(t, c.coop, fmt.Sprintf("Compa %d", i), near+float64(i)*0.001, -74.08, time.Minute)
	}
	trip, err := c.svc.RequestWith(ctx, c.passenger, c.driver, pickup, dropoff, withConsent())
	require.NoError(t, err)
	holder := c.driver
	for i := range MaxHandovers {
		got, err := c.svc.Act(ctx, holder, trip.ID, reject)
		require.NoError(t, err)
		require.Equal(t, StatusRequested, got.Status, "paso %d", i+1)
		holder = got.DriverID
	}
	got, err := c.svc.Act(ctx, holder, trip.ID, reject)
	require.NoError(t, err)
	assert.Equal(t, StatusCancelled, got.Status, "FR-017: máximo 3 pasos aunque queden compañeros")
	assert.Equal(t, CancelNoDriver, *got.CancelReason)
	assert.Equal(t, store.DriverPresenceFree, c.presenceOf(t, holder))
}

func TestIntegrationNoCoworkerLeftCancelsWithReason(t *testing.T) {
	c := setupCoop(t)
	ctx := context.Background()
	trip, err := c.svc.RequestWith(ctx, c.passenger, c.driver, pickup, dropoff, withConsent())
	require.NoError(t, err)
	got, err := c.svc.Act(ctx, c.driver, trip.ID, (*Trip).Delegate)
	require.NoError(t, err)
	assert.Equal(t, StatusCancelled, got.Status)
	assert.Equal(t, CancelNoDriver, *got.CancelReason, "sin compañeros libres se cierra con su motivo")
	assert.Equal(t, store.DriverPresenceFree, c.presenceOf(t, c.driver))
	assert.Contains(t, c.pub.types("user:"+c.passenger.String()), "trip.status")
}

func TestIntegrationCooperativeDispatchPicksNearestMember(t *testing.T) {
	c := setupCoop(t)
	ctx := context.Background()
	// El elegido está libre pero más lejos que Beto.
	require.NoError(t, c.st.SetDriverLocation(ctx, store.SetDriverLocationParams{Lat: mid, Lng: -74.08, RecordedAt: *c.clock, UserID: c.driver}))
	b := c.coworker(t, c.coop, "Beto", near, -74.08, time.Minute)

	trip, err := c.svc.RequestWith(ctx, c.passenger, c.driver, pickup, dropoff, RequestOptions{Dispatch: DispatchCooperative})
	require.NoError(t, err)
	assert.Equal(t, b, trip.DriverID, "FR-014: el miembro libre más cercano")
	assert.Equal(t, DispatchCooperative, trip.Dispatch)
	assert.True(t, trip.AllowDelegation)
	assert.Zero(t, trip.Handovers)

	// Si Beto rechaza, pasa al elegido (siguiente más cercano).
	got, err := c.svc.Act(ctx, b, trip.ID, reject)
	require.NoError(t, err)
	assert.Equal(t, c.driver, got.DriverID)
}

// RN-KYQ-001: un viaje derivado se liquida al 100 % para quien lo hace y sin comisión.
func TestIntegrationDelegatedTripZeroCommission(t *testing.T) {
	c := setupCoop(t)
	ctx := context.Background()
	b := c.coworker(t, c.coop, "Beto", near, -74.08, time.Minute)
	c.setBusy(t, c.driver)
	trip, err := c.svc.RequestWith(ctx, c.passenger, c.driver, pickup, dropoff, withConsent())
	require.NoError(t, err)
	for _, step := range []func(*Trip, Party, time.Time) error{
		func(t *Trip, p Party, now time.Time) error { return t.Accept(p, nil, now) },
		(*Trip).Arrive, (*Trip).Start, (*Trip).Complete,
	} {
		_, err := c.svc.Act(ctx, b, trip.ID, step)
		require.NoError(t, err)
	}
	row, err := c.st.GetTrip(ctx, trip.ID)
	require.NoError(t, err)
	assert.Equal(t, store.TripStatusCOMPLETED, row.Status)
	assert.Equal(t, b, row.DriverID)
	assert.Zero(t, row.PlatformCommissionMinor)
	assert.Equal(t, row.AgreedFareMinor, row.DriverPayoutMinor, "100 % de la tarifa para el compañero")
}
