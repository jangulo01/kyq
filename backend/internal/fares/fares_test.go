package fares

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Tabla de ejemplo en COP con unidades mínimas en centavos y redondeo a 100 pesos.
var bogota = Table{
	Currency: "COP", BaseMinor: 400_000, PerKmMinor: 120_000, PerMinuteMinor: 30_000,
	MinimumMinor: 700_000, RoundingMinor: 10_000,
}

// RN-KYQ-013: tarifa sugerida por distancia y tiempo con la tabla de la ciudad.
func TestSuggestFormula(t *testing.T) {
	// 4 000 + 1 200 × 5,2 km + 300 × 15 min = 4 000 + 6 240 + 4 500 = 14 740 pesos → 14 700.
	assert.Equal(t, int64(1_470_000), bogota.Suggest(5200, 900))
}

func TestSuggestAppliesMinimum(t *testing.T) {
	assert.Equal(t, int64(700_000), bogota.Suggest(300, 60))
}

func TestSuggestRoundsHalfUp(t *testing.T) {
	tb := Table{Currency: "COP", BaseMinor: 5_000, RoundingMinor: 10_000}
	assert.Equal(t, int64(10_000), tb.Suggest(0, 0))
	tb.BaseMinor = 4_999
	assert.Equal(t, int64(0), tb.Suggest(0, 0))
	tb.RoundingMinor = 1
	assert.Equal(t, int64(4_999), tb.Suggest(0, 0))
}

func TestValidate(t *testing.T) {
	assert.NoError(t, bogota.Validate())
	bad := bogota
	bad.Currency = "PESOS"
	assert.Error(t, bad.Validate())
	bad = bogota
	bad.PerKmMinor = -1
	assert.Error(t, bad.Validate())
	bad = bogota
	bad.RoundingMinor = 0
	assert.Error(t, bad.Validate())
}

func TestOSRMRoute(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "/route/v1/driving/-74.080000,4.600000;-74.050000,4.650000", r.URL.Path)
		_, _ = w.Write([]byte(`{"code":"Ok","routes":[{"distance":5199.6,"duration":899.7}]}`))
	}))
	defer srv.Close()

	r, err := OSRM{BaseURL: srv.URL}.Route(context.Background(), 4.60, -74.08, 4.65, -74.05)
	require.NoError(t, err)
	assert.Equal(t, Route{DistanceM: 5200, DurationS: 900}, r)
}

func TestOSRMNoRoute(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte(`{"code":"NoRoute","routes":[]}`))
	}))
	defer srv.Close()
	_, err := OSRM{BaseURL: srv.URL}.Route(context.Background(), 0, 0, 1, 1)
	assert.ErrorIs(t, err, ErrNoRoute)
}
