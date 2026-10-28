package affiliations

import (
	"context"
	"sort"
	"sync"
	"time"

	"github.com/google/uuid"
)

type link struct {
	passenger, driver uuid.UUID
	created           time.Time
	removed           bool
}

// MemRepo is an in-memory Repo for tests.
type MemRepo struct {
	mu      sync.Mutex
	drivers map[uuid.UUID]ChosenDriver
	tokens  map[string]uuid.UUID
	names   map[uuid.UUID]string
	links   map[[2]uuid.UUID]*link
}

// NewMemRepo returns an empty repository.
func NewMemRepo() *MemRepo {
	return &MemRepo{
		drivers: map[uuid.UUID]ChosenDriver{},
		tokens:  map[string]uuid.UUID{},
		names:   map[uuid.UUID]string{},
		links:   map[[2]uuid.UUID]*link{},
	}
}

// AddDriver registers a driver reachable by qrToken.
func (m *MemRepo) AddDriver(d ChosenDriver, qrToken string) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.drivers[d.DriverID] = d
	m.tokens[qrToken] = d.DriverID
}

// SetPassengerName sets the name shown in driver portfolios.
func (m *MemRepo) SetPassengerName(id uuid.UUID, name string) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.names[id] = name
}

func (m *MemRepo) DriverByQRToken(_ context.Context, token string) (ChosenDriver, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	id, ok := m.tokens[token]
	if !ok {
		return ChosenDriver{}, ErrDriverNotFound
	}
	return m.drivers[id], nil
}

func (m *MemRepo) State(_ context.Context, p, d uuid.UUID) (AffiliationState, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	l, ok := m.links[[2]uuid.UUID{p, d}]
	switch {
	case !ok:
		return StateNone, nil
	case l.removed:
		return StateRemoved, nil
	default:
		return StateActive, nil
	}
}

func (m *MemRepo) Insert(_ context.Context, p, d uuid.UUID) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.links[[2]uuid.UUID{p, d}] = &link{passenger: p, driver: d, created: time.Now()}
	return nil
}

func (m *MemRepo) Reactivate(_ context.Context, p, d uuid.UUID) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if l, ok := m.links[[2]uuid.UUID{p, d}]; ok {
		l.removed, l.created = false, time.Now()
	}
	return nil
}

func (m *MemRepo) Remove(_ context.Context, p, d uuid.UUID) (bool, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	l, ok := m.links[[2]uuid.UUID{p, d}]
	if !ok || l.removed {
		return false, nil
	}
	l.removed = true
	return true, nil
}

func (m *MemRepo) ChosenDrivers(_ context.Context, p uuid.UUID) ([]ChosenDriver, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	out := []ChosenDriver{}
	for _, l := range m.links {
		if l.passenger == p && !l.removed {
			out = append(out, m.drivers[l.driver])
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].DisplayName < out[j].DisplayName })
	return out, nil
}

func (m *MemRepo) Clients(_ context.Context, d uuid.UUID) ([]Client, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	out := []Client{}
	for _, l := range m.links {
		if l.driver == d && !l.removed {
			out = append(out, Client{PassengerID: l.passenger, DisplayName: m.names[l.passenger], AffiliatedAt: l.created})
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].AffiliatedAt.After(out[j].AffiliatedAt) })
	return out, nil
}
