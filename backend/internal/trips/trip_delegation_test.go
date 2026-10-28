package trips

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// --- RN-KYQ-008: delegación en el agregado (T014) ---

func delegableTrip() *Trip {
	tr := newTrip()
	coop := uuid.New()
	tr.CooperativeID = &coop
	tr.AllowDelegation = true
	return tr
}

func TestDelegateOnlyDriverWithinWindowAndConsent(t *testing.T) {
	tr := delegableTrip()
	assert.ErrorIs(t, tr.Delegate(Passenger, t0), ErrForbidden, "solo el conductor pasa la oferta")
	assert.ErrorIs(t, tr.Delegate(Driver, at(OfferWindow)), ErrExpired, "fuera de los 25 s se aplica el vencimiento")

	noConsent := newTrip()
	assert.False(t, noConsent.CanDelegate())
	assert.ErrorIs(t, noConsent.Delegate(Driver, t0), ErrDelegationDenied, "sin consentimiento del pasajero no se pasa")

	require.NoError(t, tr.Delegate(Driver, at(5*time.Second)))
	assert.Equal(t, StatusCancelled, tr.Status)
	assert.True(t, tr.AwaitsHandOver(StatusRequested), "el servicio debe pasarla o darla por perdida")

	accepted := delegableTrip()
	require.NoError(t, accepted.Accept(Driver, nil, t0))
	assert.ErrorIs(t, accepted.Delegate(Driver, t0), ErrInvalidTransition, "un viaje aceptado no se pasa")
}

func TestRejectAndExpiryAwaitHandOverOnlyWithConsent(t *testing.T) {
	rejected := delegableTrip()
	require.NoError(t, rejected.Reject(Driver, t0))
	assert.True(t, rejected.AwaitsHandOver(StatusRequested))

	expired := delegableTrip()
	require.True(t, expired.Expire(at(OfferWindow)))
	assert.True(t, expired.AwaitsHandOver(StatusRequested))

	plain := newTrip()
	require.NoError(t, plain.Reject(Driver, t0))
	assert.False(t, plain.AwaitsHandOver(StatusRequested), "sin consentimiento, como en 001")

	byPassenger := delegableTrip()
	require.NoError(t, byPassenger.Cancel(Passenger, t0))
	assert.False(t, byPassenger.AwaitsHandOver(StatusRequested), "si cancela el pasajero no se deriva")
}

func TestHandOverRestartsOfferForNextCoworker(t *testing.T) {
	tr := delegableTrip()
	first := tr.DriverID
	require.NoError(t, tr.Reject(Driver, at(3*time.Second)))
	next := uuid.New()
	now := at(4 * time.Second)
	require.NoError(t, tr.HandOver(next, now))

	assert.Equal(t, StatusRequested, tr.Status)
	assert.Equal(t, next, tr.DriverID)
	assert.Equal(t, first, tr.RequestedDriverID, "se recuerda a quién pidió el pasajero")
	assert.Equal(t, first, *tr.PreviousDriverID)
	assert.Equal(t, CancelOfferRejected, tr.HandoverReason)
	assert.Equal(t, now.Add(OfferWindow), *tr.RespondBy, "RN-KYQ-007: 25 s nuevos para el compañero")
	assert.Nil(t, tr.CancelReason)
	assert.Nil(t, tr.CancelledAt)
	assert.Equal(t, 1, tr.Handovers)
	party, ok := tr.PartyOf(next)
	assert.True(t, ok)
	assert.Equal(t, Driver, party)
	_, ok = tr.PartyOf(first)
	assert.False(t, ok, "el conductor anterior deja de ser parte del viaje")
}

func TestHandOverLimitAndGiveUp(t *testing.T) {
	tr := delegableTrip()
	now := t0
	for i := range MaxHandovers {
		require.NoError(t, tr.Reject(Driver, now), "paso %d", i)
		require.NoError(t, tr.HandOver(uuid.New(), now))
	}
	assert.False(t, tr.CanDelegate(), "agotados los pasos no hay botón de pasar")
	require.NoError(t, tr.Reject(Driver, now))
	assert.False(t, tr.HasHandoversLeft())
	assert.ErrorIs(t, tr.HandOver(uuid.New(), now), ErrInvalidTransition)
	tr.GiveUp()
	assert.Equal(t, StatusCancelled, tr.Status)
	assert.Equal(t, CancelNoDriver, *tr.CancelReason)
}
