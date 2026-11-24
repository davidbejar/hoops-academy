package telemetry

import (
	"context"
	"errors"
	"regexp"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
)

// QueryTracer reports the service's SQL statements as client spans under the span of the request or job that runs
// them (WP143, ADR-0074), with the attributes of the Java services' JDBC spans: db.system, db.operation, db.name and
// db.statement, the statement as written in the code ($n placeholders, string literals replaced by ?). Never a bound
// value, never the server's error text (it may quote a value): a refused statement keeps its SQLSTATE only. A
// statement outside any span (a background poll) starts no trace.
type QueryTracer struct{ tracer trace.Tracer }

// NewQueryTracer reports to provider.
func NewQueryTracer(provider trace.TracerProvider) *QueryTracer {
	return &QueryTracer{tracer: provider.Tracer("hoopsacademy.local/finance/database")}
}

type spanKey struct{}

var stringLiteral = regexp.MustCompile(`'(?:[^']|'')*'`)

// TraceQueryStart implements pgx.QueryTracer.
func (q *QueryTracer) TraceQueryStart(ctx context.Context, conn *pgx.Conn, data pgx.TraceQueryStartData) context.Context {
	if !trace.SpanContextFromContext(ctx).IsValid() {
		return ctx
	}
	operation := operationOf(data.SQL)
	attributes := []attribute.KeyValue{attribute.String("db.system", "postgresql"),
		attribute.String("db.operation", operation), attribute.String("db.statement", sanitise(data.SQL))}
	if conn != nil {
		attributes = append(attributes, attribute.String("db.name", conn.Config().Database))
	}
	ctx, span := q.tracer.Start(ctx, operation, trace.WithSpanKind(trace.SpanKindClient),
		trace.WithAttributes(attributes...))
	return context.WithValue(ctx, spanKey{}, span)
}

// TraceQueryEnd implements pgx.QueryTracer.
func (*QueryTracer) TraceQueryEnd(ctx context.Context, _ *pgx.Conn, data pgx.TraceQueryEndData) {
	span, ok := ctx.Value(spanKey{}).(trace.Span)
	if !ok {
		return
	}
	if data.Err != nil {
		var refused *pgconn.PgError
		if errors.As(data.Err, &refused) {
			span.SetAttributes(attribute.String("db.response.status_code", refused.Code))
			span.SetStatus(codes.Error, "SQLSTATE "+refused.Code)
		} else {
			span.SetStatus(codes.Error, "")
		}
	}
	span.End()
}

// operationOf is the statement's first keyword in upper case (SELECT, INSERT, BEGIN, ...).
func operationOf(sql string) string {
	fields := strings.Fields(sql)
	if len(fields) == 0 {
		return "SQL"
	}
	return strings.ToUpper(fields[0])
}

func sanitise(sql string) string { return stringLiteral.ReplaceAllString(sql, "?") }
