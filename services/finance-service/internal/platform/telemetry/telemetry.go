// Package telemetry sets up logging and OpenTelemetry (ADR-0046): JSON lines on stdout always, and with
// OTEL_SDK_DISABLED=false traces and log records over OTLP HTTP/protobuf (port 4318 of the collector) with
// parent-based ratio sampling and W3C trace context. Resource: service.name finance-service plus
// OTEL_RESOURCE_ATTRIBUTES (never a tenant).
package telemetry

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"os"
	"strconv"

	"go.opentelemetry.io/contrib/bridges/otelslog"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlplog/otlploghttp"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/propagation"
	sdklog "go.opentelemetry.io/otel/sdk/log"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.26.0"
)

// ServiceName is the resource's service.name.
const ServiceName = "finance-service"

// Shutdown flushes and stops the exporters.
type Shutdown func(ctx context.Context) error

// Setup returns the service's logger (JSON on stdout, and the OTLP bridge when enabled).
func Setup(ctx context.Context, enabled bool, stdout io.Writer) (*slog.Logger, Shutdown, error) {
	jsonLines := slog.NewJSONHandler(stdout, &slog.HandlerOptions{Level: slog.LevelInfo})
	base := slog.New(jsonLines).With(slog.String("service.name", ServiceName))
	if !enabled {
		return base, func(context.Context) error { return nil }, nil
	}
	res, err := resource.Merge(resource.Default(), resource.NewSchemaless(semconv.ServiceName(ServiceName)))
	if err != nil {
		return nil, nil, fmt.Errorf("telemetry resource: %w", err)
	}
	traces, err := otlptracehttp.New(ctx)
	if err != nil {
		return nil, nil, fmt.Errorf("trace exporter: %w", err)
	}
	logs, err := otlploghttp.New(ctx)
	if err != nil {
		return nil, nil, fmt.Errorf("log exporter: %w", err)
	}
	tracer := sdktrace.NewTracerProvider(sdktrace.WithResource(res), sdktrace.WithBatcher(traces),
		sdktrace.WithSampler(sdktrace.ParentBased(sdktrace.TraceIDRatioBased(ratio()))))
	logger := sdklog.NewLoggerProvider(sdklog.WithResource(res), sdklog.WithProcessor(sdklog.NewBatchProcessor(logs)))
	otel.SetTracerProvider(tracer)
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(propagation.TraceContext{}, propagation.Baggage{}))
	otel.SetLoggerProvider(logger)
	bridge := otelslog.NewHandler(ServiceName, otelslog.WithLoggerProvider(logger))
	log := slog.New(slog.NewMultiHandler(jsonLines, bridge)).With(slog.String("service.name", ServiceName))
	return log, func(ctx context.Context) error {
		return errors.Join(tracer.Shutdown(ctx), logger.Shutdown(ctx))
	}, nil
}

// ratio is OTEL_TRACES_SAMPLER_ARG (root spans kept, 0..1), 0.1 by default as the chart's.
func ratio() float64 {
	r, err := strconv.ParseFloat(os.Getenv("OTEL_TRACES_SAMPLER_ARG"), 64)
	if err != nil || r < 0 || r > 1 {
		return 0.1
	}
	return r
}
