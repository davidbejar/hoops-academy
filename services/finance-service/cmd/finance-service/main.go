// Command finance-service serves an academy's finance (ADR-0051 §2, ADR-0055, ADR-0056): it migrates the schema as
// finance_migrator, connects as finance_app, consumes core's roster topics into its replica and serves finance.yaml.
package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"
	_ "time/tzdata" // the academies' IANA zones, whatever the image holds (the dues' dates depend on them)

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"

	"hoopsacademy.local/finance/db"
	"hoopsacademy.local/finance/internal/adapters/in/events"
	"hoopsacademy.local/finance/internal/adapters/in/job"
	"hoopsacademy.local/finance/internal/adapters/in/oidc"
	"hoopsacademy.local/finance/internal/adapters/in/rest"
	"hoopsacademy.local/finance/internal/adapters/out/persistence"
	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/platform/clock"
	"hoopsacademy.local/finance/internal/platform/config"
	"hoopsacademy.local/finance/internal/platform/security"
	"hoopsacademy.local/finance/internal/platform/telemetry"
)

func main() {
	if err := run(); err != nil {
		slog.Error("finance-service stopped", slog.String("error", err.Error()))
		os.Exit(1)
	}
}

func run() error {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM, os.Interrupt)
	defer stop()
	cfg, err := config.Load(os.Getenv)
	if err != nil {
		return err
	}
	log, shutdownTelemetry, err := telemetry.Setup(ctx, cfg.Telemetry.Enabled, os.Stdout)
	if err != nil {
		return err
	}
	defer func() { _ = shutdownTelemetry(context.WithoutCancel(ctx)) }()
	slog.SetDefault(log)

	applied, err := persistence.Migrate(ctx, cfg.Database.MigratorURL(), db.Migrations)
	if err != nil {
		return fmt.Errorf("migrate: %w", err)
	}
	log.Info("schema finance migrated", slog.Int("applied", applied))
	pool, err := persistence.NewPool(ctx, cfg.Database.AppURL(), telemetry.NewQueryTracer(otel.GetTracerProvider()))
	if err != nil {
		return err
	}
	defer pool.Close()

	tx := persistence.NewTransactions(pool)
	finance := application.NewFinance(persistence.NewPorts(pool, clock.System{}, log))
	metrics := events.NewMetrics()
	retention := job.Retention{Interval: job.RetentionInterval, Log: log, Pruned: metrics.PrunedAppliedEvents,
		Job: application.NewReplicaRetention(tx, persistence.TenantDirectory{Pool: pool}, persistence.Exclusive{Pool: pool},
			persistence.ReplicaStore{}, clock.System{})}
	go retention.Run(ctx)
	if cfg.DuesJob.Enabled {
		runner := job.Runner{Interval: cfg.DuesJob.Interval, Log: log, Job: application.NewDuesJob(finance,
			persistence.TenantDirectory{Pool: pool}, persistence.Exclusive{Pool: pool})}
		go runner.Run(ctx)
	} else {
		log.Warn("dues job off (FINANCE_DUES_JOB_ENABLED=false): automatic plans create no dues")
	}
	live := func() error { return nil }
	if cfg.Kafka.Enabled {
		consumer, err := events.NewConsumer(events.Config{Brokers: cfg.Kafka.Brokers, Group: "finance-service.roster",
			User: cfg.Kafka.User, Password: cfg.Kafka.Password}, events.NewDecoder(),
			application.NewReplica(tx, persistence.ReplicaStore{}), persistence.ParkedEvents{Pool: pool}, metrics, log)
		if err != nil {
			return err
		}
		go func() { _ = consumer.Run(ctx) }()
		live = consumer.Healthy
	} else {
		log.Warn("roster consumer off (FINANCE_ROSTER_CONSUMER_ENABLED=false): the membership replica is not updated")
	}

	handler := rest.NewHandler(rest.Deps{
		Finance:  finance,
		Verifier: oidc.NewVerifier(oidc.Config{AuthServerURL: cfg.OIDC.AuthServerURL, Issuer: cfg.OIDC.Issuer, Audience: cfg.OIDC.Audience}),
		Security: security.NewEvents(log), Log: log, CORSOrigins: cfg.CORSOrigins,
		Ready: pool.Ping, Live: live, Metrics: func(w http.ResponseWriter) { metrics.Write(w) },
	})
	server := &http.Server{
		Addr:              ":" + strconv.Itoa(cfg.HTTPPort),
		Handler:           otelhttp.NewHandler(handler, "finance-service"),
		ReadHeaderTimeout: 10 * time.Second, ReadTimeout: 30 * time.Second, WriteTimeout: 60 * time.Second,
		IdleTimeout: 120 * time.Second, MaxHeaderBytes: 32 << 10,
	}
	served := make(chan error, 1)
	go func() { served <- server.ListenAndServe() }()
	log.Info("finance-service listening", slog.Int("port", cfg.HTTPPort))
	select {
	case err := <-served:
		if !errors.Is(err, http.ErrServerClosed) {
			return fmt.Errorf("http: %w", err)
		}
	case <-ctx.Done():
	}
	shutdownCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 10*time.Second)
	defer cancel()
	return server.Shutdown(shutdownCtx) //nolint:wrapcheck // the process ends with it
}
