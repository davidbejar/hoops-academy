package domain

import (
	"errors"
	"slices"
	"strings"
	"testing"
	"time"
)

var (
	created  = time.Date(2026, 11, 16, 10, 0, 0, 0, time.UTC)
	later    = created.Add(time.Hour)
	planID   = FeePlanID(mustUUID("11111111-1111-4111-8111-111111111111"))
	seasonID = SeasonID(mustUUID("22222222-2222-4222-8222-222222222222"))
	teamID   = TeamID(mustUUID("33333333-3333-4333-8333-333333333333"))
	category = AgeCategoryID(mustUUID("44444444-4444-4444-8444-444444444444"))
)

func mustUUID(text string) UUID {
	id, err := ParseUUID(text)
	if err != nil {
		panic(err)
	}
	return id
}

func strPtr(s string) *string { return &s }

func monthlyInput() FeePlanInput {
	return FeePlanInput{
		Name: "  Monthly fee U12  ", Season: seasonID, Team: &teamID, AmountMinor: 4500, Cadence: "MONTHLY",
		FirstPeriod: strPtr("2026-09"), LastPeriod: strPtr("2027-06"), AutoGenerate: true,
	}
}

func violationsOf(t *testing.T, err error) []Violation {
	t.Helper()
	var problem *Error
	if !errors.As(err, &problem) || problem.Kind != KindInvalid {
		t.Fatalf("expected an invalid input, got %v", err)
	}
	return problem.Violations
}

func TestAFeePlanForATeamChargesAnAmountPerPeriodOfItsCadence(t *testing.T) {
	plan, err := NewFeePlan(planID, monthlyInput(), created)
	if err != nil {
		t.Fatal(err)
	}
	if plan.Name != "Monthly fee U12" || plan.Amount.Minor() != 4500 || plan.Cadence != Monthly ||
		plan.First.Key() != "2026-09" || plan.Last.Key() != "2027-06" || !plan.AutoGenerate || plan.Archived ||
		*plan.Target.Team != teamID || plan.Target.AgeCategory != nil || plan.CreatedAt != created ||
		plan.UpdatedAt != created {
		t.Errorf("got %+v", plan)
	}
}

func TestAFeePlanForAnAgeCategoryOnceASeason(t *testing.T) {
	plan, err := NewFeePlan(planID, FeePlanInput{
		Name: "Season fee", Season: seasonID, AgeCategory: &category, AmountMinor: 30000, Cadence: "SEASON",
	}, created)
	if err != nil {
		t.Fatal(err)
	}
	if plan.First != nil || plan.Last != nil || *plan.Target.AgeCategory != category || plan.Target.Team != nil {
		t.Errorf("got %+v", plan)
	}
}

func TestAFeePlanNamesEveryInvalidFieldAtOnce(t *testing.T) {
	violations := violationsOf(t, errOf(NewFeePlan(planID, FeePlanInput{
		Name: "   ", Season: seasonID, Team: &teamID, AgeCategory: &category, AmountMinor: 0, Cadence: "WEEKLY",
	}, created)))

	for _, want := range []Violation{
		{Field: "name", Code: "REQUIRED"},
		{Field: "teamId", Code: "ONE_TARGET_REQUIRED"},
		{Field: "amountMinor", Code: "OUT_OF_RANGE"},
		{Field: "cadence", Code: "INVALID"},
	} {
		if !slices.Contains(violations, want) {
			t.Errorf("missing %+v in %+v", want, violations)
		}
	}
}

func TestFeePlanPeriodsFollowTheCadence(t *testing.T) {
	cases := []struct {
		name        string
		cadence     string
		first, last *string
		want        Violation
	}{
		{"monthly needs a first period", "MONTHLY", nil, nil, Violation{"firstPeriod", "REQUIRED"}},
		{"quarter key on a monthly plan", "MONTHLY", strPtr("2026-Q1"), nil, Violation{"firstPeriod", "INVALID"}},
		{"last before first", "MONTHLY", strPtr("2026-09"), strPtr("2026-08"), Violation{"lastPeriod", "BEFORE_FIRST_PERIOD"}},
		{"bad last", "QUARTERLY", strPtr("2026-Q1"), strPtr("2026-13"), Violation{"lastPeriod", "INVALID"}},
		{"season takes no first", "SEASON", strPtr("2026-09"), nil, Violation{"firstPeriod", "NOT_ALLOWED"}},
		{"season takes no last", "SEASON", nil, strPtr("2026-09"), Violation{"lastPeriod", "NOT_ALLOWED"}},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			input := monthlyInput()
			input.Cadence, input.FirstPeriod, input.LastPeriod = c.cadence, c.first, c.last
			violations := violationsOf(t, errOf(NewFeePlan(planID, input, created)))
			if !slices.Contains(violations, c.want) {
				t.Errorf("missing %+v in %+v", c.want, violations)
			}
		})
	}
}

func TestANameLongerThan80CharactersIsRefused(t *testing.T) {
	input := monthlyInput()
	input.Name = strings.Repeat("x", 81)
	if v := violationsOf(t, errOf(NewFeePlan(planID, input, created))); !slices.Contains(v, Violation{"name", "TOO_LONG"}) {
		t.Errorf("got %+v", v)
	}
	input.Name = strings.Repeat("ñ", 80)
	if _, err := NewFeePlan(planID, input, created); err != nil {
		t.Errorf("80 characters (not bytes) must pass: %v", err)
	}
}

func TestChangingAFeePlanReportsTheChangedFieldsAndBumpsUpdatedAt(t *testing.T) {
	plan, _ := NewFeePlan(planID, monthlyInput(), created)
	off := false

	changed, fields, err := plan.Change(FeePlanChanges{
		Name: strPtr("New name"), AmountMinor: ptr(int64(5000)), AutoGenerate: &off, ClearLastPeriod: true,
	}, false, later)
	if err != nil {
		t.Fatal(err)
	}
	if changed.Name != "New name" || changed.Amount.Minor() != 5000 || changed.AutoGenerate || changed.Last != nil ||
		changed.UpdatedAt != later || changed.CreatedAt != created {
		t.Errorf("got %+v", changed)
	}
	if !slices.Equal(fields, []string{"amountMinor", "autoGenerate", "lastPeriod", "name"}) {
		t.Errorf("fields %v", fields)
	}
	same, none, err := plan.Change(FeePlanChanges{Name: strPtr("Monthly fee U12")}, false, later)
	if err != nil || len(none) != 0 || same.UpdatedAt != created {
		t.Errorf("an unchanged value is no change: %v %v %v", same.UpdatedAt, none, err)
	}
}

func TestTheFirstPeriodIsFixedOnceThePlanHasDues(t *testing.T) {
	plan, _ := NewFeePlan(planID, monthlyInput(), created)

	if moved, _, err := plan.Change(FeePlanChanges{FirstPeriod: strPtr("2026-10")}, false, later); err != nil ||
		moved.First.Key() != "2026-10" {
		t.Errorf("without dues: %v", err)
	}
	var problem *Error
	if _, _, err := plan.Change(FeePlanChanges{FirstPeriod: strPtr("2026-10")}, true, later); !errors.As(err, &problem) ||
		problem.Code != "FEE_PLAN_HAS_DUES" || problem.Kind != KindConflict {
		t.Errorf("with dues: %v", err)
	}
	if _, _, err := plan.Change(FeePlanChanges{LastPeriod: strPtr("2027-03")}, true, later); err != nil {
		t.Errorf("the last period may move while dues exist: %v", err)
	}
}

func TestChangesAreValidatedLikeANewPlan(t *testing.T) {
	plan, _ := NewFeePlan(planID, monthlyInput(), created)
	cases := map[string]FeePlanChanges{
		"lastPeriod":  {LastPeriod: strPtr("2026-01")},
		"amountMinor": {AmountMinor: ptr(int64(-5))},
		"name":        {Name: strPtr("")},
		"clear":       {LastPeriod: strPtr("2027-01"), ClearLastPeriod: true},
	}
	for field, changes := range cases {
		if _, _, err := plan.Change(changes, false, later); err == nil {
			t.Errorf("%s accepted", field)
		}
	}
	season, _ := NewFeePlan(planID, FeePlanInput{Name: "S", Season: seasonID, Team: &teamID, AmountMinor: 1, Cadence: "SEASON"}, created)
	if _, _, err := season.Change(FeePlanChanges{LastPeriod: strPtr("2026-01")}, false, later); err == nil {
		t.Error("a season plan took a last period")
	}
}

func TestArchivingStopsGenerationAndDeletingNeedsAPlanWithoutDues(t *testing.T) {
	plan, _ := NewFeePlan(planID, monthlyInput(), created)

	archived, changed := plan.Archive(later)
	if !archived.Archived || !changed || archived.UpdatedAt != later || archived.GeneratesAutomatically() {
		t.Errorf("archive: %+v %v", archived, changed)
	}
	if _, again := archived.Archive(later); again {
		t.Error("archiving twice changed something")
	}
	restored, changed := archived.Unarchive(later)
	if restored.Archived || !changed || !restored.GeneratesAutomatically() {
		t.Errorf("unarchive: %+v", restored)
	}
	if _, again := plan.Unarchive(later); again {
		t.Error("unarchiving an active plan changed something")
	}
	if err := plan.CheckDeletable(false); err != nil {
		t.Errorf("no dues: %v", err)
	}
	var problem *Error
	if err := plan.CheckDeletable(true); !errors.As(err, &problem) || problem.Code != "FEE_PLAN_HAS_DUES" {
		t.Errorf("with dues: %v", err)
	}
}

func ptr[T any](v T) *T { return &v }

func errOf[T any](_ T, err error) error { return err }
