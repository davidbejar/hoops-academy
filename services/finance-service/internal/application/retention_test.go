package application

import (
	"context"
	"errors"
	"testing"
	"time"

	"hoopsacademy.local/finance/internal/domain"
)

// retentionDB is the bookkeeping of a few academies: applied event ids older than the cut-off per academy.
type retentionDB struct {
	old     map[string]int
	failing string
	bound   string
	before  []time.Time
	calls   map[string]int
}

func (d *retentionDB) InTenant(ctx context.Context, tenant domain.TenantID, work func(context.Context) error) error {
	if tenant.String() == d.failing {
		return errors.New("database down for this academy")
	}
	d.bound = tenant.String()
	defer func() { d.bound = "" }()
	return work(ctx)
}

func (d *retentionDB) DeleteAppliedBefore(_ context.Context, before time.Time, limit int) (int, error) {
	if d.bound == "" {
		return 0, ErrNoTenantTransaction
	}
	d.before = append(d.before, before)
	d.calls[d.bound]++
	n := min(limit, d.old[d.bound])
	d.old[d.bound] -= n
	return n, nil
}

// ADR-0037 (amendment WP82), WP131: the applied event ids older than the topics' tombstone retention (7 days) go,
// academy by academy in a transaction bound to it, in batches of RetentionBatch until a batch is short; a failing
// academy is reported and the others still run.
func TestTheRetentionDeletesOldAppliedEventIDsPerAcademyInBatches(t *testing.T) {
	busy, quiet, failing := tenant.String(), "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb", "cccccccc-cccc-4ccc-8ccc-cccccccccccc"
	db := &retentionDB{old: map[string]int{busy: 2*RetentionBatch + 500}, failing: failing, calls: map[string]int{}}
	retention := NewReplicaRetention(db, fakeTenants{tenants: []string{busy, failing, quiet}},
		fakeExclusive{lock: ReplicaRetentionLock}, db, fixedClock{now})

	report, ran, err := retention.Run(ctx)

	if !ran || err != nil {
		t.Fatalf("ran %v, %v", ran, err)
	}
	if report.Deleted != 2*RetentionBatch+500 || report.Tenants != 3 || report.Failed != 1 || len(report.Failures) != 1 {
		t.Errorf("report %+v", report)
	}
	if db.calls[busy] != 3 || db.calls[quiet] != 1 || db.old[busy] != 0 {
		t.Errorf("batches per academy %v, left %v", db.calls, db.old)
	}
	if want := now.Add(-7 * 24 * time.Hour); !report.Before.Equal(want) || !db.before[0].Equal(want) {
		t.Errorf("cut-off %s (%v), want %s", report.Before, db.before, want)
	}
	if AppliedEventRetention != 7*24*time.Hour {
		t.Errorf("retention %s, want the topics' 7-day tombstone retention", AppliedEventRetention)
	}
}

func TestTheRetentionSkipsWhenAnotherInstanceRunsIt(t *testing.T) {
	db := &retentionDB{old: map[string]int{tenant.String(): 3}, calls: map[string]int{}}
	retention := NewReplicaRetention(db, fakeTenants{tenants: []string{tenant.String()}},
		fakeExclusive{lock: ReplicaRetentionLock, busy: true}, db, fixedClock{now})

	report, ran, err := retention.Run(ctx)

	if ran || err != nil || report.Deleted != 0 || len(db.calls) != 0 {
		t.Errorf("ran %v %+v %v", ran, report, err)
	}
	failingList := NewReplicaRetention(db, fakeTenants{err: errors.New("no tenants")},
		fakeExclusive{lock: ReplicaRetentionLock}, db, fixedClock{now})
	if _, _, err := failingList.Run(ctx); err == nil {
		t.Error("a failing tenant list was swallowed")
	}
}
