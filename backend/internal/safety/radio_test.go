package safety_test

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/safety"
	"github.com/kyq/backend/internal/trips"
)

// 011 (FR-030, R7): Emergencia desde Radio. Sin viaje abre una alerta `raised_from = radio` con
// sala, consola y contactos; con viaje en curso abre el SOS del viaje.
func TestIntegrationRaiseFromRadio(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	_, err := f.svc.SetContacts(ctx, f.driver, []safety.Contact{{Name: "Marta", PhoneE164: "+573005559999"}})
	require.NoError(t, err)

	alertID, tripID, err := f.svc.RaiseFromRadio(ctx, f.driver, uuid.Nil, ptr(4.61), ptr(-74.07))
	require.NoError(t, err)
	assert.Nil(t, tripID, "sin viaje")
	assert.True(t, f.voice.hasRoom("sos-"+alertID.String()), "con su sala y grabación como en 003")
	assert.Contains(t, f.pub.types(realtime.OpsSOSChannel), "sos.created")
	require.Len(t, f.sms.to("+573005559999"), 1)
	assert.Contains(t, f.sms.to("+573005559999")[0], "maps.google.com/?q=4.61000,-74.07000")

	// La misma alerta mientras siga abierta.
	again, _, err := f.svc.RaiseFromRadio(ctx, f.driver, uuid.Nil, ptr(4.62), ptr(-74.07))
	require.NoError(t, err)
	assert.Equal(t, alertID, again)

	// La consola la muestra "Sin viaje · desde Radio" con el conductor y su vehículo.
	d, err := f.svc.Detail(ctx, f.operator, alertID)
	require.NoError(t, err)
	assert.Nil(t, d.TripID)
	assert.Equal(t, "radio", d.RaisedFrom)
	assert.Equal(t, f.driverName, d.Driver.Name)
	assert.Equal(t, "KYQ001", d.Driver.VehiclePlate)
	assert.Empty(t, d.Trip.Status)
	require.NotNil(t, d.LastLocation)

	_, _, err = f.svc.RaiseFromRadio(ctx, f.driver, uuid.Nil, ptr(120.0), ptr(0.0))
	assert.ErrorIs(t, err, safety.ErrInvalidLocation)

	// Con viaje aceptado, la pasajera abre el SOS de su viaje.
	trip := f.trip(t, trips.StatusAccepted)
	alert2, tripOf, err := f.svc.RaiseFromRadio(ctx, f.passenger, uuid.Nil, nil, nil)
	require.NoError(t, err)
	require.NotNil(t, tripOf)
	assert.Equal(t, trip, *tripOf)
	d2, err := f.svc.Detail(ctx, f.operator, alert2)
	require.NoError(t, err)
	assert.Equal(t, "trip", d2.RaisedFrom)
	assert.Equal(t, "Ana", d2.Passenger.Name)
}

func ptr[T any](v T) *T { return &v }
