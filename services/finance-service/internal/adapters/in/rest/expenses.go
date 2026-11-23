package rest

import (
	"bytes"
	"encoding/json"
	"net/http"
	"time"

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
	v := required(field{"spentOn", body.SpentOn != nil}, field{"category", body.Category != nil},
		field{"amountMinor", body.AmountMinor != nil}, field{"description", body.Description != nil})
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
