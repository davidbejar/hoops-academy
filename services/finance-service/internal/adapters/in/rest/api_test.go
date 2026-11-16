package rest_test

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"

	"hoopsacademy.local/finance/internal/adapters/in/oidc"
	"hoopsacademy.local/finance/internal/adapters/in/rest"
	"hoopsacademy.local/finance/internal/adapters/out/persistence"
	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/domain"
	"hoopsacademy.local/finance/internal/platform/ids"
	"hoopsacademy.local/finance/internal/platform/security"
	"hoopsacademy.local/finance/internal/testsupport/contract"
	"hoopsacademy.local/finance/internal/testsupport/pgtest"
	"hoopsacademy.local/finance/internal/testsupport/realm"
)

func TestMain(m *testing.M) { os.Exit(pgtest.Run(m)) }

// api is the whole service over HTTP: real router, real use cases, real database (as finance_app), a test realm.
type api struct {
	server *httptest.Server
	realm  *realm.Realm
	db     *pgtest.Database
	events *security.Events
	logs   *bytes.Buffer
}

func newAPI(t *testing.T) *api {
	t.Helper()
	db := pgtest.Start(t)
	r := realm.Start(t)
	logs := &bytes.Buffer{}
	log := slog.New(slog.NewJSONHandler(logs, nil))
	events := security.NewEvents(log)
	tx := persistence.NewTransactions(db.App)
	finance := application.NewFinance(application.Ports{
		Clock: systemClock{}, IDs: ids.V7{}, Transactions: tx, Settings: persistence.SettingsStore{},
		FeePlans: persistence.FeePlanStore{}, Dues: persistence.DueQueries{},
		Audit: persistence.AuditLog{IDs: ids.V7{}, Log: log}, Members: persistence.MembershipStore{},
		Roster: persistence.RosterStore{}, DueStore: persistence.DueStore{}, Payments: persistence.PaymentStore{},
	})
	handler := rest.NewHandler(rest.Deps{
		Finance: finance, Verifier: oidc.NewVerifier(oidc.Config{AuthServerURL: r.URL(), Audience: realm.Audience}),
		Security: events, Log: log, CORSOrigins: []string{"http://localhost:5173"},
		Ready: func(ctx context.Context) error { return db.App.Ping(ctx) },
	})
	server := httptest.NewServer(handler)
	t.Cleanup(server.Close)
	return &api{server: server, realm: r, db: db, events: events, logs: logs}
}

type systemClock struct{}

func (systemClock) Now() time.Time { return time.Now().UTC().Truncate(time.Microsecond) }

func uuid() string {
	var b [16]byte
	_, _ = rand.Read(b[:])
	b[6] = b[6]&0x0f | 0x40
	b[8] = b[8]&0x3f | 0x80
	id := domain.UUID(b)
	return id.String()
}

// academy creates an ACTIVE academy in the replica with members subject -> roles (as core's events would).
func (a *api) academy(t *testing.T, members map[string][]string) string {
	t.Helper()
	tenant := uuid()
	a.bound(t, tenant, `insert into finance.tenant_ref (tenant_id, status, timezone, occurred_at, event_id)
		values ($1, 'ACTIVE', 'Europe/Madrid', now(), $2)`, tenant, uuid())
	for subject, roles := range members {
		a.bound(t, tenant, `insert into finance.person_ref (tenant_id, id, subject, roles, active, occurred_at, event_id)
			values ($1, $2, $3, $4, true, now(), $5)`, tenant, uuid(), subject, roles, uuid())
	}
	return tenant
}

func (a *api) bound(t *testing.T, tenant, sql string, args ...any) {
	t.Helper()
	ctx := context.Background()
	tx, err := a.db.App.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = tx.Rollback(ctx) }()
	if _, err := tx.Exec(ctx, "select set_config('app.tenant_id', $1, true)", tenant); err != nil {
		t.Fatal(err)
	}
	if _, err := tx.Exec(ctx, sql, args...); err != nil {
		t.Fatal(err)
	}
	if err := tx.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

// auditActions reads the academy's audit trail in order, as finance_app bound to it.
func (a *api) auditActions(t *testing.T, tenant string) []string {
	t.Helper()
	ctx := context.Background()
	tx, err := a.db.App.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = tx.Rollback(ctx) }()
	if _, err := tx.Exec(ctx, "select set_config('app.tenant_id', $1, true)", tenant); err != nil {
		t.Fatal(err)
	}
	rows, err := tx.Query(ctx, "select action from finance.audit_event order by seq")
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()
	var actions []string
	for rows.Next() {
		var action string
		if err := rows.Scan(&action); err != nil {
			t.Fatal(err)
		}
		actions = append(actions, action)
	}
	return actions
}

type answer struct {
	status int
	header http.Header
	body   []byte
}

func (r answer) json(t *testing.T) map[string]any {
	t.Helper()
	var out map[string]any
	if err := json.Unmarshal(r.body, &out); err != nil {
		t.Fatalf("not a JSON object (%d): %s", r.status, r.body)
	}
	return out
}

type call struct {
	method, path string
	tenant       string // X-Tenant-Id; "" = none
	subject      string // bearer token of this subject; "" = none
	token        string // a raw token instead
	body         any
	header       map[string]string
	// outside: not an operation of finance.yaml (CORS preflight, unknown route): the answer is not validated
	outside bool
}

// do sends c, validates the answer against finance.yaml (and the request too when the service accepted it).
func (a *api) do(t *testing.T, c call) answer {
	t.Helper()
	var payload []byte
	switch b := c.body.(type) {
	case nil:
	case string:
		payload = []byte(b)
	default:
		payload, _ = json.Marshal(b)
	}
	request, err := http.NewRequestWithContext(context.Background(), c.method, a.server.URL+c.path, bytes.NewReader(payload))
	if err != nil {
		t.Fatal(err)
	}
	if payload != nil {
		request.Header.Set("Content-Type", "application/json")
	}
	if c.tenant != "" {
		request.Header.Set("X-Tenant-Id", c.tenant)
	}
	token := c.token
	if c.subject != "" {
		token = a.realm.Token(t, c.subject)
	}
	if token != "" {
		request.Header.Set("Authorization", "Bearer "+token)
	}
	for k, v := range c.header {
		request.Header.Set(k, v)
	}
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = response.Body.Close() }()
	body, _ := io.ReadAll(response.Body)
	exchange := contract.Exchange{Request: request, RequestBody: payload, Response: response, ResponseBody: body}
	if strings.HasPrefix(c.path, "/api/finance/") && !c.outside && response.StatusCode != http.StatusNotImplemented {
		contract.CheckResponse(t, exchange)
		if response.StatusCode < 300 {
			contract.CheckRequest(t, exchange)
		}
	}
	if response.StatusCode >= 400 && strings.HasPrefix(c.path, "/api/") &&
		response.Header.Get("Content-Type") != "application/problem+json" {
		t.Errorf("%s %s -> %d without a Problem: %s", c.method, c.path, response.StatusCode, body)
	}
	return answer{status: response.StatusCode, header: response.Header, body: body}
}

func expect(t *testing.T, got answer, status int) answer {
	t.Helper()
	if got.status != status {
		t.Fatalf("status %d, want %d: %s", got.status, status, got.body)
	}
	return got
}

func problemCode(t *testing.T, got answer) string {
	t.Helper()
	code, _ := got.json(t)["code"].(string)
	return code
}

const admin, coach, assistant, parent, player, stranger = "admin", "coach", "assistant", "parent", "player", "stranger"

func roster() map[string][]string {
	return map[string][]string{
		admin: {"ADMIN"}, coach: {"COACH"}, assistant: {"ASSISTANT_COACH"}, parent: {"PARENT"}, player: {"PLAYER"},
		"admin+coach": {"ADMIN", "COACH"}, "coach+parent": {"COACH", "PARENT"},
	}
}

func monthlyPlan() map[string]any {
	return map[string]any{
		"name": "U12 monthly", "seasonId": uuid(), "teamId": uuid(), "amountMinor": 4500, "cadence": "MONTHLY",
		"firstPeriod": "2026-09", "lastPeriod": "2027-06",
	}
}

func (a *api) withEuro(t *testing.T, tenant string) {
	t.Helper()
	expect(t, a.do(t, call{method: "PUT", path: "/api/finance/settings", tenant: tenant, subject: admin,
		body: map[string]any{"currency": "EUR"}}), 200)
}

func (a *api) createPlan(t *testing.T, tenant string, body map[string]any) map[string]any {
	t.Helper()
	return expect(t, a.do(t, call{method: "POST", path: "/api/finance/fee-plans", tenant: tenant, subject: admin,
		body: body}), 201).json(t)
}
