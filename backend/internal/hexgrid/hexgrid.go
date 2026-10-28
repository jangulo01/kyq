// Package hexgrid indexa posiciones en celdas hexagonales H3 sin cgo (constitución II).
//
// El índice (latitud/longitud → celda) lo calcula github.com/ziprecruiter/h3-go, una
// reimplementación en Go puro de H3. El centro y el contorno de cada celda, que esa biblioteca no
// expone, se portan de la biblioteca oficial de Uber (geometry.go). Las pruebas comparan ambos
// con valores de referencia generados con h3-js (testdata/h3js_fixtures.json). Ver research.md
// (R1) de specs/007-control-tower-crm.
package hexgrid

import (
	"errors"
	"fmt"
	"math"
	"strconv"

	"github.com/ziprecruiter/h3-go/pkg/h3"
)

// Resoluciones que admite la torre de control: de barrio (6, ~36 km²) a manzanas (9, ~0,1 km²).
const (
	MinResolution     = 6
	MaxResolution     = 9
	DefaultResolution = 8
)

// ErrInvalid significa coordenadas, resolución o celda no válidas.
var ErrInvalid = errors.New("hexgrid: valor no válido")

// Point es una posición en grados.
type Point struct {
	Lat float64
	Lng float64
}

// Cell es un índice de celda H3 (modo celda).
type Cell uint64

// String devuelve el índice en hexadecimal, como lo escriben todas las bibliotecas H3.
func (c Cell) String() string { return strconv.FormatUint(uint64(c), 16) }

// Resolution devuelve la resolución de la celda.
func (c Cell) Resolution() int { return cellRes(uint64(c)) }

// CellAt devuelve la celda de resolución res que contiene la posición.
func CellAt(p Point, res int) (Cell, error) {
	if res < 0 || res > maxH3Res || math.IsNaN(p.Lat) || math.IsNaN(p.Lng) ||
		p.Lat < -90 || p.Lat > 90 || p.Lng < -180 || p.Lng > 180 {
		return 0, ErrInvalid
	}
	c, err := h3.NewCellFromLatLng(h3.NewLatLng(p.Lat, p.Lng), res)
	if err != nil {
		return 0, fmt.Errorf("%w: %v", ErrInvalid, err)
	}
	return Cell(c), nil
}

// ParseCell lee un índice hexadecimal y comprueba que sea una celda válida.
func ParseCell(s string) (Cell, error) {
	v, err := strconv.ParseUint(s, 16, 64)
	if err != nil || !h3.Cell(v).Valid() {
		return 0, ErrInvalid
	}
	return Cell(v), nil
}

func toPoint(g latLng) Point {
	return Point{Lat: g.lat * 180 / math.Pi, Lng: g.lng * 180 / math.Pi}
}

// Center devuelve el centro de la celda.
func (c Cell) Center() Point {
	f := toFaceIJK(uint64(c))
	return toPoint(hex2dToGeo(f.coord.hex2d(), f.face, c.Resolution(), false))
}

// Boundary devuelve los vértices del contorno en sentido antihorario (6 en un hexágono, 5 en un
// pentágono, alguno más si un lado cruza una arista del icosaedro). El polígono no se cierra.
func (c Cell) Boundary() []Point {
	h := uint64(c)
	f := toFaceIJK(h)
	var verts []latLng
	if isPentagon(h) {
		verts = pentBoundary(f, c.Resolution())
	} else {
		verts = hexBoundary(f, c.Resolution())
	}
	out := make([]Point, len(verts))
	for i, v := range verts {
		out[i] = toPoint(v)
	}
	return out
}
