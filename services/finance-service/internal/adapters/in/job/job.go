// Package job triggers finance-service's scheduled work: the dues job (decision 98, ADR-0056). Every instance ticks;
// the job's database lock lets one of them run at a time, and each run works on every academy's own date, so a
// period's dues appear within one interval after midnight in the academy's time zone.
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
func (r Runner) Run(ctx context.Context) {
	ticker := time.NewTicker(r.Interval)
	defer ticker.Stop()
	for {
		r.once(ctx)
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
