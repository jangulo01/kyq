package store

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Store wraps the connection pool and the sqlc queries.
type Store struct {
	Pool *pgxpool.Pool
	*Queries
}

// Open connects to PostgreSQL and verifies the connection.
func Open(ctx context.Context, databaseURL string) (*Store, error) {
	pool, err := pgxpool.New(ctx, databaseURL)
	if err != nil {
		return nil, fmt.Errorf("open pool: %w", err)
	}
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("ping database: %w", err)
	}
	return Wrap(pool), nil
}

// Wrap wraps an existing pool.
func Wrap(pool *pgxpool.Pool) *Store {
	return &Store{Pool: pool, Queries: New(pool)}
}

// Close releases the pool.
func (s *Store) Close() { s.Pool.Close() }

// WithTx runs fn inside a transaction, committing on success and rolling back on error.
func (s *Store) WithTx(ctx context.Context, fn func(q *Queries) error) error {
	tx, err := s.Pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()
	if err := fn(s.Queries.WithTx(tx)); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

// IsNotFound reports whether err means no row matched.
func IsNotFound(err error) bool { return errors.Is(err, pgx.ErrNoRows) }
