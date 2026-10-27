package auth

import (
	"context"

	"github.com/google/uuid"
	"github.com/kyq/backend/internal/store"
)

// PgRepo implements Repo on PostgreSQL.
type PgRepo struct{ q *store.Queries }

// NewPgRepo returns a repository using q.
func NewPgRepo(q *store.Queries) *PgRepo { return &PgRepo{q: q} }

func toUser(u store.User) User {
	return User{ID: u.ID, Phone: u.PhoneE164, Role: string(u.Role), DisplayName: u.DisplayName}
}

func (r *PgRepo) GetUserByPhone(ctx context.Context, phone string) (User, error) {
	u, err := r.q.GetUserByPhone(ctx, phone)
	if store.IsNotFound(err) {
		return User{}, ErrNotFound
	}
	return toUser(u), err
}

func (r *PgRepo) GetUserByID(ctx context.Context, id uuid.UUID) (User, error) {
	u, err := r.q.GetUserByID(ctx, id)
	if store.IsNotFound(err) {
		return User{}, ErrNotFound
	}
	return toUser(u), err
}

func (r *PgRepo) CreateUser(ctx context.Context, u User) (User, error) {
	created, err := r.q.CreateUser(ctx, store.CreateUserParams{
		ID: u.ID, PhoneE164: u.Phone, Role: store.UserRole(u.Role), DisplayName: u.DisplayName,
	})
	return toUser(created), err
}

func (r *PgRepo) InsertRefreshToken(ctx context.Context, t RefreshToken) error {
	return r.q.InsertRefreshToken(ctx, store.InsertRefreshTokenParams{
		ID: t.ID, UserID: t.UserID, TokenHash: t.Hash, ExpiresAt: t.ExpiresAt,
	})
}

func (r *PgRepo) GetRefreshToken(ctx context.Context, hash []byte) (RefreshToken, error) {
	t, err := r.q.GetRefreshTokenByHash(ctx, hash)
	if store.IsNotFound(err) {
		return RefreshToken{}, ErrNotFound
	}
	if err != nil {
		return RefreshToken{}, err
	}
	return RefreshToken{ID: t.ID, UserID: t.UserID, Hash: hash, ExpiresAt: t.ExpiresAt, Rotated: t.RotatedAt.Valid}, nil
}

func (r *PgRepo) MarkRotated(ctx context.Context, id uuid.UUID) (bool, error) {
	n, err := r.q.MarkRefreshTokenRotated(ctx, id)
	return n == 1, err
}

func (r *PgRepo) RevokeAll(ctx context.Context, userID uuid.UUID) error {
	return r.q.RevokeUserRefreshTokens(ctx, userID)
}
