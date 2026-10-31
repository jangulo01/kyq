package domains

import (
	"context"
	"crypto/ed25519"
	"encoding/base64"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/testdb"
)

func newSigner(t *testing.T, b byte) *Signer {
	seed := make([]byte, ed25519.SeedSize)
	seed[0] = b
	s, err := NewSigner(base64.StdEncoding.EncodeToString(seed))
	require.NoError(t, err)
	return s
}

// SC-006: una lista sin la firma de Kyq no se acepta.
func TestSignAndVerify(t *testing.T) {
	kyq, other := newSigner(t, 1), newSigner(t, 2)
	p := Payload{Version: 3, IssuedAt: time.Date(2026, 10, 28, 12, 0, 0, 0, time.UTC), Domains: []Entry{{APIURL: "https://api.kyq.co", RealtimeURL: "wss://rt.kyq.co/connection/websocket"}}}
	signed, err := kyq.Sign(p)
	require.NoError(t, err)
	got, err := Verify(kyq.PublicKey(), signed)
	require.NoError(t, err)
	assert.Equal(t, p, got)

	_, err = Verify(other.PublicKey(), signed)
	assert.ErrorIs(t, err, ErrBadSignature, "otra clave")
	tampered := signed
	tampered.Payload = `{"version":4,"issued_at":"2026-10-28T12:00:00Z","domains":[{"api_url":"https://evil.example","realtime_url":"wss://evil.example"}]}`
	_, err = Verify(kyq.PublicKey(), tampered)
	assert.ErrorIs(t, err, ErrBadSignature, "contenido cambiado")
	_, err = Verify("no-base64", signed)
	assert.ErrorIs(t, err, ErrBadSignature)

	_, err = NewSigner("corta")
	assert.Error(t, err)
}

func TestNormalize(t *testing.T) {
	a, r, err := normalize(" https://api.kyq.co/ ", "wss://rt.kyq.co/connection/websocket")
	require.NoError(t, err)
	assert.Equal(t, "https://api.kyq.co", a)
	assert.Equal(t, "wss://rt.kyq.co/connection/websocket", r)
	for _, bad := range [][2]string{
		{"ftp://api.kyq.co", "wss://x"}, {"https://api.kyq.co/v1", "wss://x"}, {"https://api.kyq.co", "https://x"}, {"", "wss://x"},
	} {
		_, _, err := normalize(bad[0], bad[1])
		assert.ErrorIs(t, err, ErrInvalidURL, bad)
	}
}

// US5: alta, orden, desactivar y la lista firmada con su versión (FR-019, FR-020).
func TestIntegrationMirrorDomains(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	signer := newSigner(t, 7)
	svc := &Service{Store: st, Signer: signer, Probe: func(_ context.Context, api string) (time.Duration, error) {
		if api == "https://caido.kyq.co" {
			return 0, errors.New("down")
		}
		return 42 * time.Millisecond, nil
	}}

	a, err := svc.Create(ctx, "https://api.kyq.co", "wss://rt.kyq.co/connection/websocket", true)
	require.NoError(t, err)
	b, err := svc.Create(ctx, "https://caido.kyq.co", "wss://rt2.kyq.co/connection/websocket", true)
	require.NoError(t, err)
	_, err = svc.Create(ctx, "https://api.kyq.co", "wss://x.kyq.co", true)
	assert.ErrorIs(t, err, ErrDuplicate)
	_, err = svc.Create(ctx, "api.kyq.co", "wss://x.kyq.co", true)
	assert.ErrorIs(t, err, ErrInvalidURL)

	l, err := svc.List(ctx)
	require.NoError(t, err)
	require.Len(t, l.Domains, 2)
	assert.Equal(t, int64(2), l.Version)
	assert.Equal(t, "ok", l.Domains[0].Status)
	assert.Equal(t, int64(42), *l.Domains[0].LatencyMs)
	assert.Equal(t, "down", l.Domains[1].Status, "FR-019: el panel ve el caído")
	assert.Equal(t, signer.PublicKey(), *l.PublicKey)

	require.NoError(t, svc.Reorder(ctx, []uuid.UUID{b.ID, a.ID}))
	assert.ErrorIs(t, svc.Reorder(ctx, []uuid.UUID{a.ID}), ErrInvalidOrder)
	signed, err := svc.SignedList(ctx)
	require.NoError(t, err)
	p, err := Verify(signer.PublicKey(), signed)
	require.NoError(t, err)
	assert.Equal(t, int64(3), p.Version)
	require.Len(t, p.Domains, 2)
	assert.Equal(t, "https://caido.kyq.co", p.Domains[0].APIURL, "en el orden del panel")

	_, err = svc.Update(ctx, b.ID, b.APIURL, b.RealtimeURL, false)
	require.NoError(t, err)
	_, err = svc.Update(ctx, a.ID, a.APIURL, a.RealtimeURL, false)
	assert.ErrorIs(t, err, ErrLastActive, "FR-019: sin ningún dominio activo, no")
	assert.ErrorIs(t, svc.Delete(ctx, a.ID), ErrLastActive)
	require.NoError(t, svc.Delete(ctx, b.ID), "uno inactivo sí se borra")
	assert.ErrorIs(t, svc.Delete(ctx, b.ID), ErrNotFound)

	signed, err = svc.SignedList(ctx)
	require.NoError(t, err)
	p, err = Verify(signer.PublicKey(), signed)
	require.NoError(t, err)
	assert.Equal(t, []Entry{{APIURL: "https://api.kyq.co", RealtimeURL: "wss://rt.kyq.co/connection/websocket"}}, p.Domains)
	assert.Equal(t, int64(5), p.Version)

	_, err = (&Service{Store: st}).SignedList(ctx)
	assert.ErrorIs(t, err, ErrNotConfigured)
}
