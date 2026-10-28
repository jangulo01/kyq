package auth

import (
	"context"
	"encoding/hex"
	"sync"

	"github.com/google/uuid"
)

// MemRepo is an in-memory Repo for tests.
type MemRepo struct {
	mu     sync.Mutex
	users  map[uuid.UUID]User
	tokens map[string]RefreshToken
}

// NewMemRepo returns an empty repository.
func NewMemRepo() *MemRepo {
	return &MemRepo{users: map[uuid.UUID]User{}, tokens: map[string]RefreshToken{}}
}

func (m *MemRepo) GetUserByPhone(_ context.Context, phone string) (User, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	for _, u := range m.users {
		if u.Phone == phone {
			return u, nil
		}
	}
	return User{}, ErrNotFound
}

func (m *MemRepo) GetUserByID(_ context.Context, id uuid.UUID) (User, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	u, ok := m.users[id]
	if !ok {
		return User{}, ErrNotFound
	}
	return u, nil
}

func (m *MemRepo) CreateUser(_ context.Context, u User) (User, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.users[u.ID] = u
	return u, nil
}

func (m *MemRepo) CreateDriver(ctx context.Context, u User) (User, error) {
	u.Role = RoleDriver
	return m.CreateUser(ctx, u)
}

func (m *MemRepo) InsertRefreshToken(_ context.Context, t RefreshToken) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.tokens[hex.EncodeToString(t.Hash)] = t
	return nil
}

func (m *MemRepo) GetRefreshToken(_ context.Context, hash []byte) (RefreshToken, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	t, ok := m.tokens[hex.EncodeToString(hash)]
	if !ok {
		return RefreshToken{}, ErrNotFound
	}
	return t, nil
}

func (m *MemRepo) MarkRotated(_ context.Context, id uuid.UUID) (bool, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	for k, t := range m.tokens {
		if t.ID == id {
			if t.Rotated {
				return false, nil
			}
			t.Rotated = true
			m.tokens[k] = t
			return true, nil
		}
	}
	return false, nil
}

func (m *MemRepo) RevokeAll(_ context.Context, userID uuid.UUID) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	for k, t := range m.tokens {
		if t.UserID == userID {
			t.Rotated = true
			m.tokens[k] = t
		}
	}
	return nil
}
