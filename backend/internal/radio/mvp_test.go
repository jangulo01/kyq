package radio

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/store"
)

// US1: contactos por QR y por teléfono, sin teléfonos en ninguna respuesta (FR-002, FR-004).
func TestIntegrationContacts(t *testing.T) {
	f := setup(t)
	ctx := context.Background()

	inv, err := f.svc.InviteContact(ctx, f.carlos, ContactInviteInput{})
	require.NoError(t, err)
	assert.Regexp(t, `^[0-9A-Za-z]{10}$`, inv.Code)
	assert.Equal(t, "https://kyq.test/r/"+inv.Code, inv.URL)
	preview, err := f.svc.Preview(ctx, inv.Code)
	require.NoError(t, err)
	assert.Equal(t, InvitePreview{Kind: "contact", InviterName: "Carlos", InviteeKind: "driver"}, preview)

	// Un pasajero no acepta un contacto de conductores; uno mismo tampoco.
	_, err = f.svc.Accept(ctx, f.ana, inv.Code)
	assert.ErrorIs(t, err, ErrInviteWrongApp)
	_, err = f.svc.Accept(ctx, f.carlos, inv.Code)
	assert.ErrorIs(t, err, ErrInvalid)

	res, err := f.svc.Accept(ctx, f.jonathan, inv.Code)
	require.NoError(t, err)
	assert.Equal(t, KindDirect, res.Conversation.Kind)
	assert.Equal(t, "Carlos", res.Conversation.Title)
	assert.Len(t, f.pub.events(f.carlos, EventInvite), 1)

	for _, u := range []uuid.UUID{f.carlos, f.jonathan} {
		list, err := f.svc.List(ctx, u)
		require.NoError(t, err)
		require.Len(t, list, 1)
		raw, _ := json.Marshal(list)
		assert.NotContains(t, string(raw), "+57", "FR-004: sin teléfonos")
		assert.Equal(t, StatusOffline, *list[0].PeerStatus, "radio apagada")
	}
	// Aceptar dos veces no duplica la conversación.
	again, err := f.svc.Accept(ctx, f.jonathan, inv.Code)
	require.NoError(t, err)
	assert.Equal(t, res.Conversation.ID, again.Conversation.ID)

	// Por teléfono: 202 siempre, con SMS y enlace, exista o no la cuenta (US1-2).
	for _, phone := range []string{"300 555 0001", "+573100000002"} {
		out, err := f.svc.InviteContact(ctx, f.carlos, ContactInviteInput{PhoneE164: phone})
		require.NoError(t, err)
		assert.Nil(t, out)
	}
	require.Len(t, f.sms.to("+573005550001"), 1)
	assert.Contains(t, f.sms.to("+573005550001")[0], "Carlos te invita")
	assert.Contains(t, f.sms.to("+573005550001")[0], "https://kyq.test/r/")
	assert.Len(t, f.sms.to("+573100000002"), 1)

	// Borrar el contacto: desaparece para los dos y nadie puede hablar (US1-7).
	f.consent(t, f.carlos, f.jonathan)
	require.NoError(t, f.svc.Delete(ctx, f.carlos, res.Conversation.ID))
	for _, u := range []uuid.UUID{f.carlos, f.jonathan} {
		list, err := f.svc.List(ctx, u)
		require.NoError(t, err)
		assert.Empty(t, list)
	}
	_, err = f.svc.TakeFloor(ctx, f.jonathan, res.Conversation.ID)
	assert.ErrorIs(t, err, ErrNotFound)
}

// US1: turno único de 60 s, fail-closed, con su mensaje de voz (FR-006, edge cases).
func TestIntegrationFloor(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	conv := f.contact(t, f.carlos, f.jonathan)

	// Sin aceptar el aviso de registro no se transmite (FR-013).
	_, err := f.svc.TakeFloor(ctx, f.carlos, conv)
	assert.ErrorIs(t, err, ErrConsentRequired)
	f.consent(t, f.carlos, f.jonathan)

	fl, err := f.svc.TakeFloor(ctx, f.carlos, conv)
	require.NoError(t, err)
	c, err := f.st.GetRadioConversation(ctx, conv)
	require.NoError(t, err)
	assert.True(t, f.rooms.created[c.RoomName], "sala con egress automático por pista (R3)")
	assert.True(t, f.rooms.publishing(c.RoomName, f.carlos))
	assert.True(t, f.clock.Add(FloorTTL).Equal(fl.ExpiresAt))

	again, err := f.svc.TakeFloor(ctx, f.carlos, conv)
	require.NoError(t, err)
	assert.Equal(t, fl.MessageID, again.MessageID, "reintento idempotente")

	_, err = f.svc.TakeFloor(ctx, f.jonathan, conv)
	var busy *FloorBusyError
	require.ErrorAs(t, err, &busy)
	assert.Equal(t, "Carlos", busy.HolderName)
	assert.False(t, f.rooms.publishing(c.RoomName, f.jonathan))

	// Sin audio 3 s, el barrido libera el turno y la pulsación vacía no queda.
	f.advance(SilentFloor)
	n, err := f.svc.ExpireFloors(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, n)
	assert.False(t, f.rooms.publishing(c.RoomName, f.carlos))
	msg, err := f.st.GetRadioMessage(ctx, fl.MessageID)
	require.NoError(t, err)
	assert.Equal(t, store.RadioMessageStatusDiscarded, msg.Status)

	// Con audio, a los 60 s se corta solo.
	fl, err = f.svc.TakeFloor(ctx, f.jonathan, conv)
	require.NoError(t, err)
	f.svc.TrackPublished(ctx, c.RoomName, f.jonathan.String())
	f.advance(FloorTTL)
	n, err = f.svc.ExpireFloors(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, n)
	msg, err = f.st.GetRadioMessage(ctx, fl.MessageID)
	require.NoError(t, err)
	assert.Equal(t, store.RadioMessageStatusRecording, msg.Status, "espera su archivo del egress")

	// Si LiveKit no concede publicar, el turno no queda tomado.
	f.rooms.failPublish = true
	_, err = f.svc.TakeFloor(ctx, f.carlos, conv)
	assert.ErrorIs(t, err, ErrUnavailable)
	_, err = f.st.GetRadioFloor(ctx, conv)
	assert.True(t, store.IsNotFound(err))
	f.rooms.failPublish = false

	// Quien tiene el turno y se desconecta lo libera en el acto.
	_, err = f.svc.TakeFloor(ctx, f.carlos, conv)
	require.NoError(t, err)
	f.svc.TrackPublished(ctx, c.RoomName, f.carlos.String())
	f.advance(2 * time.Second)
	f.svc.ParticipantLeft(ctx, c.RoomName, f.carlos.String(), 30)
	_, err = f.st.GetRadioFloor(ctx, conv)
	assert.True(t, store.IsNotFound(err))
}

// US2: registro por egress, historial, nuevos, guardados y retención (FR-010–FR-012).
func TestIntegrationHistoryAndRetention(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	conv := f.contact(t, f.carlos, f.jonathan)
	f.consent(t, f.carlos, f.jonathan)

	ids := []uuid.UUID{}
	for range 3 {
		ids = append(ids, f.voice(t, f.carlos, conv, 2*time.Second))
		f.advance(time.Second)
	}
	// Pulsación de 0,3 s: no queda (quickstart §1.5).
	short := f.voice(t, f.carlos, conv, 300*time.Millisecond)
	msg, err := f.st.GetRadioMessage(ctx, short)
	require.NoError(t, err)
	assert.Equal(t, store.RadioMessageStatusDiscarded, msg.Status)

	events := f.pub.events(f.jonathan, EventMessage)
	require.Len(t, events, 3)
	assert.Equal(t, false, events[0]["silent"])

	list, err := f.svc.List(ctx, f.jonathan)
	require.NoError(t, err)
	assert.Equal(t, 3, list[0].UnreadCount, "3 nuevos (quickstart §1.4)")

	hist, err := f.svc.History(ctx, f.jonathan, conv, nil, 50)
	require.NoError(t, err)
	require.Len(t, hist, 3)
	assert.Equal(t, ids[2], hist[0].ID, "más reciente primero")
	assert.Equal(t, "Carlos", hist[0].AuthorName)
	assert.Equal(t, 2000, *hist[0].DurationMs)
	assert.True(t, hist[0].HasMedia)
	page, err := f.svc.History(ctx, f.jonathan, conv, &ids[2], 50)
	require.NoError(t, err)
	assert.Len(t, page, 2)

	url, err := f.svc.MediaURL(ctx, f.jonathan, ids[0])
	require.NoError(t, err)
	assert.Contains(t, url, "op=get")
	assert.Contains(t, url, "ttl=10m0s")

	heard := true
	require.NoError(t, f.svc.Receipt(ctx, f.jonathan, ids[0], ReceiptInput{Heard: &heard}))
	list, err = f.svc.List(ctx, f.jonathan)
	require.NoError(t, err)
	assert.Equal(t, 2, list[0].UnreadCount)

	save := true
	require.NoError(t, f.svc.Receipt(ctx, f.jonathan, ids[1], ReceiptInput{Saved: &save}))
	savedKey := "saved/" + f.jonathan.String() + "/" + ids[1].String() + ".ogg"
	assert.True(t, f.saved.Has(savedKey))

	// A los 30 días vence lo no guardado (FR-012); lo guardado sigue para quien lo guardó.
	f.advance(31 * 24 * time.Hour)
	n, err := f.svc.Retain(ctx)
	require.NoError(t, err)
	assert.Equal(t, 4, n, "3 mensajes y la pulsación descartada")
	hist, err = f.svc.History(ctx, f.jonathan, conv, nil, 50)
	require.NoError(t, err)
	require.Len(t, hist, 1)
	assert.Equal(t, ids[1], hist[0].ID)
	assert.True(t, hist[0].Saved)
	url, err = f.svc.MediaURL(ctx, f.jonathan, ids[1])
	require.NoError(t, err)
	assert.Contains(t, url, savedKey)
	hist, err = f.svc.History(ctx, f.carlos, conv, nil, 50)
	require.NoError(t, err)
	assert.Empty(t, hist, "el autor no lo guardó")
	_, err = f.svc.MediaURL(ctx, f.carlos, ids[0])
	assert.ErrorIs(t, err, ErrNotFound)

	// Quitar el guardado borra la copia.
	unsave := false
	require.NoError(t, f.svc.Receipt(ctx, f.jonathan, ids[1], ReceiptInput{Saved: &unsave}))
	assert.False(t, f.saved.Has(savedKey))
}

// FR-005: las tres políticas del panel para un conductor sin suscripción.
func TestIntegrationAccessPolicies(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	conv := f.contact(t, f.carlos, f.pedro)
	f.consent(t, f.pedro)

	me, err := f.svc.Me(ctx, f.pedro)
	require.NoError(t, err)
	assert.Equal(t, Full, me.Access, "prueba de 14 días")
	assert.Equal(t, 14, *me.TrialDaysLeft)
	_, err = f.svc.TakeFloor(ctx, f.pedro, conv)
	require.NoError(t, err)
	require.NoError(t, f.svc.ReleaseFloor(ctx, f.pedro, conv))

	set := func(policy string) {
		_, err := f.st.Pool.Exec(ctx, "UPDATE radio_settings SET trial_policy = $1", policy)
		require.NoError(t, err)
		f.advance(settingsTTL)
	}
	set(PolicyListenOnly)
	_, err = f.svc.TakeFloor(ctx, f.pedro, conv)
	assert.ErrorIs(t, err, ErrListenOnly)
	hist, err := f.svc.History(ctx, f.pedro, conv, nil, 10)
	require.NoError(t, err, "oye y lee")
	assert.Empty(t, hist)

	set(PolicySubscriptionOnly)
	_, err = f.svc.List(ctx, f.pedro)
	assert.ErrorIs(t, err, ErrAccessDenied)
	me, err = f.svc.Me(ctx, f.pedro)
	require.NoError(t, err)
	assert.Equal(t, None, me.Access)
	assert.Equal(t, ReasonNoSubscription, *me.AccessReason)

	// Un cambio de retención pide aceptar de nuevo el aviso (FR-013).
	_, err = f.st.Pool.Exec(ctx, "UPDATE radio_settings SET retention_days = 7")
	require.NoError(t, err)
	f.advance(settingsTTL)
	me, err = f.svc.Me(ctx, f.carlos)
	require.NoError(t, err)
	assert.True(t, me.ConsentRequired)
	assert.Equal(t, 7, me.RetentionDays)
}
