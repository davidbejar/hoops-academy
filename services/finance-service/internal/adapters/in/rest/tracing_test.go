package rest_test

import (
	"fmt"
	"strings"
	"testing"

	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	"go.opentelemetry.io/otel/sdk/trace/tracetest"
	"go.opentelemetry.io/otel/trace"
)

// WP143, ADR-0074: the SQL of a request shows in its trace, under the request's server span, and no span carries a
// bound value (a payment note) or the tenant id.
func TestTheDuesListShowsItsSQLUnderTheRequestSpanAndNoValue(t *testing.T) {
	const note = "Zelphine Quorrowby paid in cash"
	recorder := tracetest.NewSpanRecorder()
	a := newTracedAPI(t, sdktrace.NewTracerProvider(sdktrace.WithSpanProcessor(recorder)))
	l := lionsAcademy(t, a)
	l.generate(l.plan, month(0), false)
	due := l.dues("playerId=" + l.ana)[0].(map[string]any)["id"].(string)
	expect(t, l.post("/api/finance/dues/"+due+":pay", map[string]any{"paidOn": todayUTC(), "method": "CASH",
		"note": note}), 200)
	written := len(recorder.Ended())

	expect(t, a.do(t, call{method: "GET", path: "/api/finance/dues", tenant: l.id(), subject: admin}), 200)

	list := recorder.Ended()[written:]
	server, database := serverAndDatabaseSpans(t, list)
	if len(database) == 0 {
		t.Fatalf("no database span among %d spans", len(list))
	}
	for _, span := range database {
		if !under(span, server, list) {
			t.Errorf("%s is not under the request span", span.Name())
		}
	}
	operations := make([]string, 0, len(database))
	for _, span := range database {
		operations = append(operations, span.Name())
	}
	fmt.Printf("WP143 finance dues list: %d spans, %d database spans %v\n", len(list), len(database), operations)
	if text := exportedText(recorder.Ended()); strings.Contains(text, "Quorrowby") || strings.Contains(text, l.id()) {
		t.Errorf("a value or the tenant is on a span:\n%s", text)
	}
}

func serverAndDatabaseSpans(t *testing.T, spans []sdktrace.ReadOnlySpan) (sdktrace.ReadOnlySpan, []sdktrace.ReadOnlySpan) {
	t.Helper()
	var server sdktrace.ReadOnlySpan
	var database []sdktrace.ReadOnlySpan
	for _, span := range spans {
		if span.SpanKind() == trace.SpanKindServer {
			server = span
		}
		for _, kv := range span.Attributes() {
			if kv.Key == "db.system" {
				database = append(database, span)
			}
		}
	}
	if server == nil {
		t.Fatal("no server span")
	}
	return server, database
}

// under reports whether span descends from root among spans.
func under(span, root sdktrace.ReadOnlySpan, spans []sdktrace.ReadOnlySpan) bool {
	byID := map[trace.SpanID]sdktrace.ReadOnlySpan{}
	for _, s := range spans {
		byID[s.SpanContext().SpanID()] = s
	}
	for parent, ok := byID[span.Parent().SpanID()]; ok; parent, ok = byID[parent.Parent().SpanID()] {
		if parent.SpanContext().SpanID() == root.SpanContext().SpanID() {
			return true
		}
	}
	return false
}

// exportedText is everything the spans export as text: names, status, attributes, events and their attributes.
func exportedText(spans []sdktrace.ReadOnlySpan) string {
	var text strings.Builder
	for _, span := range spans {
		fmt.Fprintf(&text, "%s | %s |", span.Name(), span.Status().Description)
		for _, kv := range span.Attributes() {
			fmt.Fprintf(&text, " %s=%s", kv.Key, kv.Value.Emit())
		}
		for _, event := range span.Events() {
			fmt.Fprintf(&text, " | %s", event.Name)
			for _, kv := range event.Attributes {
				fmt.Fprintf(&text, " %s=%s", kv.Key, kv.Value.Emit())
			}
		}
		text.WriteString("\n")
	}
	return text.String()
}
