package control

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/hexgrid"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
)

var (
	now        = time.Date(2026, 10, 27, 12, 0, 0, 0, time.UTC)
	centro     = hexgrid.Point{Lat: 4.6097, Lng: -74.0817}
	chapinero  = hexgrid.Point{Lat: 4.6500, Lng: -74.0600}
	usaquen    = hexgrid.Point{Lat: 4.7000, Lng: -74.0300}
	outOfRange = hexgrid.Point{Lat: 95, Lng: 0}
)

func cellOf(t *testing.T, p hexgrid.Point, res int) string {
	t.Helper()
	c, err := hexgrid.CellAt(p, res)
	require.NoError(t, err)
	return c.String()
}

func byCell(s Snapshot) map[string]Cell {
	out := map[string]Cell{}
	for _, c := range s.Cells {
		out[c.Cell] = c
	}
	return out
}

func TestLevel(t *testing.T) {
	cases := []struct {
		requests, free int
		level          string
		pressure       *float64
	}{
		{0, 0, LevelNone, nil},
		{0, 3, LevelNone, new(0.0)},
		{4, 0, LevelNoSupply, nil},
		{1, 1, LevelBalanced, new(1.0)},
		{3, 2, LevelBalanced, new(1.5)},
		{4, 2, LevelHigh, new(2.0)},
	}
	for _, c := range cases {
		level, pressure := Level(c.requests, c.free)
		assert.Equal(t, c.level, level, "%d solicitudes, %d libres", c.requests, c.free)
		assert.Equal(t, c.pressure, pressure, "%d solicitudes, %d libres", c.requests, c.free)
	}
}

// FR-001–FR-003: conductores por su posición, viajes activos donde está su conductor (o en la
// recogida si no se conoce), solicitudes por recogida, totales y orden por presión.
func TestAggregate(t *testing.T) {
	a, b, c, d, e := uuid.New(), uuid.New(), uuid.New(), uuid.New(), uuid.New()
	drivers := []DriverInput{
		{ID: a, Name: "Ana", Presence: PresenceFree, Position: &centro, LocationAt: now.Add(-10 * time.Second)},
		{ID: b, Name: "Beto", Presence: PresenceBusy, Position: &chapinero, LocationAt: now.Add(-5 * time.Minute)},
		{ID: c, Name: "Caro", Presence: PresenceFree}, // ONLINE sin ubicación aún
		{ID: d, Name: "Dani", Presence: PresenceFree, Position: &centro, LocationAt: now},
		{ID: e, Name: "Eva", Presence: PresenceFree, Position: &outOfRange, LocationAt: now},
	}
	trips := []TripInput{
		{DriverID: b, Pickup: usaquen}, // en la posición de Beto
		{DriverID: c, Pickup: usaquen}, // conductor sin posición: en la recogida
	}
	requests := []RequestInput{
		{Pickup: usaquen}, {Pickup: usaquen, Unserved: true}, {Pickup: usaquen, Unserved: true},
		{Pickup: centro},
	}
	s := Aggregate(8, now, drivers, trips, requests)

	assert.Equal(t, Totals{
		Online: 5, Free: 4, Busy: 1, WithoutLocation: 2, Stale: 1, ActiveTrips: 2, Requests: 4, UnservedRequests: 2,
	}, s.Totals)
	assert.Equal(t, 8, s.Resolution)
	assert.Equal(t, 60, s.WindowMinutes)
	assert.Equal(t, 120, s.StaleAfterSeconds)

	cells := byCell(s)
	require.Len(t, cells, 3)
	cCentro := cells[cellOf(t, centro, 8)]
	assert.Equal(t, 2, cCentro.FreeDrivers)
	assert.Equal(t, 1, cCentro.Requests)
	assert.Equal(t, LevelBalanced, cCentro.Level)
	require.NotNil(t, cCentro.Pressure)
	assert.InDelta(t, 0.5, *cCentro.Pressure, 1e-9)

	cChap := cells[cellOf(t, chapinero, 8)]
	assert.Equal(t, 1, cChap.BusyDrivers)
	assert.Equal(t, 1, cChap.ActiveTrips, "el viaje activo va donde está su conductor")
	assert.Equal(t, LevelNone, cChap.Level)

	cUsa := cells[cellOf(t, usaquen, 8)]
	assert.Equal(t, 1, cUsa.ActiveTrips, "sin posición del conductor: en la recogida")
	assert.Equal(t, 3, cUsa.Requests)
	assert.Equal(t, 2, cUsa.UnservedRequests)
	assert.Equal(t, LevelNoSupply, cUsa.Level)
	assert.Nil(t, cUsa.Pressure)

	assert.Equal(t, cUsa.Cell, s.Cells[0].Cell, "sin oferta encabeza la lista")
	assert.Equal(t, LevelNone, s.Cells[2].Level)

	require.Len(t, s.Drivers, 3, "solo se dibujan los que tienen una posición válida")
	for _, dr := range s.Drivers {
		assert.Equal(t, dr.DriverID == b, dr.Stale, dr.DisplayName)
	}
	for _, cell := range s.Cells {
		assert.Len(t, cell.Boundary, 6, "hexágono")
		assert.NotZero(t, cell.Center.Lat)
	}
}

func TestAggregateResolutionChangesCellsNotTotals(t *testing.T) {
	drivers := []DriverInput{
		{ID: uuid.New(), Presence: PresenceFree, Position: &centro, LocationAt: now},
		{ID: uuid.New(), Presence: PresenceFree, Position: &chapinero, LocationAt: now},
	}
	fine := Aggregate(9, now, drivers, nil, nil)
	coarse := Aggregate(6, now, drivers, nil, nil)
	assert.Equal(t, fine.Totals, coarse.Totals)
	for _, s := range []Snapshot{fine, coarse} {
		want := map[string]bool{cellOf(t, centro, s.Resolution): true, cellOf(t, chapinero, s.Resolution): true}
		assert.Len(t, s.Cells, len(want))
		for _, c := range s.Cells {
			assert.True(t, want[c.Cell])
			parsed, err := hexgrid.ParseCell(c.Cell)
			require.NoError(t, err)
			assert.Equal(t, s.Resolution, parsed.Resolution())
		}
	}
}

type fakeSource struct {
	fp  store.TowerFingerprintRow
	err error
}

func (f *fakeSource) TowerFingerprint(context.Context, time.Time) (store.TowerFingerprintRow, error) {
	return f.fp, f.err
}

type recorder struct {
	mu     sync.Mutex
	events []string
	data   []any
}

func (r *recorder) Publish(_ context.Context, channel string, ev realtime.Event) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.events = append(r.events, channel+" "+ev.Type)
	r.data = append(r.data, ev.Data)
	return nil
}

// FR-005/FR-006: un aviso sin datos solo cuando la huella cambia.
func TestNotifierPublishesOnlyOnChange(t *testing.T) {
	src := &fakeSource{fp: store.TowerFingerprintRow{Online: 2, LastLocationAt: now}}
	pub := &recorder{}
	n := &Notifier{Source: src, Publisher: pub, Now: func() time.Time { return now }}
	ctx := context.Background()

	assert.False(t, n.Tick(ctx), "la primera vuelta solo registra el estado")
	assert.False(t, n.Tick(ctx), "sin cambios no se avisa")
	src.fp.LastLocationAt = now.Add(time.Second)
	assert.True(t, n.Tick(ctx), "una ubicación nueva avisa")
	assert.False(t, n.Tick(ctx))
	src.fp.OpenTrips = 1
	assert.True(t, n.Tick(ctx), "un viaje nuevo avisa")
	src.err = errors.New("sin base")
	assert.False(t, n.Tick(ctx), "un error no avisa")

	assert.Equal(t, []string{"admin:tower tower.changed", "admin:tower tower.changed"}, pub.events)
	for _, d := range pub.data {
		assert.Empty(t, d, "el aviso no lleva datos personales")
	}
}
