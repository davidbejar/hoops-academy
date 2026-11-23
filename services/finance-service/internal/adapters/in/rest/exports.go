package rest

import (
	"net/http"

	"hoopsacademy.local/finance/internal/adapters/in/export"
	"hoopsacademy.local/finance/internal/domain"
)

// CSV exports (ADR-0048); the use cases gather the rows and audit, the file is rendered here

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
