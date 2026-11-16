package application

import (
	"context"
	"errors"
	"slices"
	"testing"
	"time"

	"hoopsacademy.local/finance/internal/domain"
)

var (
	now        = time.Date(2026, 11, 16, 9, 0, 0, 0, time.UTC)
	tenant, _  = domain.ParseTenantID("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")
	season, _  = domain.ParseUUID("22222222-2222-4222-8222-222222222222")
	team, _    = domain.ParseUUID("33333333-3333-4333-8333-333333333333")
	personA, _ = domain.ParseUUID("55555555-5555-4555-8555-555555555555")
	ctx        = context.Background()
)

type fixture struct {
	finance  *Finance
	tx       *fakeTransactions
	settings *fakeSettings
	plans    *fakePlans
	dues     *fakeDues
	audit    *fakeAudit
}

func newFixture() fixture {
	f := fixture{
		tx: &fakeTransactions{}, settings: &fakeSettings{}, plans: newFakePlans(),
		dues: &fakeDues{plans: map[domain.FeePlanID]bool{}}, audit: &fakeAudit{},
	}
	f.finance = NewFinance(Ports{
		Clock: fixedClock{now}, IDs: &sequenceIDs{}, Transactions: f.tx, Settings: f.settings, FeePlans: f.plans,
		Dues: f.dues, Audit: f.audit,
		Members: &fakeMembers{members: map[string]domain.Membership{"admin": caller(domain.Admin)}},
	})
	return f
}

func caller(roles ...domain.Role) domain.Membership {
	return domain.NewMembership("sub-"+string(rune('0'+len(roles))), domain.PersonID(personA), tenant, roles)
}

var admin = caller(domain.Admin)

func withEuro(f fixture) {
	eur, _ := domain.ParseCurrency("EUR")
	f.settings.settings = &domain.Settings{Currency: eur}
}

func teamPlan() FeePlanCommand {
	first, last := "2026-09", "2027-06"
	teamID := domain.TeamID(team)
	return FeePlanCommand{Input: domain.FeePlanInput{
		Name: "U12 monthly", Season: domain.SeasonID(season), Team: &teamID, AmountMinor: 4500, Cadence: "MONTHLY",
		FirstPeriod: &first, LastPeriod: &last, AutoGenerate: true,
	}}
}

func requireKind(t *testing.T, err error, kind domain.Kind, code string) {
	t.Helper()
	var problem *domain.Error
	if !errors.As(err, &problem) || problem.Kind != kind || (code != "" && problem.Code != code) {
		t.Fatalf("expected kind %d code %q, got %v", kind, code, err)
	}
}

func TestEveryUseCaseRunsInATransactionBoundToTheCallersTenant(t *testing.T) {
	f := newFixture()
	withEuro(f)

	_, _ = f.finance.Settings(ctx, admin)
	plan, _ := f.finance.CreateFeePlan(ctx, admin, teamPlan())
	_, _ = f.finance.FeePlan(ctx, admin, plan.Plan.ID)

	if len(f.tx.bound) != 3 || slices.ContainsFunc(f.tx.bound, func(b domain.TenantID) bool { return b != tenant }) {
		t.Errorf("bound %v", f.tx.bound)
	}
}

func TestMembersWithoutTheAdminRoleAreRefusedEveryFinanceWrite(t *testing.T) {
	f := newFixture()
	withEuro(f)
	created, _ := f.finance.CreateFeePlan(ctx, admin, teamPlan())
	id := created.Plan.ID
	name := "x"
	for _, role := range []domain.Role{domain.Coach, domain.AssistantCoach, domain.Parent, domain.Player} {
		member := caller(role)
		calls := map[string]error{
			"settings":    errOf(f.finance.Settings(ctx, member)),
			"setCurrency": errOf(f.finance.UpdateSettings(ctx, member, "EUR")),
			"list":        errOf(f.finance.ListFeePlans(ctx, member, FeePlanFilter{}, Page{Size: 10})),
			"create":      errOf(f.finance.CreateFeePlan(ctx, member, teamPlan())),
			"get":         errOf(f.finance.FeePlan(ctx, member, id)),
			"update":      errOf(f.finance.UpdateFeePlan(ctx, member, id, domain.FeePlanChanges{Name: &name})),
			"archive":     errOf(f.finance.ArchiveFeePlan(ctx, member, id)),
			"unarchive":   errOf(f.finance.UnarchiveFeePlan(ctx, member, id)),
			"delete":      f.finance.DeleteFeePlan(ctx, member, id),
		}
		for name, err := range calls {
			var problem *domain.Error
			if !errors.As(err, &problem) || problem.Kind != domain.KindForbidden || problem.Code != DeniedByRole {
				t.Errorf("%s %s: %v", role, name, err)
			}
		}
	}
	if len(f.audit.events) != 1 {
		t.Errorf("a refused call wrote an audit record: %+v", f.audit.events)
	}
}

func TestSettingsWithoutACurrencyYet(t *testing.T) {
	f := newFixture()

	view, err := f.finance.Settings(ctx, admin)
	if err != nil || view.Currency != nil || view.Locked {
		t.Errorf("got %+v %v", view, err)
	}
}

func TestChoosingTheCurrencyIsAuditedWithoutValues(t *testing.T) {
	f := newFixture()

	view, err := f.finance.UpdateSettings(ctx, admin, "IDR")
	if err != nil || view.Currency.Code() != "IDR" || view.Locked {
		t.Fatalf("got %+v %v", view, err)
	}
	if len(f.audit.events) != 1 {
		t.Fatalf("audit: %+v", f.audit.events)
	}
	e := f.audit.events[0]
	if e.Action != "finance.settings_changed" || e.TargetType != "finance_settings" || e.TargetID != tenant.String() ||
		!slices.Equal(e.Metadata["fields"].([]string), []string{"currency"}) || e.Actor.Subject() != admin.Subject() {
		t.Errorf("audit event %+v", e)
	}
	again, err := f.finance.UpdateSettings(ctx, admin, "IDR")
	if err != nil || again.Currency.Code() != "IDR" || len(f.audit.events) != 1 || f.settings.saves != 1 {
		t.Errorf("the same currency again is no change: %v, %d events, %d saves", err, len(f.audit.events), f.settings.saves)
	}
}

func TestTheCurrencyIsLockedOnceADueExists(t *testing.T) {
	f := newFixture()
	withEuro(f)
	f.dues.any = true

	view, err := f.finance.Settings(ctx, admin)
	if err != nil || !view.Locked {
		t.Errorf("locked flag: %+v %v", view, err)
	}
	_, err = f.finance.UpdateSettings(ctx, admin, "USD")
	requireKind(t, err, domain.KindConflict, "CURRENCY_LOCKED")
	_, err = f.finance.UpdateSettings(ctx, admin, "usd")
	requireKind(t, err, domain.KindInvalid, "VALIDATION_FAILED")
	_, err = f.finance.UpdateSettings(ctx, admin, "XTS")
	requireKind(t, err, domain.KindRule, "UNKNOWN_CURRENCY")
}

func TestAFeePlanNeedsTheCurrencyFirst(t *testing.T) {
	f := newFixture()

	_, err := f.finance.CreateFeePlan(ctx, admin, teamPlan())
	requireKind(t, err, domain.KindConflict, "CURRENCY_NOT_SET")
}

func TestCreatingAFeePlanStoresAndAuditsIt(t *testing.T) {
	f := newFixture()
	withEuro(f)

	view, err := f.finance.CreateFeePlan(ctx, admin, teamPlan())
	if err != nil {
		t.Fatal(err)
	}
	if view.Currency.Code() != "EUR" || view.HasDues || view.Plan.CreatedAt != now || view.Plan.ID.String() == "" {
		t.Errorf("got %+v", view)
	}
	if _, ok := f.plans.plans[view.Plan.ID]; !ok {
		t.Error("not stored")
	}
	e := f.audit.events[0]
	if e.Action != "fee_plan.created" || e.TargetType != "fee_plan" || e.TargetID != view.Plan.ID.String() ||
		e.Metadata["cadence"] != "MONTHLY" {
		t.Errorf("audit %+v", e)
	}
}

func TestAnInvalidPlanIsRefusedWithItsViolations(t *testing.T) {
	f := newFixture()
	withEuro(f)
	command := teamPlan()
	command.Input.Name = ""

	_, err := f.finance.CreateFeePlan(ctx, admin, command)
	requireKind(t, err, domain.KindInvalid, "VALIDATION_FAILED")
	if len(f.plans.plans) != 0 || len(f.audit.events) != 0 {
		t.Error("an invalid plan left traces")
	}
}

func TestAnUnknownPlanIsNotFound(t *testing.T) {
	f := newFixture()
	withEuro(f)
	unknown := domain.FeePlanID(personA)
	name := "x"

	for name, err := range map[string]error{
		"get":     errOf(f.finance.FeePlan(ctx, admin, unknown)),
		"update":  errOf(f.finance.UpdateFeePlan(ctx, admin, unknown, domain.FeePlanChanges{Name: &name})),
		"archive": errOf(f.finance.ArchiveFeePlan(ctx, admin, unknown)),
		"delete":  f.finance.DeleteFeePlan(ctx, admin, unknown),
	} {
		var problem *domain.Error
		if !errors.As(err, &problem) || problem.Kind != domain.KindNotFound {
			t.Errorf("%s: %v", name, err)
		}
	}
}

func TestUpdatingAPlanAuditsTheChangedFieldNamesOnly(t *testing.T) {
	f := newFixture()
	withEuro(f)
	created, _ := f.finance.CreateFeePlan(ctx, admin, teamPlan())
	name, amount := "Renamed", int64(5000)

	view, err := f.finance.UpdateFeePlan(ctx, admin, created.Plan.ID, domain.FeePlanChanges{Name: &name, AmountMinor: &amount})
	if err != nil || view.Plan.Name != "Renamed" || view.Plan.Version != 1 {
		t.Fatalf("got %+v %v", view, err)
	}
	e := f.audit.events[1]
	if e.Action != "fee_plan.updated" || !slices.Equal(e.Metadata["fields"].([]string), []string{"amountMinor", "name"}) {
		t.Errorf("audit %+v", e)
	}
	if _, err := f.finance.UpdateFeePlan(ctx, admin, created.Plan.ID, domain.FeePlanChanges{Name: &name}); err != nil ||
		len(f.audit.events) != 2 {
		t.Errorf("no change, no audit: %v %d", err, len(f.audit.events))
	}
}

func TestAConcurrentChangeIsAConflict(t *testing.T) {
	f := newFixture()
	withEuro(f)
	created, _ := f.finance.CreateFeePlan(ctx, admin, teamPlan())
	f.plans.stale = true
	name := "Renamed"

	_, err := f.finance.UpdateFeePlan(ctx, admin, created.Plan.ID, domain.FeePlanChanges{Name: &name})
	requireKind(t, err, domain.KindConflict, "CONCURRENT_MODIFICATION")
}

func TestTheFirstPeriodIsFixedAndTheDeleteRefusedOnceDuesExist(t *testing.T) {
	f := newFixture()
	withEuro(f)
	created, _ := f.finance.CreateFeePlan(ctx, admin, teamPlan())
	f.dues.plans[created.Plan.ID] = true
	first := "2026-10"

	view, err := f.finance.FeePlan(ctx, admin, created.Plan.ID)
	if err != nil || !view.HasDues {
		t.Errorf("hasDues: %+v %v", view, err)
	}
	_, err = f.finance.UpdateFeePlan(ctx, admin, created.Plan.ID, domain.FeePlanChanges{FirstPeriod: &first})
	requireKind(t, err, domain.KindConflict, "FEE_PLAN_HAS_DUES")
	requireKind(t, f.finance.DeleteFeePlan(ctx, admin, created.Plan.ID), domain.KindConflict, "FEE_PLAN_HAS_DUES")
}

func TestArchivingIsIdempotentAndAuditedOnlyWhenItChanges(t *testing.T) {
	f := newFixture()
	withEuro(f)
	created, _ := f.finance.CreateFeePlan(ctx, admin, teamPlan())

	archived, err := f.finance.ArchiveFeePlan(ctx, admin, created.Plan.ID)
	if err != nil || !archived.Plan.Archived {
		t.Fatalf("%+v %v", archived, err)
	}
	_, _ = f.finance.ArchiveFeePlan(ctx, admin, created.Plan.ID)
	restored, err := f.finance.UnarchiveFeePlan(ctx, admin, created.Plan.ID)
	if err != nil || restored.Plan.Archived {
		t.Fatalf("%+v %v", restored, err)
	}
	var actions []string
	for _, e := range f.audit.events {
		actions = append(actions, e.Action)
	}
	if !slices.Equal(actions, []string{"fee_plan.created", "fee_plan.archived", "fee_plan.unarchived"}) {
		t.Errorf("actions %v", actions)
	}
}

func TestDeletingAPlanWithoutDues(t *testing.T) {
	f := newFixture()
	withEuro(f)
	created, _ := f.finance.CreateFeePlan(ctx, admin, teamPlan())

	if err := f.finance.DeleteFeePlan(ctx, admin, created.Plan.ID); err != nil {
		t.Fatal(err)
	}
	if len(f.plans.plans) != 0 || f.audit.events[1].Action != "fee_plan.deleted" {
		t.Errorf("plans %v audit %+v", f.plans.plans, f.audit.events)
	}
}

func TestListingPassesTheFilterAndMarksPlansWithDues(t *testing.T) {
	f := newFixture()
	withEuro(f)
	a, _ := f.finance.CreateFeePlan(ctx, admin, teamPlan())
	second := teamPlan()
	second.Input.Name = "A first"
	b, _ := f.finance.CreateFeePlan(ctx, admin, second)
	f.dues.plans[a.Plan.ID] = true
	filter := FeePlanFilter{IncludeArchived: true}

	page, err := f.finance.ListFeePlans(ctx, admin, filter, Page{Index: 0, Size: 1})
	if err != nil {
		t.Fatal(err)
	}
	if page.Total != 2 || len(page.Items) != 1 || page.Items[0].Plan.ID != b.Plan.ID || page.Items[0].HasDues ||
		page.Items[0].Currency.Code() != "EUR" || f.plans.lastList != filter {
		t.Errorf("page %+v", page)
	}
}

func TestTheTenantFilterResolvesMembershipsInsideTheTenant(t *testing.T) {
	f := newFixture()

	member, ok, err := f.finance.ResolveMembership(ctx, tenant, "admin")
	if err != nil || !ok || !member.Has(domain.Admin) {
		t.Errorf("admin: %v %v %v", member, ok, err)
	}
	if _, ok, _ := f.finance.ResolveMembership(ctx, tenant, "stranger"); ok {
		t.Error("a stranger resolved")
	}
	if len(f.tx.bound) != 2 || f.tx.bound[0] != tenant {
		t.Errorf("bound %v", f.tx.bound)
	}
	f.tx.fail = errors.New("database down")
	if _, _, err := f.finance.ResolveMembership(ctx, tenant, "admin"); err == nil {
		t.Error("the failure was swallowed")
	}
}

func errOf[T any](_ T, err error) error { return err }
