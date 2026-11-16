package application

import (
	"context"
	"errors"
	"slices"
	"testing"
	"time"

	"hoopsacademy.local/finance/internal/domain"
)

type fakeReplica struct {
	applied map[domain.UUID]bool
	tenants []*TenantState
	persons []*PersonState
	writes  []string // "<aggregate> <state or nil>" of the roster aggregates of WP119
	seen    int
}

func (f *fakeReplica) MarkApplied(_ context.Context, event domain.UUID, _ string) (bool, error) {
	if f.applied[event] {
		return false, nil
	}
	f.applied[event] = true
	return true, nil
}

func (f *fakeReplica) NoteTenant(context.Context) error { f.seen++; return nil }

func (f *fakeReplica) UpsertTenant(_ context.Context, _ RosterEvent, state *TenantState) error {
	f.tenants = append(f.tenants, state)
	return nil
}

func (f *fakeReplica) UpsertPerson(_ context.Context, _ RosterEvent, state *PersonState) error {
	f.persons = append(f.persons, state)
	return nil
}

func (f *fakeReplica) note(aggregate string, removed bool) error {
	state := "state"
	if removed {
		state = "nil"
	}
	f.writes = append(f.writes, aggregate+" "+state)
	return nil
}

func (f *fakeReplica) UpsertPlayer(_ context.Context, _ RosterEvent, s *PlayerState) error {
	return f.note("player", s == nil)
}

func (f *fakeReplica) UpsertTeam(_ context.Context, _ RosterEvent, s *TeamState) error {
	return f.note("team", s == nil)
}

func (f *fakeReplica) UpsertAssignment(_ context.Context, _ RosterEvent, s *AssignmentState) error {
	return f.note("team-player", s == nil)
}

func (f *fakeReplica) UpsertStaff(_ context.Context, _ RosterEvent, s *StaffState) error {
	return f.note("team-staff", s == nil)
}

func (f *fakeReplica) UpsertGuardianLink(_ context.Context, _ RosterEvent, s *GuardianLinkState) error {
	return f.note("guardian-link", s == nil)
}

func rosterEvent(topic, kind string) RosterEvent {
	id, _ := domain.ParseUUID("0190b6a1-0000-7000-8000-000000000001")
	return RosterEvent{ID: id, Topic: topic, Type: kind, Tenant: tenant, Aggregate: personA,
		OccurredAt: time.Date(2026, 11, 6, 10, 0, 0, 0, time.UTC),
		TenantData: &TenantState{Status: "ACTIVE", Timezone: "Europe/Madrid"},
		PersonData: &PersonState{Roles: []string{"ADMIN"}, Active: true}, PlayerData: &PlayerState{},
		TeamData: &TeamState{}, AssignmentData: &AssignmentState{}, StaffData: &StaffState{},
		LinkData: &GuardianLinkState{}}
}

func TestAnEventIsAppliedOnceInATransactionBoundToItsOwnTenant(t *testing.T) {
	tx := &fakeTransactions{}
	store := &fakeReplica{applied: map[domain.UUID]bool{}}
	replica := NewReplica(tx, store)

	first, err := replica.Apply(ctx, rosterEvent("core.person", "person.changed"))
	again, _ := replica.Apply(ctx, rosterEvent("core.person", "person.changed"))

	if err != nil || first != OutcomeApplied || again != OutcomeDuplicate || len(store.persons) != 1 || store.seen != 2 {
		t.Errorf("first %s again %s persons %d: %v", first, again, len(store.persons), err)
	}
	if len(tx.bound) != 2 || tx.bound[0] != tenant {
		t.Errorf("bound %v", tx.bound)
	}
}

func TestRemovalsAreSoftAndTenantsGoToTheirTable(t *testing.T) {
	store := &fakeReplica{applied: map[domain.UUID]bool{}}
	replica := NewReplica(&fakeTransactions{}, store)

	removed := rosterEvent("core.person", "person.removed")
	_, _ = replica.Apply(ctx, removed)
	changed := rosterEvent("core.tenant", "tenant.changed")
	changed.ID[15] = 2
	_, _ = replica.Apply(ctx, changed)
	gone := rosterEvent("core.tenant", "tenant.removed")
	gone.ID[15] = 3
	_, _ = replica.Apply(ctx, gone)

	if len(store.persons) != 1 || store.persons[0] != nil {
		t.Errorf("person removal: %v", store.persons)
	}
	if len(store.tenants) != 2 || store.tenants[0] == nil || store.tenants[1] != nil {
		t.Errorf("tenants: %v", store.tenants)
	}
}

func TestAnUnknownTypeIsNotApplied(t *testing.T) {
	replica := NewReplica(&fakeTransactions{}, &fakeReplica{applied: map[domain.UUID]bool{}})

	outcome, err := replica.Apply(ctx, rosterEvent("core.season", "season.changed"))
	if outcome != OutcomeIgnored || err != nil {
		t.Errorf("%s %v", outcome, err)
	}
	failing := NewReplica(&fakeTransactions{fail: errors.New("down")}, &fakeReplica{applied: map[domain.UUID]bool{}})
	if _, err := failing.Apply(ctx, rosterEvent("core.person", "person.changed")); err == nil {
		t.Error("a database failure was swallowed")
	}
}

// WP119: players, teams, assignments, staff and guardian links go to their tables; removals are soft (no state).
func TestTheRosterAggregatesOfFinanceGoToTheirTables(t *testing.T) {
	store := &fakeReplica{applied: map[domain.UUID]bool{}}
	replica := NewReplica(&fakeTransactions{}, store)
	var want []string
	for i, aggregate := range []string{"player", "team", "team-player", "team-staff", "guardian-link"} {
		for j, kind := range []string{"changed", "removed"} {
			event := rosterEvent("core."+aggregate, aggregate+"."+kind)
			event.ID[14], event.ID[15] = byte(i), byte(j+10)
			if outcome, err := replica.Apply(ctx, event); err != nil || outcome != OutcomeApplied {
				t.Errorf("%s: %s %v", event.Type, outcome, err)
			}
		}
		want = append(want, aggregate+" state", aggregate+" nil")
	}
	if !slices.Equal(store.writes, want) {
		t.Errorf("writes %v", store.writes)
	}
	if outcome, _ := replica.Apply(ctx, rosterEvent("core.player", "player.renamed")); outcome != OutcomeIgnored {
		t.Errorf("an unknown change of a known aggregate: %s", outcome)
	}
}
