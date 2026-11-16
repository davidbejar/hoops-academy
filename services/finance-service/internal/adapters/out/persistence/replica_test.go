package persistence_test

import (
	"context"
	"testing"
	"time"

	"hoopsacademy.local/finance/internal/adapters/out/persistence"
	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/domain"
	"hoopsacademy.local/finance/internal/testsupport/pgtest"
)

func personEvent(tenant domain.TenantID, person domain.UUID, at time.Time, state *application.PersonState) application.RosterEvent {
	kind := "person.changed"
	if state == nil {
		kind = "person.removed"
	}
	return application.RosterEvent{ID: randomUUID(), Topic: "core.person", Type: kind, Tenant: tenant,
		Aggregate: person, OccurredAt: at, PersonData: state}
}

func tenantEvent(tenant domain.TenantID, at time.Time, status string) application.RosterEvent {
	return application.RosterEvent{ID: randomUUID(), Topic: "core.tenant", Type: "tenant.changed", Tenant: tenant,
		Aggregate: tenant.UUID(), OccurredAt: at,
		TenantData: &application.TenantState{Status: status, Timezone: "Asia/Jakarta"}}
}

func TestTheReplicaKeepsTheNewestStateAndSoftRemovals(t *testing.T) {
	database := pgtest.Start(t)
	tx := persistence.NewTransactions(database.App)
	replica := application.NewReplica(tx, persistence.ReplicaStore{})
	tenant := newTenant(t)
	person := randomUUID()
	subject := "sub-" + person.String()
	t0 := time.Date(2026, 11, 6, 10, 0, 0, 0, time.UTC)
	admin := &application.PersonState{Subject: &subject, Roles: []string{"ADMIN"}, Active: true}
	parent := &application.PersonState{Subject: &subject, Roles: []string{"PARENT"}, Active: true}
	apply := func(e application.RosterEvent) string {
		outcome, err := replica.Apply(context.Background(), e)
		if err != nil {
			t.Fatal(err)
		}
		return outcome
	}
	roles := func() []string {
		var m domain.Membership
		var ok bool
		_ = tx.InTenant(context.Background(), tenant, func(ctx context.Context) error {
			var err error
			m, ok, err = persistence.MembershipStore{}.Membership(ctx, tenant, subject)
			return err
		})
		if !ok {
			return nil
		}
		return m.RoleNames()
	}

	apply(tenantEvent(tenant, t0, "ACTIVE"))
	changed := personEvent(tenant, person, t0.Add(time.Minute), admin)
	if apply(changed) != application.OutcomeApplied || apply(changed) != application.OutcomeDuplicate {
		t.Error("idempotency")
	}
	if got := roles(); len(got) != 1 || got[0] != "ADMIN" {
		t.Errorf("after the first event: %v", got)
	}
	apply(personEvent(tenant, person, t0, parent)) // older: ignored
	if got := roles(); len(got) != 1 || got[0] != "ADMIN" {
		t.Errorf("an older event overwrote a newer one: %v", got)
	}
	apply(personEvent(tenant, person, t0.Add(2*time.Minute), nil))
	if got := roles(); got != nil {
		t.Errorf("a removed person resolved: %v", got)
	}
	apply(personEvent(tenant, person, t0.Add(90*time.Second), admin)) // late older change after the removal
	if got := roles(); got != nil {
		t.Errorf("a late change brought a removed person back: %v", got)
	}
	apply(personEvent(tenant, person, t0.Add(3*time.Minute), parent)) // the person came back
	if got := roles(); len(got) != 1 || got[0] != "PARENT" {
		t.Errorf("a newer change after the removal: %v", got)
	}
	apply(tenantEvent(tenant, t0.Add(4*time.Minute), "SUSPENDED"))
	if got := roles(); got != nil {
		t.Errorf("a suspended academy's member resolved: %v", got)
	}
}

func TestParkedEventsAreWrittenWithoutTheirValue(t *testing.T) {
	database := pgtest.Start(t)
	parked := persistence.ParkedEvents{Pool: database.App}

	if err := parked.Park(context.Background(), persistence.Parked{Topic: "core.person", Partition: 0, Offset: 42,
		Key: "a:b", EventID: "x", Reason: "schema"}); err != nil {
		t.Fatal(err)
	}
	var reason string
	if err := database.Migrator.QueryRow(context.Background(),
		`select reason from finance.parked_event where "offset" = 42`).Scan(&reason); err != nil || reason != "schema" {
		t.Errorf("parked: %s %v", reason, err)
	}
}
