package radio

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/store"
)

// US7, FR-024: hasta 10 conversaciones con "Escuchar"; con "Escuchar" apagado los mensajes llegan
// al historial sin sonar.
func TestIntegrationListeningLimit(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	f.consent(t, f.carlos, f.jonathan)
	first := f.contact(t, f.carlos, f.jonathan)
	for i := 2; i <= MaxListening; i++ {
		f.channel(t, f.carlos, fmt.Sprintf("Canal %02d", i), JoinApproval, nil)
	}
	list, err := f.svc.List(ctx, f.carlos)
	require.NoError(t, err)
	require.Len(t, list, MaxListening)
	for _, c := range list {
		assert.True(t, c.Listening)
	}

	// La conversación 11 llega sin "Escuchar" y no se enciende sin apagar otra.
	other := f.newDriver(t, "+573005550301", "Rosa")
	eleventh := f.contact(t, other, f.carlos)
	m, err := f.st.GetRadioMember(ctx, store.GetRadioMemberParams{ConversationID: eleventh, UserID: f.carlos})
	require.NoError(t, err)
	assert.False(t, m.Listening)
	assert.ErrorIs(t, f.svc.SetListening(ctx, f.carlos, eleventh, true), ErrListeningLimit)
	require.NoError(t, f.svc.SetListening(ctx, f.carlos, first, false))
	require.NoError(t, f.svc.SetListening(ctx, f.carlos, eleventh, true))

	// Con "Escuchar" apagado la voz de Jonathan llega en silencio para Carlos.
	f.voice(t, f.jonathan, first, 2*time.Second)
	got := f.pub.events(f.carlos, EventMessage)
	require.NotEmpty(t, got)
	assert.Equal(t, true, got[len(got)-1]["silent"])
	assert.ErrorIs(t, f.svc.SetListening(ctx, f.pedro, first, true), ErrNotFound, "solo quien participa")
}
