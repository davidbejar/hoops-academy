package application

import (
	"context"

	"hoopsacademy.local/finance/internal/domain"
)

const expenseTarget = "expense"

// ExpenseView is an expense in the academy's currency.
type ExpenseView struct {
	Expense  domain.Expense
	Currency domain.Currency
}

// ExpensePage is one page of expenses and the total.
type ExpensePage = Paged[domain.Expense]

// CreateExpense records an expense (decision 99; the currency must be chosen first). Audited `expense.created` with
// its category, never the description, the note or the amount.
func (f *Finance) CreateExpense(ctx context.Context, caller domain.Membership, input domain.ExpenseInput) (ExpenseView, error) {
	var view ExpenseView
	err := f.asAdmin(ctx, caller, func(ctx context.Context) error {
		expense, err := domain.NewExpense(domain.ExpenseID(f.p.IDs.New()), input, f.p.Clock.Now())
		if err != nil {
			return err
		}
		currency, err := f.currency(ctx)
		if err != nil {
			return err
		}
		if err := f.p.Expenses.Insert(ctx, expense); err != nil {
			return err
		}
		view = ExpenseView{Expense: expense, Currency: currency}
		return f.audit(ctx, caller, "expense.created", expenseTarget, expense.ID.String(),
			map[string]any{"category": string(expense.Category)})
	})
	return view, err
}

// Expense reads one expense (404 for another academy's id too).
func (f *Finance) Expense(ctx context.Context, caller domain.Membership, id domain.ExpenseID) (ExpenseView, error) {
	var view ExpenseView
	err := f.asAdmin(ctx, caller, func(ctx context.Context) error {
		expense, found, err := f.p.Expenses.Get(ctx, id)
		if err != nil {
			return err
		}
		if !found {
			return errNoExpense
		}
		view, err = f.expenseView(ctx, expense)
		return err
	})
	return view, err
}

var errNoExpense = domain.NotFound("no such expense")

func (f *Finance) expenseView(ctx context.Context, expense domain.Expense) (ExpenseView, error) {
	currency, err := f.currency(ctx)
	return ExpenseView{Expense: expense, Currency: currency}, err
}

// ListExpenses reads a page of expenses, newest first.
func (f *Finance) ListExpenses(ctx context.Context, caller domain.Membership, filter ExpenseFilter, page Page) (ExpensePage, error) {
	return adminPage(ctx, f, caller, func(ctx context.Context) ([]domain.Expense, int64, error) {
		return f.p.Expenses.List(ctx, filter, page)
	})
}

// UpdateExpense corrects an expense; audited `expense.updated` with the changed field names when something changed.
func (f *Finance) UpdateExpense(ctx context.Context, caller domain.Membership, id domain.ExpenseID, changes domain.ExpenseChanges) (ExpenseView, error) {
	var view ExpenseView
	err := f.asAdmin(ctx, caller, func(ctx context.Context) error {
		expense, err := f.lockedExpense(ctx, id)
		if err != nil {
			return err
		}
		changed, fields, err := expense.Change(changes, f.p.Clock.Now())
		if err != nil {
			return err
		}
		if len(fields) > 0 {
			if changed, err = f.p.Expenses.Update(ctx, changed); err != nil {
				return err
			}
			if err := f.audit(ctx, caller, "expense.updated", expenseTarget, id.String(),
				map[string]any{"fields": fields}); err != nil {
				return err
			}
		}
		view, err = f.expenseView(ctx, changed)
		return err
	})
	return view, err
}

// DeleteExpense removes an expense recorded by mistake (for good; the audit record `expense.deleted` keeps its id
// and category).
func (f *Finance) DeleteExpense(ctx context.Context, caller domain.Membership, id domain.ExpenseID) error {
	return f.asAdmin(ctx, caller, func(ctx context.Context) error {
		expense, err := f.lockedExpense(ctx, id)
		if err != nil {
			return err
		}
		if err := f.p.Expenses.Delete(ctx, id); err != nil {
			return err
		}
		return f.audit(ctx, caller, "expense.deleted", expenseTarget, id.String(),
			map[string]any{"category": string(expense.Category)})
	})
}

func (f *Finance) lockedExpense(ctx context.Context, id domain.ExpenseID) (domain.Expense, error) {
	expense, found, err := f.p.Expenses.Lock(ctx, id)
	if err != nil {
		return domain.Expense{}, err
	}
	if !found {
		return domain.Expense{}, errNoExpense
	}
	return expense, nil
}

// BalanceView is a season's balance in the academy's currency.
type BalanceView struct {
	Balance  domain.SeasonBalance
	Currency domain.Currency
}

// SeasonBalance computes a season's balance (ADR-0056): the dues of its plans by status, the expenses within its
// dates by category, the net. A season the replica does not know is 404; so is a balance before the academy chose a
// currency (no amount can exist yet, and the answer's currency is required).
func (f *Finance) SeasonBalance(ctx context.Context, caller domain.Membership, season domain.SeasonID) (BalanceView, error) {
	var view BalanceView
	err := f.asAdmin(ctx, caller, func(ctx context.Context) error {
		dates, found, err := f.p.Roster.SeasonDates(ctx, season)
		if err != nil {
			return err
		}
		if !found {
			return domain.NotFound("no such season")
		}
		settings, chosen, err := f.p.Settings.Get(ctx)
		if err != nil {
			return err
		}
		if !chosen {
			return domain.NotFound("no currency chosen yet")
		}
		income, err := f.p.DueStore.Income(ctx, season)
		if err != nil {
			return err
		}
		spent, err := f.p.Expenses.Spent(ctx, dates.Start, dates.End)
		if err != nil {
			return err
		}
		view = BalanceView{Balance: domain.NewSeasonBalance(season, dates, income, spent), Currency: settings.Currency}
		return nil
	})
	return view, err
}
