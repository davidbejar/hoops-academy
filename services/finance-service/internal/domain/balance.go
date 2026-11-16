package domain

// IncomeTotals are the dues of a season's plans by status, in minor units: PAID by the amount of the valid payment,
// OPEN and WAIVED by the due's amount.
type IncomeTotals struct {
	PaidMinor, OpenMinor, WaivedMinor int64
}

// CategoryTotal is what was spent in one category.
type CategoryTotal struct {
	Category   ExpenseCategory
	TotalMinor int64
}

// SeasonBalance is a season's income and expenses in the academy's currency (ADR-0056): every category listed, zero
// included, in the contract's order; the net is what was paid minus what was spent (negative when the academy spent
// more). Open and waived dues are shown but never counted in the net.
type SeasonBalance struct {
	Season        SeasonID
	Dates         SeasonDates
	Income        IncomeTotals
	ByCategory    []CategoryTotal
	ExpensesMinor int64
	NetMinor      int64
}

// NewSeasonBalance builds the balance from the sums the store read; a category without expenses counts zero.
func NewSeasonBalance(season SeasonID, dates SeasonDates, income IncomeTotals, spent map[ExpenseCategory]int64) SeasonBalance {
	b := SeasonBalance{Season: season, Dates: dates, Income: income,
		ByCategory: make([]CategoryTotal, len(expenseCategories))}
	for i, category := range expenseCategories {
		b.ByCategory[i] = CategoryTotal{Category: category, TotalMinor: spent[category]}
		b.ExpensesMinor += spent[category]
	}
	b.NetMinor = income.PaidMinor - b.ExpensesMinor
	return b
}
