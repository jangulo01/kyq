package storage

import (
	"context"
	"net/url"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Firmar no contacta al servidor y usa el host público (el móvil no ve la red interna).
func TestS3SignsForPublicEndpointWithoutNetwork(t *testing.T) {
	s, err := NewS3(S3Options{
		Endpoint: "http://minio.invalid:9000", PublicEndpoint: "http://192.168.1.66:9000",
		AccessKey: "access", SecretKey: "secret-secret", Bucket: "kyq-kyc",
	})
	require.NoError(t, err)
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	put, err := s.PresignPut(ctx, "kyc/d/doc/front.jpg", "image/jpeg", 10*time.Minute)
	require.NoError(t, err)
	u, err := url.Parse(put)
	require.NoError(t, err)
	assert.Equal(t, "192.168.1.66:9000", u.Host)
	assert.Equal(t, "/kyq-kyc/kyc/d/doc/front.jpg", u.Path)
	assert.Equal(t, "600", u.Query().Get("X-Amz-Expires"))
	assert.Contains(t, u.Query().Get("X-Amz-SignedHeaders"), "content-type", "el tipo de contenido queda firmado")

	get, err := s.PresignGet(ctx, "kyc/d/doc/front.jpg", 5*time.Minute)
	require.NoError(t, err)
	gu, err := url.Parse(get)
	require.NoError(t, err)
	assert.Equal(t, "300", gu.Query().Get("X-Amz-Expires"))

	_, err = NewS3(S3Options{Endpoint: "minio:9000"})
	assert.Error(t, err, "el endpoint exige esquema")
}

func TestMemoryObjects(t *testing.T) {
	m := NewMemory()
	ctx := context.Background()
	_, err := m.Stat(ctx, "k")
	assert.ErrorIs(t, err, ErrNotFound)
	m.Put("k", []byte("jpeg"), "image/jpeg")
	info, err := m.Stat(ctx, "k")
	require.NoError(t, err)
	assert.Equal(t, ObjectInfo{Size: 4, ContentType: "image/jpeg"}, info)
	require.NoError(t, m.Remove(ctx, "k"))
	assert.False(t, m.Has("k"))
}
