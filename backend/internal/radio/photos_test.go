package radio

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// US6, FR-023: texto, ubicación y foto en la misma conversación; la foto se ve solo cuando la
// subida es un JPEG válido.
func TestIntegrationTextLocationPhoto(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	f.consent(t, f.carlos, f.jonathan)
	conv := f.contact(t, f.carlos, f.jonathan)

	txt, err := f.svc.Send(ctx, f.carlos, conv, SendInput{Kind: MessageText, Body: "voy tarde 10 min"})
	require.NoError(t, err)
	assert.Equal(t, "voy tarde 10 min", *txt.Body)
	lat, lng := 4.65, -74.05
	loc, err := f.svc.Send(ctx, f.carlos, conv, SendInput{Kind: MessageLocation, Lat: &lat, Lng: &lng, Body: "Calle 80"})
	require.NoError(t, err)
	assert.InDelta(t, 4.65, *loc.Lat, 1e-9)
	bad := 120.0
	_, err = f.svc.Send(ctx, f.carlos, conv, SendInput{Kind: MessageLocation, Lat: &bad, Lng: &lng})
	assert.ErrorIs(t, err, ErrInvalid)

	up, err := f.svc.ReservePhoto(ctx, f.carlos, conv)
	require.NoError(t, err)
	assert.Equal(t, PhotoContentType, up.ContentType)
	assert.NotEmpty(t, up.UploadURL)
	assert.ErrorIs(t, f.svc.PhotoUploaded(ctx, f.carlos, up.MessageID), ErrPhotoInvalid, "aún no se subió")
	hist, err := f.svc.History(ctx, f.jonathan, conv, nil, 50)
	require.NoError(t, err)
	assert.Len(t, hist, 2, "la foto no se ve antes de confirmarse")

	m, err := f.st.GetRadioMessage(ctx, up.MessageID)
	require.NoError(t, err)
	f.media.Put(m.ObjectKey.String, []byte("\xff\xd8\xff jpeg"), "image/jpeg")
	assert.ErrorIs(t, f.svc.PhotoUploaded(ctx, f.jonathan, up.MessageID), ErrNotFound, "solo quien la envía")
	require.NoError(t, f.svc.PhotoUploaded(ctx, f.carlos, up.MessageID))
	require.NoError(t, f.svc.PhotoUploaded(ctx, f.carlos, up.MessageID), "confirmar dos veces no falla")
	hist, err = f.svc.History(ctx, f.jonathan, conv, nil, 50)
	require.NoError(t, err)
	require.Len(t, hist, 3)
	assert.Equal(t, MessagePhoto, hist[0].Kind)
	assert.True(t, hist[0].HasMedia)
	url, err := f.svc.MediaURL(ctx, f.jonathan, up.MessageID)
	require.NoError(t, err)
	assert.NotEmpty(t, url)
	assert.NotEmpty(t, f.pub.events(f.jonathan, EventMessage))

	// Un archivo que no es JPEG se borra y el mensaje no aparece.
	up2, err := f.svc.ReservePhoto(ctx, f.carlos, conv)
	require.NoError(t, err)
	m2, err := f.st.GetRadioMessage(ctx, up2.MessageID)
	require.NoError(t, err)
	f.media.Put(m2.ObjectKey.String, []byte("<html>"), "text/html")
	assert.ErrorIs(t, f.svc.PhotoUploaded(ctx, f.carlos, up2.MessageID), ErrPhotoInvalid)
	_, err = f.media.Stat(ctx, m2.ObjectKey.String)
	assert.Error(t, err, "se borró")
	hist, err = f.svc.History(ctx, f.jonathan, conv, nil, 50)
	require.NoError(t, err)
	assert.Len(t, hist, 3)
}
