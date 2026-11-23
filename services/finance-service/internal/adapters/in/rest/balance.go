package rest

import (
	"net/http"

	"hoopsacademy.local/finance/internal/domain"
)

// seasonBalance answers GET /api/finance/balance: a season's income, expenses and net.
func (h *handler) seasonBalance(w http.ResponseWriter, r *http.Request, caller domain.Membership) {
	q := newQuery(r)
	season := q.uuid("seasonId")
	if season == nil && q.values.Get("seasonId") == "" {
		q.violations = append(q.violations, missing("seasonId"))
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
