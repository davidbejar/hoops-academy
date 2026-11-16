package application

import (
	"context"
	"time"

	"hoopsacademy.local/finance/internal/domain"
)

// RosterEvent is one valid event of a core topic (ADR-0036), decoded by the inbound events adapter. Only what the
// replica keeps is carried: no names, birth dates or genders (P-10).
type RosterEvent struct {
	ID         domain.UUID
	Topic      string
	Type       string // e.g. person.changed, person.removed
	Tenant     domain.TenantID
	Aggregate  domain.UUID
	OccurredAt time.Time
	TenantData *TenantState // tenant.changed
	PersonData *PersonState // person.changed
}

// TenantState is an academy as the replica keeps it.
type TenantState struct{ Status, Timezone string }

// PersonState is a member as the replica keeps it.
type PersonState struct {
	Subject *string
	Roles   []string
	Active  bool
}

// ReplicaStore writes the replica in the bound tenant's transaction (ADR-0037 §2-3).
type ReplicaStore interface {
	// MarkApplied records the event id; false when it was known (a duplicate).
	MarkApplied(ctx context.Context, event domain.UUID, topic string) (bool, error)
	// NoteTenant records that the replica holds rows of the bound tenant.
	NoteTenant(ctx context.Context) error
	// UpsertTenant writes the academy unless a newer event wrote it; nil state = removed (soft).
	UpsertTenant(ctx context.Context, event RosterEvent, state *TenantState) error
	// UpsertPerson writes the member unless a newer event wrote it; nil state = removed (soft).
	UpsertPerson(ctx context.Context, event RosterEvent, state *PersonState) error
}

// The outcomes of Apply (the metric's outcome tag).
const (
	OutcomeApplied   = "applied"
	OutcomeDuplicate = "duplicate"
	OutcomeIgnored   = "ignored" // a valid event of a type this replica does not keep (yet)
)

// Replica applies core's events to the local replica.
type Replica struct {
	tx    Transactions
	store ReplicaStore
}

// NewReplica wires the replica.
func NewReplica(tx Transactions, store ReplicaStore) Replica { return Replica{tx: tx, store: store} }

// Apply writes event in one transaction bound to the event's own tenant (never a request's): first the event id
// (a known one changes nothing), then the aggregate's row.
func (r Replica) Apply(ctx context.Context, event RosterEvent) (string, error) {
	write := r.writer(event)
	if write == nil {
		return OutcomeIgnored, nil
	}
	outcome := OutcomeApplied
	err := r.tx.InTenant(ctx, event.Tenant, func(ctx context.Context) error {
		first, err := r.store.MarkApplied(ctx, event.ID, event.Topic)
		if err != nil {
			return err
		}
		if err := r.store.NoteTenant(ctx); err != nil {
			return err
		}
		if !first {
			outcome = OutcomeDuplicate
			return nil
		}
		return write(ctx)
	})
	return outcome, err
}

func (r Replica) writer(event RosterEvent) func(ctx context.Context) error {
	switch event.Type {
	case "tenant.changed":
		return func(ctx context.Context) error { return r.store.UpsertTenant(ctx, event, event.TenantData) }
	case "tenant.removed":
		return func(ctx context.Context) error { return r.store.UpsertTenant(ctx, event, nil) }
	case "person.changed":
		return func(ctx context.Context) error { return r.store.UpsertPerson(ctx, event, event.PersonData) }
	case "person.removed":
		return func(ctx context.Context) error { return r.store.UpsertPerson(ctx, event, nil) }
	default:
		return nil
	}
}
