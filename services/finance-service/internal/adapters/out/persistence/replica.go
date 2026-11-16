package persistence

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"

	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/domain"
)

// ReplicaStore implements application.ReplicaStore on finance.applied_event, replica_tenant, tenant_ref and
// person_ref (ADR-0037): upserts guarded by occurred_at, soft removals with no payload kept.
type ReplicaStore struct{}

const (
	markApplied = `insert into finance.applied_event (tenant_id, event_id, topic) values (app.current_tenant(), $1, $2)
		on conflict do nothing`
	noteTenant   = "insert into finance.replica_tenant (id) values (app.current_tenant()) on conflict do nothing"
	upsertTenant = `insert into finance.tenant_ref (tenant_id, status, timezone, removed, occurred_at, event_id, slug)
		values (app.current_tenant(), $1, $2, $3, $4, $5, $6)
		on conflict (tenant_id) do update set status = excluded.status, timezone = excluded.timezone, slug = excluded.slug,
			removed = excluded.removed, occurred_at = excluded.occurred_at, event_id = excluded.event_id
		where finance.tenant_ref.occurred_at <= excluded.occurred_at`
	upsertPerson = `insert into finance.person_ref (tenant_id, id, subject, roles, active, removed, occurred_at, event_id,
			display_name)
		values (app.current_tenant(), $1, $2, $3, $4, $5, $6, $7, $8)
		on conflict (tenant_id, id) do update set subject = excluded.subject, roles = excluded.roles,
			active = excluded.active, removed = excluded.removed, occurred_at = excluded.occurred_at,
			event_id = excluded.event_id, display_name = excluded.display_name
		where finance.person_ref.occurred_at <= excluded.occurred_at`
)

// MarkApplied records the event id of the bound tenant.
func (ReplicaStore) MarkApplied(ctx context.Context, event domain.UUID, topic string) (bool, error) {
	q, err := txOf(ctx)
	if err != nil {
		return false, err
	}
	tag, err := q.Exec(ctx, markApplied, event.String(), topic)
	if err != nil {
		return false, fmt.Errorf("mark applied: %w", err)
	}
	return tag.RowsAffected() == 1, nil
}

// NoteTenant records the bound tenant in finance.replica_tenant.
func (ReplicaStore) NoteTenant(ctx context.Context) error {
	q, err := txOf(ctx)
	if err != nil {
		return err
	}
	if _, err := q.Exec(ctx, noteTenant); err != nil {
		return fmt.Errorf("note tenant: %w", err)
	}
	return nil
}

// UpsertTenant writes the academy (nil state: removed, no payload kept).
func (ReplicaStore) UpsertTenant(ctx context.Context, e application.RosterEvent, state *application.TenantState) error {
	q, err := txOf(ctx)
	if err != nil {
		return err
	}
	var status, zone, slug *string
	if state != nil {
		status, zone, slug = &state.Status, &state.Timezone, &state.Slug
	}
	if _, err := q.Exec(ctx, upsertTenant, status, zone, state == nil, e.OccurredAt, e.ID.String(), slug); err != nil {
		return fmt.Errorf("upsert tenant: %w", err)
	}
	return nil
}

// UpsertPerson writes the member (nil state: removed, no login or roles kept).
func (ReplicaStore) UpsertPerson(ctx context.Context, e application.RosterEvent, state *application.PersonState) error {
	q, err := txOf(ctx)
	if err != nil {
		return err
	}
	var subject, name *string
	var roles []string
	var active *bool
	if state != nil {
		subject, roles, active, name = state.Subject, state.Roles, &state.Active, &state.DisplayName
	}
	if _, err := q.Exec(ctx, upsertPerson, e.Aggregate.String(), subject, roles, active, state == nil, e.OccurredAt,
		e.ID.String(), name); err != nil {
		return fmt.Errorf("upsert person: %w", err)
	}
	return nil
}

// Parked is an invalid record: where it was and why, never its value (ADR-0037 §4).
type Parked struct {
	Topic     string
	Partition int32
	Offset    int64
	Key       string
	EventID   string
	Reason    string
}

// ParkedEvents writes finance.parked_event, the one table without a tenant (finance_app may only insert).
type ParkedEvents struct{ Pool *pgxpool.Pool }

const insertParked = `insert into finance.parked_event (topic, partition, "offset", record_key, event_id, reason)
	values ($1, $2, $3, $4, $5, $6)`

// Park records an invalid record.
func (p ParkedEvents) Park(ctx context.Context, parked Parked) error {
	if _, err := p.Pool.Exec(ctx, insertParked, parked.Topic, parked.Partition, parked.Offset, cut(parked.Key, 200),
		cut(parked.EventID, 64), parked.Reason); err != nil {
		return fmt.Errorf("park event: %w", err)
	}
	return nil
}

func cut(s string, n int) string {
	if len(s) > n {
		return s[:n]
	}
	return s
}
