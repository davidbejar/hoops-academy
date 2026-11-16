package domain

import (
	"errors"
	"math/rand/v2"
	"testing"
	"time"
)

func errorsAs(err error, target **Error) bool { return errors.As(err, target) }

var season2026, _ = ParseUUID("88888888-8888-4888-8888-888888888888")

var balanceSeason = SeasonDates{Start: time.Date(2026, 9, 1, 0, 0, 0, 0, time.UTC),
	End: time.Date(2027, 6, 30, 0, 0, 0, 0, time.UTC)}

func TestTheBalanceListsEveryCategoryAndNetsPaidDuesAgainstExpenses(t *testing.T) {
	b := NewSeasonBalance(SeasonID(season2026), balanceSeason, IncomeTotals{PaidMinor: 9000, OpenMinor: 4500,
		WaivedMinor: 4500}, map[ExpenseCategory]int64{Kit: 3000, CourtRental: 12000})

	if b.Season != SeasonID(season2026) || b.Dates != balanceSeason || b.Income.PaidMinor != 9000 ||
		b.ExpensesMinor != 15000 || b.NetMinor != -6000 {
		t.Errorf("balance %+v", b)
	}
	want := []CategoryTotal{{CourtRental, 12000}, {Salaries, 0}, {Kit, 3000}, {TournamentFees, 0}, {Travel, 0},
		{OtherExpense, 0}}
	if len(b.ByCategory) != len(want) {
		t.Fatalf("by category %v", b.ByCategory)
	}
	for i := range want {
		if b.ByCategory[i] != want[i] {
			t.Errorf("category %d: %+v, want %+v", i, b.ByCategory[i], want[i])
		}
	}
	empty := NewSeasonBalance(SeasonID(season2026), balanceSeason, IncomeTotals{}, nil)
	if empty.NetMinor != 0 || empty.ExpensesMinor != 0 || len(empty.ByCategory) != 6 {
		t.Errorf("empty %+v", empty)
	}
}

// Property: for any income and any expenses per category (amounts up to MaxAmountMinor, up to 10,000 of them per
// category), the categories come in the contract's order, all six, their sum is the expense total, the net is paid
// minus expenses, and open and waived dues never change the net.
func TestTheBalanceArithmeticHoldsForAnyAmounts(t *testing.T) {
	random := rand.New(rand.NewPCG(2026, 11))
	amount := func() int64 { return random.Int64N(MaxAmountMinor*10_000 + 1) }
	for round := range 2000 {
		income := IncomeTotals{PaidMinor: amount(), OpenMinor: amount(), WaivedMinor: amount()}
		expenses := map[ExpenseCategory]int64{}
		for _, c := range ExpenseCategories() {
			if random.IntN(3) > 0 {
				expenses[c] = amount()
			}
		}
		b := NewSeasonBalance(SeasonID(season2026), balanceSeason, income, expenses)

		var sum int64
		for i, total := range b.ByCategory {
			if total.Category != ExpenseCategories()[i] || total.TotalMinor != expenses[total.Category] {
				t.Fatalf("round %d: category %d is %+v (expenses %v)", round, i, total, expenses)
			}
			sum += total.TotalMinor
		}
		if len(b.ByCategory) != 6 || sum != b.ExpensesMinor || b.NetMinor != income.PaidMinor-sum ||
			b.Income != income {
			t.Fatalf("round %d: %+v from %+v and %v", round, b, income, expenses)
		}
		other := NewSeasonBalance(SeasonID(season2026), balanceSeason,
			IncomeTotals{PaidMinor: income.PaidMinor, OpenMinor: amount(), WaivedMinor: amount()}, expenses)
		if other.NetMinor != b.NetMinor {
			t.Fatalf("round %d: open or waived dues changed the net", round)
		}
	}
}
