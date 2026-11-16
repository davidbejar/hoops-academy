package domain

import (
	"slices"
	"strings"
	"testing"
	"time"
)

var (
	expenseID, _ = ParseUUID("77777777-7777-4777-8777-777777777777")
	expenseDay   = time.Date(2026, time.October, 3, 0, 0, 0, 0, time.UTC)
	expenseAt    = time.Date(2026, time.November, 16, 9, 0, 0, 0, time.UTC)
)

func courtRental() ExpenseInput {
	note := "  invoice 12  "
	return ExpenseInput{SpentOn: expenseDay, Category: "COURT_RENTAL", AmountMinor: 12000,
		Description: "  Court, October  ", Note: &note}
}

func requireViolations(t *testing.T, err error, want map[string]string) {
	t.Helper()
	var e *Error
	if !errorsAs(err, &e) || e.Kind != KindInvalid {
		t.Fatalf("expected invalid input, got %v", err)
	}
	got := map[string]string{}
	for _, v := range e.Violations {
		got[v.Field] = v.Code
	}
	for field, code := range want {
		if got[field] != code {
			t.Errorf("%s: %q, want %q (all: %v)", field, got[field], code, got)
		}
	}
	if len(got) != len(want) {
		t.Errorf("violations %v, want %v", got, want)
	}
}

func TestTheExpenseCategoriesAreTheFixedListOfDecision99InTheContractsOrder(t *testing.T) {
	want := []ExpenseCategory{"COURT_RENTAL", "SALARIES", "KIT", "TOURNAMENT_FEES", "TRAVEL", "OTHER"}
	if got := ExpenseCategories(); !slices.Equal(got, want) {
		t.Fatalf("categories %v", got)
	}
	ExpenseCategories()[0] = "CHANGED"
	if ExpenseCategories()[0] != CourtRental {
		t.Error("the list can be changed by a caller")
	}
	for _, c := range want {
		if parsed, err := ParseExpenseCategory(string(c)); err != nil || parsed != c {
			t.Errorf("%s: %v %v", c, parsed, err)
		}
	}
	for _, bad := range []string{"", "court_rental", "FOOD", "OTHER "} {
		if _, err := ParseExpenseCategory(bad); err == nil {
			t.Errorf("%q accepted", bad)
		}
	}
}

func TestANewExpenseIsTrimmedAndKeepsItsDay(t *testing.T) {
	e, err := NewExpense(ExpenseID(expenseID), courtRental(), expenseAt)
	if err != nil {
		t.Fatal(err)
	}
	if e.ID != ExpenseID(expenseID) || e.Category != CourtRental || e.Amount.Minor() != 12000 ||
		e.Description != "Court, October" || e.Note == nil || *e.Note != "invoice 12" || !e.SpentOn.Equal(expenseDay) ||
		!e.CreatedAt.Equal(expenseAt) || !e.UpdatedAt.Equal(expenseAt) || e.Version != 0 {
		t.Errorf("expense %+v", e)
	}
	without := courtRental()
	without.Note = nil
	if e, err := NewExpense(ExpenseID(expenseID), without, expenseAt); err != nil || e.Note != nil {
		t.Errorf("no note: %+v %v", e, err)
	}
}

func TestANewExpenseReportsEveryViolationAtOnce(t *testing.T) {
	blank, long := "   ", strings.Repeat("é", 201)
	_, err := NewExpense(ExpenseID(expenseID), ExpenseInput{SpentOn: expenseDay, Category: "FOOD", AmountMinor: 0,
		Description: " ", Note: &blank}, expenseAt)
	requireViolations(t, err, map[string]string{"category": "INVALID", "amountMinor": "OUT_OF_RANGE",
		"description": "REQUIRED", "note": "REQUIRED"})

	_, err = NewExpense(ExpenseID(expenseID), ExpenseInput{Category: "KIT", AmountMinor: MaxAmountMinor + 1,
		Description: strings.Repeat("a", 121), Note: &long}, expenseAt)
	requireViolations(t, err, map[string]string{"spentOn": "REQUIRED", "amountMinor": "OUT_OF_RANGE",
		"description": "TOO_LONG", "note": "TOO_LONG"})

	exact := strings.Repeat("ñ", 120)
	if e, err := NewExpense(ExpenseID(expenseID), ExpenseInput{SpentOn: expenseDay, Category: "KIT", AmountMinor: 1,
		Description: exact}, expenseAt); err != nil || e.Description != exact {
		t.Errorf("120 characters are allowed: %v", err)
	}
}

func TestAnExpenseChangeNamesTheChangedFields(t *testing.T) {
	e, _ := NewExpense(ExpenseID(expenseID), courtRental(), expenseAt)
	later := expenseAt.Add(time.Hour)
	day, category, amount, description := expenseDay.AddDate(0, 0, 1), "TRAVEL", int64(9000), "Bus to the final"

	changed, fields, err := e.Change(ExpenseChanges{SpentOn: &day, Category: &category, AmountMinor: &amount,
		Description: &description, ClearNote: true}, later)
	if err != nil {
		t.Fatal(err)
	}
	if !slices.Equal(fields, []string{"amountMinor", "category", "description", "note", "spentOn"}) {
		t.Errorf("fields %v", fields)
	}
	if changed.Category != Travel || changed.Amount.Minor() != 9000 || changed.Description != description ||
		changed.Note != nil || !changed.SpentOn.Equal(day) || !changed.UpdatedAt.Equal(later) ||
		!changed.CreatedAt.Equal(expenseAt) {
		t.Errorf("changed %+v", changed)
	}

	same := "Court, October"
	unchanged, fields, err := e.Change(ExpenseChanges{Description: &same}, later)
	if err != nil || len(fields) != 0 || !unchanged.UpdatedAt.Equal(expenseAt) {
		t.Errorf("no change: %v %v %+v", fields, err, unchanged)
	}

	note := "new note"
	withNote, fields, _ := changed.Change(ExpenseChanges{Note: &note}, later)
	if !slices.Equal(fields, []string{"note"}) || withNote.Note == nil || *withNote.Note != note {
		t.Errorf("note: %v %+v", fields, withNote)
	}
}

func TestAnInvalidExpenseChangeLeavesTheExpenseAsItWas(t *testing.T) {
	e, _ := NewExpense(ExpenseID(expenseID), courtRental(), expenseAt)
	note, bad, zero, blank := "x", "FOOD", int64(0), ""
	got, fields, err := e.Change(ExpenseChanges{Note: &note, ClearNote: true, Category: &bad, AmountMinor: &zero,
		Description: &blank}, expenseAt)
	requireViolations(t, err, map[string]string{"clear": "CLEARED_AND_SET", "category": "INVALID",
		"amountMinor": "OUT_OF_RANGE", "description": "REQUIRED"})
	if fields != nil || got.Category != CourtRental || got.Description != "Court, October" {
		t.Errorf("changed although invalid: %+v", got)
	}
}
