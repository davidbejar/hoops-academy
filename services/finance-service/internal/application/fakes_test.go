package application

import (
	"context"
	"sort"
	"strings"
	"time"

	"hoopsacademy.local/finance/internal/domain"
)

// In-memory ports for the use-case tests (one tenant; tenant binding is the persistence tests' business).

type fixedClock struct{ now time.Time }

func (c fixedClock) Now() time.Time { return c.now }

type sequenceIDs struct{ next byte }

func (s *sequenceIDs) New() domain.UUID {
	s.next++
	var id domain.UUID
	id[0], id[15] = 0x01, s.next
	return id
}

type fakeTransactions struct {
	bound []domain.TenantID
	fail  error
}

func (f *fakeTransactions) InTenant(ctx context.Context, tenant domain.TenantID, work func(context.Context) error) error {
	f.bound = append(f.bound, tenant)
	if f.fail != nil {
		return f.fail
	}
	return work(ctx)
}

type fakeSettings struct {
	settings *domain.Settings
	saves    int
}

func (f *fakeSettings) Get(context.Context) (domain.Settings, bool, error) {
	if f.settings == nil {
		return domain.Settings{}, false, nil
	}
	return *f.settings, true, nil
}

func (f *fakeSettings) Save(_ context.Context, s domain.Settings) error {
	f.saves++
	s.Version++
	f.settings = &s
	return nil
}

type fakePlans struct {
	plans    map[domain.FeePlanID]domain.FeePlan
	stale    bool // the next Update loses the race
	lastList FeePlanFilter
}

func newFakePlans() *fakePlans { return &fakePlans{plans: map[domain.FeePlanID]domain.FeePlan{}} }

func (f *fakePlans) Get(_ context.Context, id domain.FeePlanID) (domain.FeePlan, bool, error) {
	p, ok := f.plans[id]
	return p, ok, nil
}

func (f *fakePlans) Insert(_ context.Context, p domain.FeePlan) error {
	f.plans[p.ID] = p
	return nil
}

func (f *fakePlans) Update(_ context.Context, p domain.FeePlan) (domain.FeePlan, error) {
	if f.stale || f.plans[p.ID].Version != p.Version {
		return p, ErrConcurrentModification
	}
	p.Version++
	f.plans[p.ID] = p
	return p, nil
}

func (f *fakePlans) Delete(_ context.Context, id domain.FeePlanID) error {
	delete(f.plans, id)
	return nil
}

func (f *fakePlans) List(_ context.Context, filter FeePlanFilter, page Page) ([]domain.FeePlan, int64, error) {
	f.lastList = filter
	var all []domain.FeePlan
	for _, p := range f.plans {
		if filter.IncludeArchived || !p.Archived {
			all = append(all, p)
		}
	}
	sort.Slice(all, func(i, j int) bool { return strings.Compare(all[i].Name, all[j].Name) < 0 })
	start := min(page.Index*page.Size, len(all))
	end := min(start+page.Size, len(all))
	return all[start:end], int64(len(all)), nil
}

type fakeDues struct {
	any   bool
	plans map[domain.FeePlanID]bool
}

func (f *fakeDues) AnyDue(context.Context) (bool, error) { return f.any, nil }

func (f *fakeDues) PlansWithDues(_ context.Context, ids []domain.FeePlanID) (map[domain.FeePlanID]bool, error) {
	out := map[domain.FeePlanID]bool{}
	for _, id := range ids {
		out[id] = f.plans[id]
	}
	return out, nil
}

type fakeAudit struct{ events []AuditEvent }

func (f *fakeAudit) Record(_ context.Context, e AuditEvent) error {
	f.events = append(f.events, e)
	return nil
}

type fakeMembers struct {
	members map[string]domain.Membership
}

func (f *fakeMembers) Membership(_ context.Context, _ domain.TenantID, subject string) (domain.Membership, bool, error) {
	m, ok := f.members[subject]
	return m, ok, nil
}
