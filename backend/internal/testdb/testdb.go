// Package testdb gives integration tests an isolated, migrated PostgreSQL schema.
package testdb

import (
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"net/url"
	"os"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jackc/pgx/v5/stdlib"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/migrations"
	"github.com/pressly/goose/v3"
)

// New returns a store on a fresh schema migrated to the latest version. It skips the test when
// KYQ_TEST_DATABASE_URL is not set. The schema is dropped when the test ends.
func New(t *testing.T) *store.Store {
	t.Helper()
	base := os.Getenv("KYQ_TEST_DATABASE_URL")
	if base == "" {
		t.Skip("KYQ_TEST_DATABASE_URL no definido; prueba de integración omitida")
	}
	ctx := context.Background()

	var b [6]byte
	_, _ = rand.Read(b[:])
	schema := "test_" + hex.EncodeToString(b[:])

	admin, err := pgxpool.New(ctx, base)
	if err != nil {
		t.Fatalf("connect: %v", err)
	}
	t.Cleanup(admin.Close)
	if _, err := admin.Exec(ctx, "CREATE SCHEMA "+schema); err != nil {
		t.Fatalf("create schema: %v", err)
	}
	t.Cleanup(func() { _, _ = admin.Exec(context.Background(), "DROP SCHEMA "+schema+" CASCADE") })

	u, err := url.Parse(base)
	if err != nil {
		t.Fatalf("parse url: %v", err)
	}
	q := u.Query()
	q.Set("search_path", schema+",public")
	u.RawQuery = q.Encode()

	pool, err := pgxpool.New(ctx, u.String())
	if err != nil {
		t.Fatalf("connect schema: %v", err)
	}
	t.Cleanup(pool.Close)

	db := stdlib.OpenDBFromPool(pool)
	t.Cleanup(func() { _ = db.Close() })
	if err := migrate(db, schema); err != nil {
		t.Fatalf("migrate: %v", err)
	}
	return store.Wrap(pool)
}

func migrate(db *sql.DB, schema string) error {
	goose.SetBaseFS(migrations.FS)
	goose.SetLogger(goose.NopLogger())
	// Tabla de versiones dentro del esquema de la prueba: si quedara en public, goose vería
	// una base ya migrada y no crearía las tablas en el esquema aislado.
	goose.SetTableName(schema + ".goose_db_version")
	if err := goose.SetDialect("postgres"); err != nil {
		return err
	}
	return goose.Up(db, ".")
}
