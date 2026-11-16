package persistence

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/domain"
)

// Transactions binds the tenant inside each transaction (ADR-0011): `set_config('app.tenant_id', <id>, true)` is
// transaction-local, so a pooled connection never carries a tenant into the next transaction, and a query outside
// one fails (app.current_tenant() raises 42501).
type Transactions struct{ pool *pgxpool.Pool }

// NewTransactions uses pool (connected as finance_app).
func NewTransactions(pool *pgxpool.Pool) Transactions { return Transactions{pool: pool} }

type txKey struct{}

const bindTenant = "select set_config('app.tenant_id', $1, true)"

// InTenant implements application.Transactions. The nil tenant is never bound.
func (t Transactions) InTenant(ctx context.Context, tenant domain.TenantID, work func(ctx context.Context) error) error {
	if tenant.IsZero() {
		return domain.ErrNilTenant
	}
	tx, err := t.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin: %w", err)
	}
	defer func() { _ = tx.Rollback(context.WithoutCancel(ctx)) }()
	if _, err := tx.Exec(ctx, bindTenant, tenant.String()); err != nil {
		return fmt.Errorf("bind tenant: %w", err)
	}
	if err := work(context.WithValue(ctx, txKey{}, tx)); err != nil {
		return err
	}
	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit: %w", err)
	}
	return nil
}

// querier is the context's tenant transaction.
type querier interface {
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

func txOf(ctx context.Context) (querier, error) {
	tx, ok := ctx.Value(txKey{}).(pgx.Tx)
	if !ok {
		return nil, application.ErrNoTenantTransaction
	}
	return tx, nil
}
