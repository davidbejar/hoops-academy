package persistence

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// NewPool connects to url (finance_app) with every statement reported to tracer (WP143, ADR-0074).
func NewPool(ctx context.Context, url string, tracer pgx.QueryTracer) (*pgxpool.Pool, error) {
	config, err := pgxpool.ParseConfig(url)
	if err != nil {
		return nil, fmt.Errorf("database pool: %w", err)
	}
	config.ConnConfig.Tracer = tracer
	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return nil, fmt.Errorf("database pool: %w", err)
	}
	return pool, nil
}
