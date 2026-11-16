package telemetry

import (
	"bytes"
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"

	"go.opentelemetry.io/otel"
)

func TestDisabledTelemetryLogsJSONLinesAndExportsNothing(t *testing.T) {
	var out bytes.Buffer
	log, shutdown, err := Setup(context.Background(), false, &out)
	if err != nil {
		t.Fatal(err)
	}
	log.Info("hello", slog.String("tenantId", "t"))
	_ = shutdown(context.Background())

	var record map[string]any
	if err := json.Unmarshal(out.Bytes(), &record); err != nil || record["msg"] != "hello" ||
		record["service.name"] != "finance-service" {
		t.Errorf("record %s %v", out.String(), err)
	}
}

func TestEnabledTelemetrySendsSpansAndLogsOverOTLPHTTP(t *testing.T) {
	var mu sync.Mutex
	paths := map[string]int{}
	collector := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		paths[r.URL.Path]++
		mu.Unlock()
		w.WriteHeader(http.StatusOK)
	}))
	defer collector.Close()
	t.Setenv("OTEL_EXPORTER_OTLP_ENDPOINT", collector.URL)
	t.Setenv("OTEL_TRACES_SAMPLER_ARG", "1")

	var out bytes.Buffer
	log, shutdown, err := Setup(context.Background(), true, &out)
	if err != nil {
		t.Fatal(err)
	}
	ctx, span := otel.Tracer("test").Start(context.Background(), "work")
	log.InfoContext(ctx, "inside a span")
	span.End()
	if err := shutdown(context.Background()); err != nil {
		t.Fatal(err)
	}

	mu.Lock()
	defer mu.Unlock()
	if paths["/v1/traces"] == 0 || paths["/v1/logs"] == 0 {
		t.Errorf("collector saw %v", paths)
	}
	if !bytes.Contains(out.Bytes(), []byte("inside a span")) {
		t.Error("the JSON line is still written")
	}
}
