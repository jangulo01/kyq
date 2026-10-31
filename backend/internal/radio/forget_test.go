package radio

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/store"
)

// T047 (habeas data): al eliminar una cuenta se borra de inmediato lo que envió, con sus audios,
// fotos y las copias que otros guardaron, y el autor queda anónimo.
func TestIntegrationForgetUser(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	f.consent(t, f.carlos, f.jonathan)
	conv := f.contact(t, f.carlos, f.jonathan)
	voice := f.voice(t, f.jonathan, conv, 2*time.Second)
	_, err := f.svc.Send(ctx, f.jonathan, conv, SendInput{Kind: MessageText, Body: "mi dirección es…"})
	require.NoError(t, err)
	mine := f.voice(t, f.carlos, conv, 2*time.Second)
	require.NoError(t, f.svc.Receipt(ctx, f.carlos, voice, ReceiptInput{Saved: ptr(true)}))
	require.NoError(t, f.svc.Receipt(ctx, f.jonathan, mine, ReceiptInput{Saved: ptr(true)}))
	m, err := f.st.GetRadioMessage(ctx, voice)
	require.NoError(t, err)
	key := m.ObjectKey.String
	_, err = f.media.Stat(ctx, key)
	require.NoError(t, err)
	rc, err := f.st.GetRadioReceipt(ctx, store.GetRadioReceiptParams{MessageID: voice, UserID: f.carlos})
	require.NoError(t, err)
	require.True(t, rc.SavedKey.Valid)
	_, err = f.saved.Stat(ctx, rc.SavedKey.String)
	require.NoError(t, err)

	require.NoError(t, f.svc.ForgetUser(ctx, f.jonathan))
	_, err = f.saved.Stat(ctx, rc.SavedKey.String)
	assert.Error(t, err, "la copia que guardó Carlos también se borró")

	_, err = f.media.Stat(ctx, key)
	assert.Error(t, err, "el audio se borró")
	hist, err := f.svc.History(ctx, f.carlos, conv, nil, 20)
	require.NoError(t, err)
	require.Len(t, hist, 1, "solo queda el mensaje de Carlos")
	assert.Equal(t, mine, hist[0].ID)
	gone, err := f.st.GetRadioMessage(ctx, voice)
	require.NoError(t, err)
	assert.False(t, gone.AuthorID.Valid, "autor anónimo")
	assert.Equal(t, "deleted", string(gone.Status))
	// El mensaje de Carlos sigue con su audio.
	own, err := f.st.GetRadioMessage(ctx, mine)
	require.NoError(t, err)
	_, err = f.media.Stat(ctx, own.ObjectKey.String)
	assert.NoError(t, err)
}
