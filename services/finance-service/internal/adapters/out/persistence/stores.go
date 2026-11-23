package persistence

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"github.com/jackc/pgx/v5"

	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/domain"
)

// SettingsStore implements application.SettingsStore on finance.settings.
type SettingsStore struct{}

const (
	selectSettings = "select currency, version from finance.settings where tenant_id = app.current_tenant()"
	insertSettings = `insert into finance.settings (tenant_id, currency, updated_at, version)
		values (app.current_tenant(), $1, now(), 1)`
	updateSettings = `update finance.settings set currency = $1, updated_at = now(), version = version + 1
		where tenant_id = app.current_tenant() and version = $2`
)

// Get reads the bound tenant's settings.
func (SettingsStore) Get(ctx context.Context) (domain.Settings, bool, error) {
	q, err := txOf(ctx)
	if err != nil {
		return domain.Settings{}, false, err
	}
	var code string
	var version int
	if err := q.QueryRow(ctx, selectSettings).Scan(&code, &version); errors.Is(err, pgx.ErrNoRows) {
		return domain.Settings{}, false, nil
	} else if err != nil {
		return domain.Settings{}, false, fmt.Errorf("read settings: %w", err)
	}
	currency, err := domain.ParseCurrency(code)
	if err != nil {
		return domain.Settings{}, false, fmt.Errorf("stored currency %q: %w", code, err)
	}
	return domain.Settings{Currency: currency, Version: version}, true, nil
}

// Save inserts version 1 (Version 0) or updates the stored version.
func (SettingsStore) Save(ctx context.Context, settings domain.Settings) error {
	q, err := txOf(ctx)
	if err != nil {
		return err
	}
	if settings.Version == 0 {
		if _, err := q.Exec(ctx, insertSettings, settings.Currency.Code()); err != nil {
			return fmt.Errorf("insert settings: %w", err)
		}
		return nil
	}
	tag, err := q.Exec(ctx, updateSettings, settings.Currency.Code(), settings.Version)
	if err != nil {
		return fmt.Errorf("update settings: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return application.ErrConcurrentModification
	}
	return nil
}

// AuditLog implements application.AuditLog on finance.audit_event, and writes each event as one line of the logger
// `hoops.audit` (ADR-0017: ids, action, target, metadata; never personal data).
type AuditLog struct {
	IDs application.IDs
	Log *slog.Logger
}

const insertAudit = `insert into finance.audit_event (id, tenant_id, actor_sub, actor_person_id, action, target_type,
	target_id, metadata) values ($1, app.current_tenant(), $2, $3, $4, $5, $6, $7)`

// Record writes the event in the context's transaction.
func (a AuditLog) Record(ctx context.Context, event application.AuditEvent) error {
	q, err := txOf(ctx)
	if err != nil {
		return err
	}
	metadata, err := json.Marshal(event.Metadata)
	if err != nil {
		return fmt.Errorf("audit metadata: %w", err)
	}
	id := a.IDs.New()
	actor := event.Actor
	var person *string // none for the service's own actor (the daily job)
	if !actor.IsSystem() {
		text := actor.Person().String()
		person = &text
	}
	if _, err := q.Exec(ctx, insertAudit, id.String(), actor.Subject(), person, event.Action,
		event.TargetType, event.TargetID, string(metadata)); err != nil {
		return fmt.Errorf("record audit event: %w", err)
	}
	if a.Log != nil {
		a.Log.InfoContext(ctx, "audit "+event.Action, slog.String("logger", "hoops.audit"),
			slog.String("tenantId", actor.Tenant().String()), slog.String("audit.action", event.Action),
			slog.String("audit.targetType", event.TargetType), slog.String("audit.targetId", event.TargetID),
			slog.String("audit.actor", actor.Subject()), slog.String("audit.metadata", string(metadata)))
	}
	return nil
}

// MembershipStore implements application.MembershipSource on the replica (finance.tenant_ref, person_ref).
type MembershipStore struct{}

const selectMembership = `select p.id, p.roles from finance.person_ref p
	join finance.tenant_ref t on t.tenant_id = p.tenant_id
	where p.tenant_id = app.current_tenant() and p.subject = $1 and p.active and not p.removed
	  and t.status = 'ACTIVE' and not t.removed
	order by p.occurred_at desc limit 1`

// Membership reads an active member with login subject of the bound (ACTIVE) academy.
func (MembershipStore) Membership(ctx context.Context, tenant domain.TenantID, subject string) (domain.Membership, bool, error) {
	q, err := txOf(ctx)
	if err != nil {
		return domain.Membership{}, false, err
	}
	var personText string
	var roleTexts []string
	if err := q.QueryRow(ctx, selectMembership, subject).Scan(&personText, &roleTexts); errors.Is(err, pgx.ErrNoRows) {
		return domain.Membership{}, false, nil
	} else if err != nil {
		return domain.Membership{}, false, fmt.Errorf("membership: %w", err)
	}
	person, err := domain.ParseUUID(personText)
	if err != nil {
		return domain.Membership{}, false, fmt.Errorf("person id: %w", err)
	}
	roles := make([]domain.Role, 0, len(roleTexts))
	for _, text := range roleTexts {
		if role, err := domain.ParseRole(text); err == nil {
			roles = append(roles, role)
		}
	}
	return domain.NewMembership(subject, domain.PersonID(person), tenant, roles), true, nil
}

func timestamp(t time.Time) time.Time { return t.UTC() }
