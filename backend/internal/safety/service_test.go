package safety_test

import (
	"context"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/ptt"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/safety"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/trips"
)

func TestSOSTokenPublishesFromTheStartAndOperatorTokenOnlyListens(t *testing.T) {
	lk := ptt.LiveKit{APIKey: "devkey", APISecret: "secret"}
	now := time.Now().Truncate(time.Second)
	grant := func(raw string) map[string]any {
		claims := jwt.MapClaims{}
		_, err := jwt.ParseWithClaims(raw, claims, func(*jwt.Token) (any, error) { return []byte("secret"), nil })
		require.NoError(t, err)
		return claims["video"].(map[string]any)
	}
	user, err := lk.SOSToken("u1", "Ana", "sos-1", now, ptt.TokenTTL)
	require.NoError(t, err)
	video := grant(user)
	assert.Equal(t, "sos-1", video["room"])
	assert.Equal(t, true, video["canPublish"], "en emergencia no hay turno (research R1)")
	assert.Equal(t, []any{"microphone"}, video["canPublishSources"])

	op, err := lk.OperatorToken("op", "Lucía", "sos-1", now, ptt.TokenTTL)
	require.NoError(t, err)
	video = grant(op)
	assert.Equal(t, false, video["canPublish"], "hablar lo concede tomar la alerta (FR-008)")
	assert.Equal(t, true, video["canSubscribe"])
	assert.Nil(t, video["roomRecord"])
}

// RN-KYQ-015: alerta → ubicación a 1 Hz → sala con los operadores, solo dentro de la ventana
// del viaje y sin avisar a la otra parte.
func TestIntegrationRaiseOnlyDuringTheTripWindow(t *testing.T) {
	f := setup(t)
	ctx := context.Background()

	requested := f.trip(t, trips.StatusRequested)
	_, _, err := f.svc.Raise(ctx, f.passenger, requested, nil)
	assert.ErrorIs(t, err, safety.ErrUnavailable, "sin aceptar no hay SOS: se ofrece el 123")
	_, err = f.trips.Act(ctx, f.passenger, requested, func(tr *trips.Trip, p trips.Party, now time.Time) error { return tr.Cancel(p, now) })
	require.NoError(t, err)

	tripID := f.trip(t, trips.StatusAccepted)
	_, _, err = f.svc.Raise(ctx, f.stranger, tripID, nil)
	assert.ErrorIs(t, err, safety.ErrNotFound, "solo las partes del viaje")
	_, _, err = f.svc.Raise(ctx, f.passenger, tripID, &safety.Point{Lat: 91, Lng: 0})
	assert.ErrorIs(t, err, safety.ErrInvalidLocation)

	out, created, err := f.svc.Raise(ctx, f.passenger, tripID, &safety.Point{Lat: 4.61, Lng: -74.07, RecordedAt: f.clock.Add(-30 * time.Second)})
	require.NoError(t, err)
	assert.True(t, created)
	room := "sos-" + out.Alert.ID.String()
	assert.Equal(t, "open", out.Alert.Status)
	assert.True(t, out.NeedsPIN, "sin PIN se envía igual y luego se pide (US4-3)")
	require.NotNil(t, out.Voice)
	assert.Equal(t, room, out.Voice.Room)
	assert.True(t, out.Voice.CanPublish)
	assert.True(t, f.voice.hasRoom(room), "sala creada al crear la alerta")
	assert.Equal(t, safety.RecordingKey(out.Alert.ID), f.voice.egress["EG_"+room], "grabación iniciada (FR-018)")
	assert.Equal(t, []string{"sos.created"}, f.pub.types(realtime.OpsSOSChannel))

	again, created, err := f.svc.Raise(ctx, f.passenger, tripID, nil)
	require.NoError(t, err)
	assert.False(t, created, "una alerta abierta por persona y viaje")
	assert.Equal(t, out.Alert.ID, again.Alert.ID)

	byDriver, created, err := f.svc.Raise(ctx, f.driver, tripID, nil)
	require.NoError(t, err)
	assert.True(t, created, "conductor y pasajero tienen una alerta cada uno")
	assert.NotEqual(t, out.Alert.ID, byDriver.Alert.ID)

	active, err := f.svc.Active(ctx, f.passenger)
	require.NoError(t, err)
	require.NotNil(t, active)
	assert.Equal(t, out.Alert.ID, active.ID)

	// Tras COMPLETED la ventana dura 15 min (FR-001).
	f.finish(t, tripID)
	require.NoError(t, f.closeAs(t, out.Alert.ID))
	require.NoError(t, f.closeAs(t, byDriver.Alert.ID))
	f.advance(trips.PTTCloseDelay - time.Second)
	late, created, err := f.svc.Raise(ctx, f.passenger, tripID, nil)
	require.NoError(t, err)
	assert.True(t, created)
	require.NoError(t, f.closeAs(t, late.Alert.ID))
	f.advance(time.Second)
	_, _, err = f.svc.Raise(ctx, f.passenger, tripID, nil)
	assert.ErrorIs(t, err, safety.ErrUnavailable)
}

// closeAs claims and closes an alert as the on-duty operator.
func (f *fixture) closeAs(t *testing.T, alertID uuid.UUID) error {
	t.Helper()
	ctx := context.Background()
	if _, err := f.svc.Claim(ctx, f.operator, alertID); err != nil {
		return err
	}
	return f.svc.Close(ctx, f.operator, alertID, "false_alarm")
}

func TestIntegrationLocationsReachOnlyTheOperators(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	tripID := f.trip(t, trips.StatusInProgress)
	out := f.raise(t, f.passenger, tripID)
	id := out.Alert.ID

	acc := 8.5
	batch := []safety.Point{
		{Lat: 4.611, Lng: -74.071, AccuracyM: &acc, RecordedAt: f.clock.Add(-2 * time.Second)},
		{Lat: 4.612, Lng: -74.072, RecordedAt: f.clock.Add(-time.Second)},
		{Lat: 4.612, Lng: -74.072, RecordedAt: f.clock.Add(-time.Second)}, // duplicado: se ignora
	}
	self, err := f.svc.Locations(ctx, f.passenger, id, batch)
	require.NoError(t, err)
	assert.Equal(t, "open", self.Status)
	assert.False(t, self.OperatorConnected)
	points, err := f.st.ListSOSLocations(ctx, id)
	require.NoError(t, err)
	assert.Len(t, points, 3, "punto inicial + dos del lote")
	assert.Equal(t, []string{"sos.location"}, f.pub.types("sos:"+id.String()))

	_, err = f.svc.Locations(ctx, f.driver, id, batch[:1])
	assert.ErrorIs(t, err, safety.ErrNotFound, "solo quien pidió ayuda envía su ubicación")
	_, err = f.svc.Locations(ctx, f.passenger, id, make([]safety.Point, safety.MaxBatch+1))
	assert.ErrorIs(t, err, safety.ErrInvalidLocation)

	// FR-006: el conductor no recibe nada (ni en trip:{id} ni en user:{driverId}).
	assert.Empty(t, f.sosLeaks(f.passenger))
	none, err := f.svc.Active(ctx, f.driver)
	require.NoError(t, err)
	assert.Nil(t, none, "el conductor no ve la alerta del pasajero")

	// Al tomarla el operador la app lo sabe en la respuesta del siguiente lote.
	_, err = f.svc.Claim(ctx, f.operator, id)
	require.NoError(t, err)
	self, err = f.svc.Locations(ctx, f.passenger, id, batch[1:2])
	require.NoError(t, err)
	assert.True(t, self.OperatorConnected)

	require.NoError(t, f.svc.Close(ctx, f.operator, id, "resolved"))
	_, err = f.svc.Locations(ctx, f.passenger, id, batch[1:2])
	assert.ErrorIs(t, err, safety.ErrClosed, "al cerrar la app deja de enviar (US2-4)")
	assert.Contains(t, f.pub.types("user:"+f.passenger.String()), "sos.closed")
	assert.Empty(t, f.sosLeaks(f.passenger))
}

func TestIntegrationVoiceFailureDoesNotBlockTheAlert(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	tripID := f.trip(t, trips.StatusAccepted)
	f.voice.failRoom = true
	out := f.raise(t, f.passenger, tripID)
	assert.Nil(t, out.Voice, "sin LiveKit la alerta se crea igual; la app pide el token después")
	assert.Equal(t, []string{"sos.created"}, f.pub.types(realtime.OpsSOSChannel))
	_, err := f.svc.Token(ctx, f.passenger, out.Alert.ID)
	assert.ErrorIs(t, err, safety.ErrVoiceUnavailable)

	f.voice.failRoom = false
	creds, err := f.svc.Token(ctx, f.passenger, out.Alert.ID)
	require.NoError(t, err)
	assert.True(t, creds.CanPublish)
	_, err = f.svc.Token(ctx, f.driver, out.Alert.ID)
	assert.ErrorIs(t, err, safety.ErrNotFound)

	alert, err := f.st.GetSOSAlert(ctx, out.Alert.ID)
	require.NoError(t, err)
	assert.False(t, alert.EgressID.Valid)
	require.NoError(t, f.svc.StartMissingRecordings(ctx))
	alert, err = f.st.GetSOSAlert(ctx, out.Alert.ID)
	require.NoError(t, err)
	assert.True(t, alert.EgressID.Valid, "el barrido reintenta la grabación")
}

func TestIntegrationCancelNeedsThePIN(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	tripID := f.trip(t, trips.StatusInProgress)
	id := f.raise(t, f.passenger, tripID).Alert.ID

	assert.ErrorIs(t, f.svc.Cancel(ctx, f.passenger, id, "1234"), safety.ErrNoPIN, "sin PIN no se cancela")
	alert, err := f.st.GetSOSAlert(ctx, id)
	require.NoError(t, err)
	assert.Equal(t, store.SosStatusOpen, alert.Status)
	assert.True(t, alert.CancelWithoutPin, "marcada para el operador (FR-005)")
	assert.ErrorIs(t, f.svc.SetPIN(ctx, f.passenger, "1234", nil), safety.ErrPINDuringSOS, "no se fija un PIN con la alerta abierta")
	require.NoError(t, f.closeAs(t, id))

	require.NoError(t, f.svc.SetPIN(ctx, f.passenger, "2468", nil))
	id = f.raise(t, f.passenger, tripID).Alert.ID
	assert.ErrorIs(t, f.svc.Cancel(ctx, f.driver, id, "2468"), safety.ErrNotFound, "la otra parte no puede cancelar")
	for i := 1; i < safety.MaxPINAttempts; i++ {
		assert.ErrorIs(t, f.svc.Cancel(ctx, f.passenger, id, "0000"), safety.ErrInvalidPIN)
	}
	assert.ErrorIs(t, f.svc.Cancel(ctx, f.passenger, id, "0000"), safety.ErrPINLocked, "5 intentos bloquean")
	assert.ErrorIs(t, f.svc.Cancel(ctx, f.passenger, id, "2468"), safety.ErrPINLocked, "ni con el PIN correcto")
	alert, err = f.st.GetSOSAlert(ctx, id)
	require.NoError(t, err)
	assert.Equal(t, store.SosStatusOpen, alert.Status)
	assert.True(t, alert.CancelWithoutPin)
	assert.Contains(t, f.pub.types(realtime.OpsSOSChannel), "sos.cancel_attempt")

	require.NoError(t, f.closeAs(t, id), "el operador cierra y se levanta el bloqueo")
	id = f.raise(t, f.passenger, tripID).Alert.ID
	room := "sos-" + id.String()
	require.NoError(t, f.svc.Cancel(ctx, f.passenger, id, "2468"))
	alert, err = f.st.GetSOSAlert(ctx, id)
	require.NoError(t, err)
	assert.Equal(t, store.SosStatusCancelledByUser, alert.Status)
	assert.False(t, alert.CancelWithoutPin)
	assert.True(t, alert.VoiceClosedAt.Valid)
	assert.False(t, f.voice.hasRoom(room), "la sala se borra")
	assert.Contains(t, f.voice.stopped, "EG_"+room, "la grabación se detiene")
	assert.ErrorIs(t, f.svc.Cancel(ctx, f.passenger, id, "2468"), safety.ErrClosed)
	assert.Empty(t, f.sosLeaks(f.passenger), "FR-006")
}

func TestIntegrationDriverSOSIsHiddenFromThePassenger(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	tripID := f.trip(t, trips.StatusInProgress)
	out := f.raise(t, f.driver, tripID)
	_, err := f.svc.Locations(ctx, f.driver, out.Alert.ID, []safety.Point{{Lat: 4.6, Lng: -74.1, RecordedAt: *f.clock}})
	require.NoError(t, err)
	assert.Empty(t, f.sosLeaks(f.driver), "el pasajero no ve que se activó una alerta (US1-5)")
	active, err := f.svc.Active(ctx, f.passenger)
	require.NoError(t, err)
	assert.Nil(t, active)
}
