package hexgrid

import (
	"encoding/json"
	"math"
	"os"
	"testing"

	"github.com/stretchr/testify/require"
)

// Valores de referencia generados con h3-js 4.4.0 (biblioteca oficial compilada a JS): ciudades
// de Colombia y Perú, 120 puntos pseudoaleatorios en todo el globo (resoluciones 0–11) y los
// pentágonos de las resoluciones 0, 2, 5 y 8.
type fixture struct {
	Lat, Lng float64
	Res      int
	Cell     string
	Center   [2]float64
	Boundary [][2]float64
}

func loadFixtures(t *testing.T) []fixture {
	t.Helper()
	raw, err := os.ReadFile("testdata/h3js_fixtures.json")
	require.NoError(t, err)
	var fx []fixture
	require.NoError(t, json.Unmarshal(raw, &fx))
	require.Greater(t, len(fx), 200)
	return fx
}

const tolDeg = 1e-7 // ~1 cm; las referencias tienen 9 decimales

func near(a, b float64) bool {
	d := math.Abs(a - b)
	return d < tolDeg || math.Abs(d-360) < tolDeg // antimeridiano
}

func TestCellAtMatchesReference(t *testing.T) {
	for _, f := range loadFixtures(t) {
		c, err := CellAt(Point{f.Lat, f.Lng}, f.Res)
		require.NoError(t, err)
		require.Equal(t, f.Cell, c.String(), "celda de (%v, %v) res %d", f.Lat, f.Lng, f.Res)
		require.Equal(t, f.Res, c.Resolution())
	}
}

func TestCenterAndBoundaryMatchReference(t *testing.T) {
	pentagons := 0
	for _, f := range loadFixtures(t) {
		c, err := ParseCell(f.Cell)
		require.NoError(t, err)
		center := c.Center()
		require.True(t, near(center.Lat, f.Center[0]) && near(center.Lng, f.Center[1]),
			"centro de %s: %v, referencia %v", f.Cell, center, f.Center)
		b := c.Boundary()
		require.Len(t, b, len(f.Boundary), "vértices de %s", f.Cell)
		for i, p := range b {
			require.True(t, near(p.Lat, f.Boundary[i][0]) && near(p.Lng, f.Boundary[i][1]),
				"vértice %d de %s: %v, referencia %v", i, f.Cell, p, f.Boundary[i])
		}
		if isPentagon(uint64(c)) {
			pentagons++
		}
	}
	require.Positive(t, pentagons)
}

func TestInvalidInput(t *testing.T) {
	_, err := CellAt(Point{91, 0}, 8)
	require.ErrorIs(t, err, ErrInvalid)
	_, err = CellAt(Point{4.7, -74}, 16)
	require.ErrorIs(t, err, ErrInvalid)
	_, err = ParseCell("no-hex")
	require.ErrorIs(t, err, ErrInvalid)
	_, err = ParseCell("0")
	require.ErrorIs(t, err, ErrInvalid)
}
