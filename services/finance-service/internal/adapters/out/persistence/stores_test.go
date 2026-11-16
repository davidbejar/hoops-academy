package persistence_test

import (
	"context"
	"crypto/rand"
	"errors"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgconn"

	"hoopsacademy.local/finance/internal/adapters/out/persistence"
	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/domain"
	"hoopsacademy.local/finance/internal/testsupport/pgtest"
)

var created = time.Date(2026, 11, 16, 9, 0, 0, 0, time.UTC)

func newTenant(t *testing.T) domain.TenantID {
	t.Helper()
	tenant, err := domain.NewTenantID(randomUUID())
	if err != nil {
		t.Fatal(err)
	}
	return tenant
}

func randomUUID() domain.UUID {
	var id domain.UUID
	_, _ = rand.Read(id[:])
	id[6] = id[6]&0x0f | 0x40
	id[8] = id[8]&0x3f | 0x80
	return id
}

type stores struct {
	tx       persistence.Transactions
	settings persistence.SettingsStore
	plans    persistence.FeePlanStore
	dues     persistence.DueQueries
	audit    persistence.AuditLog
	members  persistence.MembershipStore
}

func newStores(t *testing.T) stores {
	database := pgtest.Start(t)
	return stores{tx: persistence.NewTransactions(database.App)}
}

func in(t *testing.T, s stores, tenant domain.TenantID, work func(ctx context.Context) error) {
	t.Helper()
	if err := s.tx.InTenant(context.Background(), tenant, work); err != nil {
		t.Fatal(err)
	}
}

func plan(t *testing.T, name string, team *domain.TeamID, season domain.SeasonID) domain.FeePlan {
	t.Helper()
	first := "2026-09"
	var category *domain.AgeCategoryID
	if team == nil {
		c := domain.AgeCategoryID(randomUUID())
		category = &c
	}
	p, err := domain.NewFeePlan(domain.FeePlanID(randomUUID()), domain.FeePlanInput{
		Name: name, Season: season, Team: team, AgeCategory: category, AmountMinor: 4500, Cadence: "MONTHLY",
		FirstPeriod: &first, AutoGenerate: true,
	}, created)
	if err != nil {
		t.Fatal(err)
	}
	return p
}

func TestAStoreOutsideATenantTransactionRefusesToWork(t *testing.T) {
	s := newStores(t)
	if _, _, err := s.settings.Get(context.Background()); !errors.Is(err, application.ErrNoTenantTransaction) {
		t.Errorf("got %v", err)
	}
}

func TestSettingsAreSavedAndVersioned(t *testing.T) {
	s := newStores(t)
	tenant := newTenant(t)
	eur, _ := domain.ParseCurrency("EUR")
	idr, _ := domain.ParseCurrency("IDR")

	in(t, s, tenant, func(ctx context.Context) error {
		if _, found, err := s.settings.Get(ctx); found || err != nil {
			t.Errorf("fresh tenant: %v %v", found, err)
		}
		if err := s.settings.Save(ctx, domain.Settings{Currency: eur}); err != nil {
			return err
		}
		stored, found, err := s.settings.Get(ctx)
		if err != nil || !found || stored.Currency != eur || stored.Version != 1 {
			t.Errorf("after insert: %+v %v %v", stored, found, err)
		}
		if err := s.settings.Save(ctx, domain.Settings{Currency: idr, Version: 1}); err != nil {
			return err
		}
		if err := s.settings.Save(ctx, domain.Settings{Currency: eur, Version: 1}); !errors.Is(err, application.ErrConcurrentModification) {
			t.Errorf("stale save: %v", err)
		}
		return nil
	})
}

func TestFeePlansRoundTripAndUpdateWithOptimisticLocking(t *testing.T) {
	s := newStores(t)
	tenant := newTenant(t)
	team := domain.TeamID(randomUUID())
	p := plan(t, "U12", &team, domain.SeasonID(randomUUID()))
	last := "2027-06"
	p.Last = mustPeriod(t, last)

	in(t, s, tenant, func(ctx context.Context) error {
		if err := s.plans.Insert(ctx, p); err != nil {
			return err
		}
		stored, found, err := s.plans.Get(ctx, p.ID)
		if err != nil || !found {
			t.Fatalf("get: %v %v", found, err)
		}
		if stored.Name != "U12" || *stored.Target.Team != team || stored.Target.AgeCategory != nil ||
			stored.First.Key() != "2026-09" || stored.Last.Key() != "2027-06" || stored.Amount.Minor() != 4500 ||
			!stored.CreatedAt.Equal(created) || stored.Version != 0 || stored.Cadence != domain.Monthly {
			t.Errorf("stored %+v", stored)
		}
		stored.Name = "Renamed"
		updated, err := s.plans.Update(ctx, stored)
		if err != nil || updated.Version != 1 {
			t.Errorf("update: %+v %v", updated, err)
		}
		if _, err := s.plans.Update(ctx, stored); !errors.Is(err, application.ErrConcurrentModification) {
			t.Errorf("stale update: %v", err)
		}
		if err := s.plans.Delete(ctx, p.ID); err != nil {
			return err
		}
		if _, found, _ := s.plans.Get(ctx, p.ID); found {
			t.Error("deleted plan still found")
		}
		return nil
	})
}

func mustPeriod(t *testing.T, key string) *domain.Period {
	t.Helper()
	p, err := domain.ParsePeriod(domain.Monthly, key)
	if err != nil {
		t.Fatal(err)
	}
	return &p
}

func TestFeePlansAreListedByNameWithFiltersAndPages(t *testing.T) {
	s := newStores(t)
	tenant := newTenant(t)
	team := domain.TeamID(randomUUID())
	season, other := domain.SeasonID(randomUUID()), domain.SeasonID(randomUUID())
	b, a, c := plan(t, "B plan", &team, season), plan(t, "A plan", nil, season), plan(t, "C plan", &team, other)
	c.Archived = true

	in(t, s, tenant, func(ctx context.Context) error {
		for _, p := range []domain.FeePlan{b, a, c} {
			if err := s.plans.Insert(ctx, p); err != nil {
				return err
			}
		}
		names := func(filter application.FeePlanFilter, page application.Page) ([]string, int64) {
			plans, total, err := s.plans.List(ctx, filter, page)
			if err != nil {
				t.Fatal(err)
			}
			var out []string
			for _, p := range plans {
				out = append(out, p.Name)
			}
			return out, total
		}
		check := func(label string, got []string, total int64, want []string, wantTotal int64) {
			if total != wantTotal || len(got) != len(want) {
				t.Errorf("%s: %v (%d)", label, got, total)
				return
			}
			for i := range want {
				if got[i] != want[i] {
					t.Errorf("%s: %v", label, got)
				}
			}
		}
		got, total := names(application.FeePlanFilter{}, application.Page{Size: 10})
		check("active", got, total, []string{"A plan", "B plan"}, 2)
		got, total = names(application.FeePlanFilter{IncludeArchived: true}, application.Page{Index: 1, Size: 2})
		check("second page", got, total, []string{"C plan"}, 3)
		got, total = names(application.FeePlanFilter{Team: &team, IncludeArchived: true}, application.Page{Size: 10})
		check("team", got, total, []string{"B plan", "C plan"}, 2)
		got, total = names(application.FeePlanFilter{Season: &season}, application.Page{Size: 10})
		check("season", got, total, []string{"A plan", "B plan"}, 2)
		got, total = names(application.FeePlanFilter{AgeCategory: a.Target.AgeCategory}, application.Page{Size: 10})
		check("category", got, total, []string{"A plan"}, 1)
		return nil
	})
}

func TestDueQueriesSeeTheDuesOfTheBoundTenant(t *testing.T) {
	s := newStores(t)
	tenant := newTenant(t)
	team := domain.TeamID(randomUUID())
	with, without := plan(t, "with", &team, domain.SeasonID(randomUUID())), plan(t, "without", &team, domain.SeasonID(randomUUID()))
	database := pgtest.Start(t)

	in(t, s, tenant, func(ctx context.Context) error {
		if anyDue, err := s.dues.AnyDue(ctx); err != nil || anyDue {
			t.Errorf("no dues yet: %v %v", anyDue, err)
		}
		for _, p := range []domain.FeePlan{with, without} {
			if err := s.plans.Insert(ctx, p); err != nil {
				return err
			}
		}
		return nil
	})
	insertDue(t, database.App, tenant, with.ID)
	in(t, s, tenant, func(ctx context.Context) error {
		anyDue, err := s.dues.AnyDue(ctx)
		if err != nil || !anyDue {
			t.Errorf("a due exists: %v %v", anyDue, err)
		}
		plans, err := s.dues.PlansWithDues(ctx, []domain.FeePlanID{with.ID, without.ID})
		if err != nil || !plans[with.ID] || plans[without.ID] {
			t.Errorf("plans with dues: %v %v", plans, err)
		}
		return nil
	})
	in(t, s, newTenant(t), func(ctx context.Context) error {
		if anyDue, _ := s.dues.AnyDue(ctx); anyDue {
			t.Error("another tenant's due counted")
		}
		return nil
	})
}

func TestAuditEventsAreAppendOnly(t *testing.T) {
	s := newStores(t)
	tenant := newTenant(t)
	member := domain.NewMembership("sub-admin", domain.PersonID(randomUUID()), tenant, []domain.Role{domain.Admin})
	database := pgtest.Start(t)

	in(t, s, tenant, func(ctx context.Context) error {
		return s.audit.Record(ctx, application.AuditEvent{
			Actor: member, Action: "fee_plan.created", TargetType: "fee_plan", TargetID: "x",
			Metadata: map[string]any{"fields": []string{"name"}},
		})
	})
	var action, metadata, actor string
	in(t, s, tenant, func(ctx context.Context) error {
		return persistence.QueryRowForTest(ctx,
			"select action, metadata::text, actor_sub from finance.audit_event", &action, &metadata, &actor)
	})
	if action != "fee_plan.created" || metadata != `{"fields": ["name"]}` || actor != "sub-admin" {
		t.Errorf("stored %s %s %s", action, metadata, actor)
	}
	err := s.tx.InTenant(context.Background(), tenant, func(ctx context.Context) error {
		return persistence.ExecForTest(ctx, "update finance.audit_event set action = 'x'")
	})
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) || pgErr.Code != "42501" {
		t.Errorf("update of the audit trail: %v", err)
	}
	_ = database
}

func TestTheMembershipComesFromTheReplicaOfAnActiveAcademy(t *testing.T) {
	s := newStores(t)
	database := pgtest.Start(t)
	tenant := newTenant(t)
	person := randomUUID()
	insertTenantRef(t, database.App, tenant, "ACTIVE", false)
	insertPersonRef(t, database.App, tenant, person, "sub-1", []string{"PARENT", "ADMIN"}, true, false)
	insertPersonRef(t, database.App, tenant, randomUUID(), "sub-inactive", []string{"ADMIN"}, false, false)
	insertPersonRef(t, database.App, tenant, randomUUID(), "sub-removed", []string{"ADMIN"}, true, true)

	resolve := func(subject string) (domain.Membership, bool) {
		var m domain.Membership
		var ok bool
		in(t, s, tenant, func(ctx context.Context) error {
			var err error
			m, ok, err = s.members.Membership(ctx, tenant, subject)
			return err
		})
		return m, ok
	}
	m, ok := resolve("sub-1")
	if !ok || !m.Has(domain.Admin) || !m.Has(domain.Parent) || m.Person() != domain.PersonID(person) || m.Tenant() != tenant {
		t.Errorf("member: %+v %v", m, ok)
	}
	for _, subject := range []string{"sub-inactive", "sub-removed", "sub-unknown"} {
		if _, ok := resolve(subject); ok {
			t.Errorf("%s resolved", subject)
		}
	}
	suspended := newTenant(t)
	insertTenantRef(t, database.App, suspended, "SUSPENDED", false)
	insertPersonRef(t, database.App, suspended, randomUUID(), "sub-1", []string{"ADMIN"}, true, false)
	in(t, s, suspended, func(ctx context.Context) error {
		if _, ok, err := s.members.Membership(ctx, suspended, "sub-1"); ok || err != nil {
			t.Errorf("a suspended academy's member resolved: %v %v", ok, err)
		}
		return nil
	})
}

// The pool part of the commit hook's isolation check (counterpart of core's CrossTenantAccessTest under the API).
func TestCrossTenantRowsAreInvisibleInTheServicesOwnPool(t *testing.T) {
	s := newStores(t)
	database := pgtest.Start(t)
	a, b := newTenant(t), newTenant(t)
	team := domain.TeamID(randomUUID())
	planB := plan(t, "B's plan", &team, domain.SeasonID(randomUUID()))
	in(t, s, b, func(ctx context.Context) error { return s.plans.Insert(ctx, planB) })

	in(t, s, a, func(ctx context.Context) error {
		if _, found, err := s.plans.Get(ctx, planB.ID); found || err != nil {
			t.Errorf("A reads B's plan by id: %v %v", found, err)
		}
		plans, total, err := s.plans.List(ctx, application.FeePlanFilter{IncludeArchived: true}, application.Page{Size: 200})
		if err != nil || total != 0 || len(plans) != 0 {
			t.Errorf("A lists B's plans: %d %v", total, err)
		}
		if _, err := s.plans.Update(ctx, planB); !errors.Is(err, application.ErrConcurrentModification) {
			t.Errorf("A updated B's plan: %v", err)
		}
		return nil
	})
	var n int64
	err := database.App.QueryRow(context.Background(), "select count(*) from finance.fee_plan").Scan(&n)
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) || pgErr.Code != "42501" {
		t.Errorf("an unbound read in the app pool: %d %v", n, err)
	}
}
