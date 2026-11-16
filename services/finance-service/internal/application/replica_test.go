package application

import (
	"context"
	"errors"
	"testing"
	"time"

	"hoopsacademy.local/finance/internal/domain"
)

type fakeReplica struct {
	applied map[domain.UUID]bool
	tenants []*TenantState
	persons []*PersonState
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

func rosterEvent(topic, kind string) RosterEvent {
	id, _ := domain.ParseUUID("0190b6a1-0000-7000-8000-000000000001")
	return RosterEvent{ID: id, Topic: topic, Type: kind, Tenant: tenant, Aggregate: personA,
		OccurredAt: time.Date(2026, 11, 6, 10, 0, 0, 0, time.UTC),
		TenantData: &TenantState{Status: "ACTIVE", Timezone: "Europe/Madrid"},
		PersonData: &PersonState{Roles: []string{"ADMIN"}, Active: true}}
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

	outcome, err := replica.Apply(ctx, rosterEvent("core.player", "player.changed"))
	if outcome != OutcomeIgnored || err != nil {
		t.Errorf("%s %v", outcome, err)
	}
	failing := NewReplica(&fakeTransactions{fail: errors.New("down")}, &fakeReplica{applied: map[domain.UUID]bool{}})
	if _, err := failing.Apply(ctx, rosterEvent("core.person", "person.changed")); err == nil {
		t.Error("a database failure was swallowed")
	}
}
