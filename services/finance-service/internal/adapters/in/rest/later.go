package rest

import (
	"net/http"

	"hoopsacademy.local/finance/internal/domain"
)

// laterOperations are finance.yaml's operations not built yet (method, contract path, Go pattern): the dues export,
// expenses and the balance (WP123). A member gets 501 NOT_IMPLEMENTED after the same authentication and tenant
// filter as every operation; the route moves to its own handler when it is built.
var laterOperations = []struct{ method, path, pattern string }{
	{"GET", "/api/finance/dues:export", "/api/finance/dues:export"},
	{"GET", "/api/finance/expenses", "/api/finance/expenses"},
	{"POST", "/api/finance/expenses", "/api/finance/expenses"},
	{"GET", "/api/finance/expenses:export", "/api/finance/expenses:export"},
	{"GET", "/api/finance/expenses/{expenseId}", "/api/finance/expenses/{id}"},
	{"PATCH", "/api/finance/expenses/{expenseId}", "/api/finance/expenses/{id}"},
	{"DELETE", "/api/finance/expenses/{expenseId}", "/api/finance/expenses/{id}"},
	{"GET", "/api/finance/balance", "/api/finance/balance"},
}

func (h *handler) notImplementedRoutes(mux *http.ServeMux) {
	for _, op := range laterOperations {
		mux.HandleFunc(op.method+" "+op.pattern, h.api(op.path,
			func(w http.ResponseWriter, r *http.Request, _ domain.Membership) {
				writeProblem(w, r, notImplemented, "NOT_IMPLEMENTED", "this operation of finance.yaml is not built yet", nil)
			}))
	}
}
