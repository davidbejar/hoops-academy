package rest_test

import (
	"fmt"
	"slices"
	"strings"
	"testing"
	"time"

	"hoopsacademy.local/finance/internal/platform/security"
)

// lions is an academy whose team Lions has Ana (joined six months ago, open) and Bea (left last month); Carl joins this
// month. The coach coaches the Lions, the parent is Ana's guardian, the player is Ana.
type lions struct {
	*seed
	team, ana, bea, carl, plan string
}

func lionsAcademy(t *testing.T, a *api) lions {
	t.Helper()
	s := a.seedAcademy(t, map[string][]string{admin: {"ADMIN"}, coach: {"COACH"}, parent: {"PARENT"},
		player: {"PLAYER"}, assistant: {"ASSISTANT_COACH"}})
	l := lions{seed: s, team: s.team(uuid(), false)}
	s.person(admin, "Ada Admin")
	l.ana = s.player("Ana", s.person(player, "Ana"))
	l.bea, l.carl = s.player("Bea", ""), s.player("Carl", "")
	s.assign(l.team, l.ana, s.start, time.Time{})
	s.assign(l.team, l.bea, s.start, firstOfMonth(0).AddDate(0, 0, -1))
	s.assign(l.team, l.carl, firstOfMonth(0), time.Time{})
	s.staff(l.team, s.person(coach, "Cleo Coach"), "COACH")
	s.staff(l.team, s.person(assistant, "Asa Assistant"), "ASSISTANT_COACH")
	s.link(s.person(parent, "Pat Parent"), l.ana)
	l.plan = s.plan(l.team, 4500)
	return l
}

func names(dues []any, key string) []string {
	var out []string
	for _, d := range dues {
		out = append(out, d.(map[string]any)[key].(string))
	}
	return out
}

func TestDuesAreGeneratedForWhoWasOnTheRosterPreviewedAndIdempotent(t *testing.T) {
	a := newAPI(t)
	l := lionsAcademy(t, a)

	preview := l.generate(l.plan, month(-1), true)
	if preview["preview"] != true || preview["created"] != float64(2) || preview["existing"] != float64(0) ||
		preview["periodStart"] != dateOf(firstOfMonth(-1)) || preview["periodEnd"] != dateOf(firstOfMonth(0).AddDate(0, 0, -1)) {
		t.Errorf("preview %v", preview)
	}
	previewed := preview["dues"].([]any)
	if got := names(previewed, "playerName"); !slices.Equal(got, []string{"Ana", "Bea"}) || previewed[0].(map[string]any)["dueId"] != nil {
		t.Errorf("previewed dues %v", previewed)
	}
	if len(l.dues("")) != 0 {
		t.Error("a preview wrote dues")
	}

	created := l.generate(l.plan, month(-1), false)
	if created["created"] != float64(2) || created["dues"].([]any)[0].(map[string]any)["dueId"] == nil {
		t.Errorf("created %v", created)
	}
	again := l.generate(l.plan, month(-1), false)
	if again["created"] != float64(0) || again["existing"] != float64(2) || len(again["dues"].([]any)) != 0 {
		t.Errorf("a re-run %v", again)
	}
	current := l.generate(l.plan, month(0), false)
	if got := names(current["dues"].([]any), "playerName"); !slices.Equal(got, []string{"Ana", "Carl"}) {
		t.Errorf("this month (Bea left, Carl joined): %v", got)
	}
	if got := a.auditActions(t, l.id()); strings.Count(strings.Join(got, ","), "dues.generated") != 2 {
		t.Errorf("audited %v", got)
	}
	plan := expect(t, a.do(t, call{method: "GET", path: "/api/finance/fee-plans/" + l.plan, tenant: l.id(), subject: admin}), 200).json(t)
	settings := expect(t, a.do(t, call{method: "GET", path: "/api/finance/settings", tenant: l.id(), subject: admin}), 200).json(t)
	if plan["hasDues"] != true || settings["currencyLocked"] != true {
		t.Errorf("plan %v settings %v", plan, settings)
	}
}

func TestAGenerationOutsideThePlanOrSeasonOrOfAnArchivedPlanIsRefused(t *testing.T) {
	a := newAPI(t)
	l := lionsAcademy(t, a)
	path := "/api/finance/fee-plans/" + l.plan + "/dues:generate"

	for body, want := range map[string]struct {
		status int
		code   string
	}{
		month(-3):         {422, "PERIOD_OUTSIDE_PLAN"},
		month(8):          {422, "PERIOD_OUTSIDE_SEASON"},
		"2026-Q4":         {400, "VALIDATION_FAILED"},
		"SEASON":          {400, "VALIDATION_FAILED"},
		"":                {400, "VALIDATION_FAILED"},
		"not even a date": {400, "VALIDATION_FAILED"},
	} {
		got := l.post(path, map[string]any{"period": body})
		if got.status != want.status || problemCode(t, got) != want.code {
			t.Errorf("%q: %d %s", body, got.status, got.body)
		}
	}
	expect(t, l.post(path, map[string]any{}), 400)
	expect(t, l.post(path, map[string]any{"period": month(0), "dryRun": true}), 400)
	expect(t, l.post("/api/finance/fee-plans/"+uuid()+"/dues:generate", map[string]any{"period": month(0)}), 404)
	expect(t, l.post("/api/finance/fee-plans/"+l.plan+":archive", nil), 200)
	if got := l.post(path, map[string]any{"period": month(0)}); got.status != 409 || problemCode(t, got) != "FEE_PLAN_ARCHIVED" {
		t.Errorf("archived: %d %s", got.status, got.body)
	}
}

func TestADueIsPaidVoidedAndPaidAgainWithEveryPaymentKept(t *testing.T) {
	a := newAPI(t)
	l := lionsAcademy(t, a)
	l.generate(l.plan, month(0), false)
	due := l.dues("playerId=" + l.ana)[0].(map[string]any)
	path := "/api/finance/dues/" + due["id"].(string)
	if due["status"] != "OPEN" || due["payment"] != nil || due["currency"] != "EUR" || due["feePlanName"] == "" ||
		due["playerName"] != "Ana" || due["teamId"] != l.team || due["amountMinor"] != float64(4500) {
		t.Fatalf("due %v", due)
	}

	future := l.post(path+":pay", map[string]any{"paidOn": dateOf(time.Now().UTC().AddDate(0, 0, 2)), "method": "CASH"})
	if future.status != 422 || problemCode(t, future) != "PAID_ON_IN_FUTURE" {
		t.Errorf("a payment day after today: %s", future.body)
	}
	paid := expect(t, l.post(path+":pay", map[string]any{"paidOn": todayUTC(), "method": "BANK_TRANSFER",
		"note": "at the court"}), 200).json(t)
	payment, _ := paid["payment"].(map[string]any)
	if paid["status"] != "PAID" || payment == nil || payment["amountMinor"] != float64(4500) || payment["method"] != "BANK_TRANSFER" ||
		payment["note"] != "at the court" || payment["voided"] != false ||
		payment["recordedBy"].(map[string]any)["displayName"] != "Ada Admin" {
		t.Fatalf("paid %v", paid)
	}
	if got := l.post(path+":pay", map[string]any{"paidOn": todayUTC(), "method": "CASH"}); got.status != 409 ||
		problemCode(t, got) != "DUE_NOT_OPEN" {
		t.Errorf("paid twice: %s", got.body)
	}
	void := "/api/finance/payments/" + payment["id"].(string) + ":void"
	reopened := expect(t, l.post(void, map[string]any{"reason": "wrong family"}), 200).json(t)
	if reopened["status"] != "OPEN" || reopened["payment"] != nil {
		t.Errorf("reopened %v", reopened)
	}
	if got := l.post(void, map[string]any{"reason": "again"}); got.status != 409 || problemCode(t, got) != "PAYMENT_ALREADY_VOIDED" {
		t.Errorf("voided twice: %s", got.body)
	}
	expect(t, l.post(path+":pay", map[string]any{"paidOn": todayUTC(), "method": "CASH"}), 200)

	detail := expect(t, a.do(t, call{method: "GET", path: path, tenant: l.id(), subject: admin}), 200).json(t)
	payments := detail["payments"].([]any)
	first := payments[0].(map[string]any)
	if len(payments) != 2 || first["voided"] != true || first["voidReason"] != "wrong family" ||
		first["voidedBy"].(map[string]any)["displayName"] != "Ada Admin" || payments[1].(map[string]any)["voided"] != false ||
		detail["status"] != "PAID" {
		t.Errorf("detail %v", detail)
	}
	expect(t, l.post("/api/finance/payments/"+uuid()+":void", map[string]any{"reason": "x"}), 404)
	expect(t, l.post("/api/finance/dues/"+uuid()+":pay", map[string]any{"paidOn": todayUTC(), "method": "CASH"}), 404)
	want := "dues.generated,payment.recorded,payment.voided,payment.recorded"
	if got := strings.Join(a.auditActions(t, l.id()), ","); !strings.HasSuffix(got, want) {
		t.Errorf("audit trail %s", got)
	}
}

func TestAnOpenDuesAmountChangesAndAWaiverIsFinal(t *testing.T) {
	a := newAPI(t)
	l := lionsAcademy(t, a)
	l.generate(l.plan, month(0), false)
	path := "/api/finance/dues/" + l.dues("playerId=" + l.ana)[0].(map[string]any)["id"].(string)

	changed := expect(t, l.post(path+":change-amount", map[string]any{"amountMinor": 3000, "reason": "sibling"}), 200).json(t)
	if changed["amountMinor"] != float64(3000) || changed["planAmountMinor"] != float64(4500) || changed["reason"] != "sibling" {
		t.Errorf("changed %v", changed)
	}
	for _, body := range []map[string]any{{"amountMinor": 0, "reason": "x"}, {"amountMinor": 100}, {"reason": "x"},
		{"amountMinor": 100, "reason": strings.Repeat("r", 201)}, {"amountMinor": 100, "reason": "   "}} {
		expect(t, l.post(path+":change-amount", body), 400)
	}
	waived := expect(t, l.post(path+":waive", map[string]any{"reason": "hardship"}), 200).json(t)
	if waived["status"] != "WAIVED" || waived["reason"] != "hardship" || waived["amountMinor"] != float64(3000) {
		t.Errorf("waived %v", waived)
	}
	for verb, body := range map[string]map[string]any{
		":waive": {"reason": "again"}, ":change-amount": {"amountMinor": 10, "reason": "x"},
		":pay": {"paidOn": todayUTC(), "method": "CASH"},
	} {
		if got := l.post(path+verb, body); got.status != 409 || problemCode(t, got) != "DUE_NOT_OPEN" {
			t.Errorf("%s of a waived due: %s", verb, got.body)
		}
	}
	expect(t, l.post(path+":refund", map[string]any{}), 404)
	expect(t, l.post("/api/finance/dues/nope:waive", map[string]any{"reason": "x"}), 400)
	if got := a.auditActions(t, l.id()); !slices.Contains(got, "due.amount_changed") || !slices.Contains(got, "due.waived") {
		t.Errorf("audit %v", got)
	}
}

func TestDuesAreListedWithFiltersAndPages(t *testing.T) {
	a := newAPI(t)
	l := lionsAcademy(t, a)
	l.generate(l.plan, month(-2), false)
	l.generate(l.plan, month(-1), false)
	l.generate(l.plan, month(0), false)
	ana := l.dues("playerId=" + l.ana)
	expect(t, l.post("/api/finance/dues/"+ana[0].(map[string]any)["id"].(string)+":waive", map[string]any{"reason": "x"}), 200)

	if got := names(l.dues(""), "period"); !slices.Equal(got, []string{month(-2), month(-2), month(-1), month(-1), month(0), month(0)}) {
		t.Errorf("all, by period start: %v", got)
	}
	if got := names(l.dues("period="+month(-1)), "playerName"); !slices.Equal(got, []string{"Ana", "Bea"}) {
		t.Errorf("one period, by name: %v", got)
	}
	for query, count := range map[string]int{
		"status=WAIVED": 1, "status=OPEN": 5, "feePlanId=" + l.plan: 6, "teamId=" + l.team: 6, "seasonId=" + l.season: 6,
		"seasonId=" + uuid(): 0, "from=" + dateOf(firstOfMonth(-1)): 4, "to=" + dateOf(firstOfMonth(-1)): 4,
		"from=" + dateOf(firstOfMonth(-1)) + "&to=" + dateOf(firstOfMonth(-1)): 2, "playerId=" + l.carl: 1,
	} {
		if got := len(l.dues(query)); got != count {
			t.Errorf("%s: %d dues, want %d", query, got, count)
		}
	}
	page := expect(t, a.do(t, call{method: "GET", path: "/api/finance/dues?page=1&size=4", tenant: l.id(), subject: admin}), 200).json(t)
	if len(page["items"].([]any)) != 2 || page["page"].(map[string]any)["totalElements"] != float64(6) {
		t.Errorf("page %v", page)
	}
	for _, query := range []string{"status=open", "period=2026-13", "from=yesterday", "playerId=1", "size=0"} {
		expect(t, a.do(t, call{method: "GET", path: "/api/finance/dues?" + query, tenant: l.id(), subject: admin}), 400)
	}
}

// Decision 96: the coach sees who is up to date (no amounts); the family the dues of their player (no reasons, notes
// or voided payments).
func TestTheCoachSeesStatusOnlyAndTheFamilyNoReasonsNotesOrVoidedPayments(t *testing.T) {
	a := newAPI(t)
	l := lionsAcademy(t, a)
	l.generate(l.plan, month(0), false)
	nextMonth := l.generate(l.plan, month(1), false) // not started: never makes anyone behind
	if nextMonth["created"] != float64(2) {
		t.Fatalf("next month %v", nextMonth)
	}
	for _, d := range l.dues("period=" + month(0)) {
		due := d.(map[string]any)
		if due["playerName"] == "Ana" {
			paid := expect(t, l.post("/api/finance/dues/"+due["id"].(string)+":pay", map[string]any{"paidOn": todayUTC(),
				"method": "CASH", "note": "secret-note"}), 200).json(t)
			payment := paid["payment"].(map[string]any)["id"].(string)
			expect(t, l.post("/api/finance/payments/"+payment+":void", map[string]any{"reason": "secret-void"}), 200)
			expect(t, l.post("/api/finance/dues/"+due["id"].(string)+":pay", map[string]any{"paidOn": todayUTC(),
				"method": "CARD", "note": "secret-note"}), 200)
		}
	}
	waive := l.dues("period=" + month(1) + "&playerId=" + l.ana)[0].(map[string]any)["id"].(string)
	expect(t, l.post("/api/finance/dues/"+waive+":waive", map[string]any{"reason": "secret-waiver"}), 200)

	status := expect(t, a.do(t, call{method: "GET", path: "/api/finance/teams/" + l.team + "/due-status", tenant: l.id(),
		subject: coach}), 200)
	body := status.json(t)
	players := body["players"].([]any)
	if body["teamId"] != l.team || len(players) != 2 ||
		fmt.Sprint(players[0]) != fmt.Sprintf("map[playerId:%s playerName:Ana upToDate:true]", l.ana) ||
		fmt.Sprint(players[1]) != fmt.Sprintf("map[playerId:%s playerName:Carl upToDate:false]", l.carl) {
		t.Errorf("status %s", status.body)
	}

	family := expect(t, a.do(t, call{method: "GET", path: "/api/finance/players/" + l.ana + "/dues", tenant: l.id(),
		subject: parent}), 200)
	items := family.json(t)["items"].([]any)
	newest, current := items[0].(map[string]any), items[1].(map[string]any)
	if len(items) != 2 || newest["period"] != month(1) || newest["status"] != "WAIVED" || newest["paidOn"] != nil ||
		current["status"] != "PAID" || current["paymentMethod"] != "CARD" || current["paidOn"] != todayUTC() ||
		current["amountMinor"] != float64(4500) || current["currency"] != "EUR" {
		t.Errorf("family view %s", family.body)
	}
	if strings.Contains(string(family.body), "secret") || strings.Contains(string(family.body), "reason") {
		t.Errorf("the family sees reasons or notes: %s", family.body)
	}
	self := expect(t, a.do(t, call{method: "GET", path: "/api/finance/players/" + l.ana + "/dues?size=1", tenant: l.id(),
		subject: player}), 200).json(t)
	if len(self["items"].([]any)) != 1 || self["page"].(map[string]any)["totalElements"] != float64(2) {
		t.Errorf("the player's own dues %v", self)
	}
}

// Privacy P-12: reasons and notes never reach the logs or the audit trail's metadata.
func TestReasonsAndNotesNeverReachLogsOrAudit(t *testing.T) {
	a := newAPI(t)
	l := lionsAcademy(t, a)
	l.generate(l.plan, month(0), false)
	dues := l.dues("")
	first, second := "/api/finance/dues/"+dues[0].(map[string]any)["id"].(string), "/api/finance/dues/"+dues[1].(map[string]any)["id"].(string)
	expect(t, l.post(first+":change-amount", map[string]any{"amountMinor": 100, "reason": "marker-change"}), 200)
	expect(t, l.post(first+":waive", map[string]any{"reason": "marker-waive"}), 200)
	paid := expect(t, l.post(second+":pay", map[string]any{"paidOn": todayUTC(), "method": "OTHER", "note": "marker-note"}), 200).json(t)
	expect(t, l.post("/api/finance/payments/"+paid["payment"].(map[string]any)["id"].(string)+":void",
		map[string]any{"reason": "marker-void"}), 200)

	if strings.Contains(a.logs.String(), "marker-") {
		t.Errorf("a reason or note was logged:\n%s", a.logs.String())
	}
	metadata := a.text(t, l.id(), "select coalesce(string_agg(metadata::text, ' '), '') from finance.audit_event")
	if strings.Contains(metadata, "marker-") || !strings.Contains(metadata, "BANK") && !strings.Contains(metadata, "OTHER") {
		t.Errorf("audit metadata %s", metadata)
	}
}

// docs/domain/authz-matrix.md, section Finance: dues and payments ADMIN only; a team's status ADMIN and its current
// coach; a player's dues ADMIN, a linked parent, the player. Members without the right 403 (a security event), non-members 404.
func TestRoleMatrixOfDuesPaymentsAndTheReads(t *testing.T) {
	a := newAPI(t)
	l := lionsAcademy(t, a)
	s := l.seed
	tigers := s.team(uuid(), false)
	former := s.team(uuid(), true)
	a.bound(t, l.id(), `insert into finance.person_ref (tenant_id, id, subject, roles, active, occurred_at, event_id)
		values ($1, $2, 'coach2', '{COACH}', true, now(), $3), ($1, $4, 'former', '{COACH}', true, now(), $5),
		($1, $6, 'parent2', '{PARENT}', true, now(), $7), ($1, $8, 'player2', '{PLAYER}', true, now(), $9)`,
		l.id(), uuid(), uuid(), uuid(), uuid(), uuid(), uuid(), uuid(), uuid())
	s.staff(tigers, s.person("coach2", "C2"), "COACH")
	s.staff(former, s.person("former", "F"), "COACH")
	s.link(s.person("parent2", "P2"), l.bea)
	s.player("Bea again", s.person("player2", "P2"))
	l.generate(l.plan, month(0), false)
	due := l.dues("playerId=" + l.ana)[0].(map[string]any)["id"].(string)
	paid := expect(t, l.post("/api/finance/dues/"+l.dues("playerId=" + l.carl)[0].(map[string]any)["id"].(string)+":pay",
		map[string]any{"paidOn": todayUTC(), "method": "CASH"}), 200).json(t)
	payment := paid["payment"].(map[string]any)["id"].(string)

	type operation struct {
		name, method, path string
		body               any
	}
	adminOnly := []operation{
		{"generateDues", "POST", "/api/finance/fee-plans/" + l.plan + "/dues:generate", map[string]any{"period": month(0), "preview": true}},
		{"listDues", "GET", "/api/finance/dues", nil},
		{"getDue", "GET", "/api/finance/dues/" + due, nil},
		{"changeDueAmount", "POST", "/api/finance/dues/" + due + ":change-amount", map[string]any{"amountMinor": 4000, "reason": "x"}},
		{"waiveDue", "POST", "/api/finance/dues/" + due + ":waive", map[string]any{"reason": "x"}},
		{"payDue", "POST", "/api/finance/dues/" + due + ":pay", map[string]any{"paidOn": todayUTC(), "method": "CASH"}},
		{"voidPayment", "POST", "/api/finance/payments/" + payment + ":void", map[string]any{"reason": "x"}},
	}
	status := operation{"getTeamDueStatus", "GET", "/api/finance/teams/" + l.team + "/due-status", nil}
	dues := operation{"listPlayerDues", "GET", "/api/finance/players/" + l.ana + "/dues", nil}
	check := func(subject string, op operation, want int, kind security.Kind) {
		t.Helper()
		before := a.events.Count(kind)
		got := a.do(t, call{method: op.method, path: op.path, tenant: l.id(), subject: subject, body: op.body})
		if got.status != want {
			t.Errorf("%s %s: %d, want %d (%s)", subject, op.name, got.status, want, got.body)
		}
		if want == 403 && a.events.Count(kind) != before+1 {
			t.Errorf("%s %s: the 403 was not a security event of kind %s", subject, op.name, kind)
		}
	}
	for _, subject := range []string{coach, "coach2", assistant, parent, player} {
		for _, op := range adminOnly {
			check(subject, op, 403, security.Role)
		}
	}
	for _, op := range adminOnly[:3] {
		check(admin, op, 200, security.Role)
	}
	check(admin, status, 200, security.Role)
	check(coach, status, 200, security.Role)
	check("coach2", status, 403, security.FineGrained)
	check("former", status, 403, security.FineGrained)
	check(assistant, status, 403, security.Role)
	check(parent, status, 403, security.Role)
	check(player, status, 403, security.Role)
	check(admin, dues, 200, security.Role)
	check(parent, dues, 200, security.Role)
	check(player, dues, 200, security.Role)
	check("parent2", dues, 403, security.FineGrained)
	check("player2", dues, 403, security.FineGrained)
	check(coach, dues, 403, security.Role)
	check(assistant, dues, 403, security.Role)
	check("parent2", operation{"listPlayerDues of an unknown player", "GET", "/api/finance/players/" + uuid() + "/dues", nil},
		403, security.FineGrained)
	check(coach, operation{"getTeamDueStatus of an unknown team", "GET", "/api/finance/teams/" + uuid() + "/due-status", nil},
		403, security.FineGrained)
	check(admin, operation{"getTeamDueStatus of an unknown team", "GET", "/api/finance/teams/" + uuid() + "/due-status", nil},
		404, security.Role)
	for _, op := range append(adminOnly, status, dues) {
		check(stranger, op, 404, security.NotMember)
	}
}

// The commit hook's isolation check (TestCrossTenant*): academy B's admin never reads or changes A's dues, payments,
// team status or player dues.
func TestCrossTenantDuesAndPaymentsAreRefused(t *testing.T) {
	a := newAPI(t)
	l := lionsAcademy(t, a)
	other := a.seedAcademy(t, map[string][]string{"admin-b": {"ADMIN"}})
	other.person("admin-b", "B")
	expect(t, a.do(t, call{method: "PUT", path: "/api/finance/settings", tenant: other.id(), subject: "admin-b",
		body: map[string]any{"currency": "EUR"}}), 200)
	l.generate(l.plan, month(0), false)
	due := l.dues("playerId=" + l.ana)[0].(map[string]any)["id"].(string)
	paid := expect(t, l.post("/api/finance/dues/"+due+":pay", map[string]any{"paidOn": todayUTC(), "method": "CASH"}), 200).json(t)
	payment := paid["payment"].(map[string]any)["id"].(string)
	b := func(method, path string, body any) answer {
		return a.do(t, call{method: method, path: path, tenant: other.id(), subject: "admin-b", body: body})
	}

	expect(t, b("GET", "/api/finance/dues/"+due, nil), 404)
	expect(t, b("POST", "/api/finance/dues/"+due+":waive", map[string]any{"reason": "x"}), 404)
	expect(t, b("POST", "/api/finance/dues/"+due+":change-amount", map[string]any{"amountMinor": 1, "reason": "x"}), 404)
	expect(t, b("POST", "/api/finance/payments/"+payment+":void", map[string]any{"reason": "x"}), 404)
	expect(t, b("POST", "/api/finance/fee-plans/"+l.plan+"/dues:generate", map[string]any{"period": month(0)}), 404)
	expect(t, b("GET", "/api/finance/teams/"+l.team+"/due-status", nil), 404)
	if items := expect(t, b("GET", "/api/finance/dues", nil), 200).json(t)["items"].([]any); len(items) != 0 {
		t.Errorf("B lists A's dues: %v", items)
	}
	if items := expect(t, b("GET", "/api/finance/players/"+l.ana+"/dues", nil), 200).json(t)["items"].([]any); len(items) != 0 {
		t.Errorf("B lists A's player's dues: %v", items)
	}
	expect(t, a.do(t, call{method: "GET", path: "/api/finance/dues/" + due, tenant: l.id(), subject: "admin-b"}), 404)
	if got := expect(t, l.post("/api/finance/dues/"+due+":waive", map[string]any{"reason": "x"}), 409); problemCode(t, got) != "DUE_NOT_OPEN" {
		t.Error("A's due changed")
	}
}
