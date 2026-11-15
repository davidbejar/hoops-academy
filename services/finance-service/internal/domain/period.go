package domain

import (
	"fmt"
	"regexp"
	"strconv"
	"time"
)

// Cadence is how often a fee plan charges (decision 93).
type Cadence string

// The cadences.
const (
	Monthly   Cadence = "MONTHLY"
	Quarterly Cadence = "QUARTERLY"
	Season    Cadence = "SEASON"
)

// ParseCadence reads MONTHLY, QUARTERLY or SEASON.
func ParseCadence(text string) (Cadence, error) {
	switch c := Cadence(text); c {
	case Monthly, Quarterly, Season:
		return c, nil
	default:
		return "", invalid("cadence", "INVALID")
	}
}

// Period is one period of a cadence (ADR-0056): a calendar month "YYYY-MM", a calendar quarter "YYYY-Qn" (Q1 =
// January to March), or the one period "SEASON" of a season plan, whose dates are the season's.
type Period struct {
	cadence Cadence
	year    int
	index   int // month 1..12 or quarter 1..4; 0 for SEASON
}

// SeasonKey is the key of the one period of a SEASON plan.
const SeasonKey = "SEASON"

const (
	minYear = 2000
	maxYear = 2100
)

var (
	monthKey   = regexp.MustCompile(`^([0-9]{4})-(0[1-9]|1[0-2])$`)
	quarterKey = regexp.MustCompile(`^([0-9]{4})-Q([1-4])$`)
)

// ParsePeriod reads the key of a period of cadence; a key of another cadence, or a year outside 2000..2100, is
// invalid.
func ParsePeriod(cadence Cadence, key string) (Period, error) {
	var match []string
	switch cadence {
	case Monthly:
		match = monthKey.FindStringSubmatch(key)
	case Quarterly:
		match = quarterKey.FindStringSubmatch(key)
	case Season:
		if key == SeasonKey {
			return Period{cadence: Season}, nil
		}
	}
	if match == nil {
		return Period{}, invalid("period", "INVALID")
	}
	year, _ := strconv.Atoi(match[1])
	index, _ := strconv.Atoi(match[2])
	if year < minYear || year > maxYear {
		return Period{}, invalid("period", "INVALID")
	}
	return Period{cadence: cadence, year: year, index: index}, nil
}

// Cadence is the period's cadence.
func (p Period) Cadence() Cadence { return p.cadence }

// Key is the period's text form.
func (p Period) Key() string {
	switch p.cadence {
	case Monthly:
		return fmt.Sprintf("%04d-%02d", p.year, p.index)
	case Quarterly:
		return fmt.Sprintf("%04d-Q%d", p.year, p.index)
	default:
		return SeasonKey
	}
}

// Dates are the first and last day of a month or quarter (UTC midnight); ok is false for SEASON.
func (p Period) Dates() (start, end time.Time, ok bool) {
	months := 1
	firstMonth := p.index
	switch p.cadence {
	case Monthly:
	case Quarterly:
		months, firstMonth = 3, 3*(p.index-1)+1
	default:
		return time.Time{}, time.Time{}, false
	}
	start = time.Date(p.year, time.Month(firstMonth), 1, 0, 0, 0, 0, time.UTC)
	return start, start.AddDate(0, months, -1), true
}

// Next is the following period of the cadence (SEASON has one period: itself).
func (p Period) Next() Period {
	if p.cadence == Season {
		return p
	}
	count := 12
	if p.cadence == Quarterly {
		count = 4
	}
	if p.index == count {
		return Period{cadence: p.cadence, year: p.year + 1, index: 1}
	}
	return Period{cadence: p.cadence, year: p.year, index: p.index + 1}
}

// Before reports whether p comes strictly before other (same cadence).
func (p Period) Before(other Period) bool {
	return p.year < other.year || p.year == other.year && p.index < other.index
}
