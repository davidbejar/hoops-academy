package rest_test

import (
	"context"
	"testing"
	"time"

	"hoopsacademy.local/finance/internal/adapters/out/persistence"
	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/domain"
)

// The dues tests run on today's date (the API's clock is the system's), so their seasons and periods are relative to
// the current month, in an academy of zone UTC.

func firstOfMonth(offset int) time.Time {
	now := time.Now().UTC()
	return time.Date(now.Year(), now.Month()+time.Month(offset), 1, 0, 0, 0, 0, time.UTC)
}

func month(offset int) string { return firstOfMonth(offset).Format("2006-01") }

func dateOf(t time.Time) string { return t.Format(time.DateOnly) }

func todayUTC() string { return time.Now().UTC().Format(time.DateOnly) }

// seed writes core's roster into the replica of one academy through the real replica, as the consumer would.
type seed struct {
	t       *testing.T
	a       *api
	tenant  domain.TenantID
	replica application.Replica
	at      time.Time
	season  string
	start   time.Time
	end     time.Time
}

// seedAcademy is an ACTIVE academy in zone UTC with members subject -> roles, and a season from six months ago to
// seven months ahead.
func (a *api) seedAcademy(t *testing.T, members map[string][]string) *seed {
	t.Helper()
	tenantText := a.academy(t, members)
	a.bound(t, tenantText, "update finance.tenant_ref set timezone = 'UTC'")
	tenant, err := domain.ParseTenantID(tenantText)
	if err != nil {
		t.Fatal(err)
	}
	return &seed{t: t, a: a, tenant: tenant, at: time.Now().UTC().Add(-time.Hour), season: uuid(),
		replica: application.NewReplica(persistence.NewTransactions(a.db.App), persistence.ReplicaStore{}),
		start:   firstOfMonth(-6), end: firstOfMonth(7).AddDate(0, 0, -1)}
}

func (s *seed) id() string { return s.tenant.String() }

func (s *seed) apply(topic, kind, id string, fill func(*application.RosterEvent)) {
	s.t.Helper()
	s.at = s.at.Add(time.Millisecond)
	aggregate, _ := domain.ParseUUID(id)
	eventID, _ := domain.ParseUUID(uuid())
	event := application.RosterEvent{ID: eventID, Topic: topic, Type: kind, Tenant: s.tenant, Aggregate: aggregate,
		OccurredAt: s.at}
	fill(&event)
	if _, err := s.replica.Apply(context.Background(), event); err != nil {
		s.t.Fatal(err)
	}
}

func parse(text string) domain.UUID {
	id, err := domain.ParseUUID(text)
	if err != nil {
		panic(err)
	}
	return id
}

// team is a team of the seed's season (or of a season that ended last month, when ended).
func (s *seed) team(category string, ended bool) string {
	id, season, start, end := uuid(), s.season, s.start, s.end
	if ended {
		season, start, end = uuid(), firstOfMonth(-13), firstOfMonth(0).AddDate(0, 0, -1)
	}
	s.apply("core.team", "team.changed", id, func(e *application.RosterEvent) {
		e.TeamData = &application.TeamState{Season: domain.SeasonID(parse(season)), SeasonStart: start, SeasonEnd: end,
			AgeCategory: domain.AgeCategoryID(parse(category)), Name: "Team " + id[:4]}
	})
	return id
}

// slug sends the academy's tenant.changed with slug (ACTIVE, zone UTC), as core does after an edit.
func (s *seed) slug(slug string) {
	s.at = time.Now().UTC() // newer than the row academy() wrote, so the replica takes it
	s.apply("core.tenant", "tenant.changed", s.id(), func(e *application.RosterEvent) {
		e.TenantData = &application.TenantState{Status: "ACTIVE", Timezone: "UTC", Slug: slug}
	})
}

// player is a player whose person is person ("" = a person without a login).
func (s *seed) player(name, person string) string {
	id := uuid()
	if person == "" {
		person = uuid()
	}
	s.apply("core.player", "player.changed", id, func(e *application.RosterEvent) {
		e.PlayerData = &application.PlayerState{Person: domain.PersonID(parse(person)), DisplayName: name, Status: "ACTIVE"}
	})
	return id
}

// assign puts player on team from joined (open when left is the zero time).
func (s *seed) assign(team, player string, joined, left time.Time) {
	s.apply("core.team-player", "team-player.changed", uuid(), func(e *application.RosterEvent) {
		state := &application.AssignmentState{Team: domain.TeamID(parse(team)), Player: domain.PlayerID(parse(player)),
			JoinedOn: joined}
		if !left.IsZero() {
			state.LeftOn = &left
		}
		e.AssignmentData = state
	})
}

func (s *seed) staff(team, person, role string) {
	s.apply("core.team-staff", "team-staff.changed", uuid(), func(e *application.RosterEvent) {
		e.StaffData = &application.StaffState{Team: domain.TeamID(parse(team)), Person: domain.PersonID(parse(person)),
			Role: role}
	})
}

func (s *seed) link(guardian, player string) {
	s.apply("core.guardian-link", "guardian-link.changed", uuid(), func(e *application.RosterEvent) {
		e.LinkData = &application.GuardianLinkState{Guardian: domain.PersonID(parse(guardian)),
			Player: domain.PlayerID(parse(player))}
	})
}

// person is the person id of a member's login, with display name set.
func (s *seed) person(subject, name string) string {
	s.t.Helper()
	s.a.bound(s.t, s.id(), "update finance.person_ref set display_name = $1 where subject = $2", name, subject)
	return s.a.text(s.t, s.id(), "select id::text from finance.person_ref where subject = $1", subject)
}

// text reads one text value as finance_app bound to tenant.
func (a *api) text(t *testing.T, tenant, sql string, args ...any) string {
	t.Helper()
	ctx := context.Background()
	tx, err := a.db.App.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = tx.Rollback(ctx) }()
	if _, err := tx.Exec(ctx, "select set_config('app.tenant_id', $1, true)", tenant); err != nil {
		t.Fatal(err)
	}
	var value string
	if err := tx.QueryRow(ctx, sql, args...).Scan(&value); err != nil {
		t.Fatal(err)
	}
	return value
}

// plan creates a MONTHLY plan of team from two months ago (EUR chosen first) and returns its id.
func (s *seed) plan(team string, amount int) string {
	s.t.Helper()
	a := s.a
	if got := a.do(s.t, call{method: "GET", path: "/api/finance/settings", tenant: s.id(), subject: admin}); got.json(s.t)["currency"] == nil {
		a.withEuro(s.t, s.id())
	}
	return a.createPlan(s.t, s.id(), map[string]any{"name": "Monthly " + team[:4], "seasonId": s.season, "teamId": team,
		"amountMinor": amount, "cadence": "MONTHLY", "firstPeriod": month(-2), "autoGenerate": false})["id"].(string)
}

func (s *seed) generate(plan, period string, preview bool) map[string]any {
	s.t.Helper()
	return expect(s.t, s.a.do(s.t, call{method: "POST", path: "/api/finance/fee-plans/" + plan + "/dues:generate",
		tenant: s.id(), subject: admin, body: map[string]any{"period": period, "preview": preview}}), 200).json(s.t)
}

// dues lists the academy's dues of a query as ADMIN.
func (s *seed) dues(query string) []any {
	s.t.Helper()
	return expect(s.t, s.a.do(s.t, call{method: "GET", path: "/api/finance/dues?size=200&" + query, tenant: s.id(),
		subject: admin}), 200).json(s.t)["items"].([]any)
}

func (s *seed) post(path string, body any) answer {
	s.t.Helper()
	return s.a.do(s.t, call{method: "POST", path: path, tenant: s.id(), subject: admin, body: body})
}
