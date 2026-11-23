package pgtest

import (
	"context"
	"fmt"
	"testing"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// InTenant runs work in a transaction of pool bound to tenant (`set_config('app.tenant_id', tenant, true)`, as
// persistence.Transactions binds it) and commits it when work succeeds. Tests use it for rows and reads the use cases
// do not offer; the pool is finance_app's (or finance_migrator's for fixtures), never a superuser's.
func InTenant(ctx context.Context, pool *pgxpool.Pool, tenant string, work func(pgx.Tx) error) error {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()
	if _, err := tx.Exec(ctx, "select set_config('app.tenant_id', $1, true)", tenant); err != nil {
		return fmt.Errorf("bind tenant: %w", err)
	}
	if err := work(tx); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

// Exec runs sql with args bound to tenant; the test fails on an error.
func Exec(t testing.TB, pool *pgxpool.Pool, tenant, sql string, args ...any) {
	t.Helper()
	err := InTenant(context.Background(), pool, tenant, func(tx pgx.Tx) error {
		_, err := tx.Exec(context.Background(), sql, args...)
		return err
	})
	if err != nil {
		t.Fatal(err)
	}
}

// Rows reads the one-column rows of sql bound to tenant; the test fails on an error.
func Rows[T any](t testing.TB, pool *pgxpool.Pool, tenant, sql string, args ...any) []T {
	t.Helper()
	var out []T
	err := InTenant(context.Background(), pool, tenant, func(tx pgx.Tx) error {
		rows, err := tx.Query(context.Background(), sql, args...)
		if err != nil {
			return err
		}
		out, err = pgx.CollectRows(rows, pgx.RowTo[T])
		return err
	})
	if err != nil {
		t.Fatal(err)
	}
	return out
}

// Value reads the one value of sql bound to tenant; the test fails on an error or when there is no row.
func Value[T any](t testing.TB, pool *pgxpool.Pool, tenant, sql string, args ...any) T {
	t.Helper()
	var value T
	err := InTenant(context.Background(), pool, tenant, func(tx pgx.Tx) error {
		return tx.QueryRow(context.Background(), sql, args...).Scan(&value)
	})
	if err != nil {
		t.Fatal(err)
	}
	return value
}
