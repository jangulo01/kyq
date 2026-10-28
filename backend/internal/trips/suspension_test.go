package trips

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/store"
)

// Pruebas de integración de la suspensión de conductores (007, FR-016) en el despacho: un
// suspendido no vuelve a quedar libre al terminar su viaje ni puede recibir solicitudes nuevas.

func suspend(t *testing.T, st *store.Store, id uuid.UUID, at time.Time) {
	require.NoError(t, st.SetUserSuspension(context.Background(), store.SetUserSuspensionParams{
		ID: id, SuspendedAt: pgtype.Timestamptz{Time: at, Valid: true}, SuspensionReason: pgtype.Text{String: "prueba", Valid: true},
	}))
}

// lastPresence devuelve la presencia del último driver.presence publicado para el conductor.
func (r *recorder) lastPresence(driverID uuid.UUID) any {
	r.mu.Lock()
	defer r.mu.Unlock()
	var out any
	for _, m := range r.msgs {
		if m.Channel == "driver_presence:"+driverID.String() && m.Event.Type == "driver.presence" {
			out = m.Event.Data.(map[string]any)["presence"]
		}
	}
	return out
}

func TestIntegrationSuspendedDriverEndsTripOffline(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	trip, err := f.svc.Request(ctx, f.passenger, f.driver, pickup, dropoff)
	require.NoError(t, err)
	for _, step := range []func(*Trip, Party, time.Time) error{
		func(t *Trip, p Party, now time.Time) error { return t.Accept(p, nil, now) },
		(*Trip).Arrive, (*Trip).Start,
	} {
		_, err := f.svc.Act(ctx, f.driver, trip.ID, step)
		require.NoError(t, err)
	}

	// Lo suspenden en pleno viaje: el viaje sigue hasta terminar, pero luego no queda libre.
	suspend(t, f.st, f.driver, *f.clock)
	_, err = f.svc.Act(ctx, f.driver, trip.ID, (*Trip).Complete)
	require.NoError(t, err)
	assert.Equal(t, store.DriverPresenceOffline, f.presence(t), "un suspendido queda OFFLINE al terminar")
	assert.Equal(t, store.DriverPresenceOffline, f.pub.lastPresence(f.driver), "los pasajeros lo ven desconectado")

	_, err = f.svc.Request(ctx, f.passenger, f.driver, pickup, dropoff)
	assert.ErrorIs(t, err, ErrDriverNotFree)
}

func TestIntegrationSuspendedDriverIsNotChosen(t *testing.T) {
	c := setupCoop(t)
	ctx := context.Background()
	b := c.coworker(t, c.coop, "Beto", near, -74.08, time.Minute)
	// Figura libre (p. ej. una carrera con la suspensión), pero está suspendido.
	suspend(t, c.st, c.driver, *c.clock)

	_, err := c.svc.Request(ctx, c.passenger, c.driver, pickup, dropoff)
	assert.ErrorIs(t, err, ErrDriverNotFree, "no recibe la oferta aunque figure libre")
	assert.Empty(t, c.pub.types("user:"+c.driver.String()))
	assert.Equal(t, store.DriverPresenceFree, c.presenceOf(t, c.driver), "no se le reserva")

	trip, err := c.svc.RequestWith(ctx, c.passenger, c.driver, pickup, dropoff, withConsent())
	require.NoError(t, err)
	assert.Equal(t, b, trip.DriverID, "con consentimiento va a un compañero no suspendido")
	assert.Equal(t, HandoverDriverUnavailable, trip.HandoverReason)
}

func TestIntegrationSuspendedCoworkerIsNotDelegationCandidate(t *testing.T) {
	c := setupCoop(t)
	ctx := context.Background()
	suspended := c.coworker(t, c.coop, "Beto", near, -74.08, time.Minute)
	suspend(t, c.st, suspended, *c.clock)
	c.setBusy(t, c.driver)

	_, err := c.svc.RequestWith(ctx, c.passenger, c.driver, pickup, dropoff, withConsent())
	assert.ErrorIs(t, err, ErrNoDriverAvailable, "el único compañero cercano está suspendido")
	_, err = c.svc.RequestWith(ctx, c.passenger, c.driver, pickup, dropoff, RequestOptions{Dispatch: DispatchCooperative})
	assert.ErrorIs(t, err, ErrNoDriverAvailable, "tampoco al pedir directo a la cooperativa")
	assert.Empty(t, c.pub.types("user:"+suspended.String()))

	cami := c.coworker(t, c.coop, "Cami", mid, -74.08, time.Minute)
	trip, err := c.svc.RequestWith(ctx, c.passenger, c.driver, pickup, dropoff, withConsent())
	require.NoError(t, err)
	assert.Equal(t, cami, trip.DriverID, "se salta al suspendido aunque esté más cerca")
}

func TestIntegrationSuspendedDriverHandsOverOffline(t *testing.T) {
	c := setupCoop(t)
	ctx := context.Background()
	b := c.coworker(t, c.coop, "Beto", near, -74.08, time.Minute)
	trip, err := c.svc.RequestWith(ctx, c.passenger, c.driver, pickup, dropoff, withConsent())
	require.NoError(t, err)
	require.Equal(t, c.driver, trip.DriverID)

	// Lo suspenden con la oferta abierta y la rechaza: pasa al compañero y él queda OFFLINE.
	suspend(t, c.st, c.driver, *c.clock)
	trip, err = c.svc.Act(ctx, c.driver, trip.ID, reject)
	require.NoError(t, err)
	assert.Equal(t, b, trip.DriverID)
	assert.Equal(t, store.DriverPresenceOffline, c.presenceOf(t, c.driver))
	assert.Equal(t, store.DriverPresenceOffline, c.pub.lastPresence(c.driver))
}
