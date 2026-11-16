package rest

import (
	"bytes"
	"encoding/json"
	"net/http"
	"time"

	"hoopsacademy.local/finance/internal/adapters/in/export"
	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/domain"
)

const expenses = "/api/finance/expenses"

func (h *handler) expenseRoutes(mux *http.ServeMux) {
	mux.HandleFunc("GET "+expenses, h.api(expenses, h.listExpenses))
	mux.HandleFunc("POST "+expenses, h.api(expenses, h.createExpense))
	mux.HandleFunc("GET "+expenses+":export", h.api(expenses+":export", h.exportExpenses))
	mux.HandleFunc("GET "+expenses+"/{id}", h.api(expenses+"/{expenseId}", withID("expenseId", h.getExpense)))
	mux.HandleFunc("PATCH "+expenses+"/{id}", h.api(expenses+"/{expenseId}", withID("expenseId", h.patchExpense)))
	mux.HandleFunc("DELETE "+expenses+"/{id}", h.api(expenses+"/{expenseId}", withID("expenseId", h.deleteExpense)))
	mux.HandleFunc("GET /api/finance/balance", h.api("/api/finance/balance", h.seasonBalance))
	mux.HandleFunc("GET "+dues+":export", h.api(dues+":export", h.exportDues))
}

// --- expenses

type expenseDTO struct {
	ID          string  `json:"id"`
	SpentOn     string  `json:"spentOn"`
	Category    string  `json:"category"`
	AmountMinor int64   `json:"amountMinor"`
	Currency    string  `json:"currency"`
	Description string  `json:"description"`
	Note        *string `json:"note"`
	CreatedAt   string  `json:"createdAt"`
	UpdatedAt   string  `json:"updatedAt"`
}

func expenseOf(e domain.Expense, currency domain.Currency) expenseDTO {
	return expenseDTO{
		ID: e.ID.String(), SpentOn: day(e.SpentOn), Category: string(e.Category), AmountMinor: e.Amount.Minor(),
		Currency: currency.Code(), Description: e.Description, Note: e.Note, CreatedAt: instant(e.CreatedAt),
		UpdatedAt: instant(e.UpdatedAt),
	}
}

func (h *handler) answerExpense(w http.ResponseWriter, r *http.Request, status int, view application.ExpenseView, err error) {
	if err != nil {
		h.writeError(w, r, err)
		return
	}
	writeJSON(w, status, expenseOf(view.Expense, view.Currency))
}

// expenseFilterOf reads the filters of listExpenses and exportExpenses.
func expenseFilterOf(q *query) application.ExpenseFilter {
	filter := application.ExpenseFilter{From: q.date("from"), To: q.date("to")}
	if raw := q.values.Get("category"); raw != "" {
		if category, err := domain.ParseExpenseCategory(raw); err != nil {
			q.invalid("category")
		} else {
			filter.Category = &category
		}
	}
	return filter
}

func (h *handler) listExpenses(w http.ResponseWriter, r *http.Request, caller domain.Membership) {
	q := newQuery(r)
	filter, page := expenseFilterOf(q), q.page()
	if q.failed(w, r) {
		return
	}
	result, err := h.Finance.ListExpenses(r.Context(), caller, filter, page)
	if err != nil {
		h.writeError(w, withCaller(r, caller), err)
		return
	}
	writePage(w, page, result.Total, result.Items, result.Currency, expenseOf)
}

func (h *handler) createExpense(w http.ResponseWriter, r *http.Request, caller domain.Membership) {
	var body struct {
		SpentOn     *string `json:"spentOn"`
		Category    *string `json:"category"`
		AmountMinor *int64  `json:"amountMinor"`
		Description *string `json:"description"`
		Note        *string `json:"note"`
	}
	if !decode(w, r, &body) {
		return
	}
	var v []violation
	for _, field := range []struct {
		name    string
		present bool
	}{{"spentOn", body.SpentOn != nil}, {"category", body.Category != nil}, {"amountMinor", body.AmountMinor != nil},
		{"description", body.Description != nil}} {
		if !field.present {
			v = append(v, violation{field.name, "REQUIRED", messageOf("REQUIRED")})
		}
	}
	var spentOn time.Time
	if body.SpentOn != nil {
		var err error
		if spentOn, err = time.Parse(time.DateOnly, *body.SpentOn); err != nil {
			v = append(v, violation{"spentOn", "INVALID", messageOf("INVALID")})
		}
	}
	if len(v) > 0 {
		writeProblem(w, r, validation, "VALIDATION_FAILED", "", v)
		return
	}
	view, err := h.Finance.CreateExpense(r.Context(), caller, domain.ExpenseInput{SpentOn: spentOn,
		Category: *body.Category, AmountMinor: *body.AmountMinor, Description: *body.Description, Note: body.Note})
	if err == nil {
		w.Header().Set("Location", expenses+"/"+view.Expense.ID.String())
	}
	h.answerExpense(w, withCaller(r, caller), http.StatusCreated, view, err)
}

func (h *handler) getExpense(w http.ResponseWriter, r *http.Request, caller domain.Membership, id domain.UUID) {
	view, err := h.Finance.Expense(r.Context(), caller, domain.ExpenseID(id))
	h.answerExpense(w, r, http.StatusOK, view, err)
}

func (h *handler) patchExpense(w http.ResponseWriter, r *http.Request, caller domain.Membership, id domain.UUID) {
	var body map[string]jsonRaw
	if !decode(w, r, &body) {
		return
	}
	changes, violations := expenseChanges(body)
	if len(violations) > 0 {
		writeProblem(w, r, validation, "VALIDATION_FAILED", "", violations)
		return
	}
	view, err := h.Finance.UpdateExpense(r.Context(), caller, domain.ExpenseID(id), changes)
	h.answerExpense(w, r, http.StatusOK, view, err)
}

func (h *handler) deleteExpense(w http.ResponseWriter, r *http.Request, caller domain.Membership, id domain.UUID) {
	if err := h.Finance.DeleteExpense(r.Context(), caller, domain.ExpenseID(id)); err != nil {
		h.writeError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// expenseChanges reads an UpdateExpenseRequest: at least one property, only the contract's properties, `clear` an
// array of unique clearable names (note); spentOn a date.
func expenseChanges(body map[string]jsonRaw) (domain.ExpenseChanges, []violation) {
	var changes domain.ExpenseChanges
	var v []violation
	add := func(field, code string) { v = append(v, violation{field, code, messageOf(code)}) }
	if len(body) == 0 {
		add("body", "EMPTY_UPDATE")
	}
	var spentOn *string
	var clear []string
	fields := map[string]any{"spentOn": &spentOn, "category": &changes.Category, "amountMinor": &changes.AmountMinor,
		"description": &changes.Description, "note": &changes.Note, "clear": &clear}
	for name, raw := range body {
		into, known := fields[name]
		switch {
		case !known:
			add(safeField(name), "UNKNOWN_PROPERTY")
		case bytes.Equal(bytes.TrimSpace(raw), []byte("null")):
			// absent or null = unchanged (ADR-0032)
		case json.Unmarshal(raw, into) != nil:
			add(name, "INVALID_TYPE")
		}
	}
	changes.ClearNote = readClearList(clear, map[string]bool{"note": true}, add)["note"]
	if spentOn != nil {
		if day, err := time.Parse(time.DateOnly, *spentOn); err != nil {
			add("spentOn", "INVALID")
		} else {
			changes.SpentOn = &day
		}
	}
	return changes, v
}

// readClearList checks a `clear` list: each name clearable and named once (else INVALID); returns the names seen.
func readClearList(names []string, clearable map[string]bool, add func(field, code string)) map[string]bool {
	seen := map[string]bool{}
	for _, name := range names {
		if !clearable[name] || seen[name] {
			add("clear", "INVALID")
			continue
		}
		seen[name] = true
	}
	return seen
}

// --- balance

func (h *handler) seasonBalance(w http.ResponseWriter, r *http.Request, caller domain.Membership) {
	q := newQuery(r)
	season := q.uuid("seasonId")
	if season == nil && q.values.Get("seasonId") == "" {
		q.violations = append(q.violations, violation{"seasonId", "REQUIRED", messageOf("REQUIRED")})
	}
	if q.failed(w, r) {
		return
	}
	view, err := h.Finance.SeasonBalance(r.Context(), caller, domain.SeasonID(*season))
	if err != nil {
		h.writeError(w, withCaller(r, caller), err)
		return
	}
	b := view.Balance
	type categoryDTO struct {
		Category   string `json:"category"`
		TotalMinor int64  `json:"totalMinor"`
	}
	categories := make([]categoryDTO, len(b.ByCategory))
	for i, c := range b.ByCategory {
		categories[i] = categoryDTO{Category: string(c.Category), TotalMinor: c.TotalMinor}
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"seasonId": b.Season.String(), "from": day(b.Dates.Start), "to": day(b.Dates.End),
		"currency": view.Currency.Code(),
		"income": map[string]int64{"paidMinor": b.Income.PaidMinor, "openMinor": b.Income.OpenMinor,
			"waivedMinor": b.Income.WaivedMinor},
		"expenses": map[string]any{"totalMinor": b.ExpensesMinor, "byCategory": categories},
		"netMinor": b.NetMinor,
	})
}

// --- CSV exports (ADR-0048); the use cases gather the rows and audit, the file is rendered here

func (h *handler) exportDues(w http.ResponseWriter, r *http.Request, caller domain.Membership) {
	q := newQuery(r)
	filter := dueFilterOf(q)
	if q.failed(w, r) {
		return
	}
	result, err := h.Finance.ExportDues(r.Context(), caller, filter)
	if err != nil {
		h.writeError(w, withCaller(r, caller), err)
		return
	}
	labels := export.LabelsOf(export.Negotiate(r.Header.Get("Accept-Language")))
	doc := export.NewDocument(labels.DueHeader())
	currency := codeOf(result.Currency)
	for _, record := range result.Rows {
		d := record.Due
		paidOn, method := "", ""
		if record.Payment != nil {
			paidOn, method = day(record.Payment.Payment.PaidOn), labels.Value(string(record.Payment.Payment.Method))
		}
		doc.Row(export.Text(d.Period), export.Text(day(d.Start)), export.Text(day(d.End)), export.Text(record.PlanName),
			export.Text(record.PlayerName), export.Text(record.TeamName), export.Number(d.Amount.Minor()),
			export.Text(currency), export.Text(labels.Value(string(d.Status))), export.Text(paidOn), export.Text(method))
	}
	writeCSV(w, export.FileName(result.File.Slug, "dues", result.File.Today), doc)
}

func (h *handler) exportExpenses(w http.ResponseWriter, r *http.Request, caller domain.Membership) {
	q := newQuery(r)
	filter := expenseFilterOf(q)
	if q.failed(w, r) {
		return
	}
	result, err := h.Finance.ExportExpenses(r.Context(), caller, filter)
	if err != nil {
		h.writeError(w, withCaller(r, caller), err)
		return
	}
	labels := export.LabelsOf(export.Negotiate(r.Header.Get("Accept-Language")))
	doc := export.NewDocument(labels.ExpenseHeader())
	currency := codeOf(result.Currency)
	for _, e := range result.Rows {
		doc.Row(export.Text(day(e.SpentOn)), export.Text(labels.Value(string(e.Category))), export.Text(string(e.Category)),
			export.Number(e.Amount.Minor()), export.Text(currency), export.Text(e.Description))
	}
	writeCSV(w, export.FileName(result.File.Slug, "expenses", result.File.Today), doc)
}

func codeOf(currency *domain.Currency) string {
	if currency == nil {
		return ""
	}
	return currency.Code()
}

// writeCSV answers a file: text/csv, an attachment with its name; Cache-Control no-store is set for every answer.
func writeCSV(w http.ResponseWriter, name string, doc *export.Document) {
	w.Header().Set("Content-Type", "text/csv; charset=utf-8")
	w.Header().Set("Content-Disposition", export.ContentDisposition(name))
	w.WriteHeader(http.StatusOK)
	// a text/csv attachment (nosniff, CSP default-src none): the cells are data, quoted and formula-guarded by ADR-0048
	_, _ = w.Write(doc.Bytes()) //nolint:gosec // G705: not HTML; see above
}
