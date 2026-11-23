package application

import (
	"cmp"
	"context"
	"errors"
	"testing"

	"hoopsacademy.local/finance/internal/domain"
)

type fakeTenants struct {
	tenants []string
	err     error
}

func (f fakeTenants) Tenants(context.Context) ([]domain.TenantID, error) {
	out := make([]domain.TenantID, len(f.tenants))
	for i, text := range f.tenants {
		out[i], _ = domain.ParseTenantID(text)
	}
	return out, f.err
}

// fakeExclusive holds lock (DuesJobLock when empty) unless busy.
type fakeExclusive struct {
	lock string
	busy bool
}

func (f fakeExclusive) Run(ctx context.Context, lock string, work func(context.Context) error) (bool, error) {
	if want := cmp.Or(f.lock, DuesJobLock); lock != want {
		return false, errors.New("unexpected lock " + lock)
	}
	if f.busy {
		return false, nil
	}
	return true, work(ctx)
}

// selectiveTransactions fails the transactions of one tenant.
type selectiveTransactions struct{ failing string }

func (s selectiveTransactions) InTenant(ctx context.Context, tenant domain.TenantID, work func(context.Context) error) error {
	if tenant.String() == s.failing {
		return errors.New("database down for this academy")
	}
	return work(ctx)
}

type emptyRoster struct{ RosterReads }

func (emptyRoster) Academy(context.Context) (Academy, bool, error) { return Academy{}, false, nil }

func TestTheJobSkipsWhenAnotherInstanceRunsIt(t *testing.T) {
	f := newFixture()
	job := NewDuesJob(f.finance, fakeTenants{tenants: []string{tenant.String()}}, fakeExclusive{busy: true})

	report, ran, err := job.Run(ctx)

	if ran || err != nil || report.Academies != 0 || report.Created != 0 || len(f.tx.bound) != 0 {
		t.Errorf("ran %v %+v %v, bound %v", ran, report, err, f.tx.bound)
	}
}

func TestAFailingAcademyIsReportedAndTheOthersStillRun(t *testing.T) {
	other := "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
	finance := NewFinance(Ports{Clock: fixedClock{now}, IDs: &sequenceIDs{},
		Transactions: selectiveTransactions{failing: other}, Roster: emptyRoster{}})
	job := NewDuesJob(finance, fakeTenants{tenants: []string{other, tenant.String()}}, fakeExclusive{})

	report, ran, err := job.Run(ctx)

	if !ran || err != nil || report.Academies != 2 || report.Failed != 1 || len(report.Failures) != 1 {
		t.Errorf("ran %v %+v %v", ran, report, err)
	}
	if _, _, err := NewDuesJob(finance, fakeTenants{err: errors.New("no tenants")}, fakeExclusive{}).Run(ctx); err == nil {
		t.Error("a failing tenant list was swallowed")
	}
}
