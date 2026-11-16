package rest_test

import (
	"context"
	"fmt"
	"strings"
	"testing"

	"hoopsacademy.local/finance/internal/platform/security"
	"hoopsacademy.local/finance/internal/testsupport/contract"
)

// The commit hook's isolation check through the API (counterpart of core's CrossTenantAccessTest): academy A's
// admin creates a plan; academy B's admin never reads it, by id, in the list, or by naming A's tenant.
func TestCrossTenantAccessThroughTheAPIIsRefused(t *testing.T) {
	a := newAPI(t)
	academyA := a.academy(t, map[string][]string{"admin-a": {"ADMIN"}})
	academyB := a.academy(t, map[string][]string{"admin-b": {"ADMIN"}})
	expect(t, a.do(t, call{method: "PUT", path: "/api/finance/settings", tenant: academyA, subject: "admin-a",
		body: map[string]any{"currency": "EUR"}}), 200)
	plan := expect(t, a.do(t, call{method: "POST", path: "/api/finance/fee-plans", tenant: academyA, subject: "admin-a",
		body: monthlyPlan()}), 201).json(t)
	path := "/api/finance/fee-plans/" + plan["id"].(string)

	expect(t, a.do(t, call{method: "GET", path: path, tenant: academyA, subject: "admin-a"}), 200)
	expect(t, a.do(t, call{method: "GET", path: path, tenant: academyB, subject: "admin-b"}), 404)
	expect(t, a.do(t, call{method: "PATCH", path: path, tenant: academyB, subject: "admin-b",
		body: map[string]any{"name": "taken over"}}), 404)
	expect(t, a.do(t, call{method: "DELETE", path: path, tenant: academyB, subject: "admin-b"}), 404)
	list := expect(t, a.do(t, call{method: "GET", path: "/api/finance/fee-plans?includeArchived=true", tenant: academyB,
		subject: "admin-b"}), 200).json(t)
	if items := list["items"].([]any); len(items) != 0 {
		t.Errorf("B lists A's plans: %v", items)
	}
	before := a.events.Count(security.NotMember)
	expect(t, a.do(t, call{method: "GET", path: path, tenant: academyA, subject: "admin-b"}), 404)
	expect(t, a.do(t, call{method: "GET", path: "/api/finance/settings", tenant: academyA, subject: "admin-b"}), 404)
	if a.events.Count(security.NotMember) != before+2 {
		t.Error("a non-member's request is a security event not_member")
	}
	expect(t, a.do(t, call{method: "GET", path: path, tenant: academyA, subject: "admin-a"}), 200)
}

// docs/domain/authz-matrix.md, section Finance: "Settings and fee plans" ADMIN only; other members 403; non-members 404.
func TestRoleMatrixOfSettingsAndFeePlans(t *testing.T) {
	a := newAPI(t)
	academy := a.academy(t, roster())
	a.withCurrency(t, academy, "EUR")
	type operation struct {
		name, method, path string
		body               any
		success            int
	}
	operations := func(planID string) []operation {
		plan := "/api/finance/fee-plans/" + planID
		return []operation{
			{"getFinanceSettings", "GET", "/api/finance/settings", nil, 200},
			{"updateFinanceSettings", "PUT", "/api/finance/settings", map[string]any{"currency": "EUR"}, 200},
			{"listFeePlans", "GET", "/api/finance/fee-plans", nil, 200},
			{"createFeePlan", "POST", "/api/finance/fee-plans", monthlyPlan(), 201},
			{"getFeePlan", "GET", plan, nil, 200},
			{"updateFeePlan", "PATCH", plan, map[string]any{"autoGenerate": false}, 200},
			{"archiveFeePlan", "POST", plan + ":archive", nil, 200},
			{"unarchiveFeePlan", "POST", plan + ":unarchive", nil, 200},
			{"deleteFeePlan", "DELETE", plan, nil, 204},
		}
	}
	callers := map[string]bool{ // subject -> allowed
		admin: true, "admin+coach": true, coach: false, assistant: false, parent: false, player: false,
		"coach+parent": false,
	}
	for subject, allowed := range callers {
		planID := a.createPlan(t, academy, monthlyPlan())["id"].(string)
		for _, op := range operations(planID) {
			want := op.success
			if !allowed {
				want = 403
			}
			before := a.events.Count(security.Role)
			got := a.do(t, call{method: op.method, path: op.path, tenant: academy, subject: subject, body: op.body})
			if got.status != want {
				t.Errorf("%s %s: %d, want %d (%s)", subject, op.name, got.status, want, got.body)
			}
			if !allowed && a.events.Count(security.Role) != before+1 {
				t.Errorf("%s %s: the 403 was not a security event of kind role", subject, op.name)
			}
		}
	}
	planID := a.createPlan(t, academy, monthlyPlan())["id"].(string)
	for _, op := range operations(planID) {
		got := a.do(t, call{method: op.method, path: op.path, tenant: academy, subject: stranger, body: op.body})
		if got.status != 404 {
			t.Errorf("non-member %s: %d", op.name, got.status)
		}
	}
}

func TestTheCurrencyIsChosenOnceAndLockedByTheFirstDue(t *testing.T) {
	a := newAPI(t)
	academy := a.academy(t, roster())

	fresh := expect(t, a.do(t, call{method: "GET", path: "/api/finance/settings", tenant: academy, subject: admin}), 200).json(t)
	if fresh["currency"] != nil || fresh["minorDigits"] != nil || fresh["currencyLocked"] != false {
		t.Errorf("fresh settings %v", fresh)
	}
	expect(t, a.do(t, call{method: "POST", path: "/api/finance/fee-plans", tenant: academy, subject: admin,
		body: monthlyPlan()}), 409)
	chosen := expect(t, a.do(t, call{method: "PUT", path: "/api/finance/settings", tenant: academy, subject: admin,
		body: map[string]any{"currency": "JPY"}}), 200).json(t)
	if chosen["currency"] != "JPY" || chosen["minorDigits"] != float64(0) {
		t.Errorf("chosen %v", chosen)
	}
	unknown := expect(t, a.do(t, call{method: "PUT", path: "/api/finance/settings", tenant: academy, subject: admin,
		body: map[string]any{"currency": "XAU"}}), 422)
	if problemCode(t, unknown) != "UNKNOWN_CURRENCY" {
		t.Errorf("unknown currency: %s", unknown.body)
	}
	plan := a.createPlan(t, academy, monthlyPlan())
	a.bound(t, academy, `insert into finance.due (tenant_id, id, fee_plan_id, player_id, team_id, period, period_start,
		period_end, amount_minor, plan_amount_minor, status, created_at, updated_at)
		values ($1, $2, $3, $4, $5, '2026-09', '2026-09-01', '2026-09-30', 4500, 4500, 'OPEN', now(), now())`,
		academy, uuid(), plan["id"], uuid(), uuid())
	locked := expect(t, a.do(t, call{method: "PUT", path: "/api/finance/settings", tenant: academy, subject: admin,
		body: map[string]any{"currency": "EUR"}}), 409)
	if problemCode(t, locked) != "CURRENCY_LOCKED" {
		t.Errorf("locked: %s", locked.body)
	}
	if got := expect(t, a.do(t, call{method: "GET", path: "/api/finance/settings", tenant: academy, subject: admin}), 200).json(t); got["currencyLocked"] != true {
		t.Errorf("settings %v", got)
	}
	hasDues := expect(t, a.do(t, call{method: "GET", path: "/api/finance/fee-plans/" + plan["id"].(string),
		tenant: academy, subject: admin}), 200).json(t)
	if hasDues["hasDues"] != true {
		t.Errorf("plan %v", hasDues)
	}
	expect(t, a.do(t, call{method: "DELETE", path: "/api/finance/fee-plans/" + plan["id"].(string), tenant: academy,
		subject: admin}), 409)
}

func TestAFeePlanIsCreatedReadChangedArchivedAndDeleted(t *testing.T) {
	a := newAPI(t)
	academy := a.academy(t, roster())
	a.withCurrency(t, academy, "EUR")

	response := expect(t, a.do(t, call{method: "POST", path: "/api/finance/fee-plans", tenant: academy, subject: admin,
		body: monthlyPlan()}), 201)
	plan := response.json(t)
	id := plan["id"].(string)
	if response.header.Get("Location") != "/api/finance/fee-plans/"+id || plan["currency"] != "EUR" ||
		plan["autoGenerate"] != true || plan["archived"] != false || plan["hasDues"] != false ||
		plan["ageCategoryId"] != nil || plan["lastPeriod"] != "2027-06" {
		t.Errorf("created %v (Location %s)", plan, response.header.Get("Location"))
	}
	path := "/api/finance/fee-plans/" + id
	changed := expect(t, a.do(t, call{method: "PATCH", path: path, tenant: academy, subject: admin,
		body: map[string]any{"name": "Renamed", "amountMinor": 5000, "clear": []string{"lastPeriod"}}}), 200).json(t)
	if changed["name"] != "Renamed" || changed["amountMinor"] != float64(5000) || changed["lastPeriod"] != nil {
		t.Errorf("changed %v", changed)
	}
	archived := expect(t, a.do(t, call{method: "POST", path: path + ":archive", tenant: academy, subject: admin}), 200).json(t)
	if archived["archived"] != true {
		t.Errorf("archived %v", archived)
	}
	list := expect(t, a.do(t, call{method: "GET", path: "/api/finance/fee-plans", tenant: academy, subject: admin}), 200).json(t)
	if len(list["items"].([]any)) != 0 {
		t.Errorf("an archived plan is listed without includeArchived: %v", list)
	}
	expect(t, a.do(t, call{method: "POST", path: path + ":unarchive", tenant: academy, subject: admin}), 200)
	expect(t, a.do(t, call{method: "DELETE", path: path, tenant: academy, subject: admin}), 204)
	expect(t, a.do(t, call{method: "GET", path: path, tenant: academy, subject: admin}), 404)

	want := []string{"finance.settings_changed", "fee_plan.created", "fee_plan.updated", "fee_plan.archived",
		"fee_plan.unarchived", "fee_plan.deleted"}
	if got := a.auditActions(t, academy); strings.Join(got, ",") != strings.Join(want, ",") {
		t.Errorf("audit trail %v", got)
	}
}

func TestFeePlansAreListedWithFiltersAndPages(t *testing.T) {
	a := newAPI(t)
	academy := a.academy(t, roster())
	a.withCurrency(t, academy, "EUR")
	season := uuid()
	for _, name := range []string{"C", "A", "B"} {
		body := monthlyPlan()
		body["name"], body["seasonId"] = name, season
		a.createPlan(t, academy, body)
	}
	a.createPlan(t, academy, monthlyPlan()) // another season

	page := expect(t, a.do(t, call{method: "GET", tenant: academy, subject: admin,
		path: "/api/finance/fee-plans?seasonId=" + season + "&page=1&size=2"}), 200).json(t)
	items, meta := page["items"].([]any), page["page"].(map[string]any)
	if len(items) != 1 || items[0].(map[string]any)["name"] != "C" || meta["totalElements"] != float64(3) ||
		meta["totalPages"] != float64(2) || meta["page"] != float64(1) || meta["size"] != float64(2) {
		t.Errorf("page %v", page)
	}
	for _, query := range []string{"size=0", "size=201", "page=-1", "seasonId=nope", "includeArchived=maybe", "teamId=1"} {
		expect(t, a.do(t, call{method: "GET", tenant: academy, subject: admin, path: "/api/finance/fee-plans?" + query}), 400)
	}
}

func TestInvalidRequestsAreProblemsNamingFieldsNeverValues(t *testing.T) {
	a := newAPI(t)
	academy := a.academy(t, roster())
	a.withCurrency(t, academy, "EUR")
	secret := "Ana-Lopez-hardship"
	bad := monthlyPlan()
	bad["name"], bad["cadence"], bad["ageCategoryId"] = "", "WEEKLY", uuid()

	invalid := expect(t, a.do(t, call{method: "POST", path: "/api/finance/fee-plans", tenant: academy, subject: admin,
		body: bad}), 400).json(t)
	fields := map[string]string{}
	for _, v := range invalid["violations"].([]any) {
		violation := v.(map[string]any)
		fields[violation["field"].(string)] = violation["code"].(string)
	}
	if fields["name"] != "REQUIRED" || fields["cadence"] != "INVALID" || fields["teamId"] != "ONE_TARGET_REQUIRED" ||
		invalid["type"] != "urn:hoops:problem:validation" || invalid["code"] != "VALIDATION_FAILED" {
		t.Errorf("violations %v", invalid)
	}
	for name, body := range map[string]string{
		"unknown property": `{"currency":"EUR","note":"` + secret + `"}`,
		"wrong type":       `{"currency":7}`,
		"malformed":        `{"currency":`,
		"missing":          `{}`,
		"two documents":    `{"currency":"EUR"}{"currency":"EUR"}`,
		"lower case":       `{"currency":"` + strings.ToLower(secret) + `"}`,
	} {
		got := expect(t, a.do(t, call{method: "PUT", path: "/api/finance/settings", tenant: academy, subject: admin,
			body: body}), 400)
		if strings.Contains(string(got.body), secret) || strings.Contains(string(got.body), strings.ToLower(secret)) {
			t.Errorf("%s: the answer repeats a request value: %s", name, got.body)
		}
	}
	expect(t, a.do(t, call{method: "PATCH", path: "/api/finance/fee-plans/" + uuid(), tenant: academy, subject: admin,
		body: `{}`}), 400)
	expect(t, a.do(t, call{method: "PATCH", path: "/api/finance/fee-plans/" + uuid(), tenant: academy, subject: admin,
		body: `{"clear":["name"]}`}), 400)
	expect(t, a.do(t, call{method: "GET", path: "/api/finance/fee-plans/not-a-uuid", tenant: academy, subject: admin}), 400)
	tooLarge := `{"currency":"EUR","x":"` + strings.Repeat("a", 70_000) + `"}`
	if got := expect(t, a.do(t, call{method: "PUT", path: "/api/finance/settings", tenant: academy, subject: admin,
		body: tooLarge}), 413); problemCode(t, got) != "REQUEST_TOO_LARGE" {
		t.Errorf("413: %s", got.body)
	}
	expect(t, a.do(t, call{method: "PUT", path: "/api/finance/settings", tenant: academy, subject: admin,
		body: `{"currency":"EUR"}`, header: map[string]string{"Content-Type": "text/plain"}}), 415)
	if strings.Contains(a.logs.String(), secret) {
		t.Error("a request value reached the log")
	}
}

func TestAuthenticationAndTheTenantHeader(t *testing.T) {
	a := newAPI(t)
	academy := a.academy(t, roster())
	path := "/api/finance/settings"

	before := a.events.Count(security.Unauthenticated)
	none := expect(t, a.do(t, call{method: "GET", path: path, tenant: academy}), 401)
	if none.header.Get("WWW-Authenticate") != "Bearer" || a.events.Count(security.Unauthenticated) != before+1 {
		t.Errorf("401 without a token: %v", none.header)
	}
	wrongAudience := a.realm.Sign(t, map[string]any{"sub": admin, "aud": "core-service", "iss": a.realm.Issuer(),
		"exp": 4102444800})
	invalidBefore := a.events.Count(security.InvalidToken)
	expect(t, a.do(t, call{method: "GET", path: path, tenant: academy, token: wrongAudience}), 401)
	expect(t, a.do(t, call{method: "GET", path: path, tenant: academy, token: "garbage"}), 401)
	if a.events.Count(security.InvalidToken) != invalidBefore+2 {
		t.Error("refused tokens are security events invalid_token")
	}
	if strings.Contains(a.logs.String(), wrongAudience) {
		t.Error("a token reached the log")
	}
	expect(t, a.do(t, call{method: "GET", path: path, subject: admin}), 400)
	expect(t, a.do(t, call{method: "GET", path: path, tenant: "not-a-uuid", subject: admin}), 400)
	expect(t, a.do(t, call{method: "GET", path: path, tenant: "00000000-0000-0000-0000-000000000000", subject: admin}), 400)
	expect(t, a.do(t, call{method: "GET", path: path, tenant: uuid(), subject: admin}), 404)
	suspended := a.academy(t, map[string][]string{admin: {"ADMIN"}})
	a.bound(t, suspended, "update finance.tenant_ref set status = 'SUSPENDED'")
	expect(t, a.do(t, call{method: "GET", path: path, tenant: suspended, subject: admin}), 404)
}

// The operations of WP119 and WP123: a member gets 501 NOT_IMPLEMENTED, a non-member 404, nobody 401.
func TestOperationsOfLaterWorkPackagesAnswer501(t *testing.T) {
	a := newAPI(t)
	academy := a.academy(t, roster())
	id := uuid()
	for _, op := range NotImplemented(id) {
		t.Run(op[0]+" "+op[1], func(t *testing.T) {
			got := expect(t, a.do(t, call{method: op[0], path: op[1], tenant: academy, subject: admin, body: op2body(op)}), 501)
			if problemCode(t, got) != "NOT_IMPLEMENTED" || got.json(t)["status"] != float64(501) {
				t.Errorf("501: %s", got.body)
			}
			expect(t, a.do(t, call{method: op[0], path: op[1], tenant: academy, subject: stranger, body: op2body(op)}), 404)
			expect(t, a.do(t, call{method: op[0], path: op[1], tenant: academy}), 401)
		})
	}
}

func op2body(op [2]string) any {
	if op[0] == "GET" || op[0] == "DELETE" {
		return nil
	}
	return map[string]any{}
}

// NotImplemented lists the contract's operations finance-service answers 501 in WP118 (method, concrete path).
func NotImplemented(id string) [][2]string {
	return [][2]string{
		{"POST", "/api/finance/fee-plans/" + id + "/dues:generate"},
		{"GET", "/api/finance/dues"},
		{"GET", "/api/finance/dues:export"},
		{"GET", "/api/finance/dues/" + id},
		{"POST", "/api/finance/dues/" + id + ":change-amount"},
		{"POST", "/api/finance/dues/" + id + ":waive"},
		{"POST", "/api/finance/dues/" + id + ":pay"},
		{"POST", "/api/finance/payments/" + id + ":void"},
		{"GET", "/api/finance/teams/" + id + "/due-status"},
		{"GET", "/api/finance/players/" + id + "/dues"},
		{"GET", "/api/finance/expenses"},
		{"POST", "/api/finance/expenses"},
		{"GET", "/api/finance/expenses:export"},
		{"GET", "/api/finance/expenses/" + id},
		{"PATCH", "/api/finance/expenses/" + id},
		{"DELETE", "/api/finance/expenses/" + id},
		{"GET", "/api/finance/balance?seasonId=" + id},
	}
}

func TestEveryContractOperationIsServedOrAnswers501(t *testing.T) {
	doc, _ := contract.Document(t)
	built := 9
	operations := 0
	for _, item := range doc.Paths.Map() {
		operations += len(item.Operations())
	}
	if got := operations; got != built+len(NotImplemented(uuid())) {
		t.Errorf("finance.yaml has %d operations, the service knows %d + %d", got, built, len(NotImplemented(uuid())))
	}
}

func TestHealthMetricsAndHeaders(t *testing.T) {
	a := newAPI(t)
	for _, path := range []string{"/q/health", "/q/health/live", "/q/health/ready", "/q/health/started"} {
		got := expect(t, a.do(t, call{method: "GET", path: path}), 200)
		if got.json(t)["status"] != "UP" {
			t.Errorf("%s: %s", path, got.body)
		}
	}
	metrics := string(expect(t, a.do(t, call{method: "GET", path: "/q/metrics"}), 200).body)
	if !strings.Contains(metrics, `hoops_authz_denied_total{kind="role"} 0`) {
		t.Errorf("metrics:\n%s", metrics)
	}
	academy := a.academy(t, roster())
	got := expect(t, a.do(t, call{method: "GET", path: "/api/finance/settings", tenant: academy, subject: admin}), 200)
	for header, value := range map[string]string{
		"X-Content-Type-Options": "nosniff", "X-Frame-Options": "DENY", "Referrer-Policy": "no-referrer",
		"Content-Security-Policy": "default-src 'none'; frame-ancestors 'none'", "Cache-Control": "no-store",
		"Cross-Origin-Resource-Policy": "same-origin",
	} {
		if got.header.Get(header) != value {
			t.Errorf("%s: %q", header, got.header.Get(header))
		}
	}
	preflight := a.do(t, call{method: "OPTIONS", path: "/api/finance/settings", header: map[string]string{
		"Origin": "http://localhost:5173", "Access-Control-Request-Method": "PUT",
		"Access-Control-Request-Headers": "authorization,content-type,x-tenant-id"}})
	if preflight.status != 204 || preflight.header.Get("Access-Control-Allow-Origin") != "http://localhost:5173" ||
		!strings.Contains(preflight.header.Get("Access-Control-Allow-Headers"), "X-Tenant-Id") {
		t.Errorf("preflight %d %v", preflight.status, preflight.header)
	}
	foreign := a.do(t, call{method: "OPTIONS", path: "/api/finance/settings", header: map[string]string{
		"Origin": "https://evil.example", "Access-Control-Request-Method": "PUT"}})
	if foreign.header.Get("Access-Control-Allow-Origin") != "" {
		t.Error("a foreign origin was allowed")
	}
	unknown := expect(t, a.do(t, call{method: "GET", path: "/api/finance/nothing-here", tenant: academy, subject: admin}), 404)
	if !strings.HasPrefix(fmt.Sprint(unknown.json(t)["type"]), "urn:hoops:problem:") {
		t.Errorf("unknown route: %s", unknown.body)
	}
}
