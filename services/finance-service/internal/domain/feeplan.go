package domain

import (
	"sort"
	"time"
)

// MaxNameLength is the longest fee plan name, in characters.
const MaxNameLength = 80

// Target is what a fee plan charges: the players of one team, or of every team of one age category, in its season.
// Exactly one is set.
type Target struct {
	Team        *TeamID
	AgeCategory *AgeCategoryID
}

// FeePlan charges every player of its target an amount per period of its cadence (decision 93, ADR-0056).
// Immutable after creation: ID, Season, Target, Cadence; First only while the plan has no dues.
type FeePlan struct {
	ID           FeePlanID
	Name         string
	Season       SeasonID
	Target       Target
	Amount       Amount
	Cadence      Cadence
	First, Last  *Period // nil for SEASON; Last nil = to the end of the season
	AutoGenerate bool
	Archived     bool
	CreatedAt    time.Time
	UpdatedAt    time.Time
	Version      int
}

// FeePlanInput is a new plan as requested.
type FeePlanInput struct {
	Name         string
	Season       SeasonID
	Team         *TeamID
	AgeCategory  *AgeCategoryID
	AmountMinor  int64
	Cadence      string
	FirstPeriod  *string
	LastPeriod   *string
	AutoGenerate bool
}

// NewFeePlan validates input and reports every violation at once (400 VALIDATION_FAILED).
func NewFeePlan(id FeePlanID, input FeePlanInput, now time.Time) (FeePlan, error) {
	var v violations
	name := checkName(&v, input.Name)
	if (input.Team == nil) == (input.AgeCategory == nil) {
		v.add("teamId", "ONE_TARGET_REQUIRED")
	}
	amount, err := NewAmount(input.AmountMinor)
	if err != nil {
		v.add("amountMinor", "OUT_OF_RANGE")
	}
	cadence, err := ParseCadence(input.Cadence)
	if err != nil {
		v.add("cadence", "INVALID")
	}
	var first, last *Period
	if cadence != "" {
		first, last = checkPeriods(&v, cadence, input.FirstPeriod, input.LastPeriod)
	}
	if err := v.err(); err != nil {
		return FeePlan{}, err
	}
	return FeePlan{
		ID: id, Name: name, Season: input.Season, Target: Target{Team: input.Team, AgeCategory: input.AgeCategory},
		Amount: amount, Cadence: cadence, First: first, Last: last, AutoGenerate: input.AutoGenerate,
		CreatedAt: now, UpdatedAt: now,
	}, nil
}

func checkName(v *violations, raw string) string {
	name := cleanText(raw)
	switch {
	case name == "":
		v.add("name", "REQUIRED")
	case textLength(name) > MaxNameLength:
		v.add("name", "TOO_LONG")
	}
	return name
}

// checkPeriods: MONTHLY and QUARTERLY need a first period of their cadence and take an optional last one not before
// it; SEASON takes neither.
func checkPeriods(v *violations, cadence Cadence, firstKey, lastKey *string) (first, last *Period) {
	if cadence == Season {
		if firstKey != nil {
			v.add("firstPeriod", "NOT_ALLOWED")
		}
		if lastKey != nil {
			v.add("lastPeriod", "NOT_ALLOWED")
		}
		return nil, nil
	}
	if firstKey == nil {
		v.add("firstPeriod", "REQUIRED")
	} else if p, err := ParsePeriod(cadence, *firstKey); err != nil {
		v.add("firstPeriod", codeOf(err))
	} else {
		first = &p
	}
	if lastKey != nil {
		if p, err := ParsePeriod(cadence, *lastKey); err != nil {
			v.add("lastPeriod", codeOf(err))
		} else {
			last = &p
		}
	}
	if first != nil && last != nil && last.Before(*first) {
		v.add("lastPeriod", "BEFORE_FIRST_PERIOD")
	}
	return first, last
}

// FeePlanChanges are the editable fields; nil leaves a field as it is, ClearLastPeriod sets no last period (the
// contract's `clear` list, ADR-0032).
type FeePlanChanges struct {
	Name            *string
	AmountMinor     *int64
	FirstPeriod     *string
	LastPeriod      *string
	ClearLastPeriod bool
	AutoGenerate    *bool
}

// Change applies changes and returns the changed plan with the names of the fields whose value changed (sorted, as
// in the contract). A new amount applies to dues generated afterwards; existing dues keep theirs. The first period is
// fixed once the plan has dues (409 FEE_PLAN_HAS_DUES). No changed value: the plan unchanged, UpdatedAt kept.
func (p FeePlan) Change(changes FeePlanChanges, hasDues bool, now time.Time) (FeePlan, []string, error) {
	var v violations
	if changes.ClearLastPeriod && changes.LastPeriod != nil {
		v.add("clear", "CLEARED_AND_SET")
	}
	next := p
	if changes.Name != nil {
		next.Name = checkName(&v, *changes.Name)
	}
	if changes.AmountMinor != nil {
		if amount, err := NewAmount(*changes.AmountMinor); err != nil {
			v.add("amountMinor", "OUT_OF_RANGE")
		} else {
			next.Amount = amount
		}
	}
	if changes.AutoGenerate != nil {
		next.AutoGenerate = *changes.AutoGenerate
	}
	next.First, next.Last = p.changedPeriods(&v, changes)
	if err := v.err(); err != nil {
		return p, nil, err
	}
	fields := p.diff(next)
	if contains(fields, "firstPeriod") && hasDues {
		return p, nil, Conflict("FEE_PLAN_HAS_DUES", "the first period is fixed once the plan has dues")
	}
	if len(fields) == 0 {
		return p, nil, nil
	}
	next.UpdatedAt = now
	return next, fields, nil
}

func (p FeePlan) changedPeriods(v *violations, changes FeePlanChanges) (first, last *Period) {
	firstKey, lastKey := keyOf(p.First), keyOf(p.Last)
	if changes.FirstPeriod != nil {
		firstKey = changes.FirstPeriod
	}
	if changes.LastPeriod != nil {
		lastKey = changes.LastPeriod
	}
	if changes.ClearLastPeriod {
		lastKey = nil
	}
	return checkPeriods(v, p.Cadence, firstKey, lastKey)
}

func keyOf(p *Period) *string {
	if p == nil {
		return nil
	}
	key := p.Key()
	return &key
}

func (p FeePlan) diff(next FeePlan) []string {
	var fields []string
	if next.Name != p.Name {
		fields = append(fields, "name")
	}
	if next.Amount != p.Amount {
		fields = append(fields, "amountMinor")
	}
	if next.AutoGenerate != p.AutoGenerate {
		fields = append(fields, "autoGenerate")
	}
	if !samePeriod(next.First, p.First) {
		fields = append(fields, "firstPeriod")
	}
	if !samePeriod(next.Last, p.Last) {
		fields = append(fields, "lastPeriod")
	}
	sort.Strings(fields)
	return fields
}

func samePeriod(a, b *Period) bool {
	if a == nil || b == nil {
		return a == b
	}
	return *a == *b
}

func contains(values []string, value string) bool {
	for _, v := range values {
		if v == value {
			return true
		}
	}
	return false
}

// Archive stops the plan: no more dues, by the job or by hand; its dues stay. changed is false when it was archived.
func (p FeePlan) Archive(now time.Time) (FeePlan, bool) {
	if p.Archived {
		return p, false
	}
	p.Archived, p.UpdatedAt = true, now
	return p, true
}

// Unarchive makes an archived plan active again.
func (p FeePlan) Unarchive(now time.Time) (FeePlan, bool) {
	if !p.Archived {
		return p, false
	}
	p.Archived, p.UpdatedAt = false, now
	return p, true
}

// GeneratesAutomatically reports whether the daily job creates this plan's dues (an active plan with automatic
// generation on).
func (p FeePlan) GeneratesAutomatically() bool { return p.AutoGenerate && !p.Archived }

// CheckDeletable refuses a plan with dues (409 FEE_PLAN_HAS_DUES): only a plan without dues may be deleted;
// archive the others.
func (p FeePlan) CheckDeletable(hasDues bool) error {
	if hasDues {
		return Conflict("FEE_PLAN_HAS_DUES", "a plan with dues cannot be deleted; archive it instead")
	}
	return nil
}
