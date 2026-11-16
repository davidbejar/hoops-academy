package rest_test

import (
	"strings"
	"testing"
	"time"
)

const bom = "\uFEFF"

// csvLines splits a file of the ADR-0048 spec into its lines (after checking the BOM and the CRLF ends).
func csvLines(t *testing.T, got answer) []string {
	t.Helper()
	body := string(got.body)
	if !strings.HasPrefix(body, bom) || !strings.HasSuffix(body, "\r\n") {
		t.Fatalf("not UTF-8 with BOM and CRLF: %q", body)
	}
	return strings.Split(strings.TrimSuffix(strings.TrimPrefix(body, bom), "\r\n"), "\r\n")
}

func exportHeaders(t *testing.T, got answer, what string) {
	t.Helper()
	today := time.Now().UTC().Format("20060102")
	for header, want := range map[string]string{
		"Content-Type":        "text/csv; charset=utf-8",
		"Cache-Control":       "no-store",
		"Content-Disposition": `attachment; filename="hoops-hang-tuah-` + what + `-` + today + `.csv"`,
	} {
		if got.header.Get(header) != want {
			t.Errorf("%s: %q, want %q", header, got.header.Get(header), want)
		}
	}
}

// ADR-0048 for the dues: the rows listDues returns for the same filters, header and enum labels in the caller's
// language, the formula guard, never reasons or notes, one audit record `dues.exported` with the row count and the
// filter.
func TestTheDuesExportFollowsTheCsvSpec(t *testing.T) {
	a := newAPI(t)
	s := a.seedAcademy(t, roster())
	s.slug("hang-tuah")
	team := s.team(uuid(), false)
	for _, name := range []string{"=A1+B1", "Pérez, Ana", "Ben"} {
		s.assign(team, s.player(name, ""), s.start, zeroTime)
	}
	plan := s.plan(team, 4500)
	s.generate(plan, month(0), false)
	dues := map[string]string{}
	for _, item := range s.dues("period=" + month(0)) {
		due := item.(map[string]any)
		dues[due["playerName"].(string)] = due["id"].(string)
	}
	secretReason, secretNote := "Hardship of the family", "Paid by the grandmother"
	expect(t, s.post("/api/finance/dues/"+dues["Pérez, Ana"]+":pay", map[string]any{"paidOn": todayUTC(),
		"method": "CARD", "note": secretNote}), 200)
	expect(t, s.post("/api/finance/dues/"+dues["Ben"]+":waive", map[string]any{"reason": secretReason}), 200)

	got := expect(t, a.do(t, call{method: "GET", path: "/api/finance/dues:export?period=" + month(0), tenant: s.id(),
		subject: admin, header: map[string]string{"Accept-Language": "es-ES,es;q=0.9,en;q=0.5"}}), 200)
	exportHeaders(t, got, "dues")
	lines := csvLines(t, got)
	planName := "Monthly " + team[:4]
	start, end := dateOf(firstOfMonth(0)), dateOf(firstOfMonth(1).AddDate(0, 0, -1))
	teamName := "Team " + team[:4]
	want := []string{
		"Periodo,Inicio del periodo,Fin del periodo,Plan de cuotas,Jugador,Equipo,Importe (unidades menores),Moneda,Estado,Pagado el,Forma de pago",
		strings.Join([]string{month(0), start, end, planName, "'=A1+B1", teamName, "4500", "EUR", "Pendiente", "", ""}, ","),
		strings.Join([]string{month(0), start, end, planName, "Ben", teamName, "4500", "EUR", "Condonada", "", ""}, ","),
		strings.Join([]string{month(0), start, end, planName, `"Pérez, Ana"`, teamName, "4500", "EUR", "Pagada", todayUTC(), "Tarjeta"}, ","),
	}
	if strings.Join(lines, "\n") != strings.Join(want, "\n") {
		t.Errorf("file\n%s\nwant\n%s", strings.Join(lines, "\n"), strings.Join(want, "\n"))
	}
	for _, private := range []string{secretReason, secretNote} {
		if strings.Contains(string(got.body), private) || strings.Contains(a.logs.String(), private) {
			t.Errorf("%q reached the file or the log", private)
		}
	}

	paid := csvLines(t, expect(t, a.do(t, call{method: "GET", path: "/api/finance/dues:export?status=PAID&teamId=" + team,
		tenant: s.id(), subject: admin, header: map[string]string{"Accept-Language": "fr, id;q=0.4"}}), 200))
	if len(paid) != 2 || !strings.HasPrefix(paid[0], "Periode,Awal periode") || !strings.HasSuffix(paid[1], ",Lunas,"+todayUTC()+",Kartu") {
		t.Errorf("filtered, in Indonesian: %q", paid)
	}
	english := csvLines(t, expect(t, a.do(t, call{method: "GET", path: "/api/finance/dues:export?playerId=" + uuid(),
		tenant: s.id(), subject: admin}), 200))
	if len(english) != 1 || !strings.HasPrefix(english[0], "Period,Period start,Period end,Fee plan,Player,Team") {
		t.Errorf("no rows, in English: %q", english)
	}
	for _, query := range []string{"status=LATE", "period=2026-13", "from=soon", "teamId=1"} {
		expect(t, a.do(t, call{method: "GET", path: "/api/finance/dues:export?" + query, tenant: s.id(), subject: admin}), 400)
	}

	metadata := a.text(t, s.id(), `select string_agg(metadata::text, ' ' order by seq) from finance.audit_event
		where action = 'dues.exported'`)
	if !strings.Contains(metadata, `"rows": 3`) || !strings.Contains(metadata, `"period": "`+month(0)+`"`) ||
		!strings.Contains(metadata, `"rows": 1`) || !strings.Contains(metadata, `"status": "PAID"`) ||
		!strings.Contains(metadata, `"rows": 0`) || strings.Contains(metadata, "Pérez") {
		t.Errorf("audit metadata %s", metadata)
	}
	if n := strings.Count(strings.Join(a.auditActions(t, s.id()), ","), "dues.exported"); n != 3 {
		t.Errorf("%d export records, want 3 (a refused export writes none)", n)
	}
}

func TestTheExpensesExportFollowsTheCsvSpec(t *testing.T) {
	a := newAPI(t)
	s := a.seedAcademy(t, roster())
	s.slug("hang-tuah")
	a.withEuro(t, s.id())
	note := "Salary of Ana Lopez"
	risky := expenseBody("2026-10-03", "TOURNAMENT_FEES", 2500)
	risky["description"], risky["note"] = "+SUM(A1:A9)", note
	a.createExpense(t, s.id(), risky)
	a.createExpense(t, s.id(), map[string]any{"spentOn": "2026-10-01", "category": "COURT_RENTAL", "amountMinor": 12000,
		"description": "Court \"Norte\", October"})
	a.createExpense(t, s.id(), expenseBody("2026-09-01", "KIT", 3000))

	got := expect(t, a.do(t, call{method: "GET", path: "/api/finance/expenses:export?from=2026-10-01", tenant: s.id(),
		subject: admin, header: map[string]string{"Accept-Language": "en-GB"}}), 200)
	exportHeaders(t, got, "expenses")
	want := []string{
		"Day,Category,Category code,Amount (minor units),Currency,Description",
		"2026-10-03,Tournament fees,TOURNAMENT_FEES,2500,EUR,'+SUM(A1:A9)",
		`2026-10-01,Court rental,COURT_RENTAL,12000,EUR,"Court ""Norte"", October"`,
	}
	if lines := csvLines(t, got); strings.Join(lines, "\n") != strings.Join(want, "\n") {
		t.Errorf("file\n%s\nwant\n%s", strings.Join(lines, "\n"), strings.Join(want, "\n"))
	}
	if strings.Contains(string(got.body), note) {
		t.Error("the note reached the file")
	}
	spanish := csvLines(t, expect(t, a.do(t, call{method: "GET", path: "/api/finance/expenses:export?category=KIT",
		tenant: s.id(), subject: admin, header: map[string]string{"Accept-Language": "es"}}), 200))
	if len(spanish) != 2 || spanish[0] != "Día,Categoría,Código de categoría,Importe (unidades menores),Moneda,Descripción" ||
		!strings.HasPrefix(spanish[1], "2026-09-01,Equipación,KIT,3000,EUR,") {
		t.Errorf("Spanish: %q", spanish)
	}
	metadata := a.text(t, s.id(), `select string_agg(metadata::text, ' ' order by seq) from finance.audit_event
		where action = 'expenses.exported'`)
	if !strings.Contains(metadata, `"rows": 2`) || !strings.Contains(metadata, `"from": "2026-10-01"`) ||
		!strings.Contains(metadata, `"category": "KIT"`) {
		t.Errorf("audit metadata %s", metadata)
	}

	// an academy whose slug the replica does not know yet: the part is left out of the file name
	other := a.academy(t, roster())
	unnamed := expect(t, a.do(t, call{method: "GET", path: "/api/finance/expenses:export", tenant: other, subject: admin}), 200)
	if name := unnamed.header.Get("Content-Disposition"); !strings.HasPrefix(name, `attachment; filename="hoops-expenses-`) {
		t.Errorf("file name without a slug: %s", name)
	}
}

// ADR-0048: more than 10,000 rows is 422 EXPORT_TOO_LARGE with a detail that asks for a narrower filter; nothing is
// sent and nothing audited.
func TestAnExportOfMoreThanTenThousandRowsIsRefused(t *testing.T) {
	a := newAPI(t)
	s := a.seedAcademy(t, roster())
	team := s.team(uuid(), false)
	plan := s.plan(team, 100)
	a.bound(t, s.id(), `insert into finance.expense (tenant_id, id, spent_on, category, amount_minor, description,
			created_at, updated_at)
		select $1, gen_random_uuid(), date '2026-10-01' + (n % 30), case when n = 0 then 'KIT' else 'TRAVEL' end, 100,
			'Bus', now(), now()
		from generate_series(0, 10000) n`, s.id())
	a.bound(t, s.id(), `insert into finance.due (tenant_id, id, fee_plan_id, player_id, team_id, period, period_start,
			period_end, amount_minor, plan_amount_minor, status, created_at, updated_at)
		select $1, gen_random_uuid(), $2, gen_random_uuid(), $3, $4, $5, $6, 100, 100, 'OPEN', now(), now()
		from generate_series(0, 10000) n`, s.id(), plan, team, month(0), dateOf(firstOfMonth(0)),
		dateOf(firstOfMonth(1).AddDate(0, 0, -1)))

	for _, path := range []string{"/api/finance/expenses:export", "/api/finance/dues:export"} {
		refused := expect(t, a.do(t, call{method: "GET", path: path, tenant: s.id(), subject: admin}), 422)
		if problemCode(t, refused) != "EXPORT_TOO_LARGE" || !strings.Contains(refused.json(t)["detail"].(string), "filter") {
			t.Errorf("%s: %s", path, refused.body)
		}
	}
	if actions := strings.Join(a.auditActions(t, s.id()), ","); strings.Contains(actions, "exported") {
		t.Errorf("a refused export was audited: %s", actions)
	}
	narrow := csvLines(t, expect(t, a.do(t, call{method: "GET", path: "/api/finance/expenses:export?category=KIT",
		tenant: s.id(), subject: admin}), 200))
	if len(narrow) != 2 {
		t.Errorf("narrowed: %d lines", len(narrow))
	}
	exactly := csvLines(t, expect(t, a.do(t, call{method: "GET", path: "/api/finance/expenses:export?category=TRAVEL",
		tenant: s.id(), subject: admin}), 200))
	if len(exactly) != 10_001 {
		t.Errorf("10,000 rows are allowed: %d lines", len(exactly))
	}
}
