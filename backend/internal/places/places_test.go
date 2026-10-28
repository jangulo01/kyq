package places

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// US5 (FR-014): sugerencias de la ciudad desde 3 caracteres, con caché y sin datos de fuera.
func TestSearch(t *testing.T) {
	var calls atomic.Int32
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		calls.Add(1)
		assert.Equal(t, "/api", r.URL.Path)
		assert.Equal(t, "es", r.URL.Query().Get("lang"))
		assert.NotEmpty(t, r.URL.Query().Get("bbox"))
		_ = json.NewEncoder(w).Encode(map[string]any{"features": []any{
			map[string]any{"geometry": map[string]any{"coordinates": []float64{-74.053, 4.666}},
				"properties": map[string]any{"name": "Centro Comercial Andino", "street": "Carrera 11", "housenumber": "82-71", "city": "Bogotá"}},
			map[string]any{"geometry": map[string]any{"coordinates": []float64{-74.06, 4.65}},
				"properties": map[string]any{"street": "Calle 72", "housenumber": "10-07", "district": "Chapinero", "city": "Bogotá"}},
			map[string]any{"geometry": map[string]any{"coordinates": []float64{-75.56, 6.25}},
				"properties": map[string]any{"name": "Andino Medellín", "city": "Medellín"}},
		}})
	}))
	t.Cleanup(srv.Close)
	s := &Service{URL: srv.URL, BBox: Bogota}
	ctx := context.Background()

	_, err := s.Search(ctx, " an ")
	assert.ErrorIs(t, err, ErrQueryTooShort)
	got, err := s.Search(ctx, "Andino")
	require.NoError(t, err)
	require.Len(t, got, 2, "fuera de la ciudad no se sugiere")
	assert.Equal(t, Place{Label: "Centro Comercial Andino", Detail: "Carrera 11 82-71, Bogotá", Lat: 4.666, Lng: -74.053}, got[0])
	assert.Equal(t, "Calle 72 10-07", got[1].Label)
	assert.Equal(t, "Chapinero, Bogotá", got[1].Detail)

	_, err = s.Search(ctx, "andino")
	require.NoError(t, err)
	assert.Equal(t, int32(1), calls.Load(), "caché de 10 minutos")

	_, err = (&Service{BBox: Bogota}).Search(ctx, "Andino")
	assert.ErrorIs(t, err, ErrUnavailable)
	_, err = (&Service{URL: "http://127.0.0.1:1", BBox: Bogota}).Search(ctx, "Andino")
	assert.ErrorIs(t, err, ErrUnavailable)
}

func TestParseBBox(t *testing.T) {
	b, err := ParseBBox("")
	require.NoError(t, err)
	assert.Equal(t, Bogota, b)
	b, err = ParseBBox("-75.7, 6.1, -75.4, 6.4")
	require.NoError(t, err)
	assert.True(t, b.Contains(6.25, -75.56))
	for _, bad := range []string{"1,2,3", "a,b,c,d", "-74,5,-75,4"} {
		_, err := ParseBBox(bad)
		assert.Error(t, err, bad)
	}
}
