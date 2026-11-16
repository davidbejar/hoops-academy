package application

import (
	"context"
	"strings"
	"time"

	"hoopsacademy.local/finance/internal/domain"
)

// RosterEvent is one valid event of a core topic (ADR-0036), decoded by the inbound events adapter. Only what the
// replica keeps is carried: never a birth date or a gender (P-10).
type RosterEvent struct {
	ID             domain.UUID
	Topic          string
	Type           string // e.g. person.changed, person.removed
	Tenant         domain.TenantID
	Aggregate      domain.UUID
	OccurredAt     time.Time
	TenantData     *TenantState       // tenant.changed
	PersonData     *PersonState       // person.changed
	PlayerData     *PlayerState       // player.changed
	TeamData       *TeamState         // team.changed
	AssignmentData *AssignmentState   // team-player.changed
	StaffData      *StaffState        // team-staff.changed
	LinkData       *GuardianLinkState // guardian-link.changed
}

// TenantState is an academy as the replica keeps it (the slug names the export files).
type TenantState struct{ Status, Timezone, Slug string }

// PersonState is a member as the replica keeps it.
type PersonState struct {
	Subject     *string
	Roles       []string
	Active      bool
	DisplayName string // shown as who recorded or voided a payment
}

// PlayerState is a player as the replica keeps it: no birth date, no gender (P-10).
type PlayerState struct {
	Person      domain.PersonID
	DisplayName string
	Status      string
}

// TeamState is a team as the replica keeps it: its season's dates, its age category and its name (the dues export).
type TeamState struct {
	Season                 domain.SeasonID
	SeasonStart, SeasonEnd time.Time
	AgeCategory            domain.AgeCategoryID
	Name                   string
}

// AssignmentState is a player's assignment to a team (core.team_player); LeftOn is the last day on the team.
type AssignmentState struct {
	Team     domain.TeamID
	Player   domain.PlayerID
	JoinedOn time.Time
	LeftOn   *time.Time
	Invalid  *string // the eligibility reason that invalidated it
}

// StaffState is a coach or assistant coach of a team.
type StaffState struct {
	Team   domain.TeamID
	Person domain.PersonID
	Role   string
}

// GuardianLinkState links a guardian (PARENT) to a player.
type GuardianLinkState struct {
	Guardian domain.PersonID
	Player   domain.PlayerID
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
	// UpsertPlayer, UpsertTeam, UpsertAssignment, UpsertStaff and UpsertGuardianLink write the other aggregates by
	// the same rules.
	UpsertPlayer(ctx context.Context, event RosterEvent, state *PlayerState) error
	UpsertTeam(ctx context.Context, event RosterEvent, state *TeamState) error
	UpsertAssignment(ctx context.Context, event RosterEvent, state *AssignmentState) error
	UpsertStaff(ctx context.Context, event RosterEvent, state *StaffState) error
	UpsertGuardianLink(ctx context.Context, event RosterEvent, state *GuardianLinkState) error
}

// The outcomes of Apply (the metric's outcome tag).
const (
	OutcomeApplied   = "applied"
	OutcomeDuplicate = "duplicate"
	OutcomeIgnored   = "ignored" // a valid event of a type this replica does not keep
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

// writer is the write of event's aggregate: its state for `<aggregate>.changed`, none (a soft removal) for
// `<aggregate>.removed`; nil for a type this replica does not keep.
func (r Replica) writer(event RosterEvent) func(ctx context.Context) error {
	aggregate, change, _ := strings.Cut(event.Type, ".")
	write, known := r.writes()[aggregate]
	if !known || (change != "changed" && change != "removed") {
		return nil
	}
	removed := change == "removed"
	return func(ctx context.Context) error { return write(ctx, event, removed) }
}

type aggregateWrite func(ctx context.Context, event RosterEvent, removed bool) error

func (r Replica) writes() map[string]aggregateWrite {
	s := r.store
	return map[string]aggregateWrite{
		"tenant": func(ctx context.Context, e RosterEvent, removed bool) error {
			return s.UpsertTenant(ctx, e, unless(removed, e.TenantData))
		},
		"person": func(ctx context.Context, e RosterEvent, removed bool) error {
			return s.UpsertPerson(ctx, e, unless(removed, e.PersonData))
		},
		"player": func(ctx context.Context, e RosterEvent, removed bool) error {
			return s.UpsertPlayer(ctx, e, unless(removed, e.PlayerData))
		},
		"team": func(ctx context.Context, e RosterEvent, removed bool) error {
			return s.UpsertTeam(ctx, e, unless(removed, e.TeamData))
		},
		"team-player": func(ctx context.Context, e RosterEvent, removed bool) error {
			return s.UpsertAssignment(ctx, e, unless(removed, e.AssignmentData))
		},
		"team-staff": func(ctx context.Context, e RosterEvent, removed bool) error {
			return s.UpsertStaff(ctx, e, unless(removed, e.StaffData))
		},
		"guardian-link": func(ctx context.Context, e RosterEvent, removed bool) error {
			return s.UpsertGuardianLink(ctx, e, unless(removed, e.LinkData))
		},
	}
}

// unless is state, or nil when removed (a removal keeps no state).
func unless[T any](removed bool, state *T) *T {
	if removed {
		return nil
	}
	return state
}
