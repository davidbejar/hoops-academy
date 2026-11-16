package domain

import (
	"slices"
	"time"
)

// ExpenseID identifies an expense.
type ExpenseID UUID

// String is the canonical text form.
func (id ExpenseID) String() string { return UUID(id).String() }

// ExpenseCategory is one of the fixed categories of decision 99 (no management of categories; the web labels them).
type ExpenseCategory string

// The categories, in the contract's order.
const (
	CourtRental    ExpenseCategory = "COURT_RENTAL"
	Salaries       ExpenseCategory = "SALARIES"
	Kit            ExpenseCategory = "KIT"
	TournamentFees ExpenseCategory = "TOURNAMENT_FEES"
	Travel         ExpenseCategory = "TRAVEL"
	OtherExpense   ExpenseCategory = "OTHER"
)

var expenseCategories = []ExpenseCategory{CourtRental, Salaries, Kit, TournamentFees, Travel, OtherExpense}

// ExpenseCategories are all categories in the contract's order (a copy).
func ExpenseCategories() []ExpenseCategory { return slices.Clone(expenseCategories) }

// ParseExpenseCategory reads one of the six categories.
func ParseExpenseCategory(text string) (ExpenseCategory, error) {
	if c := ExpenseCategory(text); slices.Contains(expenseCategories, c) {
		return c, nil
	}
	return "", invalid("category", "INVALID")
}

// MaxDescriptionLength bounds an expense's description, in characters.
const MaxDescriptionLength = 120

// Expense is money the academy spent (decision 99): a day, a category, an amount in the academy's currency, what it
// was for and an optional note. The note follows the rules of reasons (P-12: short, never a named person's salary or
// health details; read by ADMIN only, never logged, audited or exported).
type Expense struct {
	ID          ExpenseID
	SpentOn     time.Time // a date (UTC midnight)
	Category    ExpenseCategory
	Amount      Amount
	Description string
	Note        *string
	CreatedAt   time.Time
	UpdatedAt   time.Time
	Version     int
}

// ExpenseInput is a new expense as requested; a zero SpentOn is a missing day.
type ExpenseInput struct {
	SpentOn     time.Time
	Category    string
	AmountMinor int64
	Description string
	Note        *string
}

// NewExpense validates input and reports every violation at once (400 VALIDATION_FAILED).
func NewExpense(id ExpenseID, input ExpenseInput, now time.Time) (Expense, error) {
	var v violations
	if input.SpentOn.IsZero() {
		v.add("spentOn", "REQUIRED")
	}
	e := Expense{ID: id, SpentOn: input.SpentOn, CreatedAt: now, UpdatedAt: now}
	e.Category = checkCategory(&v, input.Category)
	e.Amount = checkAmount(&v, input.AmountMinor)
	e.Description = checkDescription(&v, input.Description)
	e.Note = checkNote(&v, input.Note)
	if err := v.err(); err != nil {
		return Expense{}, err
	}
	return e, nil
}

func checkCategory(v *violations, raw string) ExpenseCategory {
	category, err := ParseExpenseCategory(raw)
	if err != nil {
		v.add("category", "INVALID")
	}
	return category
}

func checkAmount(v *violations, minor int64) Amount {
	amount, err := NewAmount(minor)
	if err != nil {
		v.add("amountMinor", "OUT_OF_RANGE")
	}
	return amount
}

func checkDescription(v *violations, raw string) string {
	description := cleanText(raw)
	switch {
	case description == "":
		v.add("description", "REQUIRED")
	case textLength(description) > MaxDescriptionLength:
		v.add("description", "TOO_LONG")
	}
	return description
}

func checkNote(v *violations, raw *string) *string {
	if raw == nil {
		return nil
	}
	note := checkReason(v, "note", *raw)
	return &note
}

// ExpenseChanges are the fields of a correction; nil leaves a field as it is, ClearNote removes the note (the
// contract's `clear` list, ADR-0032).
type ExpenseChanges struct {
	SpentOn     *time.Time
	Category    *string
	AmountMinor *int64
	Description *string
	Note        *string
	ClearNote   bool
}

// Change applies changes and returns the changed expense with the names of the fields whose value changed (sorted,
// as in the contract). No changed value: the expense unchanged, UpdatedAt kept. Invalid changes change nothing.
func (e Expense) Change(changes ExpenseChanges, now time.Time) (Expense, []string, error) {
	var v violations
	if changes.ClearNote && changes.Note != nil {
		v.add("clear", "CLEARED_AND_SET")
	}
	next := e
	if changes.SpentOn != nil {
		next.SpentOn = *changes.SpentOn
	}
	if changes.Category != nil {
		next.Category = checkCategory(&v, *changes.Category)
	}
	if changes.AmountMinor != nil {
		next.Amount = checkAmount(&v, *changes.AmountMinor)
	}
	if changes.Description != nil {
		next.Description = checkDescription(&v, *changes.Description)
	}
	if changes.Note != nil {
		next.Note = checkNote(&v, changes.Note)
	}
	if changes.ClearNote {
		next.Note = nil
	}
	if err := v.err(); err != nil {
		return e, nil, err
	}
	fields := e.diff(next)
	if len(fields) == 0 {
		return e, nil, nil
	}
	next.UpdatedAt = now
	return next, fields, nil
}

// diff names the changed fields in alphabetical order (the contract's property names).
func (e Expense) diff(next Expense) []string {
	var fields []string
	add := func(changed bool, field string) {
		if changed {
			fields = append(fields, field)
		}
	}
	add(next.Amount != e.Amount, "amountMinor")
	add(next.Category != e.Category, "category")
	add(next.Description != e.Description, "description")
	add(!sameText(next.Note, e.Note), "note")
	add(!next.SpentOn.Equal(e.SpentOn), "spentOn")
	return fields
}

func sameText(a, b *string) bool {
	if a == nil || b == nil {
		return a == b
	}
	return *a == *b
}
