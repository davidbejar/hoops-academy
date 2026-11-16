package persistence_test

import (
	"context"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"hoopsacademy.local/finance/internal/domain"
)

// Rows the use cases of WP118 never write (dues: WP119; the replica: the event consumer), inserted as finance_app
// in a transaction bound to their tenant.

func bound(t *testing.T, pool *pgxpool.Pool, tenant domain.TenantID, sql string, args ...any) {
	t.Helper()
	ctx := context.Background()
	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = tx.Rollback(ctx) }()
	if _, err := tx.Exec(ctx, "select set_config('app.tenant_id', $1, true)", tenant.String()); err != nil {
		t.Fatal(err)
	}
	if _, err := tx.Exec(ctx, sql, args...); err != nil {
		t.Fatal(err)
	}
	if err := tx.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func insertDue(t *testing.T, pool *pgxpool.Pool, tenant domain.TenantID, plan domain.FeePlanID) {
	t.Helper()
	bound(t, pool, tenant, `insert into finance.due (tenant_id, id, fee_plan_id, player_id, team_id, period,
		period_start, period_end, amount_minor, plan_amount_minor, status, created_at, updated_at)
		values ($1, $2, $3, $4, $5, '2026-09', '2026-09-01', '2026-09-30', 4500, 4500, 'OPEN', now(), now())`,
		tenant.String(), randomUUID().String(), plan.String(), randomUUID().String(), randomUUID().String())
}

func insertTenantRef(t *testing.T, pool *pgxpool.Pool, tenant domain.TenantID, status string, removed bool) {
	t.Helper()
	bound(t, pool, tenant, `insert into finance.tenant_ref (tenant_id, status, timezone, removed, occurred_at, event_id)
		values ($1, $2, 'Europe/Madrid', $3, $4, $5)`, tenant.String(), status, removed, time.Now(), randomUUID().String())
}

func insertPersonRef(t *testing.T, pool *pgxpool.Pool, tenant domain.TenantID, person domain.UUID, subject string,
	roles []string, active, removed bool) {
	t.Helper()
	bound(t, pool, tenant, `insert into finance.person_ref (tenant_id, id, subject, roles, active, removed, occurred_at,
		event_id) values ($1, $2, $3, $4, $5, $6, $7, $8)`, tenant.String(), person.String(), subject, roles, active,
		removed, time.Now(), randomUUID().String())
}
