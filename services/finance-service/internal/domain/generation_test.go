package domain

import (
	"slices"
	"testing"
	"time"
)

func date(y int, m time.Month, d int) time.Time { return time.Date(y, m, d, 0, 0, 0, 0, time.UTC) }

// The season of the fixtures: 15 September 2026 to 30 June 2027.
var season2627 = SeasonDates{Start: date(2026, time.September, 15), End: date(2027, time.June, 30)}

func planOf(t *testing.T, cadence string, first, last *string) FeePlan {
	t.Helper()
	input := monthlyInput()
	input.Cadence, input.FirstPeriod, input.LastPeriod = cadence, first, last
	plan, err := NewFeePlan(planID, input, created)
	if err != nil {
		t.Fatal(err)
	}
	return plan
}

func TestAWindowIsThePeriodsIntersectionWithTheSeason(t *testing.T) {
	monthly := planOf(t, "MONTHLY", strPtr("2026-09"), nil)
	quarterly := planOf(t, "QUARTERLY", strPtr("2026-Q3"), strPtr("2027-Q2"))
	once := planOf(t, "SEASON", nil, nil)
	for _, c := range []struct {
		plan       FeePlan
		key        string
		start, end time.Time
	}{
		{monthly, "2026-09", date(2026, time.September, 15), date(2026, time.September, 30)},
		{monthly, "2026-11", date(2026, time.November, 1), date(2026, time.November, 30)},
		{monthly, "2027-06", date(2027, time.June, 1), date(2027, time.June, 30)},
		{quarterly, "2026-Q3", date(2026, time.September, 15), date(2026, time.September, 30)},
		{quarterly, "2027-Q2", date(2027, time.April, 1), date(2027, time.June, 30)},
		{once, "SEASON", season2627.Start, season2627.End},
	} {
		window, err := c.plan.Window(c.key, season2627)
		if err != nil || window.Period.Key() != c.key || !window.Start.Equal(c.start) || !window.End.Equal(c.end) {
			t.Errorf("%s: %+v %v", c.key, window, err)
		}
	}
}

func TestAWindowOutsideThePlanOrTheSeasonIsRefused(t *testing.T) {
	monthly := planOf(t, "MONTHLY", strPtr("2026-10"), strPtr("2027-03"))

	if v := violationsOf(t, errOnly(monthly.Window("2026-Q4", season2627))); !slices.Equal(v, []Violation{{"period", "INVALID"}}) {
		t.Errorf("another cadence: %v", v)
	}
	requireError(t, errOnly(monthly.Window("2026-09", season2627)), KindRule, "PERIOD_OUTSIDE_PLAN")
	requireError(t, errOnly(monthly.Window("2027-04", season2627)), KindRule, "PERIOD_OUTSIDE_PLAN")
	open := planOf(t, "MONTHLY", strPtr("2026-01"), nil)
	requireError(t, errOnly(open.Window("2026-08", season2627)), KindRule, "PERIOD_OUTSIDE_SEASON")
	requireError(t, errOnly(open.Window("2027-07", season2627)), KindRule, "PERIOD_OUTSIDE_SEASON")
}

func keys(windows []DueWindow) []string {
	out := make([]string, len(windows))
	for i, w := range windows {
		out[i] = w.Period.Key()
	}
	return out
}

func TestTheJobsWindowsAreThePlansStartedPeriodsWithinTheSeason(t *testing.T) {
	for _, c := range []struct {
		name  string
		plan  FeePlan
		today time.Time
		want  []string
	}{
		{"monthly, mid November", planOf(t, "MONTHLY", strPtr("2026-01"), nil), date(2026, time.November, 16),
			[]string{"2026-09", "2026-10", "2026-11"}},
		{"monthly, the first day of a month", planOf(t, "MONTHLY", strPtr("2026-10"), nil), date(2026, time.December, 1),
			[]string{"2026-10", "2026-11", "2026-12"}},
		{"monthly, bounded by the last period", planOf(t, "MONTHLY", strPtr("2026-09"), strPtr("2026-10")),
			date(2027, time.March, 1), []string{"2026-09", "2026-10"}},
		{"monthly, after the season", planOf(t, "MONTHLY", strPtr("2027-05"), nil), date(2027, time.August, 1),
			[]string{"2027-05", "2027-06"}},
		{"monthly, before the season", planOf(t, "MONTHLY", strPtr("2026-09"), nil), date(2026, time.September, 14), nil},
		{"monthly, the season's first day", planOf(t, "MONTHLY", strPtr("2026-09"), nil), date(2026, time.September, 15),
			[]string{"2026-09"}},
		{"quarterly", planOf(t, "QUARTERLY", strPtr("2026-Q3"), nil), date(2027, time.January, 1),
			[]string{"2026-Q3", "2026-Q4", "2027-Q1"}},
		{"season, started", planOf(t, "SEASON", nil, nil), date(2026, time.September, 15), []string{"SEASON"}},
		{"season, not yet", planOf(t, "SEASON", nil, nil), date(2026, time.September, 1), nil},
	} {
		if got := keys(c.plan.StartedWindows(season2627, c.today)); !slices.Equal(got, c.want) {
			t.Errorf("%s: %v, want %v", c.name, got, c.want)
		}
	}
}

func TestAPlayerOnTwoTeamsOwesOnceThroughTheFirstTeamFound(t *testing.T) {
	other := TeamID(mustUUID("33333333-3333-4333-8333-333333333334"))
	ana := PlayerID(mustUUID("88888888-8888-4888-8888-888888888881"))
	bea := PlayerID(mustUUID("88888888-8888-4888-8888-888888888882"))

	got := OncePerPlayer([]Candidate{
		{Player: bea, Team: teamID, Name: "Bea"},
		{Player: ana, Team: other, Name: "Ana"},
		{Player: bea, Team: other, Name: "Bea"},
		{Player: ana, Team: teamID, Name: "Ana"},
	})

	want := []Candidate{{Player: ana, Team: other, Name: "Ana"}, {Player: bea, Team: teamID, Name: "Bea"}}
	if !slices.Equal(got, want) {
		t.Errorf("%v", got)
	}
}

func TestAGenerationCreatesAt2000Dues(t *testing.T) {
	if err := CheckGenerationSize(MaxDuesPerGeneration); err != nil {
		t.Error(err)
	}
	requireError(t, CheckGenerationSize(MaxDuesPerGeneration+1), KindRule, "TOO_MANY_DUES")
}

func TestTodayIsTheDateInTheAcademysZone(t *testing.T) {
	instant := time.Date(2026, 11, 30, 23, 30, 0, 0, time.UTC)
	jakarta := time.FixedZone("WIB", 7*3600)
	newYork := time.FixedZone("EST", -5*3600)

	if got := Today(instant, jakarta); !got.Equal(date(2026, time.December, 1)) {
		t.Errorf("Jakarta: %v", got)
	}
	if got := Today(instant, newYork); !got.Equal(date(2026, time.November, 30)) {
		t.Errorf("New York: %v", got)
	}
	if got := Today(instant, nil); !got.Equal(date(2026, time.November, 30)) {
		t.Errorf("no zone is UTC: %v", got)
	}
}
