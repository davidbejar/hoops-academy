// Package security writes the security events of ADR-0043 and counts them, the Go counterpart of common-quarkus'
// SecurityEventLog: one WARN record of the logger `hoops.security` per refused request with the fields
// security.event (authz_denied), security.kind, security.outcome (the HTTP status), tenantId, security.subject,
// security.roles, security.resource (METHOD /route) and security.reason; and hoops_authz_denied_total{kind} with every
// kind present from 0. Never a token, an unverified claim, a request value, a name or an e-mail.
package security

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"sort"
	"strconv"
	"strings"
	"sync/atomic"
)

// Kind is what kind of failure an event records.
type Kind string

// The kinds (the names of common-quarkus' DenialKind).
const (
	Unauthenticated Kind = "unauthenticated"
	InvalidToken    Kind = "invalid_token"
	NotMember       Kind = "not_member"
	TenantMismatch  Kind = "tenant_mismatch"
	Role            Kind = "role"
	FineGrained     Kind = "fine_grained"
	RealmRole       Kind = "realm_role"
)

// AllKinds in the order of the Java enum.
var AllKinds = []Kind{Unauthenticated, InvalidToken, NotMember, TenantMismatch, Role, FineGrained, RealmRole}

// Status is the HTTP status the caller was answered.
func (k Kind) Status() int {
	switch k {
	case Unauthenticated, InvalidToken:
		return 401
	case NotMember, TenantMismatch:
		return 404
	default:
		return 403
	}
}

// Denial is one refused request.
type Denial struct {
	Kind     Kind
	Tenant   string
	Subject  string // of a verified token only
	Roles    []string
	Resource string
	Reason   string
}

// Events writes and counts denials.
type Events struct {
	log    *slog.Logger
	counts map[Kind]*atomic.Uint64
}

// NewEvents writes to log.
func NewEvents(log *slog.Logger) *Events {
	counts := make(map[Kind]*atomic.Uint64, len(AllKinds))
	for _, kind := range AllKinds {
		counts[kind] = &atomic.Uint64{}
	}
	return &Events{log: log, counts: counts}
}

// MaxValueLength is the longest value written; longer ones end in "...".
const MaxValueLength = 200

// Deny records one denial.
func (e *Events) Deny(ctx context.Context, d Denial) {
	e.counts[d.Kind].Add(1)
	roles := make([]string, len(d.Roles))
	for i, r := range d.Roles {
		roles[i] = clean(r)
	}
	sort.Strings(roles)
	fields := [][2]string{
		{"security.event", "authz_denied"}, {"security.kind", string(d.Kind)},
		{"security.outcome", strconv.Itoa(d.Kind.Status())}, {"tenantId", clean(d.Tenant)},
		{"security.subject", clean(d.Subject)}, {"security.roles", clean(strings.Join(roles, ","))},
		{"security.resource", clean(d.Resource)}, {"security.reason", clean(d.Reason)},
	}
	attrs := []slog.Attr{slog.String("logger", "hoops.security")}
	for _, f := range fields {
		attrs = append(attrs, slog.String(f[0], f[1]))
	}
	message := fmt.Sprintf(`authz_denied kind=%s outcome=%s tenant=%s subject=%s roles=%s resource="%s" reason="%s"`,
		fields[1][1], fields[2][1], fields[3][1], fields[4][1], fields[5][1], fields[6][1], fields[7][1])
	e.log.LogAttrs(ctx, slog.LevelWarn, message, attrs...)
}

// Count is how many denials of kind were recorded.
func (e *Events) Count(kind Kind) uint64 { return e.counts[kind].Load() }

// WriteMetrics writes the counter in the Prometheus text format.
func (e *Events) WriteMetrics(w io.Writer) {
	_, _ = fmt.Fprint(w, "# HELP hoops_authz_denied_total Authentication and authorization failures answered to callers, by kind (ADR-0043)\n")
	_, _ = fmt.Fprint(w, "# TYPE hoops_authz_denied_total counter\n")
	for _, kind := range AllKinds {
		_, _ = fmt.Fprintf(w, "hoops_authz_denied_total{kind=%q} %d\n", string(kind), e.Count(kind))
	}
}

// clean drops control characters and quotes, cuts at MaxValueLength and writes "-" for nothing.
func clean(value string) string {
	value = strings.Map(func(r rune) rune {
		if r < 0x20 || r == 0x7f || r == '"' {
			return -1
		}
		return r
	}, value)
	if value == "" {
		return "-"
	}
	if runes := []rune(value); len(runes) > MaxValueLength {
		return string(runes[:MaxValueLength-3]) + "..."
	}
	return value
}
