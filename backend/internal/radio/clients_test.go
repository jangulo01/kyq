package radio

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/store"
)

// US3, FR-003: "Radio con mis clientes" apagada por defecto; al encenderla cada cliente activo
// tiene su conversación, el conductor silencia o bloquea, y al terminar la afiliación se cierra.
func TestIntegrationClients(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	f.consent(t, f.carlos, f.ana)
	require.NoError(t, f.st.InsertAffiliation(ctx, store.InsertAffiliationParams{PassengerID: f.ana, DriverID: f.carlos}))

	me, err := f.svc.Me(ctx, f.carlos)
	require.NoError(t, err)
	assert.Equal(t, false, *me.ClientsEnabled, "desactivado por defecto")
	list, err := f.svc.List(ctx, f.ana)
	require.NoError(t, err)
	assert.Empty(t, list)
	assert.ErrorIs(t, f.svc.SetClients(ctx, f.ana, true), ErrInvalid, "solo el conductor")

	require.NoError(t, f.svc.SetClients(ctx, f.carlos, true))
	assert.NotEmpty(t, f.pub.events(f.ana, EventMember))
	list, err = f.svc.List(ctx, f.ana)
	require.NoError(t, err)
	require.Len(t, list, 1)
	assert.Equal(t, KindClient, list[0].Kind)
	assert.Equal(t, "Carlos", list[0].Title)
	conv := list[0].ID
	driverList, err := f.svc.List(ctx, f.carlos)
	require.NoError(t, err)
	require.Len(t, driverList, 1)
	assert.Equal(t, "Ana", driverList[0].Title)

	// Silenciado: los mensajes de Ana llegan sin sonar al conductor.
	require.NoError(t, f.svc.SetClient(ctx, f.carlos, f.ana, ClientUpdate{Muted: ptr(true)}))
	_, err = f.svc.Send(ctx, f.ana, conv, SendInput{Kind: MessageText, Body: "¿Está disponible a las 6?"})
	require.NoError(t, err)
	got := f.pub.events(f.carlos, EventMessage)
	require.NotEmpty(t, got)
	assert.Equal(t, true, got[len(got)-1]["silent"])
	require.NoError(t, f.svc.SetClient(ctx, f.carlos, f.ana, ClientUpdate{Muted: ptr(false)}))

	// 20 mensajes por hora del pasajero a su conductor.
	for range ClientMessagesHour - 1 {
		_, err = f.svc.Send(ctx, f.ana, conv, SendInput{Kind: MessageText, Body: "hola"})
		require.NoError(t, err)
	}
	_, err = f.svc.Send(ctx, f.ana, conv, SendInput{Kind: MessageText, Body: "otro"})
	assert.ErrorIs(t, err, ErrRateLimited)
	_, err = f.svc.Send(ctx, f.carlos, conv, SendInput{Kind: MessageText, Body: "Sí, a las 6"})
	require.NoError(t, err, "el conductor no tiene ese límite")
	f.advance(time.Hour)

	// Bloqueada: no envía ni toma el turno; desbloqueada vuelve.
	require.NoError(t, f.svc.SetClient(ctx, f.carlos, f.ana, ClientUpdate{Blocked: ptr(true)}))
	_, err = f.svc.Send(ctx, f.ana, conv, SendInput{Kind: MessageText, Body: "hola"})
	assert.ErrorIs(t, err, ErrBlocked)
	_, err = f.svc.TakeFloor(ctx, f.ana, conv)
	assert.ErrorIs(t, err, ErrBlocked)
	require.NoError(t, f.svc.SetClient(ctx, f.carlos, f.ana, ClientUpdate{Blocked: ptr(false)}))
	_, err = f.svc.TakeFloor(ctx, f.ana, conv)
	require.NoError(t, err)
	require.NoError(t, f.svc.ReleaseFloor(ctx, f.ana, conv))

	// Apagarla esconde la conversación a los dos; encenderla la devuelve con su historial.
	require.NoError(t, f.svc.SetClients(ctx, f.carlos, false))
	list, err = f.svc.List(ctx, f.ana)
	require.NoError(t, err)
	assert.Empty(t, list)
	_, err = f.svc.Send(ctx, f.ana, conv, SendInput{Kind: MessageText, Body: "hola"})
	assert.ErrorIs(t, err, ErrNotFound)
	require.NoError(t, f.svc.SetClients(ctx, f.carlos, true))
	list, err = f.svc.List(ctx, f.ana)
	require.NoError(t, err)
	require.Len(t, list, 1)
	assert.Equal(t, conv, list[0].ID)

	// Fin de la afiliación: se cierra (US3-5).
	n, err := f.st.RemoveAffiliation(ctx, store.RemoveAffiliationParams{PassengerID: f.ana, DriverID: f.carlos})
	require.NoError(t, err)
	require.EqualValues(t, 1, n)
	list, err = f.svc.List(ctx, f.carlos)
	require.NoError(t, err)
	assert.Empty(t, list)
	_, err = f.svc.Token(ctx, f.ana, conv)
	assert.ErrorIs(t, err, ErrNotFound)
	assert.ErrorIs(t, f.svc.SetClient(ctx, f.carlos, f.ana, ClientUpdate{Muted: ptr(true)}), ErrNotFound)
}
