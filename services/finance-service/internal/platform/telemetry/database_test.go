package telemetry

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"testing"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"go.opentelemetry.io/otel/codes"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	"go.opentelemetry.io/otel/sdk/trace/tracetest"
	"go.opentelemetry.io/otel/trace"
)

func recording() (*tracetest.SpanRecorder, trace.Tracer, *QueryTracer) {
	recorder := tracetest.NewSpanRecorder()
	provider := sdktrace.NewTracerProvider(sdktrace.WithSpanProcessor(recorder))
	return recorder, provider.Tracer("test"), NewQueryTracer(provider)
}

func query(ctx context.Context, tracer *QueryTracer, sql string, err error, args ...any) {
	ctx = tracer.TraceQueryStart(ctx, nil, pgx.TraceQueryStartData{SQL: sql, Args: args})
	tracer.TraceQueryEnd(ctx, nil, pgx.TraceQueryEndData{Err: err})
}

func TestAStatementOutsideASpanStartsNoTrace(t *testing.T) {
	recorder, _, tracer := recording()

	query(context.Background(), tracer, "select 1 from finance.due where id = $1", nil, "x")

	if spans := recorder.Ended(); len(spans) != 0 {
		t.Errorf("a database call without a request or job span is not traced, got %d spans", len(spans))
	}
}

func TestAStatementIsAClientSpanUnderTheCallerWithTheParameterisedText(t *testing.T) {
	recorder, parentTracer, tracer := recording()
	ctx, parent := parentTracer.Start(context.Background(), "GET /api/finance/dues")

	query(ctx, tracer, "select set_config('app.tenant_id', $1, true)", nil, "6f1c0b8e-tenant")
	if !parent.IsRecording() {
		t.Fatal("the tracer ended the caller's span")
	}
	parent.End()

	spans := recorder.Ended()
	if len(spans) != 2 {
		t.Fatalf("spans %d", len(spans))
	}
	db := spans[0]
	attributes := map[string]string{}
	for _, kv := range db.Attributes() {
		attributes[string(kv.Key)] = kv.Value.Emit()
	}
	if db.Name() != "SELECT" || db.SpanKind() != trace.SpanKindClient || db.Parent().SpanID() != parent.SpanContext().SpanID() {
		t.Errorf("span %s kind %v parent %v", db.Name(), db.SpanKind(), db.Parent().SpanID())
	}
	want := map[string]string{"db.system": "postgresql", "db.operation": "SELECT",
		"db.statement": "select set_config(?, $1, true)"}
	for key, value := range want {
		if attributes[key] != value {
			t.Errorf("%s = %q, want %q (all: %v)", key, attributes[key], value, attributes)
		}
	}
	if text := fmt.Sprint(attributes); strings.Contains(text, "6f1c0b8e") {
		t.Errorf("a bound value is on the span: %s", text)
	}
}

func TestARefusedStatementKeepsItsSQLStateNotTheServersText(t *testing.T) {
	recorder, parentTracer, tracer := recording()
	ctx, parent := parentTracer.Start(context.Background(), "POST /api/finance/dues")
	refused := &pgconn.PgError{Code: "23505", Message: `duplicate key value violates unique constraint "due_uq"`,
		Detail: "Key (player_name)=(Zelphine Quorrowby) already exists."}

	query(ctx, tracer, "insert into finance.due (player_name) values ($1)", fmt.Errorf("insert: %w", refused),
		"Zelphine Quorrowby")
	parent.End()

	db := recorder.Ended()[0]
	if db.Status().Code != codes.Error || db.Status().Description != "SQLSTATE 23505" {
		t.Errorf("status %+v", db.Status())
	}
	if len(db.Events()) != 0 {
		t.Errorf("no exception event (the driver's text may quote a value): %v", db.Events())
	}
	for _, kv := range db.Attributes() {
		if strings.Contains(kv.Value.Emit(), "Quorrowby") {
			t.Errorf("%s carries a value: %s", kv.Key, kv.Value.Emit())
		}
	}
}

func TestAFailureThatIsNotTheServersKeepsNoText(t *testing.T) {
	recorder, parentTracer, tracer := recording()
	ctx, parent := parentTracer.Start(context.Background(), "GET /api/finance/dues")

	query(ctx, tracer, "select 1", errors.New("dial tcp: secret-host refused"))
	parent.End()

	if status := recorder.Ended()[0].Status(); status.Code != codes.Error || status.Description != "" {
		t.Errorf("status %+v", status)
	}
}
