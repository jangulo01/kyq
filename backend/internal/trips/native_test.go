package trips

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/store"
)

// Pruebas de integración de 010: llegada automática a la recogida, nota del conductor y tarifa
// reservada en la oferta.

func acc(m float64) *float64 { return &m }

// FR-010, FR-011: 10 s seguidos a < 60 m con precisión ≤ 50 m marcan la llegada, una vez.
func TestIntegrationAutomaticArrival(t *testing.T) {
	c := setupCoop(t)
	ctx := context.Background()
	trip, err := c.svc.Request(ctx, c.passenger, c.driver, pickup, dropoff)
	require.NoError(t, err)
	trip, err = c.svc.Act(ctx, c.driver, trip.ID, func(t *Trip, p Party, now time.Time) error { return t.Accept(p, nil, now) })
	require.NoError(t, err)

	t0 := *c.clock
	close30m := pickup.Lat + 0.00027 // ~30 m al norte
	observe := func(lat float64, accuracy *float64, at time.Time) bool {
		arrived, err := c.svc.ObserveArrival(ctx, c.driver, trip.ID, lat, pickup.Lng, accuracy, at)
		require.NoError(t, err)
		return arrived
	}
	assert.False(t, observe(close30m, nil, t0), "sin precisión no cuenta")
	assert.False(t, observe(close30m, acc(80), t0), "precisión peor que 50 m no cuenta")
	assert.False(t, observe(close30m, acc(10), t0), "empieza la racha")
	assert.False(t, observe(close30m, acc(10), t0.Add(5*time.Second)))
	assert.False(t, observe(close30m, acc(90), t0.Add(6*time.Second)), "una imprecisa no corta la racha")
	assert.False(t, observe(km3, acc(10), t0.Add(7*time.Second)), "se alejó: pasa sin detenerse")
	assert.False(t, observe(close30m, acc(10), t0.Add(12*time.Second)), "otra racha")
	got, err := c.svc.Get(ctx, c.passenger, trip.ID)
	require.NoError(t, err)
	assert.Equal(t, StatusAccepted, got.Status)

	assert.True(t, observe(close30m, acc(10), t0.Add(23*time.Second)), "11 s en la zona")
	got, err = c.svc.Get(ctx, c.passenger, trip.ID)
	require.NoError(t, err)
	assert.Equal(t, StatusArrived, got.Status)
	assert.Contains(t, c.pub.types("user:"+c.passenger.String()), "trip.status", "el pasajero recibe el aviso")
	assert.False(t, observe(close30m, acc(10), t0.Add(40*time.Second)), "no se repite")
	assert.InDelta(t, 30, DistanceM(pickup, Point{Lat: close30m, Lng: pickup.Lng}), 1)
}

// FR-008, SC-005: la nota del conductor va en su oferta; la reserva conserva su tarifa.
func TestIntegrationOfferCarriesNoteAndReservedFare(t *testing.T) {
	c := setupCoop(t)
	ctx := context.Background()
	require.NoError(t, c.st.UpsertClientNote(ctx, store.UpsertClientNoteParams{
		DriverID: c.driver, PassengerID: c.passenger, Body: "Recoger en la portería 2", UpdatedAt: *c.clock,
	}))
	trip, err := c.svc.RequestWith(ctx, c.passenger, c.driver, pickup, dropoff, RequestOptions{ReservedFare: 1_200_000, Reservation: true})
	require.NoError(t, err)
	assert.Equal(t, int64(1_200_000), trip.SuggestedFare, "tarifa reservada")
	offer := c.pub.lastOffer(c.driver)
	require.NotNil(t, offer)
	note, _ := offer["client_note"].(*string)
	require.NotNil(t, note)
	assert.Equal(t, "Recoger en la portería 2", *note)
	assert.Equal(t, true, offer["reservation"])
	for _, typ := range c.pub.types("user:" + c.passenger.String()) {
		assert.NotEqual(t, "trip.offer", typ, "la oferta, con su nota, nunca va al pasajero")
	}
}
