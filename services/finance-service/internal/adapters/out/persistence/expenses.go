package persistence

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"

	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/domain"
)

// ExpenseStore implements application.ExpenseStore on finance.expense. Every statement names the bound tenant on top
// of the RLS policy; the optional filters are bound parameters (null = no filter), so the statements stay constant.
type ExpenseStore struct{}

const (
	expenseColumns = `id, spent_on, category, amount_minor, description, note, created_at, updated_at, version`
	insertExpense  = `insert into finance.expense (tenant_id, id, spent_on, category, amount_minor, description, note,
			created_at, updated_at)
		values (app.current_tenant(), $1, $2, $3, $4, $5, $6, $7, $8)`
	selectExpense = "select " + expenseColumns + " from finance.expense where tenant_id = app.current_tenant() and id = $1"
	lockExpense   = selectExpense + " for update"
	updateExpense = `update finance.expense set spent_on = $2, category = $3, amount_minor = $4, description = $5,
			note = $6, updated_at = $7, version = version + 1
		where tenant_id = app.current_tenant() and id = $1 and version = $8`
	deleteExpense = "delete from finance.expense where tenant_id = app.current_tenant() and id = $1"
	expenseFilter = ` and ($1::date is null or spent_on >= $1) and ($2::date is null or spent_on <= $2)
		and ($3::text is null or category = $3)`
	listExpenses = "select " + expenseColumns + " from finance.expense where tenant_id = app.current_tenant()" +
		expenseFilter + " order by spent_on desc, created_at desc, id desc limit $4 offset $5"
	countExpenses   = "select count(*) from finance.expense where tenant_id = app.current_tenant()" + expenseFilter
	anyExpense      = "select exists (select 1 from finance.expense where tenant_id = app.current_tenant())"
	spentByCategory = `select category, sum(amount_minor)::bigint from finance.expense
		where tenant_id = app.current_tenant() and spent_on between $1 and $2
		group by category`
)

// Insert stores a new expense.
func (ExpenseStore) Insert(ctx context.Context, e domain.Expense) error {
	q, err := txOf(ctx)
	if err != nil {
		return err
	}
	if _, err := q.Exec(ctx, insertExpense, e.ID.String(), e.SpentOn, string(e.Category), e.Amount.Minor(),
		e.Description, e.Note, e.CreatedAt, e.UpdatedAt); err != nil {
		return fmt.Errorf("insert expense: %w", err)
	}
	return nil
}

// Get reads an expense.
func (ExpenseStore) Get(ctx context.Context, id domain.ExpenseID) (domain.Expense, bool, error) {
	return readExpense(ctx, selectExpense, id)
}

// Lock reads an expense for update.
func (ExpenseStore) Lock(ctx context.Context, id domain.ExpenseID) (domain.Expense, bool, error) {
	return readExpense(ctx, lockExpense, id)
}

func readExpense(ctx context.Context, sql string, id domain.ExpenseID) (domain.Expense, bool, error) {
	q, err := txOf(ctx)
	if err != nil {
		return domain.Expense{}, false, err
	}
	var row expenseRow
	if err := q.QueryRow(ctx, sql, id.String()).Scan(row.dests()...); errors.Is(err, pgx.ErrNoRows) {
		return domain.Expense{}, false, nil
	} else if err != nil {
		return domain.Expense{}, false, fmt.Errorf("read expense: %w", err)
	}
	expense, err := row.expense()
	return expense, err == nil, err
}

// Update writes a correction if the version still matches.
func (ExpenseStore) Update(ctx context.Context, e domain.Expense) (domain.Expense, error) {
	q, err := txOf(ctx)
	if err != nil {
		return e, err
	}
	tag, err := q.Exec(ctx, updateExpense, e.ID.String(), e.SpentOn, string(e.Category), e.Amount.Minor(), e.Description,
		e.Note, e.UpdatedAt, e.Version)
	if err != nil {
		return e, fmt.Errorf("update expense: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return e, application.ErrConcurrentModification
	}
	e.Version++
	return e, nil
}

// Delete removes an expense.
func (ExpenseStore) Delete(ctx context.Context, id domain.ExpenseID) error {
	q, err := txOf(ctx)
	if err != nil {
		return err
	}
	if _, err := q.Exec(ctx, deleteExpense, id.String()); err != nil {
		return fmt.Errorf("delete expense: %w", err)
	}
	return nil
}

// List reads a page of expenses, newest first, and the total.
func (ExpenseStore) List(ctx context.Context, f application.ExpenseFilter, page application.Page) ([]domain.Expense, int64, error) {
	q, err := txOf(ctx)
	if err != nil {
		return nil, 0, err
	}
	args := []any{f.From, f.To, optionalText(f.Category)}
	var total int64
	if err := q.QueryRow(ctx, countExpenses, args...).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("count expenses: %w", err)
	}
	rows, err := q.Query(ctx, listExpenses, append(args, page.Size, page.Index*page.Size)...)
	if err != nil {
		return nil, 0, fmt.Errorf("expenses: %w", err)
	}
	expenses, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (domain.Expense, error) {
		var r expenseRow
		if err := scan(row, r.dests()...); err != nil {
			return domain.Expense{}, err
		}
		return r.expense()
	})
	if err != nil {
		return nil, 0, fmt.Errorf("expenses: %w", err)
	}
	return expenses, total, nil
}

// Any reports whether the bound tenant has an expense.
func (ExpenseStore) Any(ctx context.Context) (bool, error) {
	q, err := txOf(ctx)
	if err != nil {
		return false, err
	}
	var exists bool
	if err := q.QueryRow(ctx, anyExpense).Scan(&exists); err != nil {
		return false, fmt.Errorf("any expense: %w", err)
	}
	return exists, nil
}

// Spent sums the expenses of from..to by category.
func (ExpenseStore) Spent(ctx context.Context, from, to time.Time) (map[domain.ExpenseCategory]int64, error) {
	q, err := txOf(ctx)
	if err != nil {
		return nil, err
	}
	rows, err := q.Query(ctx, spentByCategory, from, to)
	if err != nil {
		return nil, fmt.Errorf("spent: %w", err)
	}
	type sum struct {
		Category string
		Total    int64
	}
	sums, err := pgx.CollectRows(rows, pgx.RowToStructByPos[sum])
	if err != nil {
		return nil, fmt.Errorf("spent: %w", err)
	}
	out := make(map[domain.ExpenseCategory]int64, len(sums))
	for _, s := range sums {
		category, err := domain.ParseExpenseCategory(s.Category)
		if err != nil {
			return nil, fmt.Errorf("stored category %q: %w", s.Category, err)
		}
		out[category] = s.Total
	}
	return out, nil
}

// expenseRow is an expense's columns as scanned.
type expenseRow struct {
	id, category, description string
	spentOn, created, updated time.Time
	amount                    int64
	note                      *string
	version                   int
}

func (r *expenseRow) dests() []any {
	return []any{&r.id, &r.spentOn, &r.category, &r.amount, &r.description, &r.note, &r.created, &r.updated, &r.version}
}

func (r *expenseRow) expense() (domain.Expense, error) {
	read := reader{}
	e := domain.Expense{ID: domain.ExpenseID(read.uuid(r.id)), SpentOn: r.spentOn.UTC(), Description: r.description,
		Note: r.note, CreatedAt: timestamp(r.created), UpdatedAt: timestamp(r.updated), Version: r.version}
	var err error
	if e.Category, err = domain.ParseExpenseCategory(r.category); err != nil {
		read.fail(err)
	}
	if e.Amount, err = domain.NewAmount(r.amount); err != nil {
		read.fail(err)
	}
	if read.err != nil {
		return domain.Expense{}, fmt.Errorf("stored expense %s: %w", r.id, read.err)
	}
	return e, nil
}
