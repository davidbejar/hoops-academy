package application

import (
	"context"
	"time"

	"hoopsacademy.local/finance/internal/domain"
)

// ReplicaRetentionLock is the cluster-wide lock of the replica retention: with several replicas only its holder runs it.
const ReplicaRetentionLock = "finance.replica-retention"

// AppliedEventRetention is how long an applied event id is kept: the topics' tombstone retention (ADR-0036, 7 days),
// the longest a redelivery can come later; an older redelivery is stale anyway (the occurred_at guard). The same
// value as game's and athlete's default and minimum (ADR-0037 amendment WP82).
const AppliedEventRetention = 7 * 24 * time.Hour

// RetentionBatch is the most rows one transaction deletes.
const RetentionBatch = 1000

// AppliedEvents is the replica's idempotency record (finance.applied_event).
type AppliedEvents interface {
	// DeleteAppliedBefore deletes at most limit of the bound tenant's event ids applied before before; it returns how
	// many it deleted.
	DeleteAppliedBefore(ctx context.Context, before time.Time, limit int) (int, error)
}

// RetentionReport is what one run of the replica retention deleted.
type RetentionReport struct {
	Before   time.Time // ids applied before it were deleted
	Tenants  int       // academies entered
	Deleted  int       // ids deleted
	Failed   int       // academies whose deletion failed (the next run retries)
	Failures []string  // one line per failure: the academy and the error
}

// ReplicaRetention deletes the applied event ids older than AppliedEventRetention, academy by academy in transactions
// bound to it (never an unbound or nil tenant), in batches of RetentionBatch, under the lock ReplicaRetentionLock.
type ReplicaRetention struct {
	transactions Transactions
	tenants      TenantDirectory
	exclusive    Exclusive
	events       AppliedEvents
	clock        Clock
}

// NewReplicaRetention wires the retention.
func NewReplicaRetention(transactions Transactions, tenants TenantDirectory, exclusive Exclusive, events AppliedEvents,
	clock Clock) ReplicaRetention {
	return ReplicaRetention{transactions: transactions, tenants: tenants, exclusive: exclusive, events: events, clock: clock}
}

// Run runs the retention once; ran is false when another instance holds the lock. A failing academy is reported and
// the others still run; err is a failure to run at all (the lock, the list of academies).
func (r ReplicaRetention) Run(ctx context.Context) (RetentionReport, bool, error) {
	report := RetentionReport{Before: r.clock.Now().Add(-AppliedEventRetention)}
	ran, err := r.exclusive.Run(ctx, ReplicaRetentionLock, func(ctx context.Context) error {
		tenants, err := r.tenants.Tenants(ctx)
		if err != nil {
			return err
		}
		for _, tenant := range tenants {
			report.Tenants++
			deleted, err := r.pruneAcademy(ctx, tenant, report.Before)
			report.Deleted += deleted
			if err != nil {
				report.Failed++
				report.Failures = append(report.Failures, tenant.String()+": "+err.Error())
			}
		}
		return nil
	})
	return report, ran, err
}

// pruneAcademy deletes the academy's ids applied before before, a batch per transaction until a batch is short.
func (r ReplicaRetention) pruneAcademy(ctx context.Context, tenant domain.TenantID, before time.Time) (int, error) {
	total := 0
	for {
		var deleted int
		err := r.transactions.InTenant(ctx, tenant, func(ctx context.Context) error {
			var err error
			deleted, err = r.events.DeleteAppliedBefore(ctx, before, RetentionBatch)
			return err
		})
		if err != nil {
			return total, err
		}
		total += deleted
		if deleted < RetentionBatch {
			return total, nil
		}
	}
}
