package radio

import (
	"context"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// FR-022: la alerta de llamada suena aunque el otro esté en Ocupado, con texto de hasta 80 y
// como mucho 3 por emisor y conversación cada 10 minutos.
func TestIntegrationCallAlert(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	f.consent(t, f.carlos, f.jonathan)
	conv := f.contact(t, f.carlos, f.jonathan)
	_, err := f.svc.UpdateMe(ctx, f.jonathan, MeUpdate{Status: ptr(StatusBusy)})
	require.NoError(t, err)

	_, err = f.svc.Send(ctx, f.carlos, conv, SendInput{Kind: MessageText, Body: "¿Dónde estás?"})
	require.NoError(t, err)
	got := f.pub.events(f.jonathan, EventMessage)
	require.NotEmpty(t, got)
	assert.Equal(t, true, got[len(got)-1]["silent"], "en Ocupado un texto no suena")

	_, err = f.svc.Send(ctx, f.carlos, conv, SendInput{Kind: MessageAlert, Body: strings.Repeat("a", MaxAlertLength+1)})
	assert.ErrorIs(t, err, ErrInvalid)
	for range AlertsPerWindow {
		_, err = f.svc.Send(ctx, f.carlos, conv, SendInput{Kind: MessageAlert, Body: "Llámame, es urgente"})
		require.NoError(t, err)
	}
	alerts := f.pub.events(f.jonathan, EventAlert)
	require.Len(t, alerts, AlertsPerWindow)
	assert.Equal(t, false, alerts[0]["silent"], "la alerta suena también en Ocupado")
	_, err = f.svc.Send(ctx, f.carlos, conv, SendInput{Kind: MessageAlert})
	assert.ErrorIs(t, err, ErrRateLimited)
	f.advance(AlertWindow + time.Second)
	_, err = f.svc.Send(ctx, f.carlos, conv, SendInput{Kind: MessageAlert})
	require.NoError(t, err)
}
