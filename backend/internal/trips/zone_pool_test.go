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

// Pruebas de integración de 008: bolsa zonal (opción 3), origen de la oferta y tarifa
// preferencial para la cartera (RN-KYQ-013).

// Recogida en (4.60, -74.08): ~3 km y ~6 km al norte (near y mid están en delegation_test.go).
const (
	km3 = 4.627
	km6 = 4.654
)

// poolDriver crea un conductor libre fuera de cooperativa que acepta la bolsa zonal.
func (c *coopFixture) poolDriver(t *testing.T, name string, lat float64, age time.Duration) uuid.UUID {
	id := c.coworker(t, uuid.Nil, name, lat, -74.08, age)
	c.setPool(t, id, true, 0)
	return id
}

func (c *coopFixture) setPool(t *testing.T, id uuid.UUID, accepts bool, discount int16) {
	_, err := c.st.SetDispatchSettings(context.Background(), store.SetDispatchSettingsParams{
		AcceptsZonePool: accepts, PreferentialDiscountPct: discount, UserID: id,
	})
	require.NoError(t, err)
}

// lastOffer devuelve los datos del último trip.offer publicado al conductor.
func (r *recorder) lastOffer(driverID uuid.UUID) map[string]any {
	r.mu.Lock()
	defer r.mu.Unlock()
	var out map[string]any
	for _, m := range r.msgs {
		if m.Channel == "user:"+driverID.String() && m.Event.Type == "trip.offer" {
			out = m.Event.Data.(map[string]any)
		}
	}
	return out
}

func pool() RequestOptions { return RequestOptions{Dispatch: DispatchZonePool} }

func TestIntegrationZonePoolNearestOptedInDriver(t *testing.T) {
	c := setupCoop(t)
	ctx := context.Background()
	// El conductor del fixture está a 1 km libre pero no acepta la bolsa (FR-009).
	require.NoError(t, c.st.SetDriverLocation(ctx, store.SetDriverLocationParams{Lat: near, Lng: -74.08, RecordedAt: *c.clock, UserID: c.driver}))
	b := c.poolDriver(t, "Beto", km3, time.Minute)
	cc := c.poolDriver(t, "Cami", mid, time.Minute)
	stranger := c.newPassenger(t, "Sofía")

	trip, err := c.svc.RequestWith(ctx, stranger, uuid.Nil, pickup, dropoff, pool())
	require.NoError(t, err, "FR-001: sin Conductor Elegido")
	assert.Equal(t, b, trip.DriverID, "FR-002: el más cercano con la bolsa activada")
	assert.Equal(t, b, trip.RequestedDriverID)
	assert.Equal(t, DispatchZonePool, trip.Dispatch)
	assert.Nil(t, trip.CooperativeID)
	assert.Empty(t, c.pub.types("user:"+c.driver.String()), "sin la bolsa no recibe nada")
	offer := c.pub.lastOffer(b)
	require.NotNil(t, offer)
	assert.Equal(t, DispatchZonePool, offer["origin"])
	assert.Equal(t, false, offer["loyal_client"])
	require.NotNil(t, offer["pickup_distance_m"])
	assert.InDelta(t, 3000, *offer["pickup_distance_m"].(*int), 100)
	assert.Equal(t, store.DriverPresenceBusy, c.presenceOf(t, b), "RN-KYQ-007: la oferta lo reserva")

	trip, err = c.svc.Act(ctx, b, trip.ID, reject)
	require.NoError(t, err)
	assert.Equal(t, cc, trip.DriverID, "FR-004: pasa al siguiente")
	assert.Equal(t, StatusRequested, trip.Status)
	assert.Equal(t, store.DriverPresenceFree, c.presenceOf(t, b))
	assert.Equal(t, t0OfferDeadline(c), *trip.RespondBy, "25 s nuevos")

	*c.clock = c.clock.Add(OfferWindow + time.Second)
	_, err = c.svc.ExpireDue(ctx)
	require.NoError(t, err)
	got, err := c.svc.Get(ctx, stranger, trip.ID)
	require.NoError(t, err)
	assert.Equal(t, StatusCancelled, got.Status, "sin más candidatos se cierra")
	assert.Equal(t, CancelNoDriver, *got.CancelReason)
}

func TestIntegrationZonePoolExcludesFarStaleSuspendedAndBusy(t *testing.T) {
	c := setupCoop(t)
	ctx := context.Background()
	stranger := c.newPassenger(t, "Sofía")
	c.poolDriver(t, "Lejos", km6, time.Minute)                     // más de 5 km
	c.poolDriver(t, "Viejo", near, CandidateFreshness+time.Minute) // ubicación vieja
	suspended := c.poolDriver(t, "Suspendido", near, time.Minute)
	suspend(t, c.st, suspended, *c.clock)
	busy := c.poolDriver(t, "Ocupado", near, time.Minute)
	c.setBusy(t, busy)

	_, err := c.svc.RequestWith(ctx, stranger, uuid.Nil, pickup, dropoff, pool())
	assert.ErrorIs(t, err, ErrNoDriverAvailable, "SC-002: ninguno elegible")

	off := c.poolDriver(t, "Apagó", near, time.Minute)
	c.setPool(t, off, false, 0)
	_, err = c.svc.RequestWith(ctx, stranger, uuid.Nil, pickup, dropoff, pool())
	assert.ErrorIs(t, err, ErrNoDriverAvailable, "desactivar la bolsa lo saca")
}

func TestIntegrationZonePoolTripPaysFullFare(t *testing.T) {
	c := setupCoop(t)
	ctx := context.Background()
	d := c.poolDriver(t, "Beto", near, time.Minute)
	stranger := c.newPassenger(t, "Sofía")
	trip, err := c.svc.RequestWith(ctx, stranger, uuid.Nil, pickup, dropoff, pool())
	require.NoError(t, err)
	for _, step := range []func(*Trip, Party, time.Time) error{
		func(t *Trip, p Party, now time.Time) error { return t.Accept(p, nil, now) },
		(*Trip).Arrive, (*Trip).Start, (*Trip).Complete,
	} {
		trip, err = c.svc.Act(ctx, d, trip.ID, step)
		require.NoError(t, err)
	}
	assert.Equal(t, StatusCompleted, trip.Status)
	assert.Equal(t, trip.ListFare, *trip.DriverPayout, "RN-KYQ-001: 100 % para el conductor, sin descuento")
	assert.Equal(t, 0, trip.DiscountPct)
}

// RN-KYQ-013: tarifa preferencial para los clientes de la cartera.
func TestIntegrationPreferentialFareForPortfolio(t *testing.T) {
	c := setupCoop(t)
	ctx := context.Background()
	c.setPool(t, c.driver, false, 10)

	pct, err := c.svc.Discount(ctx, c.passenger, c.driver)
	require.NoError(t, err)
	assert.Equal(t, 10, pct, "la cotización con el conductor ve el descuento")
	pct, err = c.svc.Discount(ctx, c.newPassenger(t, "Sofía"), c.driver)
	require.NoError(t, err)
	assert.Equal(t, 0, pct, "un pasajero que no es su cliente no lo tiene")

	trip, err := c.svc.Request(ctx, c.passenger, c.driver, pickup, dropoff)
	require.NoError(t, err)
	assert.Equal(t, int64(1_470_000), trip.ListFare)
	assert.Equal(t, int64(1_320_000), trip.SuggestedFare, "14 700 − 10 % = 13 230 → 13 200")
	assert.Equal(t, 10, trip.DiscountPct)
	offer := c.pub.lastOffer(c.driver)
	assert.Equal(t, DispatchChosenDriver, offer["origin"])
	assert.Equal(t, true, offer["loyal_client"], "⭐ Cliente de tu cartera")
	assert.Equal(t, 10, offer["preferential_discount_pct"])

	// FR-013: cambiar el descuento después no altera el viaje.
	c.setPool(t, c.driver, false, 0)
	trip, err = c.svc.Act(ctx, c.driver, trip.ID, func(t *Trip, p Party, now time.Time) error { return t.Accept(p, nil, now) })
	require.NoError(t, err)
	assert.Equal(t, int64(1_320_000), *trip.AgreedFare)
}

func TestIntegrationPreferentialFareNotForCoworker(t *testing.T) {
	c := setupCoop(t)
	ctx := context.Background()
	c.setPool(t, c.driver, false, 20)
	b := c.coworker(t, c.coop, "Beto", near, -74.08, time.Minute)

	trip, err := c.svc.RequestWith(ctx, c.passenger, c.driver, pickup, dropoff, withConsent())
	require.NoError(t, err)
	require.Equal(t, 20, trip.DiscountPct)
	trip, err = c.svc.Act(ctx, c.driver, trip.ID, reject)
	require.NoError(t, err)
	assert.Equal(t, b, trip.DriverID)
	assert.Equal(t, trip.ListFare, trip.SuggestedFare, "FR-012: el compañero ofrece la tarifa de lista")
	assert.Equal(t, 0, trip.DiscountPct)
	offer := c.pub.lastOffer(b)
	assert.Equal(t, DispatchCooperative, offer["origin"], "De tu cooperativa")
	assert.Equal(t, false, offer["loyal_client"])
	stored, err := c.svc.Get(ctx, c.passenger, trip.ID)
	require.NoError(t, err)
	assert.Equal(t, trip.ListFare, stored.SuggestedFare, "se guarda la tarifa del traspaso")
}

func TestIntegrationOfferCountsTripsTogether(t *testing.T) {
	c := setupCoop(t)
	ctx := context.Background()
	for range 2 {
		trip, err := c.svc.Request(ctx, c.passenger, c.driver, pickup, dropoff)
		require.NoError(t, err)
		for _, step := range []func(*Trip, Party, time.Time) error{
			func(t *Trip, p Party, now time.Time) error { return t.Accept(p, nil, now) },
			(*Trip).Arrive, (*Trip).Start, (*Trip).Complete,
		} {
			_, err = c.svc.Act(ctx, c.driver, trip.ID, step)
			require.NoError(t, err)
		}
	}
	_, err := c.svc.Request(ctx, c.passenger, c.driver, pickup, dropoff)
	require.NoError(t, err)
	assert.Equal(t, 2, c.pub.lastOffer(c.driver)["trips_together"], "viajes completados juntos")
}

// newPassenger crea un pasajero sin Conductores Elegidos.
func (c *coopFixture) newPassenger(t *testing.T, name string) uuid.UUID {
	c.n++
	id := uuid.New()
	_, err := c.st.CreateUser(context.Background(), store.CreateUserParams{
		ID: id, PhoneE164: "+57320200" + fmt.Sprintf("%04d", c.n), Role: store.UserRolePassenger, DisplayName: name,
	})
	require.NoError(t, err)
	return id
}
