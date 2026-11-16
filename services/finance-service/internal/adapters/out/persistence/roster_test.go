package persistence_test

import (
	"context"
	"slices"
	"testing"
	"time"

	"hoopsacademy.local/finance/internal/adapters/out/persistence"
	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/domain"
	"hoopsacademy.local/finance/internal/testsupport/pgtest"
)

func day(y int, m time.Month, d int) time.Time { return time.Date(y, m, d, 0, 0, 0, 0, time.UTC) }

// rosterWorld writes core's roster through the replica (as the consumer does) and reads it back as finance needs it.
type rosterWorld struct {
	t       *testing.T
	tx      persistence.Transactions
	replica application.Replica
	tenant  domain.TenantID
	at      time.Time
}

func newRosterWorld(t *testing.T) *rosterWorld {
	t.Helper()
	database := pgtest.Start(t)
	tx := persistence.NewTransactions(database.App)
	w := &rosterWorld{t: t, tx: tx, replica: application.NewReplica(tx, persistence.ReplicaStore{}), tenant: newTenant(t),
		at: time.Date(2026, 11, 6, 10, 0, 0, 0, time.UTC)}
	w.apply("core.tenant", "tenant.changed", w.tenant.UUID(), func(e *application.RosterEvent) {
		e.TenantData = &application.TenantState{Status: "ACTIVE", Timezone: "Asia/Jakarta"}
	})
	return w
}

// apply writes one event of aggregate id, a second later than the previous one.
func (w *rosterWorld) apply(topic, kind string, id domain.UUID, fill func(*application.RosterEvent)) string {
	w.t.Helper()
	w.at = w.at.Add(time.Second)
	event := application.RosterEvent{ID: randomUUID(), Topic: topic, Type: kind, Tenant: w.tenant, Aggregate: id,
		OccurredAt: w.at}
	if fill != nil {
		fill(&event)
	}
	outcome, err := w.replica.Apply(context.Background(), event)
	if err != nil {
		w.t.Fatal(err)
	}
	return outcome
}

func (w *rosterWorld) team(season domain.UUID, category domain.UUID, start, end time.Time) domain.TeamID {
	id := randomUUID()
	w.apply("core.team", "team.changed", id, func(e *application.RosterEvent) {
		e.TeamData = &application.TeamState{Season: domain.SeasonID(season), SeasonStart: start, SeasonEnd: end,
			AgeCategory: domain.AgeCategoryID(category)}
	})
	return domain.TeamID(id)
}

func (w *rosterWorld) player(name string, person domain.UUID) domain.PlayerID {
	id := randomUUID()
	w.apply("core.player", "player.changed", id, func(e *application.RosterEvent) {
		e.PlayerData = &application.PlayerState{Person: domain.PersonID(person), DisplayName: name, Status: "ACTIVE"}
	})
	return domain.PlayerID(id)
}

func (w *rosterWorld) assign(team domain.TeamID, player domain.PlayerID, joined time.Time, left *time.Time,
	invalid *string) domain.UUID {
	id := randomUUID()
	w.apply("core.team-player", "team-player.changed", id, func(e *application.RosterEvent) {
		e.AssignmentData = &application.AssignmentState{Team: team, Player: player, JoinedOn: joined, LeftOn: left,
			Invalid: invalid}
	})
	return id
}

func (w *rosterWorld) staff(team domain.TeamID, person domain.UUID, role string) domain.UUID {
	id := randomUUID()
	w.apply("core.team-staff", "team-staff.changed", id, func(e *application.RosterEvent) {
		e.StaffData = &application.StaffState{Team: team, Person: domain.PersonID(person), Role: role}
	})
	return id
}

func (w *rosterWorld) link(guardian domain.UUID, player domain.PlayerID) domain.UUID {
	id := randomUUID()
	w.apply("core.guardian-link", "guardian-link.changed", id, func(e *application.RosterEvent) {
		e.LinkData = &application.GuardianLinkState{Guardian: domain.PersonID(guardian), Player: player}
	})
	return id
}

func (w *rosterWorld) read(work func(ctx context.Context, store persistence.RosterStore) error) {
	w.t.Helper()
	if err := w.tx.InTenant(context.Background(), w.tenant, func(ctx context.Context) error {
		return work(ctx, persistence.RosterStore{})
	}); err != nil {
		w.t.Fatal(err)
	}
}

func (w *rosterWorld) candidates(season domain.UUID, target domain.Target, from, to time.Time) []domain.Candidate {
	w.t.Helper()
	var found []domain.Candidate
	w.read(func(ctx context.Context, store persistence.RosterStore) error {
		var err error
		found, err = store.Candidates(ctx, domain.SeasonID(season), target, domain.DueWindow{Start: from, End: to})
		return err
	})
	return found
}

func (w *rosterWorld) relations(person domain.UUID, today time.Time) domain.Relations {
	w.t.Helper()
	var relations domain.Relations
	w.read(func(ctx context.Context, store persistence.RosterStore) error {
		var err error
		relations, err = store.Relations(ctx, domain.PersonID(person), today)
		return err
	})
	return relations
}

func TestTheRosterReplicaAnswersWhoOwesAndWhoMayRead(t *testing.T) {
	w := newRosterWorld(t)
	season, oldSeason, u12, u14 := randomUUID(), randomUUID(), randomUUID(), randomUUID()
	start, end := day(2026, time.September, 1), day(2027, time.June, 30)
	lions := w.team(season, u12, start, end)
	tigers := w.team(season, u12, start, end)
	bears := w.team(season, u14, start, end)
	former := w.team(oldSeason, u12, day(2025, time.September, 1), day(2026, time.June, 30))
	anaPerson, coachPerson, parentPerson := randomUUID(), randomUUID(), randomUUID()
	ana, bea, carl, dan := w.player("Ana", anaPerson), w.player("Bea", randomUUID()), w.player("Carl", randomUUID()),
		w.player("Dan", randomUUID())
	left, invalid := day(2026, time.October, 15), "CATEGORY_TOO_LOW"
	w.assign(lions, ana, start, nil, nil)
	w.assign(tigers, ana, day(2026, time.October, 1), nil, nil)
	w.assign(lions, bea, start, &left, nil)
	w.assign(lions, carl, start, nil, nil)
	w.assign(lions, dan, start, nil, &invalid)
	w.apply("core.player", "player.removed", domain.UUID(carl), nil)
	coaching := w.staff(lions, coachPerson, "COACH")
	w.staff(former, coachPerson, "COACH")
	w.staff(bears, coachPerson, "ASSISTANT_COACH")
	w.link(parentPerson, ana)
	w.link(parentPerson, carl)
	november, october := day(2026, time.November, 1), day(2026, time.October, 1)
	today := day(2026, time.November, 16)

	if got := w.candidates(season, domain.Target{Team: &lions}, november, day(2026, time.November, 30)); !slices.Equal(got,
		[]domain.Candidate{{Player: ana, Team: lions, Name: "Ana"}}) {
		t.Errorf("Lions in November: %v", got)
	}
	if got := w.candidates(season, domain.Target{Team: &lions}, october, day(2026, time.October, 31)); len(got) != 2 {
		t.Errorf("Lions in October (Ana, and Bea until the 15th): %v", got)
	}
	category := domain.AgeCategoryID(u12)
	got := w.candidates(season, domain.Target{AgeCategory: &category}, october, day(2026, time.October, 31))
	if len(got) != 3 || got[0].Team != lions || got[2] != (domain.Candidate{Player: ana, Team: tigers, Name: "Ana"}) {
		t.Errorf("U12 in October, by the day each joined: %v", got)
	}
	if got := w.candidates(randomUUID(), domain.Target{Team: &lions}, november, day(2026, time.November, 30)); len(got) != 0 {
		t.Errorf("another season: %v", got)
	}

	if r := w.relations(coachPerson, today); !slices.Equal(r.StaffTeams, []domain.TeamID{lions}) {
		t.Errorf("a coach coaches the current teams only, not as assistant: %v", r.StaffTeams)
	}
	if r := w.relations(parentPerson, today); !slices.Equal(r.LinkedPlayers, []domain.PlayerID{ana}) {
		t.Errorf("a parent's linked players without the removed one: %v", r.LinkedPlayers)
	}
	if r := w.relations(anaPerson, today); r.OwnPlayer == nil || *r.OwnPlayer != ana {
		t.Errorf("own player: %v", r.OwnPlayer)
	}

	w.read(func(ctx context.Context, store persistence.RosterStore) error {
		academy, found, err := store.Academy(ctx)
		if err != nil || !found || !academy.Active || academy.Zone.String() != "Asia/Jakarta" {
			t.Errorf("academy %+v %v %v", academy, found, err)
		}
		dates, found, err := store.SeasonDates(ctx, domain.SeasonID(season))
		if err != nil || !found || !dates.Start.Equal(start) || !dates.End.Equal(end) {
			t.Errorf("season %+v %v %v", dates, found, err)
		}
		if _, found, _ := store.SeasonDates(ctx, domain.SeasonID(randomUUID())); found {
			t.Error("an unknown season was found")
		}
		players, found, err := store.TeamRoster(ctx, lions)
		if err != nil || !found || !slices.Equal(players, []application.RosterPlayer{{Player: ana, Name: "Ana"}}) {
			t.Errorf("the Lions' roster today: %v %v %v", players, found, err)
		}
		if _, found, _ := store.TeamRoster(ctx, domain.TeamID(randomUUID())); found {
			t.Error("an unknown team was found")
		}
		return nil
	})

	w.apply("core.team-staff", "team-staff.removed", coaching, nil)
	if r := w.relations(coachPerson, today); len(r.StaffTeams) != 0 {
		t.Errorf("a detached coach: %v", r.StaffTeams)
	}
}

func TestAnOlderRosterEventNeverOverwritesANewerOne(t *testing.T) {
	w := newRosterWorld(t)
	season := randomUUID()
	team := w.team(season, randomUUID(), day(2026, time.September, 1), day(2027, time.June, 30))
	moved := day(2026, time.October, 1)
	late := application.RosterEvent{ID: randomUUID(), Topic: "core.team", Type: "team.changed", Tenant: w.tenant,
		Aggregate: domain.UUID(team), OccurredAt: w.at.Add(-time.Hour), TeamData: &application.TeamState{
			Season: domain.SeasonID(season), SeasonStart: moved, SeasonEnd: moved, AgeCategory: domain.AgeCategoryID(randomUUID())}}
	if _, err := w.replica.Apply(context.Background(), late); err != nil {
		t.Fatal(err)
	}

	w.read(func(ctx context.Context, store persistence.RosterStore) error {
		dates, _, err := store.SeasonDates(ctx, domain.SeasonID(season))
		if err != nil || !dates.Start.Equal(day(2026, time.September, 1)) {
			t.Errorf("the older event won: %+v %v", dates, err)
		}
		return nil
	})
	w.apply("core.team", "team.removed", domain.UUID(team), nil)
	w.read(func(ctx context.Context, store persistence.RosterStore) error {
		if _, found, _ := store.TeamRoster(ctx, team); found {
			t.Error("a removed team was found")
		}
		return nil
	})
}
