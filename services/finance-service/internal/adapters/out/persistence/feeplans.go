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

// FeePlanStore implements application.FeePlanStore on finance.fee_plan. Every statement names the bound tenant
// (`tenant_id = app.current_tenant()`) on top of the RLS policy, as Hibernate's @TenantId filter does in Java: two
// layers.
type FeePlanStore struct{}

const (
	feePlanColumns = `id, name, season_id, team_id, age_category_id, amount_minor, cadence, first_period, last_period,
		auto_generate, archived, created_at, updated_at, version`
	selectFeePlan = "select " + feePlanColumns + " from finance.fee_plan where tenant_id = app.current_tenant() and id = $1"
	insertFeePlan = `insert into finance.fee_plan (tenant_id, ` + feePlanColumns + `)
		values (app.current_tenant(), $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, 0)`
	updateFeePlan = `update finance.fee_plan set name = $2, amount_minor = $3, first_period = $4, last_period = $5,
		auto_generate = $6, archived = $7, updated_at = $8, version = version + 1
		where tenant_id = app.current_tenant() and id = $1 and version = $9`
	deleteFeePlan = "delete from finance.fee_plan where tenant_id = app.current_tenant() and id = $1"
	// The optional filters are bound parameters (null = no filter), so the statement stays constant.
	feePlanFilter = ` from finance.fee_plan where tenant_id = app.current_tenant()
		and ($1::uuid is null or season_id = $1) and ($2::uuid is null or team_id = $2)
		and ($3::uuid is null or age_category_id = $3) and ($4 or not archived)`
	listFeePlans    = "select " + feePlanColumns + feePlanFilter + " order by name, id limit $5 offset $6"
	countFeePlans   = "select count(*)" + feePlanFilter
	generatingPlans = "select " + feePlanColumns + ` from finance.fee_plan
		where tenant_id = app.current_tenant() and auto_generate and not archived order by name, id`
)

// Generating reads the bound tenant's automatic, active plans (the daily job's).
func (FeePlanStore) Generating(ctx context.Context) ([]domain.FeePlan, error) {
	q, err := txOf(ctx)
	if err != nil {
		return nil, err
	}
	rows, err := q.Query(ctx, generatingPlans)
	if err != nil {
		return nil, fmt.Errorf("generating fee plans: %w", err)
	}
	plans, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (domain.FeePlan, error) { return scanFeePlan(row) })
	if err != nil {
		return nil, fmt.Errorf("generating fee plans: %w", err)
	}
	return plans, nil
}

// Get reads a plan of the bound tenant.
func (FeePlanStore) Get(ctx context.Context, id domain.FeePlanID) (domain.FeePlan, bool, error) {
	q, err := txOf(ctx)
	if err != nil {
		return domain.FeePlan{}, false, err
	}
	plan, err := scanFeePlan(q.QueryRow(ctx, selectFeePlan, id.String()))
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.FeePlan{}, false, nil
	}
	if err != nil {
		return domain.FeePlan{}, false, err
	}
	return plan, true, nil
}

// Insert stores a new plan with version 0.
func (FeePlanStore) Insert(ctx context.Context, p domain.FeePlan) error {
	q, err := txOf(ctx)
	if err != nil {
		return err
	}
	if _, err := q.Exec(ctx, insertFeePlan, p.ID.String(), p.Name, p.Season.String(), optionalTeam(p.Target.Team),
		optionalCategory(p.Target.AgeCategory), p.Amount.Minor(), string(p.Cadence), periodKey(p.First),
		periodKey(p.Last), p.AutoGenerate, p.Archived, p.CreatedAt, p.UpdatedAt); err != nil {
		return fmt.Errorf("insert fee plan: %w", err)
	}
	return nil
}

// Update writes the editable fields if the version still matches.
func (FeePlanStore) Update(ctx context.Context, p domain.FeePlan) (domain.FeePlan, error) {
	q, err := txOf(ctx)
	if err != nil {
		return p, err
	}
	tag, err := q.Exec(ctx, updateFeePlan, p.ID.String(), p.Name, p.Amount.Minor(), periodKey(p.First),
		periodKey(p.Last), p.AutoGenerate, p.Archived, p.UpdatedAt, p.Version)
	if err != nil {
		return p, fmt.Errorf("update fee plan: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return p, application.ErrConcurrentModification
	}
	p.Version++
	return p, nil
}

// Delete removes a plan.
func (FeePlanStore) Delete(ctx context.Context, id domain.FeePlanID) error {
	q, err := txOf(ctx)
	if err != nil {
		return err
	}
	if _, err := q.Exec(ctx, deleteFeePlan, id.String()); err != nil {
		return fmt.Errorf("delete fee plan: %w", err)
	}
	return nil
}

// List reads a page of plans ordered by name, then id, and the total.
func (FeePlanStore) List(ctx context.Context, f application.FeePlanFilter, page application.Page) ([]domain.FeePlan, int64, error) {
	q, err := txOf(ctx)
	if err != nil {
		return nil, 0, err
	}
	args := []any{optionalSeason(f.Season), optionalTeam(f.Team), optionalCategory(f.AgeCategory), f.IncludeArchived}
	var total int64
	if err := q.QueryRow(ctx, countFeePlans, args...).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("count fee plans: %w", err)
	}
	rows, err := q.Query(ctx, listFeePlans, append(args, page.Size, page.Index*page.Size)...)
	if err != nil {
		return nil, 0, fmt.Errorf("list fee plans: %w", err)
	}
	plans, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (domain.FeePlan, error) { return scanFeePlan(row) })
	if err != nil {
		return nil, 0, fmt.Errorf("list fee plans: %w", err)
	}
	return plans, total, nil
}

func scanFeePlan(row pgx.Row) (domain.FeePlan, error) {
	var (
		id, name, season, cadence string
		team, category            *string
		first, last               *string
		amount                    int64
		p                         domain.FeePlan
		createdAt, updatedAt      time.Time
	)
	if err := row.Scan(&id, &name, &season, &team, &category, &amount, &cadence, &first, &last, &p.AutoGenerate,
		&p.Archived, &createdAt, &updatedAt, &p.Version); err != nil {
		return domain.FeePlan{}, fmt.Errorf("read fee plan: %w", err)
	}
	var err error
	r := reader{}
	p.ID = domain.FeePlanID(r.uuid(id))
	p.Season = domain.SeasonID(r.uuid(season))
	if team != nil {
		t := domain.TeamID(r.uuid(*team))
		p.Target.Team = &t
	}
	if category != nil {
		c := domain.AgeCategoryID(r.uuid(*category))
		p.Target.AgeCategory = &c
	}
	p.Name, p.CreatedAt, p.UpdatedAt = name, timestamp(createdAt), timestamp(updatedAt)
	if p.Amount, err = domain.NewAmount(amount); err != nil {
		r.fail(err)
	}
	if p.Cadence, err = domain.ParseCadence(cadence); err != nil {
		r.fail(err)
	}
	p.First, p.Last = r.period(p.Cadence, first), r.period(p.Cadence, last)
	if r.err != nil {
		return domain.FeePlan{}, fmt.Errorf("stored fee plan %s: %w", id, r.err)
	}
	return p, nil
}

// reader converts stored text, keeping the first failure.
type reader struct{ err error }

func (r *reader) fail(err error) {
	if r.err == nil {
		r.err = err
	}
}

func (r *reader) uuid(text string) domain.UUID {
	id, err := domain.ParseUUID(text)
	r.fail(err)
	return id
}

func (r *reader) period(cadence domain.Cadence, key *string) *domain.Period {
	if key == nil {
		return nil
	}
	p, err := domain.ParsePeriod(cadence, *key)
	r.fail(err)
	return &p
}

func periodKey(p *domain.Period) *string {
	if p == nil {
		return nil
	}
	key := p.Key()
	return &key
}

func optionalTeam(id *domain.TeamID) *string {
	if id == nil {
		return nil
	}
	s := id.String()
	return &s
}

func optionalCategory(id *domain.AgeCategoryID) *string {
	if id == nil {
		return nil
	}
	s := id.String()
	return &s
}

func optionalSeason(id *domain.SeasonID) *string {
	if id == nil {
		return nil
	}
	s := id.String()
	return &s
}
