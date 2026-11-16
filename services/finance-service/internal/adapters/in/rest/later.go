package rest

import (
	"net/http"
	"strings"

	"hoopsacademy.local/finance/internal/domain"
)

// laterOperations are finance.yaml's operations not built in WP118 (method, contract path, Go pattern): dues and
// payments (WP119), expenses, balance and exports (WP123). A member gets 501 NOT_IMPLEMENTED after the same
// authentication and tenant filter as every operation; the route moves to its own handler when it is built.
var laterOperations = []struct{ method, path, pattern string }{
	{"POST", "/api/finance/fee-plans/{feePlanId}/dues:generate", "/api/finance/fee-plans/{id}/dues:generate"},
	{"GET", "/api/finance/dues", "/api/finance/dues"},
	{"GET", "/api/finance/dues:export", "/api/finance/dues:export"},
	{"GET", "/api/finance/dues/{dueId}", "/api/finance/dues/{id}"},
	{"POST", "/api/finance/dues/{dueId}:<verb>", "/api/finance/dues/{target}"}, // :change-amount, :waive, :pay
	{"POST", "/api/finance/payments/{paymentId}:void", "/api/finance/payments/{target}"},
	{"GET", "/api/finance/teams/{teamId}/due-status", "/api/finance/teams/{id}/due-status"},
	{"GET", "/api/finance/players/{playerId}/dues", "/api/finance/players/{id}/dues"},
	{"GET", "/api/finance/expenses", "/api/finance/expenses"},
	{"POST", "/api/finance/expenses", "/api/finance/expenses"},
	{"GET", "/api/finance/expenses:export", "/api/finance/expenses:export"},
	{"GET", "/api/finance/expenses/{expenseId}", "/api/finance/expenses/{id}"},
	{"PATCH", "/api/finance/expenses/{expenseId}", "/api/finance/expenses/{id}"},
	{"DELETE", "/api/finance/expenses/{expenseId}", "/api/finance/expenses/{id}"},
	{"GET", "/api/finance/balance", "/api/finance/balance"},
}

var laterVerbs = map[string][]string{
	"/api/finance/dues/{target}":     {"change-amount", "waive", "pay"},
	"/api/finance/payments/{target}": {"void"},
}

func (h *handler) notImplementedRoutes(mux *http.ServeMux) {
	for _, op := range laterOperations {
		verbs := laterVerbs[op.pattern]
		path := op.path
		mux.HandleFunc(op.method+" "+op.pattern, func(w http.ResponseWriter, r *http.Request) {
			if verbs != nil {
				_, verb, _ := strings.Cut(r.PathValue("target"), ":")
				if !contains(verbs, verb) {
					writeProblem(w, r, notFound, "", "", nil)
					return
				}
				path = strings.Replace(op.path, "<verb>", verb, 1)
			}
			h.api(path, func(w http.ResponseWriter, r *http.Request, _ domain.Membership) {
				writeProblem(w, r, notImplemented, "NOT_IMPLEMENTED", "this operation of finance.yaml is not built yet", nil)
			})(w, r)
		})
	}
}

func contains(values []string, value string) bool {
	for _, v := range values {
		if v == value {
			return true
		}
	}
	return false
}
