package domain

import (
	"sort"
	"time"
)

// SeasonDates are a season's first and last day (dates as UTC midnight), from the team replica.
type SeasonDates struct{ Start, End time.Time }

// DueWindow is one period of a plan and its days: the period's intersection with the season (ADR-0056).
type DueWindow struct {
	Period     Period
	Start, End time.Time
}

// Window is the plan's period key within season: a key of another cadence is invalid (400), a period outside the
// plan's first and last period 422 PERIOD_OUTSIDE_PLAN, one without a day in the season 422 PERIOD_OUTSIDE_SEASON.
func (p FeePlan) Window(key string, season SeasonDates) (DueWindow, error) {
	period, err := ParsePeriod(p.Cadence, key)
	if err != nil {
		return DueWindow{}, err
	}
	if !p.covers(period) {
		return DueWindow{}, RuleViolation("PERIOD_OUTSIDE_PLAN", "the period lies outside the plan's periods")
	}
	window, ok := windowOf(period, season)
	if !ok {
		return DueWindow{}, RuleViolation("PERIOD_OUTSIDE_SEASON", "the period has no day in the plan's season")
	}
	return window, nil
}

func (p FeePlan) covers(period Period) bool {
	return (p.First == nil || !period.Before(*p.First)) && (p.Last == nil || !p.Last.Before(period))
}

// windowOf intersects period with season; ok is false when they share no day.
func windowOf(period Period, season SeasonDates) (DueWindow, bool) {
	start, end, dated := period.Dates()
	if !dated {
		start, end = season.Start, season.End
	}
	if start.Before(season.Start) {
		start = season.Start
	}
	if end.After(season.End) {
		end = season.End
	}
	return DueWindow{Period: period, Start: start, End: end}, !start.After(end)
}

// StartedWindows are the windows the daily job generates on today (the academy's date): every period of the plan
// that has a day in the season and has started (its first day on or before today). Earlier periods are included, so
// a player added to the roster afterwards still owes them (a re-run creates only what is missing).
func (p FeePlan) StartedWindows(season SeasonDates, today time.Time) []DueWindow {
	if p.Cadence == Season {
		window, ok := windowOf(Period{cadence: Season}, season)
		if !ok || window.Start.After(today) {
			return nil
		}
		return []DueWindow{window}
	}
	var windows []DueWindow
	for period := *p.First; p.covers(period); period = period.Next() {
		window, ok := windowOf(period, season)
		if window.Start.After(today) || window.Start.After(season.End) {
			break
		}
		if ok {
			windows = append(windows, window)
		}
	}
	return windows
}

// Candidate is a player found on the roster of a plan's target during a window, through one team.
type Candidate struct {
	Player PlayerID
	Team   TeamID
	Name   string
}

// OncePerPlayer keeps each player's first candidate (a player on two teams of one category owes once, through the
// first team found) and orders them by name, then player id.
func OncePerPlayer(candidates []Candidate) []Candidate {
	seen := map[PlayerID]bool{}
	var once []Candidate
	for _, c := range candidates {
		if !seen[c.Player] {
			seen[c.Player] = true
			once = append(once, c)
		}
	}
	sort.SliceStable(once, func(i, j int) bool {
		if once[i].Name != once[j].Name {
			return once[i].Name < once[j].Name
		}
		return once[i].Player.String() < once[j].Player.String()
	})
	return once
}

// MaxDuesPerGeneration bounds one generation (the contract's maxItems): more is a mistake in the plan's target.
const MaxDuesPerGeneration = 2000

// CheckGenerationSize refuses more than MaxDuesPerGeneration new dues (422 TOO_MANY_DUES).
func CheckGenerationSize(count int) error {
	if count > MaxDuesPerGeneration {
		return RuleViolation("TOO_MANY_DUES", "one generation creates at most 2000 dues")
	}
	return nil
}

// Today is now's date in zone (nil = UTC), as UTC midnight like every date of the domain.
func Today(now time.Time, zone *time.Location) time.Time {
	if zone == nil {
		zone = time.UTC
	}
	y, m, d := now.In(zone).Date()
	return time.Date(y, m, d, 0, 0, 0, 0, time.UTC)
}
