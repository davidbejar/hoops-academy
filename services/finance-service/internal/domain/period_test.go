package domain

import (
	"errors"
	"testing"
	"time"
)

func day2026(month time.Month, d int) time.Time {
	return time.Date(2026, month, d, 0, 0, 0, 0, time.UTC)
}

func TestCadencesAreTheThreeOfDecision93(t *testing.T) {
	for _, text := range []string{"MONTHLY", "QUARTERLY", "SEASON"} {
		cadence, err := ParseCadence(text)
		if err != nil || string(cadence) != text {
			t.Errorf("%s: %v %v", text, cadence, err)
		}
	}
	for _, text := range []string{"", "monthly", "WEEKLY", "YEARLY"} {
		if _, err := ParseCadence(text); !errors.Is(err, ErrInvalid) {
			t.Errorf("%q accepted", text)
		}
	}
}

func TestAMonthlyPeriodIsACalendarMonth(t *testing.T) {
	period, err := ParsePeriod(Monthly, "2026-02")
	if err != nil {
		t.Fatal(err)
	}
	start, end, ok := period.Dates()
	if !ok || start != day2026(2, 1) || end != day2026(2, 28) || period.Key() != "2026-02" {
		t.Errorf("got %s %v..%v %v", period.Key(), start, end, ok)
	}
	if next := period.Next(); next.Key() != "2026-03" {
		t.Errorf("next: %s", next.Key())
	}
	december, _ := ParsePeriod(Monthly, "2026-12")
	if next := december.Next(); next.Key() != "2027-01" {
		t.Errorf("after december: %s", next.Key())
	}
}

func TestAQuarterlyPeriodIsACalendarQuarter(t *testing.T) {
	period, err := ParsePeriod(Quarterly, "2026-Q3")
	if err != nil {
		t.Fatal(err)
	}
	start, end, ok := period.Dates()
	if !ok || start != day2026(7, 1) || end != day2026(9, 30) {
		t.Errorf("got %v..%v %v", start, end, ok)
	}
	q4, _ := ParsePeriod(Quarterly, "2026-Q4")
	if next := q4.Next(); next.Key() != "2027-Q1" {
		t.Errorf("after Q4: %s", next.Key())
	}
	if !period.Before(q4) || q4.Before(period) || period.Before(period) {
		t.Error("order")
	}
}

func TestTheSeasonPeriodTakesItsDatesFromTheSeason(t *testing.T) {
	period, err := ParsePeriod(Season, "SEASON")
	if err != nil {
		t.Fatal(err)
	}
	if _, _, ok := period.Dates(); ok || period.Key() != "SEASON" || period.Cadence() != Season {
		t.Errorf("season period: %s %v", period.Key(), ok)
	}
	if next := period.Next(); next != period {
		t.Error("a season has one period")
	}
}

func TestPeriodKeysMustMatchTheirCadence(t *testing.T) {
	for cadence, keys := range map[Cadence][]string{
		Monthly:   {"", "2026-13", "2026-00", "2026-1", "26-01", "2026-Q1", "SEASON", "1999-01", "2101-01"},
		Quarterly: {"2026-Q0", "2026-Q5", "2026-03", "2026-q1", "SEASON"},
		Season:    {"2026-01", "season", ""},
	} {
		for _, key := range keys {
			if _, err := ParsePeriod(cadence, key); !errors.Is(err, ErrInvalid) {
				t.Errorf("%s %q accepted", cadence, key)
			}
		}
	}
}
