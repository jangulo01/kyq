// Package control implements the admin control tower (spec 007, US1): drivers ONLINE, active
// trips and recent requests aggregated in H3 hexagons, and the live "tower.changed" notice.
package control

import (
	"sort"
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/hexgrid"
)

// Parámetros de la instantánea (research R2).
const (
	RequestWindow     = time.Hour
	StaleAfter        = 2 * time.Minute
	HighPressureRatio = 2.0
)

// Niveles de presión de un hexágono (FR-002).
const (
	LevelNone     = "none"
	LevelBalanced = "balanced"
	LevelHigh     = "high"
	LevelNoSupply = "no_supply"
)

// Presencias que aparecen en la torre.
const (
	PresenceFree = "free"
	PresenceBusy = "busy"
)

// DriverInput is a driver ONLINE with its last known position (nil when it never sent one).
type DriverInput struct {
	ID         uuid.UUID
	Name       string
	Presence   string // free | busy
	Position   *hexgrid.Point
	LocationAt time.Time
}

// TripInput is an active trip (ACCEPTED, ARRIVED, IN_PROGRESS).
type TripInput struct {
	DriverID uuid.UUID
	Pickup   hexgrid.Point
}

// RequestInput is a trip created inside the window.
type RequestInput struct {
	Pickup   hexgrid.Point
	Unserved bool // oferta vencida, rechazada o negociación fallida
}

// Point is a position in the API (contracts: Point).
type Point struct {
	Lat float64 `json:"lat"`
	Lng float64 `json:"lng"`
}

// Totals are the tower totals (contracts: TowerTotals).
type Totals struct {
	Online           int `json:"online"`
	Free             int `json:"free"`
	Busy             int `json:"busy"`
	WithoutLocation  int `json:"without_location"`
	Stale            int `json:"stale"`
	ActiveTrips      int `json:"active_trips"`
	Requests         int `json:"requests"`
	UnservedRequests int `json:"unserved_requests"`
}

// Cell is one hexagon with activity (contracts: TowerCell).
type Cell struct {
	Cell             string   `json:"cell"`
	Center           Point    `json:"center"`
	Boundary         []Point  `json:"boundary"`
	FreeDrivers      int      `json:"free_drivers"`
	BusyDrivers      int      `json:"busy_drivers"`
	ActiveTrips      int      `json:"active_trips"`
	Requests         int      `json:"requests"`
	UnservedRequests int      `json:"unserved_requests"`
	Pressure         *float64 `json:"pressure"`
	Level            string   `json:"level"`
}

// Driver is a driver drawn on the map (contracts: TowerDriver).
type Driver struct {
	DriverID    uuid.UUID `json:"driver_id"`
	DisplayName string    `json:"display_name"`
	Presence    string    `json:"presence"`
	Lat         float64   `json:"lat"`
	Lng         float64   `json:"lng"`
	LocationAt  time.Time `json:"location_at"`
	Stale       bool      `json:"stale"`
	Cell        string    `json:"cell"`
}

// Snapshot is GET /v1/admin/tower (contracts: TowerSnapshot).
type Snapshot struct {
	GeneratedAt       time.Time `json:"generated_at"`
	Resolution        int       `json:"resolution"`
	WindowMinutes     int       `json:"window_minutes"`
	StaleAfterSeconds int       `json:"stale_after_seconds"`
	Totals            Totals    `json:"totals"`
	Cells             []Cell    `json:"cells"`
	Drivers           []Driver  `json:"drivers"`
}

// Level returns the pressure level and ratio of a hexagon from its requests and free drivers.
func Level(requests, free int) (string, *float64) {
	var pressure *float64
	if free > 0 {
		p := float64(requests) / float64(free)
		pressure = &p
	}
	switch {
	case requests == 0:
		return LevelNone, pressure
	case free == 0:
		return LevelNoSupply, pressure
	case *pressure >= HighPressureRatio:
		return LevelHigh, pressure
	default:
		return LevelBalanced, pressure
	}
}

var levelRank = map[string]int{LevelNoSupply: 0, LevelHigh: 1, LevelBalanced: 2, LevelNone: 3}

// Aggregate builds the snapshot at resolution res. Positions outside the valid range are
// ignored (they cannot be indexed).
func Aggregate(res int, now time.Time, drivers []DriverInput, trips []TripInput, requests []RequestInput) Snapshot {
	snap := Snapshot{
		GeneratedAt: now, Resolution: res,
		WindowMinutes: int(RequestWindow / time.Minute), StaleAfterSeconds: int(StaleAfter / time.Second),
		Cells: []Cell{}, Drivers: []Driver{},
	}
	cells := map[hexgrid.Cell]*Cell{}
	cellOf := func(p hexgrid.Point) (hexgrid.Cell, *Cell, bool) {
		c, err := hexgrid.CellAt(p, res)
		if err != nil {
			return 0, nil, false
		}
		if existing, ok := cells[c]; ok {
			return c, existing, true
		}
		center := c.Center()
		out := &Cell{Cell: c.String(), Center: Point{center.Lat, center.Lng}}
		for _, v := range c.Boundary() {
			out.Boundary = append(out.Boundary, Point{v.Lat, v.Lng})
		}
		cells[c] = out
		return c, out, true
	}

	driverPos := map[uuid.UUID]hexgrid.Point{}
	for _, d := range drivers {
		snap.Totals.Online++
		if d.Presence == PresenceBusy {
			snap.Totals.Busy++
		} else {
			snap.Totals.Free++
		}
		if d.Position == nil {
			snap.Totals.WithoutLocation++
			continue
		}
		c, cell, ok := cellOf(*d.Position)
		if !ok {
			snap.Totals.WithoutLocation++
			continue
		}
		driverPos[d.ID] = *d.Position
		stale := now.Sub(d.LocationAt) > StaleAfter
		if stale {
			snap.Totals.Stale++
		}
		if d.Presence == PresenceBusy {
			cell.BusyDrivers++
		} else {
			cell.FreeDrivers++
		}
		snap.Drivers = append(snap.Drivers, Driver{
			DriverID: d.ID, DisplayName: d.Name, Presence: d.Presence, Lat: d.Position.Lat, Lng: d.Position.Lng,
			LocationAt: d.LocationAt, Stale: stale, Cell: c.String(),
		})
	}
	for _, t := range trips {
		snap.Totals.ActiveTrips++
		// Donde está ahora el conductor; si no se conoce, en la recogida.
		at, ok := driverPos[t.DriverID]
		if !ok {
			at = t.Pickup
		}
		if _, cell, ok := cellOf(at); ok {
			cell.ActiveTrips++
		}
	}
	for _, r := range requests {
		snap.Totals.Requests++
		if r.Unserved {
			snap.Totals.UnservedRequests++
		}
		if _, cell, ok := cellOf(r.Pickup); ok {
			cell.Requests++
			if r.Unserved {
				cell.UnservedRequests++
			}
		}
	}
	for _, c := range cells {
		c.Level, c.Pressure = Level(c.Requests, c.FreeDrivers)
		snap.Cells = append(snap.Cells, *c)
	}
	sort.Slice(snap.Cells, func(i, j int) bool {
		a, b := snap.Cells[i], snap.Cells[j]
		if levelRank[a.Level] != levelRank[b.Level] {
			return levelRank[a.Level] < levelRank[b.Level]
		}
		if a.Requests != b.Requests {
			return a.Requests > b.Requests
		}
		return a.Cell < b.Cell
	})
	return snap
}
