package rest_test

import (
	"fmt"
	"strings"
	"testing"
	"time"

	"hoopsacademy.local/finance/internal/platform/security"
)

var zeroTime time.Time

func expenseBody(day, category string, amount int) map[string]any {
	return map[string]any{"spentOn": day, "category": category, "amountMinor": amount, "description": "Court, " + day}
}

func (a *api) createExpense(t *testing.T, tenant string, body map[string]any) map[string]any {
	t.Helper()
	return expect(t, a.do(t, call{method: "POST", path: "/api/finance/expenses", tenant: tenant, subject: admin,
		body: body}), 201).json(t)
}

// docs/domain/authz-matrix.md, section Finance: expenses, the season balance and both CSV exports are ADMIN's
// (decision 96); every other member 403 (security event `role`), a non-member 404.
func TestRoleMatrixOfExpensesBalanceAndExports(t *testing.T) {
	a := newAPI(t)
	s := a.seedAcademy(t, roster())
	s.team(uuid(), false)
	a.withEuro(t, s.id())
	type operation struct {
		name, method, path string
		body               any
		success            int
	}
	operations := func(expense string) []operation {
		path := "/api/finance/expenses/" + expense
		return []operation{
			{"listExpenses", "GET", "/api/finance/expenses", nil, 200},
			{"createExpense", "POST", "/api/finance/expenses", expenseBody("2026-10-01", "KIT", 3000), 201},
			{"getExpense", "GET", path, nil, 200},
			{"updateExpense", "PATCH", path, map[string]any{"amountMinor": 3100}, 200},
			{"exportExpenses", "GET", "/api/finance/expenses:export", nil, 200},
			{"exportDues", "GET", "/api/finance/dues:export", nil, 200},
			{"getSeasonBalance", "GET", "/api/finance/balance?seasonId=" + s.season, nil, 200},
			{"deleteExpense", "DELETE", path, nil, 204},
		}
	}
	callers := map[string]bool{
		admin: true, "admin+coach": true, coach: false, assistant: false, parent: false, player: false,
		"coach+parent": false,
	}
	for subject, allowed := range callers {
		expense := a.createExpense(t, s.id(), expenseBody("2026-10-02", "TRAVEL", 900))["id"].(string)
		for _, op := range operations(expense) {
			want := op.success
			if !allowed {
				want = 403
			}
			before := a.events.Count(security.Role)
			got := a.do(t, call{method: op.method, path: op.path, tenant: s.id(), subject: subject, body: op.body})
			if got.status != want {
				t.Errorf("%s %s: %d, want %d (%s)", subject, op.name, got.status, want, got.body)
			}
			if !allowed && a.events.Count(security.Role) != before+1 {
				t.Errorf("%s %s: the 403 was not a security event of kind role", subject, op.name)
			}
		}
	}
	expense := a.createExpense(t, s.id(), expenseBody("2026-10-02", "TRAVEL", 900))["id"].(string)
	for _, op := range operations(expense) {
		if got := a.do(t, call{method: op.method, path: op.path, tenant: s.id(), subject: stranger, body: op.body}); got.status != 404 {
			t.Errorf("non-member %s: %d", op.name, got.status)
		}
	}
}

// The commit hook's isolation check (`TestCrossTenant*`): academy B's admin never reads, changes or exports A's
// expenses, nor A's balance, by id, in a list, in a file, or by naming A's tenant.
func TestCrossTenantExpensesBalanceAndExportsAreRefused(t *testing.T) {
	a := newAPI(t)
	academyA := a.seedAcademy(t, map[string][]string{"admin-a": {"ADMIN"}})
	academyA.team(uuid(), false)
	academyB := a.academy(t, map[string][]string{"admin-b": {"ADMIN"}})
	for _, tenant := range []string{academyA.id(), academyB} {
		subject := map[bool]string{true: "admin-a", false: "admin-b"}[tenant == academyA.id()]
		expect(t, a.do(t, call{method: "PUT", path: "/api/finance/settings", tenant: tenant, subject: subject,
			body: map[string]any{"currency": "EUR"}}), 200)
	}
	secret := "Secret court of A"
	created := expect(t, a.do(t, call{method: "POST", path: "/api/finance/expenses", tenant: academyA.id(),
		subject: "admin-a", body: map[string]any{"spentOn": "2026-10-01", "category": "KIT", "amountMinor": 777,
			"description": secret}}), 201).json(t)
	path := "/api/finance/expenses/" + created["id"].(string)

	expect(t, a.do(t, call{method: "GET", path: path, tenant: academyB, subject: "admin-b"}), 404)
	expect(t, a.do(t, call{method: "PATCH", path: path, tenant: academyB, subject: "admin-b",
		body: map[string]any{"amountMinor": 1}}), 404)
	expect(t, a.do(t, call{method: "DELETE", path: path, tenant: academyB, subject: "admin-b"}), 404)
	list := expect(t, a.do(t, call{method: "GET", path: "/api/finance/expenses", tenant: academyB, subject: "admin-b"}), 200).json(t)
	if items := list["items"].([]any); len(items) != 0 {
		t.Errorf("B lists A's expenses: %v", items)
	}
	file := expect(t, a.do(t, call{method: "GET", path: "/api/finance/expenses:export", tenant: academyB,
		subject: "admin-b"}), 200)
	if strings.Contains(string(file.body), secret) || strings.Count(string(file.body), "\r\n") != 1 {
		t.Errorf("B's file holds A's rows: %q", file.body)
	}
	expect(t, a.do(t, call{method: "GET", path: "/api/finance/balance?seasonId=" + academyA.season, tenant: academyB,
		subject: "admin-b"}), 404)
	for _, p := range []string{path, "/api/finance/expenses", "/api/finance/expenses:export", "/api/finance/dues:export",
		"/api/finance/balance?seasonId=" + academyA.season} {
		expect(t, a.do(t, call{method: "GET", path: p, tenant: academyA.id(), subject: "admin-b"}), 404)
	}
	got := expect(t, a.do(t, call{method: "GET", path: path, tenant: academyA.id(), subject: "admin-a"}), 200).json(t)
	if got["description"] != secret || got["amountMinor"] != float64(777) {
		t.Errorf("A's expense changed: %v", got)
	}
}

func TestAnExpenseIsRecordedListedCorrectedAndDeleted(t *testing.T) {
	a := newAPI(t)
	academy := a.academy(t, roster())
	notSet := expect(t, a.do(t, call{method: "POST", path: "/api/finance/expenses", tenant: academy, subject: admin,
		body: expenseBody("2026-10-01", "KIT", 3000)}), 409)
	if problemCode(t, notSet) != "CURRENCY_NOT_SET" {
		t.Errorf("no currency: %s", notSet.body)
	}
	a.withEuro(t, academy)

	note := "Invoice 2026/41 for the hall"
	body := expenseBody("2026-10-01", "COURT_RENTAL", 12000)
	body["note"] = note
	response := expect(t, a.do(t, call{method: "POST", path: "/api/finance/expenses", tenant: academy, subject: admin,
		body: body}), 201)
	created := response.json(t)
	id := created["id"].(string)
	if response.header.Get("Location") != "/api/finance/expenses/"+id || created["currency"] != "EUR" ||
		created["category"] != "COURT_RENTAL" || created["amountMinor"] != float64(12000) || created["note"] != note ||
		created["spentOn"] != "2026-10-01" {
		t.Errorf("created %v (Location %s)", created, response.header.Get("Location"))
	}
	a.createExpense(t, academy, expenseBody("2026-10-05", "KIT", 3000))
	a.createExpense(t, academy, expenseBody("2026-09-20", "TRAVEL", 900))
	a.createExpense(t, academy, expenseBody("2026-10-05", "TRAVEL", 1500))

	list := func(query string) []string {
		page := expect(t, a.do(t, call{method: "GET", path: "/api/finance/expenses?" + query, tenant: academy,
			subject: admin}), 200).json(t)
		var days []string
		for _, item := range page["items"].([]any) {
			e := item.(map[string]any)
			days = append(days, e["spentOn"].(string)+" "+e["category"].(string))
		}
		return days
	}
	if got := strings.Join(list(""), ","); got != "2026-10-05 TRAVEL,2026-10-05 KIT,2026-10-01 COURT_RENTAL,2026-09-20 TRAVEL" {
		t.Errorf("newest first (day, then creation): %s", got)
	}
	if got := strings.Join(list("category=TRAVEL&from=2026-10-01&to=2026-10-31"), ","); got != "2026-10-05 TRAVEL" {
		t.Errorf("filters: %s", got)
	}
	page := expect(t, a.do(t, call{method: "GET", path: "/api/finance/expenses?page=1&size=3", tenant: academy,
		subject: admin}), 200).json(t)
	if meta := page["page"].(map[string]any); meta["totalElements"] != float64(4) || meta["totalPages"] != float64(2) ||
		len(page["items"].([]any)) != 1 {
		t.Errorf("page %v", page)
	}
	for _, query := range []string{"category=FOOD", "from=yesterday", "size=0", "page=-1"} {
		expect(t, a.do(t, call{method: "GET", path: "/api/finance/expenses?" + query, tenant: academy, subject: admin}), 400)
	}

	path := "/api/finance/expenses/" + id
	changed := expect(t, a.do(t, call{method: "PATCH", path: path, tenant: academy, subject: admin,
		body: map[string]any{"amountMinor": 12500, "clear": []string{"note"}}}), 200).json(t)
	if changed["amountMinor"] != float64(12500) || changed["note"] != nil || changed["description"] != body["description"] {
		t.Errorf("changed %v", changed)
	}
	unchanged := expect(t, a.do(t, call{method: "PATCH", path: path, tenant: academy, subject: admin,
		body: map[string]any{"category": "COURT_RENTAL"}}), 200).json(t)
	if unchanged["updatedAt"] != changed["updatedAt"] {
		t.Error("a correction without a change touched the expense")
	}
	for name, bad := range map[string]string{
		"empty":         `{}`,
		"cleared+set":   `{"note":"x","clear":["note"]}`,
		"clear unknown": `{"clear":["description"]}`,
		"unknown":       `{"payee":"Ana"}`,
		"wrong type":    `{"amountMinor":"12"}`,
		"bad day":       `{"spentOn":"2026-13-01"}`,
		"bad category":  `{"category":"FOOD"}`,
		"blank":         `{"description":"  "}`,
	} {
		if got := a.do(t, call{method: "PATCH", path: path, tenant: academy, subject: admin, body: bad}); got.status != 400 {
			t.Errorf("%s: %d %s", name, got.status, got.body)
		}
	}
	for name, bad := range map[string]map[string]any{
		"missing":   {"category": "KIT", "amountMinor": 1},
		"zero":      {"spentOn": "2026-10-01", "category": "KIT", "amountMinor": 0, "description": "x"},
		"day":       {"spentOn": "01/10/2026", "category": "KIT", "amountMinor": 1, "description": "x"},
		"long note": {"spentOn": "2026-10-01", "category": "KIT", "amountMinor": 1, "description": "x", "note": strings.Repeat("n", 201)},
	} {
		if got := a.do(t, call{method: "POST", path: "/api/finance/expenses", tenant: academy, subject: admin, body: bad}); got.status != 400 {
			t.Errorf("%s: %d %s", name, got.status, got.body)
		}
	}
	expect(t, a.do(t, call{method: "DELETE", path: path, tenant: academy, subject: admin}), 204)
	expect(t, a.do(t, call{method: "GET", path: path, tenant: academy, subject: admin}), 404)
	expect(t, a.do(t, call{method: "DELETE", path: path, tenant: academy, subject: admin}), 404)
	expect(t, a.do(t, call{method: "GET", path: "/api/finance/expenses/" + uuid(), tenant: academy, subject: admin}), 404)
	expect(t, a.do(t, call{method: "GET", path: "/api/finance/expenses/nope", tenant: academy, subject: admin}), 400)

	want := "finance.settings_changed,expense.created,expense.created,expense.created,expense.created,expense.updated,expense.deleted"
	if got := strings.Join(a.auditActions(t, academy), ","); got != want {
		t.Errorf("audit trail %s", got)
	}
	metadata := a.text(t, academy, "select string_agg(metadata::text, ' ') from finance.audit_event")
	for _, private := range []string{note, "Court, 2026", "12000"} {
		if strings.Contains(metadata, private) || strings.Contains(a.logs.String(), private) {
			t.Errorf("%q reached the audit metadata or the log: %s", private, metadata)
		}
	}
	if !strings.Contains(metadata, `"fields": ["amountMinor", "note"]`) || !strings.Contains(metadata, `"category": "COURT_RENTAL"`) {
		t.Errorf("audit metadata: %s", metadata)
	}
}

// ADR-0056 amendment WP123: an expense is kept in the academy's currency too, so the first one fixes the currency.
func TestTheFirstExpenseLocksTheCurrency(t *testing.T) {
	a := newAPI(t)
	academy := a.academy(t, roster())
	a.withEuro(t, academy)
	expect(t, a.do(t, call{method: "PUT", path: "/api/finance/settings", tenant: academy, subject: admin,
		body: map[string]any{"currency": "USD"}}), 200)
	a.createExpense(t, academy, expenseBody("2026-10-01", "KIT", 3000))
	locked := expect(t, a.do(t, call{method: "PUT", path: "/api/finance/settings", tenant: academy, subject: admin,
		body: map[string]any{"currency": "EUR"}}), 409)
	if problemCode(t, locked) != "CURRENCY_LOCKED" {
		t.Errorf("locked: %s", locked.body)
	}
	if got := expect(t, a.do(t, call{method: "GET", path: "/api/finance/settings", tenant: academy, subject: admin}), 200).json(t); got["currencyLocked"] != true || got["currency"] != "USD" {
		t.Errorf("settings %v", got)
	}
}

// The season balance: dues of the season's plans by status (PAID by the paid amount), expenses within the season's
// dates by category (all six), net = paid - expenses.
func TestTheSeasonBalanceSumsDuesByStatusAndExpensesByCategory(t *testing.T) {
	a := newAPI(t)
	s := a.seedAcademy(t, roster())
	team := s.team(uuid(), false)
	for _, name := range []string{"Ana", "Ben", "Cris", "Dani"} {
		s.assign(team, s.player(name, ""), s.start, zeroTime)
	}
	plan := s.plan(team, 4500)
	s.generate(plan, month(0), false)
	byName := map[string]string{}
	for _, item := range s.dues("period=" + month(0)) {
		due := item.(map[string]any)
		byName[due["playerName"].(string)] = due["id"].(string)
	}
	expect(t, s.post("/api/finance/dues/"+byName["Ana"]+":pay", map[string]any{"paidOn": todayUTC(), "method": "CASH"}), 200)
	paid := expect(t, s.post("/api/finance/dues/"+byName["Ben"]+":pay", map[string]any{"paidOn": todayUTC(),
		"method": "CARD"}), 200).json(t)
	expect(t, s.post("/api/finance/payments/"+paid["payment"].(map[string]any)["id"].(string)+":void",
		map[string]any{"reason": "wrong due"}), 200) // Ben is OPEN again
	expect(t, s.post("/api/finance/dues/"+byName["Cris"]+":change-amount", map[string]any{"amountMinor": 2000,
		"reason": "sibling"}), 200)
	expect(t, s.post("/api/finance/dues/"+byName["Cris"]+":waive", map[string]any{"reason": "hardship"}), 200)
	expect(t, s.post("/api/finance/dues/"+byName["Dani"]+":change-amount", map[string]any{"amountMinor": 4000,
		"reason": "late joiner"}), 200)
	expect(t, s.post("/api/finance/dues/"+byName["Dani"]+":pay", map[string]any{"paidOn": todayUTC(),
		"method": "BANK_TRANSFER"}), 200)
	// another season's plan and dues do not count
	other := s.team(uuid(), true)
	s.assign(other, s.player("Eva", ""), firstOfMonth(-13), zeroTime)
	otherPlan := a.createPlan(t, s.id(), map[string]any{"name": "Old", "seasonId": a.text(t, s.id(),
		"select season_id::text from finance.team_ref where id = $1", other), "teamId": other, "amountMinor": 999,
		"cadence": "SEASON", "autoGenerate": false})["id"].(string)
	s.generate(otherPlan, "SEASON", false)

	a.createExpense(t, s.id(), expenseBody(dateOf(s.start), "KIT", 3000))
	a.createExpense(t, s.id(), expenseBody(dateOf(s.end), "COURT_RENTAL", 12000))
	a.createExpense(t, s.id(), expenseBody(dateOf(s.end), "COURT_RENTAL", 500))
	a.createExpense(t, s.id(), expenseBody(dateOf(s.start.AddDate(0, 0, -1)), "SALARIES", 70000)) // before the season
	a.createExpense(t, s.id(), expenseBody(dateOf(s.end.AddDate(0, 0, 1)), "TRAVEL", 80000))      // after it

	balance := expect(t, a.do(t, call{method: "GET", path: "/api/finance/balance?seasonId=" + s.season, tenant: s.id(),
		subject: admin}), 200).json(t)
	income := balance["income"].(map[string]any)
	expenses := balance["expenses"].(map[string]any)
	if balance["seasonId"] != s.season || balance["from"] != dateOf(s.start) || balance["to"] != dateOf(s.end) ||
		balance["currency"] != "EUR" || income["paidMinor"] != float64(8500) || income["openMinor"] != float64(4500) ||
		income["waivedMinor"] != float64(2000) || expenses["totalMinor"] != float64(15500) ||
		balance["netMinor"] != float64(-7000) {
		t.Errorf("balance %v", balance)
	}
	var categories []string
	for _, item := range expenses["byCategory"].([]any) {
		c := item.(map[string]any)
		categories = append(categories, fmt.Sprintf("%s=%d", c["category"], int64(c["totalMinor"].(float64))))
	}
	if got := strings.Join(categories, ","); got != "COURT_RENTAL=12500,SALARIES=0,KIT=3000,TOURNAMENT_FEES=0,TRAVEL=0,OTHER=0" {
		t.Errorf("by category %s", got)
	}

	expect(t, a.do(t, call{method: "GET", path: "/api/finance/balance?seasonId=" + uuid(), tenant: s.id(), subject: admin}), 404)
	expect(t, a.do(t, call{method: "GET", path: "/api/finance/balance", tenant: s.id(), subject: admin}), 400)
	expect(t, a.do(t, call{method: "GET", path: "/api/finance/balance?seasonId=nope", tenant: s.id(), subject: admin}), 400)

	// a season the replica knows, in an academy that chose no currency yet: nothing to balance (404)
	fresh := a.seedAcademy(t, map[string][]string{"admin-fresh": {"ADMIN"}})
	fresh.team(uuid(), false)
	expect(t, a.do(t, call{method: "GET", path: "/api/finance/balance?seasonId=" + fresh.season, tenant: fresh.id(),
		subject: "admin-fresh"}), 404)
}
