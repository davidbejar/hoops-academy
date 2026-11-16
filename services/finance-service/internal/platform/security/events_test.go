package security

import (
	"bytes"
	"context"
	"encoding/json"
	"log/slog"
	"strings"
	"testing"
)

func TestADenialIsOneWarnRecordWithTheFieldsOfCommonQuarkusAndACount(t *testing.T) {
	var out bytes.Buffer
	events := NewEvents(slog.New(slog.NewJSONHandler(&out, nil)))

	events.Deny(context.Background(), Denial{
		Kind: Role, Tenant: "t-1", Subject: "sub-1", Roles: []string{"PARENT", "COACH"},
		Resource: "GET /api/finance/fee-plans", Reason: "finance is managed by ADMIN",
	})

	var record map[string]any
	if err := json.Unmarshal(out.Bytes(), &record); err != nil {
		t.Fatal(err)
	}
	want := map[string]any{
		"level": "WARN", "logger": "hoops.security", "security.event": "authz_denied", "security.kind": "role",
		"security.outcome": "403", "tenantId": "t-1", "security.subject": "sub-1", "security.roles": "COACH,PARENT",
		"security.resource": "GET /api/finance/fee-plans", "security.reason": "finance is managed by ADMIN",
		"msg": `authz_denied kind=role outcome=403 tenant=t-1 subject=sub-1 roles=COACH,PARENT resource="GET /api/finance/fee-plans" reason="finance is managed by ADMIN"`,
	}
	for key, value := range want {
		if record[key] != value {
			t.Errorf("%s = %v, want %v", key, record[key], value)
		}
	}
	if events.Count(Role) != 1 || events.Count(NotMember) != 0 {
		t.Errorf("counts %d %d", events.Count(Role), events.Count(NotMember))
	}
}

func TestEveryKindHasItsStatusAndStartsAtZero(t *testing.T) {
	events := NewEvents(slog.New(slog.DiscardHandler))
	statuses := map[Kind]int{
		Unauthenticated: 401, InvalidToken: 401, NotMember: 404, TenantMismatch: 404, Role: 403, FineGrained: 403,
		RealmRole: 403,
	}
	if len(AllKinds) != len(statuses) {
		t.Fatalf("kinds %v", AllKinds)
	}
	for kind, status := range statuses {
		if kind.Status() != status || events.Count(kind) != 0 {
			t.Errorf("%s: %d", kind, kind.Status())
		}
	}
}

func TestValuesAreCleanedAndCutAndEmptyOnesAreADash(t *testing.T) {
	var out bytes.Buffer
	events := NewEvents(slog.New(slog.NewJSONHandler(&out, nil)))

	events.Deny(context.Background(), Denial{Kind: InvalidToken, Subject: "evil\"\n" + strings.Repeat("x", 300)})

	var record map[string]any
	_ = json.Unmarshal(out.Bytes(), &record)
	subject := record["security.subject"].(string)
	if strings.ContainsAny(subject, "\"\n") || len(subject) != 200 || !strings.HasSuffix(subject, "...") {
		t.Errorf("subject %q", subject)
	}
	if record["tenantId"] != "-" || record["security.roles"] != "-" || record["security.reason"] != "-" {
		t.Errorf("empty values: %v", record)
	}
}

func TestTheMetricIsPrometheusTextWithEveryKind(t *testing.T) {
	events := NewEvents(slog.New(slog.DiscardHandler))
	events.Deny(context.Background(), Denial{Kind: NotMember})
	var out bytes.Buffer

	events.WriteMetrics(&out)

	text := out.String()
	for _, line := range []string{
		"# TYPE hoops_authz_denied_total counter",
		`hoops_authz_denied_total{kind="not_member"} 1`,
		`hoops_authz_denied_total{kind="role"} 0`,
	} {
		if !strings.Contains(text, line+"\n") {
			t.Errorf("missing %q in\n%s", line, text)
		}
	}
}
