package telemetry

import (
	"context"

	"github.com/jackc/pgx/v5"
	"go.opentelemetry.io/otel/trace"
)

// QueryTracer reports the service's SQL statements as spans (WP143, ADR-0074; red: reports nothing yet).
type QueryTracer struct{}

// NewQueryTracer reports to provider.
func NewQueryTracer(trace.TracerProvider) *QueryTracer { return &QueryTracer{} }

// TraceQueryStart implements pgx.QueryTracer.
func (*QueryTracer) TraceQueryStart(ctx context.Context, _ *pgx.Conn, _ pgx.TraceQueryStartData) context.Context {
	return ctx
}

// TraceQueryEnd implements pgx.QueryTracer.
func (*QueryTracer) TraceQueryEnd(context.Context, *pgx.Conn, pgx.TraceQueryEndData) {}
