package persistence

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"

	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/domain"
)

// The roster aggregates of WP119 (V10): each statement takes the aggregate id ($1), the removal flag ($2), the
// event's occurred_at ($3) and id ($4), then the state columns, all null for a removal (ADR-0037 §2-3).
const (
	upsertPlayer = `insert into finance.player_ref (tenant_id, id, removed, occurred_at, event_id, person_id,
			display_name, status)
		values (app.current_tenant(), $1, $2, $3, $4, $5, $6, $7)
		on conflict (tenant_id, id) do update set removed = excluded.removed, occurred_at = excluded.occurred_at,
			event_id = excluded.event_id, person_id = excluded.person_id, display_name = excluded.display_name,
			status = excluded.status
		where finance.player_ref.occurred_at <= excluded.occurred_at`
	upsertTeam = `insert into finance.team_ref (tenant_id, id, removed, occurred_at, event_id, season_id, season_start,
			season_end, age_category_id, name)
		values (app.current_tenant(), $1, $2, $3, $4, $5, $6, $7, $8, $9)
		on conflict (tenant_id, id) do update set removed = excluded.removed, occurred_at = excluded.occurred_at,
			event_id = excluded.event_id, season_id = excluded.season_id, season_start = excluded.season_start,
			season_end = excluded.season_end, age_category_id = excluded.age_category_id, name = excluded.name
		where finance.team_ref.occurred_at <= excluded.occurred_at`
	upsertAssignment = `insert into finance.team_player_ref (tenant_id, id, removed, occurred_at, event_id, team_id,
			player_id, joined_on, left_on, invalid_reason)
		values (app.current_tenant(), $1, $2, $3, $4, $5, $6, $7, $8, $9)
		on conflict (tenant_id, id) do update set removed = excluded.removed, occurred_at = excluded.occurred_at,
			event_id = excluded.event_id, team_id = excluded.team_id, player_id = excluded.player_id,
			joined_on = excluded.joined_on, left_on = excluded.left_on, invalid_reason = excluded.invalid_reason
		where finance.team_player_ref.occurred_at <= excluded.occurred_at`
	upsertStaff = `insert into finance.team_staff_ref (tenant_id, id, removed, occurred_at, event_id, team_id, person_id,
			role)
		values (app.current_tenant(), $1, $2, $3, $4, $5, $6, $7)
		on conflict (tenant_id, id) do update set removed = excluded.removed, occurred_at = excluded.occurred_at,
			event_id = excluded.event_id, team_id = excluded.team_id, person_id = excluded.person_id,
			role = excluded.role
		where finance.team_staff_ref.occurred_at <= excluded.occurred_at`
	upsertGuardianLink = `insert into finance.guardian_link_ref (tenant_id, id, removed, occurred_at, event_id,
			guardian_person_id, player_id)
		values (app.current_tenant(), $1, $2, $3, $4, $5, $6)
		on conflict (tenant_id, id) do update set removed = excluded.removed, occurred_at = excluded.occurred_at,
			event_id = excluded.event_id, guardian_person_id = excluded.guardian_person_id,
			player_id = excluded.player_id
		where finance.guardian_link_ref.occurred_at <= excluded.occurred_at`
)

// upsert runs one of the statements above for e; state holds the state columns (nil values for a removal).
func upsert(ctx context.Context, what, sql string, e application.RosterEvent, removed bool, state ...any) error {
	q, err := txOf(ctx)
	if err != nil {
		return err
	}
	args := append([]any{e.Aggregate.String(), removed, e.OccurredAt, e.ID.String()}, state...)
	if _, err := q.Exec(ctx, sql, args...); err != nil {
		return fmt.Errorf("upsert %s: %w", what, err)
	}
	return nil
}

// UpsertPlayer writes a player: person, display name and status only (P-10).
func (ReplicaStore) UpsertPlayer(ctx context.Context, e application.RosterEvent, s *application.PlayerState) error {
	if s == nil {
		return upsert(ctx, "player", upsertPlayer, e, true, nil, nil, nil)
	}
	return upsert(ctx, "player", upsertPlayer, e, false, s.Person.String(), s.DisplayName, s.Status)
}

// UpsertTeam writes a team: its season's dates, its age category and its name.
func (ReplicaStore) UpsertTeam(ctx context.Context, e application.RosterEvent, s *application.TeamState) error {
	if s == nil {
		return upsert(ctx, "team", upsertTeam, e, true, nil, nil, nil, nil, nil)
	}
	return upsert(ctx, "team", upsertTeam, e, false, s.Season.String(), s.SeasonStart, s.SeasonEnd,
		s.AgeCategory.String(), s.Name)
}

// UpsertAssignment writes a player's assignment to a team.
func (ReplicaStore) UpsertAssignment(ctx context.Context, e application.RosterEvent, s *application.AssignmentState) error {
	if s == nil {
		return upsert(ctx, "assignment", upsertAssignment, e, true, nil, nil, nil, nil, nil)
	}
	return upsert(ctx, "assignment", upsertAssignment, e, false, s.Team.String(), s.Player.String(), s.JoinedOn,
		s.LeftOn, s.Invalid)
}

// UpsertStaff writes a staff entry.
func (ReplicaStore) UpsertStaff(ctx context.Context, e application.RosterEvent, s *application.StaffState) error {
	if s == nil {
		return upsert(ctx, "staff", upsertStaff, e, true, nil, nil, nil)
	}
	return upsert(ctx, "staff", upsertStaff, e, false, s.Team.String(), s.Person.String(), s.Role)
}

// UpsertGuardianLink writes a guardian link.
func (ReplicaStore) UpsertGuardianLink(ctx context.Context, e application.RosterEvent, s *application.GuardianLinkState) error {
	if s == nil {
		return upsert(ctx, "guardian link", upsertGuardianLink, e, true, nil, nil)
	}
	return upsert(ctx, "guardian link", upsertGuardianLink, e, false, s.Guardian.String(), s.Player.String())
}

// RosterStore implements application.RosterReads on the replica; removed rows count as absent (ADR-0037).
type RosterStore struct{}

const (
	selectAcademy = `select status, timezone, removed, coalesce(slug, '') from finance.tenant_ref
		where tenant_id = app.current_tenant()`
	selectStaffTeams = `select distinct s.team_id from finance.team_staff_ref s
		join finance.team_ref t on t.tenant_id = s.tenant_id and t.id = s.team_id
		where s.tenant_id = app.current_tenant() and s.person_id = $1 and s.role = 'COACH' and not s.removed
		  and not t.removed and t.season_end >= $2
		order by s.team_id`
	selectLinkedPlayers = `select distinct l.player_id from finance.guardian_link_ref l
		join finance.player_ref p on p.tenant_id = l.tenant_id and p.id = l.player_id
		where l.tenant_id = app.current_tenant() and l.guardian_person_id = $1 and not l.removed and not p.removed
		order by l.player_id`
	selectOwnPlayer = `select id from finance.player_ref
		where tenant_id = app.current_tenant() and person_id = $1 and not removed
		order by occurred_at desc limit 1`
	selectSeasonDates = `select season_start, season_end from finance.team_ref
		where tenant_id = app.current_tenant() and season_id = $1 and not removed
		order by occurred_at desc limit 1`
	// An assignment counts when it is valid and overlaps the window ($4..$5); left_on is the last day on the team.
	selectCandidates = `select tp.player_id, tp.team_id, coalesce(p.display_name, '') from finance.team_player_ref tp
		join finance.team_ref t on t.tenant_id = tp.tenant_id and t.id = tp.team_id
		join finance.player_ref p on p.tenant_id = tp.tenant_id and p.id = tp.player_id
		where tp.tenant_id = app.current_tenant() and not tp.removed and not t.removed and not p.removed
		  and tp.invalid_reason is null and t.season_id = $1
		  and ($2::uuid is null or t.id = $2) and ($3::uuid is null or t.age_category_id = $3)
		  and tp.joined_on <= $5 and (tp.left_on is null or tp.left_on >= $4)
		order by tp.joined_on, tp.team_id, tp.player_id`
	selectTeamExists = `select exists (select 1 from finance.team_ref
		where tenant_id = app.current_tenant() and id = $1 and not removed)`
	selectTeamRoster = `select distinct p.id, coalesce(p.display_name, '') as name from finance.team_player_ref tp
		join finance.player_ref p on p.tenant_id = tp.tenant_id and p.id = tp.player_id
		where tp.tenant_id = app.current_tenant() and tp.team_id = $1 and not tp.removed and tp.left_on is null
		  and tp.invalid_reason is null and not p.removed
		order by name, p.id`
)

// Academy reads the bound academy's status, time zone and slug.
func (RosterStore) Academy(ctx context.Context) (application.Academy, bool, error) {
	q, err := txOf(ctx)
	if err != nil {
		return application.Academy{}, false, err
	}
	var status, zone *string
	var removed bool
	var slug string
	if err := q.QueryRow(ctx, selectAcademy).Scan(&status, &zone, &removed, &slug); errors.Is(err, pgx.ErrNoRows) {
		return application.Academy{}, false, nil
	} else if err != nil {
		return application.Academy{}, false, fmt.Errorf("academy: %w", err)
	}
	location := time.UTC
	if zone != nil {
		if loaded, err := time.LoadLocation(*zone); err == nil {
			location = loaded
		}
	}
	active := !removed && status != nil && *status == "ACTIVE"
	return application.Academy{Active: active, Zone: location, Slug: slug}, true, nil
}

// Relations reads person's coached teams of seasons not ended on today, linked players and own player.
func (RosterStore) Relations(ctx context.Context, person domain.PersonID, today time.Time) (domain.Relations, error) {
	q, err := txOf(ctx)
	if err != nil {
		return domain.Relations{}, err
	}
	teams, err := ids(ctx, q, "staff teams", selectStaffTeams, person.String(), today)
	if err != nil {
		return domain.Relations{}, err
	}
	players, err := ids(ctx, q, "linked players", selectLinkedPlayers, person.String())
	if err != nil {
		return domain.Relations{}, err
	}
	own, err := ids(ctx, q, "own player", selectOwnPlayer, person.String())
	if err != nil {
		return domain.Relations{}, err
	}
	var relations domain.Relations
	for _, id := range teams {
		relations.StaffTeams = append(relations.StaffTeams, domain.TeamID(id))
	}
	for _, id := range players {
		relations.LinkedPlayers = append(relations.LinkedPlayers, domain.PlayerID(id))
	}
	if len(own) == 1 {
		player := domain.PlayerID(own[0])
		relations.OwnPlayer = &player
	}
	return relations, nil
}

// scan reads one row, wrapping the driver's error.
func scan(row pgx.Row, dest ...any) error {
	if err := row.Scan(dest...); err != nil {
		return fmt.Errorf("scan: %w", err)
	}
	return nil
}

// ids runs a query of one uuid column.
func ids(ctx context.Context, q querier, what, sql string, args ...any) ([]domain.UUID, error) {
	rows, err := q.Query(ctx, sql, args...)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", what, err)
	}
	texts, err := pgx.CollectRows(rows, pgx.RowTo[string])
	if err != nil {
		return nil, fmt.Errorf("%s: %w", what, err)
	}
	out := make([]domain.UUID, len(texts))
	r := reader{}
	for i, text := range texts {
		out[i] = r.uuid(text)
	}
	if r.err != nil {
		return nil, fmt.Errorf("%s: %w", what, r.err)
	}
	return out, nil
}

// SeasonDates reads a season's dates from its teams.
func (RosterStore) SeasonDates(ctx context.Context, season domain.SeasonID) (domain.SeasonDates, bool, error) {
	q, err := txOf(ctx)
	if err != nil {
		return domain.SeasonDates{}, false, err
	}
	var start, end *time.Time
	if err := q.QueryRow(ctx, selectSeasonDates, season.String()).Scan(&start, &end); errors.Is(err, pgx.ErrNoRows) {
		return domain.SeasonDates{}, false, nil
	} else if err != nil {
		return domain.SeasonDates{}, false, fmt.Errorf("season dates: %w", err)
	}
	if start == nil || end == nil {
		return domain.SeasonDates{}, false, nil
	}
	return domain.SeasonDates{Start: start.UTC(), End: end.UTC()}, true, nil
}

// Candidates reads who was on the roster of target's teams of season during window.
func (RosterStore) Candidates(ctx context.Context, season domain.SeasonID, target domain.Target, window domain.DueWindow) ([]domain.Candidate, error) {
	q, err := txOf(ctx)
	if err != nil {
		return nil, err
	}
	rows, err := q.Query(ctx, selectCandidates, season.String(), optionalTeam(target.Team),
		optionalCategory(target.AgeCategory), window.Start, window.End)
	if err != nil {
		return nil, fmt.Errorf("candidates: %w", err)
	}
	r := reader{}
	candidates, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (domain.Candidate, error) {
		var player, team, name string
		err := scan(row, &player, &team, &name)
		return domain.Candidate{Player: domain.PlayerID(r.uuid(player)), Team: domain.TeamID(r.uuid(team)), Name: name}, err
	})
	if err == nil {
		err = r.err
	}
	if err != nil {
		return nil, fmt.Errorf("candidates: %w", err)
	}
	return candidates, nil
}

// TeamRoster reads a team's roster today.
func (RosterStore) TeamRoster(ctx context.Context, team domain.TeamID) ([]application.RosterPlayer, bool, error) {
	q, err := txOf(ctx)
	if err != nil {
		return nil, false, err
	}
	var exists bool
	if err := q.QueryRow(ctx, selectTeamExists, team.String()).Scan(&exists); err != nil {
		return nil, false, fmt.Errorf("team: %w", err)
	}
	if !exists {
		return nil, false, nil
	}
	rows, err := q.Query(ctx, selectTeamRoster, team.String())
	if err != nil {
		return nil, false, fmt.Errorf("team roster: %w", err)
	}
	r := reader{}
	players, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (application.RosterPlayer, error) {
		var player, name string
		err := scan(row, &player, &name)
		return application.RosterPlayer{Player: domain.PlayerID(r.uuid(player)), Name: name}, err
	})
	if err == nil {
		err = r.err
	}
	if err != nil {
		return nil, false, fmt.Errorf("team roster: %w", err)
	}
	return players, true, nil
}
