package application

import (
	"context"
	"errors"

	"hoopsacademy.local/finance/internal/domain"
)

// DuesJobLock is the cluster-wide lock of the daily dues job: with several replicas only its holder runs it.
const DuesJobLock = "finance.dues-generation"

// JobReport is what one run of the dues job did.
type JobReport struct {
	Academies int      // academies entered
	Created   int      // dues created
	Skipped   int      // plan periods a rule refused (e.g. TOO_MANY_DUES), left for ADMIN
	Failed    int      // academies whose transaction failed (rolled back; the next run retries)
	Failures  []string // one line per failure: the academy and the error, never request or personal data
}

// DuesJob creates the dues of every started period of the automatic plans of each ACTIVE academy, on the academy's
// own date (decision 98). It enters each academy the replica knows in a transaction bound to that academy (never an
// unbound or nil tenant), under the cluster-wide lock DuesJobLock, and is idempotent: a re-run creates only what is
// missing.
type DuesJob struct {
	finance   *Finance
	tenants   TenantDirectory
	exclusive Exclusive
}

// NewDuesJob wires the job.
func NewDuesJob(finance *Finance, tenants TenantDirectory, exclusive Exclusive) DuesJob {
	return DuesJob{finance: finance, tenants: tenants, exclusive: exclusive}
}

// Run runs the job once; ran is false when another instance holds the lock (nothing was done). A failing academy is
// reported and the others still run; err is a failure to run at all (the lock, the list of academies).
func (j DuesJob) Run(ctx context.Context) (JobReport, bool, error) {
	var report JobReport
	ran, err := j.exclusive.Run(ctx, DuesJobLock, func(ctx context.Context) error {
		tenants, err := j.tenants.Tenants(ctx)
		if err != nil {
			return err
		}
		for _, tenant := range tenants {
			report.Academies++
			var academy JobReport
			err := j.finance.p.Transactions.InTenant(ctx, tenant, func(ctx context.Context) error {
				return j.finance.generateAcademy(ctx, tenant, &academy)
			})
			if err != nil {
				report.Failed++
				report.Failures = append(report.Failures, tenant.String()+": "+err.Error())
				continue
			}
			report.Created += academy.Created
			report.Skipped += academy.Skipped
		}
		return nil
	})
	return report, ran, err
}

// generateAcademy generates the bound academy's automatic plans, if it is ACTIVE.
func (f *Finance) generateAcademy(ctx context.Context, tenant domain.TenantID, report *JobReport) error {
	academy, found, err := f.p.Roster.Academy(ctx)
	if err != nil || !found || !academy.Active {
		return err
	}
	today := domain.Today(f.p.Clock.Now(), academy.Zone)
	plans, err := f.p.FeePlans.Generating(ctx)
	if err != nil {
		return err
	}
	actor := domain.SystemActor(tenant)
	for _, plan := range plans {
		season, found, err := f.p.Roster.SeasonDates(ctx, plan.Season)
		if err != nil {
			return err
		}
		if !found {
			continue
		}
		for _, window := range plan.StartedWindows(season, today) {
			generation, err := f.generate(ctx, actor, plan, window, false)
			var refused *domain.Error
			if errors.As(err, &refused) {
				report.Skipped++
				continue
			}
			if err != nil {
				return err
			}
			report.Created += len(generation.Created)
		}
	}
	return nil
}
