package application

import (
	"context"
	"time"

	"hoopsacademy.local/finance/internal/domain"
)

// ExportRowLimit is the most rows one export holds (ADR-0048); more is 422 EXPORT_TOO_LARGE.
const ExportRowLimit = 10_000

var errExportTooLarge = domain.RuleViolation("EXPORT_TOO_LARGE",
	"more than 10,000 rows: narrow the filter (dates, plan, team, status or category)")

// ExportFile is what names an export file: the academy's slug (empty while unknown) and today in its time zone.
type ExportFile struct {
	Slug  string
	Today time.Time
}

// Export is the rows of an export and what its file needs; the currency is nil while none was chosen (then there are
// no rows).
type Export[T any] struct {
	File     ExportFile
	Currency *domain.Currency
	Rows     []T
}

// ExportDues gathers the dues of filter for a CSV file (ADR-0048), in listDues' order: ADMIN only, at most
// ExportRowLimit rows, audited `dues.exported` with the row count and the filter as given (after reading, so a refused
// export writes nothing).
func (f *Finance) ExportDues(ctx context.Context, caller domain.Membership, filter DueFilter) (Export[DueRecord], error) {
	return exportOf(ctx, f, caller, "dues.exported", dueFilterMetadata(filter),
		func(ctx context.Context) ([]DueRecord, int64, error) {
			return f.p.Dues.List(ctx, filter, Page{Size: ExportRowLimit})
		})
}

// ExportExpenses gathers the expenses of filter for a CSV file, newest first, as ExportDues; audited
// `expenses.exported`.
func (f *Finance) ExportExpenses(ctx context.Context, caller domain.Membership, filter ExpenseFilter) (Export[domain.Expense], error) {
	return exportOf(ctx, f, caller, "expenses.exported", expenseFilterMetadata(filter),
		func(ctx context.Context) ([]domain.Expense, int64, error) {
			return f.p.Expenses.List(ctx, filter, Page{Size: ExportRowLimit})
		})
}

// exportOf runs one export: authorise, read the first ExportRowLimit rows and the total (more is refused), the file's
// name parts, then the audit record.
func exportOf[T any](ctx context.Context, f *Finance, caller domain.Membership, action string, filter map[string]any,
	read func(ctx context.Context) ([]T, int64, error)) (Export[T], error) {
	var export Export[T]
	err := f.asAdmin(ctx, caller, func(ctx context.Context) error {
		rows, total, err := read(ctx)
		if err != nil {
			return err
		}
		if total > ExportRowLimit {
			return errExportTooLarge
		}
		export.Rows = rows
		if export.File, export.Currency, err = f.exportFile(ctx); err != nil {
			return err
		}
		return f.audit(ctx, caller, action, academyTarget, caller.Tenant().String(),
			map[string]any{"rows": len(rows), "filter": filter})
	})
	return export, err
}

// academyTarget is the audit target type of an export: the academy (ADR-0048's audit.exported does the same).
const academyTarget = "academy"

func (f *Finance) exportFile(ctx context.Context) (ExportFile, *domain.Currency, error) {
	academy, _, err := f.p.Roster.Academy(ctx)
	if err != nil {
		return ExportFile{}, nil, err
	}
	file := ExportFile{Slug: academy.Slug, Today: domain.Today(f.p.Clock.Now(), academy.Zone)}
	settings, chosen, err := f.p.Settings.Get(ctx)
	if err != nil || !chosen {
		return file, nil, err
	}
	return file, &settings.Currency, nil
}

// dueFilterMetadata is the filter as given: ids, the period key, the status and dates; never a name.
func dueFilterMetadata(filter DueFilter) map[string]any {
	given := map[string]any{}
	putID(given, "feePlanId", filter.Plan)
	putID(given, "teamId", filter.Team)
	putID(given, "playerId", filter.Player)
	putID(given, "seasonId", filter.Season)
	if filter.Period != nil {
		given["period"] = *filter.Period
	}
	if filter.Status != nil {
		given["status"] = string(*filter.Status)
	}
	putDates(given, filter.From, filter.To)
	return given
}

func expenseFilterMetadata(filter ExpenseFilter) map[string]any {
	given := map[string]any{}
	if filter.Category != nil {
		given["category"] = string(*filter.Category)
	}
	putDates(given, filter.From, filter.To)
	return given
}

func putID[T interface{ String() string }](given map[string]any, name string, id *T) {
	if id != nil {
		given[name] = (*id).String()
	}
}

func putDates(given map[string]any, from, to *time.Time) {
	if from != nil {
		given["from"] = from.Format(time.DateOnly)
	}
	if to != nil {
		given["to"] = to.Format(time.DateOnly)
	}
}
