// Package job triggers finance-service's scheduled work: the dues job (decision 98, ADR-0056) and the replica
// retention (ADR-0037 amendment WP82). Every instance ticks; each job's database lock lets one of them run at a time.
// The dues job works on every academy's own date, so a period's dues appear within one interval after midnight in the
// academy's time zone.
package job

import (
	"context"
	"log/slog"
	"time"

	"hoopsacademy.local/finance/internal/application"
)

// Runner runs the dues job at start and then every Interval until its context ends.
type Runner struct {
	Job      application.DuesJob
	Interval time.Duration
	Log      *slog.Logger
}

// Run blocks until ctx ends.
func (r Runner) Run(ctx context.Context) { every(ctx, r.Interval, r.once) }

// every runs once at start and then every interval until ctx ends.
func every(ctx context.Context, interval time.Duration, once func(context.Context)) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		once(ctx)
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
		}
	}
}

// once runs the job and logs what it did: counts and failing academies, never personal data.
func (r Runner) once(ctx context.Context) {
	report, ran, err := r.Job.Run(ctx)
	switch {
	case err != nil:
		if ctx.Err() == nil {
			r.Log.ErrorContext(ctx, "dues job failed", slog.String("error", err.Error()))
		}
	case !ran:
		r.Log.InfoContext(ctx, "dues job skipped: another instance holds its lock")
	default:
		r.Log.InfoContext(ctx, "dues job ran", slog.Int("academies", report.Academies), slog.Int("created", report.Created),
			slog.Int("skipped", report.Skipped), slog.Int("failed", report.Failed))
		for _, failure := range report.Failures {
			r.Log.WarnContext(ctx, "dues job: an academy failed (retried on the next run)", slog.String("failure", failure))
		}
	}
}

// RetentionInterval is how often the replica retention runs.
const RetentionInterval = 24 * time.Hour

// Retention runs the replica retention at start and then every Interval until its context ends.
type Retention struct {
	Job      application.ReplicaRetention
	Interval time.Duration
	Log      *slog.Logger
	// Pruned counts the deleted ids (hoops_roster_replica_pruned_total{table="applied_event"}); nil counts nothing.
	Pruned func(int)
}

// Run blocks until ctx ends.
func (r Retention) Run(ctx context.Context) { every(ctx, r.Interval, r.once) }

// once runs the retention and logs what it did: counts and failing academies, never event content.
func (r Retention) once(ctx context.Context) {
	report, ran, err := r.Job.Run(ctx)
	switch {
	case err != nil:
		if ctx.Err() == nil {
			r.Log.ErrorContext(ctx, "replica retention failed", slog.String("error", err.Error()))
		}
	case !ran:
		r.Log.InfoContext(ctx, "replica retention skipped: another instance holds its lock")
	default:
		if r.Pruned != nil {
			r.Pruned(report.Deleted)
		}
		r.Log.InfoContext(ctx, "replica retention ran", slog.Int("academies", report.Tenants),
			slog.Int("deleted", report.Deleted), slog.Time("appliedBefore", report.Before), slog.Int("failed", report.Failed))
		for _, failure := range report.Failures {
			r.Log.WarnContext(ctx, "replica retention: an academy failed (retried on the next run)",
				slog.String("failure", failure))
		}
	}
}
