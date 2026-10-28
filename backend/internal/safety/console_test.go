package safety_test

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/safety"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/trips"
)

func TestIntegrationConsoleOnlyForEmergencyOperators(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	id := f.raise(t, f.passenger, f.trip(t, trips.StatusAccepted)).Alert.ID

	for _, user := range []struct {
		name string
		id   uuid.UUID
	}{{"admin sin permiso", f.admin}, {"pasajero", f.passenger}, {"conductor", f.driver}} {
		_, err := f.svc.ListOpen(ctx, user.id)
		assert.ErrorIs(t, err, safety.ErrNotOperator, user.name)
		_, err = f.svc.Detail(ctx, user.id, id)
		assert.ErrorIs(t, err, safety.ErrNotOperator, user.name)
		_, err = f.svc.Claim(ctx, user.id, id)
		assert.ErrorIs(t, err, safety.ErrNotOperator, user.name)
		_, err = f.svc.OperatorToken(ctx, user.id, id)
		assert.ErrorIs(t, err, safety.ErrNotOperator, user.name)
	}
	ok, err := f.st.IsEmergencyOperator(ctx, f.admin)
	require.NoError(t, err)
	assert.False(t, ok)

	queue, err := f.svc.ListOpen(ctx, f.operator)
	require.NoError(t, err)
	require.Len(t, queue, 1)
	assert.Equal(t, "Ana", queue[0].RaisedByName)
	assert.Equal(t, "passenger", queue[0].RaisedRole)
	require.NotNil(t, queue[0].LastLocation)
	assert.InDelta(t, 4.61, queue[0].LastLocation.Lat, 1e-9)

	// Auditoría (FR-012): cada acceso queda registrado.
	_, err = f.svc.Detail(ctx, f.operator, id)
	require.NoError(t, err)
	audit, err := f.st.ListSOSAudit(ctx, f.operator)
	require.NoError(t, err)
	var actions []string
	for _, a := range audit {
		actions = append(actions, a.Action)
	}
	assert.Equal(t, []string{"list_open", "view"}, actions)
}

func TestIntegrationClaimReleaseAndVoiceFailClosed(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	id := f.raise(t, f.passenger, f.trip(t, trips.StatusInProgress)).Alert.ID
	room := "sos-" + id.String()

	// Ambos operadores escuchan; nadie habla sin tomar la alerta (FR-008).
	for _, op := range []struct{ id uuid.UUID }{{f.operator}, {f.operator2}} {
		creds, err := f.svc.OperatorToken(ctx, op.id, id)
		require.NoError(t, err)
		assert.False(t, creds.CanPublish)
		assert.Equal(t, room, creds.Room)
	}

	claimed, err := f.svc.Claim(ctx, f.operator, id)
	require.NoError(t, err)
	assert.Equal(t, "claimed", claimed.Status)
	require.NotNil(t, claimed.ClaimedByName)
	assert.Equal(t, "Operadora Lucía", *claimed.ClaimedByName)
	assert.True(t, f.voice.publishes(room, f.operator), "quien toma la alerta habla")
	assert.Contains(t, f.pub.types(realtime.OpsSOSChannel), "sos.claimed")

	_, err = f.svc.Claim(ctx, f.operator2, id)
	assert.ErrorIs(t, err, safety.ErrClaimed, "al otro le aparece tomada")
	assert.False(t, f.voice.publishes(room, f.operator2))
	_, err = f.svc.Claim(ctx, f.operator, id)
	assert.NoError(t, err, "volver a tomarla concede la voz otra vez (tras entrar en la sala)")

	assert.ErrorIs(t, f.svc.Release(ctx, f.operator2, id), safety.ErrNotClaimant)

	// Si LiveKit no confirma la retirada, la alerta sigue tomada y nadie más puede hablar.
	f.voice.failRevoke = true
	assert.ErrorIs(t, f.svc.Release(ctx, f.operator, id), safety.ErrVoiceUnavailable)
	_, err = f.svc.Claim(ctx, f.operator2, id)
	assert.ErrorIs(t, err, safety.ErrClaimed)
	f.voice.failRevoke = false

	require.NoError(t, f.svc.Release(ctx, f.operator, id))
	assert.False(t, f.voice.publishes(room, f.operator), "liberar retira la voz")
	assert.Contains(t, f.pub.types(realtime.OpsSOSChannel), "sos.released")

	// Si LiveKit falla al conceder, la toma queda pero sin voz (la retirada se confirmó).
	f.voice.failGrant = true
	_, err = f.svc.Claim(ctx, f.operator2, id)
	assert.ErrorIs(t, err, safety.ErrVoiceUnavailable)
	f.voice.failGrant = false
	alert, err := f.st.GetSOSAlert(ctx, id)
	require.NoError(t, err)
	assert.Equal(t, store.SosStatusClaimed, alert.Status)
	assert.False(t, alert.VoiceHolderID.Valid, "permiso retirado y olvidado")
	_, err = f.svc.Claim(ctx, f.operator2, id)
	require.NoError(t, err, "reintento")
	assert.True(t, f.voice.publishes(room, f.operator2))
	assert.Empty(t, f.sosLeaks(f.passenger))
}

func TestIntegrationNotesAndCloseWithOutcome(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	tripID := f.trip(t, trips.StatusInProgress)
	id := f.raise(t, f.passenger, tripID).Alert.ID
	room := "sos-" + id.String()
	byDriver := f.raise(t, f.driver, tripID).Alert.ID

	_, err := f.svc.AddNote(ctx, f.operator, id, "   ")
	assert.ErrorIs(t, err, safety.ErrInvalidNote)
	_, err = f.svc.Claim(ctx, f.operator, id)
	require.NoError(t, err)
	n1, err := f.svc.AddNote(ctx, f.operator, id, "Llamé a la policía, cuadrante 12")
	require.NoError(t, err)
	assert.Equal(t, "Operadora Lucía", n1.OperatorName)
	f.advance(time.Minute)
	_, err = f.svc.AddNote(ctx, f.operator, id, "Contacté a la familia")
	require.NoError(t, err)

	assert.ErrorIs(t, f.svc.Close(ctx, f.operator, id, ""), safety.ErrInvalidOutcome, "desenlace obligatorio")
	assert.ErrorIs(t, f.svc.Close(ctx, f.operator, id, "otro"), safety.ErrInvalidOutcome)
	assert.ErrorIs(t, f.svc.Close(ctx, f.operator2, id, "resolved"), safety.ErrNotClaimant)

	f.voice.failDelete = true
	require.NoError(t, f.svc.Close(ctx, f.operator, id, "escalated_authorities"))
	alert, err := f.st.GetSOSAlert(ctx, id)
	require.NoError(t, err)
	assert.Equal(t, store.SosStatusClosed, alert.Status)
	assert.Equal(t, store.SosOutcomeEscalatedAuthorities, alert.Outcome.SosOutcome)
	assert.Equal(t, f.operator, alert.ClaimedBy.UUID, "queda quién la atendió")
	assert.False(t, alert.VoiceClosedAt.Valid, "LiveKit no borró la sala: pendiente")
	assert.ErrorIs(t, f.svc.Close(ctx, f.operator, id, "resolved"), safety.ErrClosed)
	_, err = f.svc.OperatorToken(ctx, f.operator, id)
	assert.ErrorIs(t, err, safety.ErrClosed)

	f.voice.failDelete = false
	n, err := f.svc.CloseVoicePending(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, n, "el barrido cierra la sala")
	assert.False(t, f.voice.hasRoom(room))
	assert.Contains(t, f.voice.stopped, "EG_"+room, "la grabación se detiene al cerrar")

	// Historial con notas, desenlace y grabación reproducible (FR-010, FR-018).
	f.objects.Put(safety.RecordingKey(id), []byte("ogg"), "audio/ogg")
	d, err := f.svc.Detail(ctx, f.operator, id)
	require.NoError(t, err)
	require.Len(t, d.Notes, 2)
	assert.Equal(t, "Llamé a la policía, cuadrante 12", d.Notes[0].Body)
	require.NotNil(t, d.Outcome)
	assert.Equal(t, "escalated_authorities", *d.Outcome)
	require.NotNil(t, d.RecordingURL)
	assert.Contains(t, *d.RecordingURL, "ttl=5m0s", "URL firmada de 5 min")
	assert.Equal(t, f.driverName, d.Driver.Name)
	assert.Equal(t, "KYQ001", d.Driver.VehiclePlate)
	assert.Equal(t, "Ana", d.Passenger.Name)
	assert.Equal(t, passengerPhone, d.RaisedByPhone)
	assert.Equal(t, []uuid.UUID{byDriver}, d.RelatedAlertIDs, "las dos alertas del viaje se ven juntas")
	require.NotEmpty(t, d.Track)
	assert.Equal(t, 1, d.RaisedByAlerts)

	history, err := f.svc.ListHistory(ctx, f.operator, safety.HistoryFilter{From: f.clock.Add(-time.Hour), To: f.clock.Add(time.Hour), Outcome: "escalated_authorities"})
	require.NoError(t, err)
	require.Len(t, history, 1)
	assert.Equal(t, id, history[0].ID)
	history, err = f.svc.ListHistory(ctx, f.operator, safety.HistoryFilter{From: f.clock.Add(-time.Hour), To: f.clock.Add(time.Hour), Outcome: "false_alarm"})
	require.NoError(t, err)
	assert.Empty(t, history)
	_, err = f.svc.ListHistory(ctx, f.operator, safety.HistoryFilter{From: f.clock.Add(time.Hour), To: f.clock.Add(-time.Hour)})
	assert.ErrorIs(t, err, safety.ErrInvalidFilter)

	queue, err := f.svc.ListOpen(ctx, f.operator)
	require.NoError(t, err)
	require.Len(t, queue, 1, "solo queda la del conductor")
	assert.Equal(t, byDriver, queue[0].ID)
}

func TestIntegrationEscalationAfter60sOnce(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	id := f.raise(t, f.passenger, f.trip(t, trips.StatusAccepted)).Alert.ID

	f.advance(safety.EscalateAfter - time.Second)
	n, err := f.svc.Escalate(ctx)
	require.NoError(t, err)
	assert.Zero(t, n)

	f.advance(time.Second)
	n, err = f.svc.Escalate(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, n)
	assert.Len(t, f.sms.to(operatorPhone), 1, "SMS al operador de guardia (FR-011)")
	assert.Empty(t, f.sms.to(operator2Phone), "fuera de guardia no recibe")
	assert.Contains(t, f.pub.types(realtime.OpsSOSChannel), "sos.escalated")

	f.advance(time.Minute)
	n, err = f.svc.Escalate(ctx)
	require.NoError(t, err)
	assert.Zero(t, n, "una sola vez")
	assert.Len(t, f.sms.to(operatorPhone), 1)

	self, err := f.svc.Locations(ctx, f.passenger, id, []safety.Point{{Lat: 4.6, Lng: -74.1}})
	require.NoError(t, err)
	assert.True(t, self.Escalated, "la app muestra «Seguimos intentando conectar con un operador»")

	// Una alerta tomada a tiempo no se escala.
	require.NoError(t, f.closeAs(t, id))
	id2 := f.raise(t, f.passenger, f.trip2(t)).Alert.ID
	_, err = f.svc.Claim(ctx, f.operator2, id2)
	require.NoError(t, err)
	f.advance(2 * safety.EscalateAfter)
	n, err = f.svc.Escalate(ctx)
	require.NoError(t, err)
	assert.Zero(t, n)

	// Turno de guardia.
	require.NoError(t, f.svc.SetDuty(ctx, f.operator2, true))
	on, err := f.svc.Duty(ctx, f.operator2)
	require.NoError(t, err)
	assert.True(t, on)
	assert.ErrorIs(t, f.svc.SetDuty(ctx, f.admin, true), safety.ErrNotOperator)
}

// trip2 completes the current trip and returns a new accepted one.
func (f *fixture) trip2(t *testing.T) uuid.UUID {
	t.Helper()
	trip, err := f.trips.Active(context.Background(), f.passenger, false)
	require.NoError(t, err)
	f.finish(t, trip.ID)
	return f.trip(t, trips.StatusAccepted)
}
