package persistence

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/domain"
)

// DueStore implements application.DueStore on finance.due (with the plan's and the player's names and the valid
// payment for the reads). Every statement names the bound tenant on top of the RLS policy.
type DueStore struct{}

const (
	dueColumns = `d.id, d.fee_plan_id, d.player_id, d.team_id, d.period, d.period_start, d.period_end, d.amount_minor,
		d.plan_amount_minor, d.status, d.reason, d.created_at, d.updated_at, d.version`
	// A due as read: its plan's name, its player's name (none once removed), its team's name (none until known), its
	// valid payment and who recorded it.
	dueRecord = `select ` + dueColumns + `, f.name, coalesce(p.display_name, '') as player_name, coalesce(t.name, ''),
			pay.id, pay.amount_minor, pay.paid_on, pay.method, pay.note, pay.recorded_by, pay.recorded_at,
			coalesce(rb.display_name, '')
		from finance.due d
		join finance.fee_plan f on f.tenant_id = d.tenant_id and f.id = d.fee_plan_id
		left join finance.player_ref p on p.tenant_id = d.tenant_id and p.id = d.player_id and not p.removed
		left join finance.team_ref t on t.tenant_id = d.tenant_id and t.id = d.team_id and not t.removed
		left join finance.payment pay on pay.tenant_id = d.tenant_id and pay.due_id = d.id and pay.voided_at is null
		left join finance.person_ref rb on rb.tenant_id = d.tenant_id and rb.id = pay.recorded_by
		where d.tenant_id = app.current_tenant()`
	// The optional filters are bound parameters (null = no filter), so the statements stay constant.
	dueFilter = ` and ($1::uuid is null or d.fee_plan_id = $1) and ($2::uuid is null or d.team_id = $2)
		and ($3::uuid is null or d.player_id = $3) and ($4::uuid is null or f.season_id = $4)
		and ($5::text is null or d.period = $5) and ($6::text is null or d.status = $6)
		and ($7::date is null or d.period_start >= $7) and ($8::date is null or d.period_start <= $8)`
	listDues  = dueRecord + dueFilter + " order by d.period_start, player_name, d.id limit $9 offset $10"
	countDues = `select count(*) from finance.due d
		join finance.fee_plan f on f.tenant_id = d.tenant_id and f.id = d.fee_plan_id
		where d.tenant_id = app.current_tenant()` + dueFilter
	selectDueRecord = dueRecord + " and d.id = $1"
	playerDues      = dueRecord + " and d.player_id = $1 order by d.period_start desc, f.name, d.id limit $2 offset $3"
	countPlayerDues = "select count(*) from finance.due where tenant_id = app.current_tenant() and player_id = $1"
	lockDue         = "select " + dueColumns + " from finance.due d where d.tenant_id = app.current_tenant() and d.id = $1 for update"
	existingDues    = `select player_id from finance.due
		where tenant_id = app.current_tenant() and fee_plan_id = $1 and period = $2`
	insertDues = `insert into finance.due (tenant_id, id, fee_plan_id, player_id, team_id, period, period_start,
			period_end, amount_minor, plan_amount_minor, status, created_at, updated_at)
		select app.current_tenant(), u.id, u.plan, u.player, u.team, u.period, u.first_day, u.last_day, u.amount,
			u.plan_amount, 'OPEN', u.created, u.created
		from unnest($1::uuid[], $2::uuid[], $3::uuid[], $4::uuid[], $5::text[], $6::date[], $7::date[], $8::bigint[],
			$9::bigint[], $10::timestamptz[]) as u(id, plan, player, team, period, first_day, last_day, amount,
			plan_amount, created)
		on conflict (tenant_id, fee_plan_id, player_id, period) do nothing
		returning id`
	updateDue = `update finance.due set amount_minor = $2, status = $3, reason = $4, updated_at = $5,
			version = version + 1
		where tenant_id = app.current_tenant() and id = $1 and version = $6`
	behindPlayers = `select distinct player_id from finance.due
		where tenant_id = app.current_tenant() and player_id = any($1::uuid[]) and status = 'OPEN' and period_start <= $2`
	// The season's income: PAID by the valid payment's amount, OPEN and WAIVED by the due's amount.
	seasonIncome = `select
			coalesce(sum(pay.amount_minor) filter (where d.status = 'PAID'), 0)::bigint,
			coalesce(sum(d.amount_minor) filter (where d.status = 'OPEN'), 0)::bigint,
			coalesce(sum(d.amount_minor) filter (where d.status = 'WAIVED'), 0)::bigint
		from finance.due d
		join finance.fee_plan f on f.tenant_id = d.tenant_id and f.id = d.fee_plan_id
		left join finance.payment pay on pay.tenant_id = d.tenant_id and pay.due_id = d.id and pay.voided_at is null
		where d.tenant_id = app.current_tenant() and f.season_id = $1`
)

// Existing reads the players with a due of plan and period.
func (DueStore) Existing(ctx context.Context, plan domain.FeePlanID, period string) (map[domain.PlayerID]bool, error) {
	q, err := txOf(ctx)
	if err != nil {
		return nil, err
	}
	players, err := ids(ctx, q, "existing dues", existingDues, plan.String(), period)
	if err != nil {
		return nil, err
	}
	out := make(map[domain.PlayerID]bool, len(players))
	for _, id := range players {
		out[domain.PlayerID(id)] = true
	}
	return out, nil
}

// Insert stores dues in one statement, leaving out those whose (plan, player, period) exists.
func (DueStore) Insert(ctx context.Context, dues []domain.Due) ([]domain.DueID, error) {
	q, err := txOf(ctx)
	if err != nil {
		return nil, err
	}
	n := len(dues)
	idsOf, plans, players, teams := make([]string, n), make([]string, n), make([]string, n), make([]string, n)
	periods, starts, ends := make([]string, n), make([]time.Time, n), make([]time.Time, n)
	amounts, planAmounts, created := make([]int64, n), make([]int64, n), make([]time.Time, n)
	for i, d := range dues {
		idsOf[i], plans[i], players[i], teams[i] = d.ID.String(), d.Plan.String(), d.Player.String(), d.Team.String()
		periods[i], starts[i], ends[i] = d.Period, d.Start, d.End
		amounts[i], planAmounts[i], created[i] = d.Amount.Minor(), d.PlanAmount.Minor(), d.CreatedAt
	}
	stored, err := ids(ctx, q, "insert dues", insertDues, idsOf, plans, players, teams, periods, starts, ends, amounts,
		planAmounts, created)
	if err != nil {
		return nil, err
	}
	out := make([]domain.DueID, len(stored))
	for i, id := range stored {
		out[i] = domain.DueID(id)
	}
	return out, nil
}

// Lock reads a due for update.
func (DueStore) Lock(ctx context.Context, id domain.DueID) (domain.Due, bool, error) {
	var row dueRow
	return lockRow(ctx, "due", lockDue, id.String(), row.dests(), row.due)
}

// lockRow reads one row by id for update into dests and converts it; found is false without one.
func lockRow[T any](ctx context.Context, what, sql, id string, dests []any, convert func() (T, error)) (T, bool, error) {
	var zero T
	q, err := txOf(ctx)
	if err != nil {
		return zero, false, err
	}
	if err := q.QueryRow(ctx, sql, id).Scan(dests...); errors.Is(err, pgx.ErrNoRows) {
		return zero, false, nil
	} else if err != nil {
		return zero, false, fmt.Errorf("lock %s: %w", what, err)
	}
	value, err := convert()
	return value, err == nil, err
}

// Update writes a due's amount, status and reason if its version still matches.
func (DueStore) Update(ctx context.Context, d domain.Due) error {
	q, err := txOf(ctx)
	if err != nil {
		return err
	}
	tag, err := q.Exec(ctx, updateDue, d.ID.String(), d.Amount.Minor(), string(d.Status), d.Reason, d.UpdatedAt, d.Version)
	if err != nil {
		return fmt.Errorf("update due: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return application.ErrConcurrentModification
	}
	return nil
}

// Record reads a due with its names and valid payment.
func (DueStore) Record(ctx context.Context, id domain.DueID) (application.DueRecord, bool, error) {
	q, err := txOf(ctx)
	if err != nil {
		return application.DueRecord{}, false, err
	}
	records, err := dueRecords(ctx, q, selectDueRecord, id.String())
	if err != nil || len(records) == 0 {
		return application.DueRecord{}, false, err
	}
	return records[0], true, nil
}

// List reads a page of dues and the total.
func (DueStore) List(ctx context.Context, f application.DueFilter, page application.Page) ([]application.DueRecord, int64, error) {
	q, err := txOf(ctx)
	if err != nil {
		return nil, 0, err
	}
	var status *string
	if f.Status != nil {
		text := string(*f.Status)
		status = &text
	}
	args := []any{optional(f.Plan), optional(f.Team), optional(f.Player), optional(f.Season), f.Period, status, f.From,
		f.To}
	var total int64
	if err := q.QueryRow(ctx, countDues, args...).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("count dues: %w", err)
	}
	records, err := dueRecords(ctx, q, listDues, append(args, page.Size, page.Index*page.Size)...)
	return records, total, err
}

// OfPlayer reads a page of a player's dues, newest period first, and the total.
func (DueStore) OfPlayer(ctx context.Context, player domain.PlayerID, page application.Page) ([]application.DueRecord, int64, error) {
	q, err := txOf(ctx)
	if err != nil {
		return nil, 0, err
	}
	var total int64
	if err := q.QueryRow(ctx, countPlayerDues, player.String()).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("count player dues: %w", err)
	}
	records, err := dueRecords(ctx, q, playerDues, player.String(), page.Size, page.Index*page.Size)
	return records, total, err
}

// Behind reads which players have an OPEN due of a period started on or before today.
func (DueStore) Behind(ctx context.Context, players []domain.PlayerID, today time.Time) (map[domain.PlayerID]bool, error) {
	out := map[domain.PlayerID]bool{}
	if len(players) == 0 {
		return out, nil
	}
	q, err := txOf(ctx)
	if err != nil {
		return nil, err
	}
	texts := make([]string, len(players))
	for i, p := range players {
		texts[i] = p.String()
	}
	behind, err := ids(ctx, q, "players behind", behindPlayers, texts, today)
	if err != nil {
		return nil, err
	}
	for _, id := range behind {
		out[domain.PlayerID(id)] = true
	}
	return out, nil
}

// dueRow is a due's columns as scanned.
type dueRow struct {
	id, plan, player, team, period, status string
	start, end, createdAt, updatedAt       time.Time
	amount, planAmount                     int64
	reason                                 *string
	version                                int
}

func (r *dueRow) dests() []any {
	return []any{&r.id, &r.plan, &r.player, &r.team, &r.period, &r.start, &r.end, &r.amount, &r.planAmount, &r.status,
		&r.reason, &r.createdAt, &r.updatedAt, &r.version}
}

func (r *dueRow) due() (domain.Due, error) {
	read := reader{}
	d := domain.Due{
		ID: domain.DueID(read.uuid(r.id)), Plan: domain.FeePlanID(read.uuid(r.plan)),
		Player: domain.PlayerID(read.uuid(r.player)), Team: domain.TeamID(read.uuid(r.team)), Period: r.period,
		Start: r.start.UTC(), End: r.end.UTC(), Reason: r.reason, CreatedAt: timestamp(r.createdAt),
		UpdatedAt: timestamp(r.updatedAt), Version: r.version,
	}
	var err error
	if d.Amount, err = domain.NewAmount(r.amount); err != nil {
		read.fail(err)
	}
	if d.PlanAmount, err = domain.NewAmount(r.planAmount); err != nil {
		read.fail(err)
	}
	if d.Status, err = domain.ParseDueStatus(r.status); err != nil {
		read.fail(err)
	}
	if read.err != nil {
		return domain.Due{}, fmt.Errorf("stored due %s: %w", r.id, read.err)
	}
	return d, nil
}

// validPayment is the valid payment's columns of a due record (all null without one).
type validPayment struct {
	id, method, recordedBy *string
	amount                 *int64
	paidOn, recordedAt     *time.Time
	note                   *string
	recordedByName         string
}

func dueRecords(ctx context.Context, q querier, sql string, args ...any) ([]application.DueRecord, error) {
	rows, err := q.Query(ctx, sql, args...)
	if err != nil {
		return nil, fmt.Errorf("dues: %w", err)
	}
	records, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (application.DueRecord, error) {
		var d dueRow
		var p validPayment
		var record application.DueRecord
		dests := append(d.dests(), &record.PlanName, &record.PlayerName, &record.TeamName, &p.id, &p.amount, &p.paidOn,
			&p.method, &p.note, &p.recordedBy, &p.recordedAt, &p.recordedByName)
		if err := scan(row, dests...); err != nil {
			return record, err
		}
		due, err := d.due()
		if err != nil {
			return record, err
		}
		record.Due = due
		if p.id != nil {
			valid := paymentRow{id: *p.id, due: d.id, method: *p.method, recordedBy: *p.recordedBy,
				amount: *p.amount, paidOn: *p.paidOn, recordedAt: *p.recordedAt, note: p.note}
			payment, err := valid.payment()
			if err != nil {
				return record, err
			}
			record.Payment = &application.PaymentRecord{Payment: payment,
				RecordedBy: application.PersonRef{Person: payment.RecordedBy, Name: p.recordedByName}}
		}
		return record, nil
	})
	if err != nil {
		return nil, fmt.Errorf("dues: %w", err)
	}
	return records, nil
}

// PaymentStore implements application.PaymentStore on finance.payment.
type PaymentStore struct{}

const (
	paymentColumns = `pay.id, pay.due_id, pay.amount_minor, pay.paid_on, pay.method, pay.note, pay.recorded_by,
		pay.recorded_at, pay.voided_at, pay.void_reason, pay.voided_by`
	insertPayment = `insert into finance.payment (tenant_id, id, due_id, amount_minor, paid_on, method, note, recorded_by,
			recorded_at)
		values (app.current_tenant(), $1, $2, $3, $4, $5, $6, $7, $8)`
	lockPayment = "select " + paymentColumns + ` from finance.payment pay
		where pay.tenant_id = app.current_tenant() and pay.id = $1 for update`
	voidPayment = `update finance.payment set voided_at = $2, void_reason = $3, voided_by = $4
		where tenant_id = app.current_tenant() and id = $1 and voided_at is null`
	paymentsOfDue = "select " + paymentColumns + `, coalesce(rb.display_name, ''), coalesce(vb.display_name, '')
		from finance.payment pay
		left join finance.person_ref rb on rb.tenant_id = pay.tenant_id and rb.id = pay.recorded_by
		left join finance.person_ref vb on vb.tenant_id = pay.tenant_id and vb.id = pay.voided_by
		where pay.tenant_id = app.current_tenant() and pay.due_id = $1
		order by pay.recorded_at, pay.id`
)

// Insert stores a payment.
func (PaymentStore) Insert(ctx context.Context, p domain.Payment) error {
	q, err := txOf(ctx)
	if err != nil {
		return err
	}
	if _, err := q.Exec(ctx, insertPayment, p.ID.String(), p.Due.String(), p.Amount.Minor(), p.PaidOn, string(p.Method),
		p.Note, p.RecordedBy.String(), p.RecordedAt); err != nil {
		return fmt.Errorf("insert payment: %w", err)
	}
	return nil
}

// Lock reads a payment for update.
func (PaymentStore) Lock(ctx context.Context, id domain.PaymentID) (domain.Payment, bool, error) {
	var row paymentRow
	return lockRow(ctx, "payment", lockPayment, id.String(), row.dests(), row.payment)
}

// Void writes a payment's void unless it was voided meanwhile.
func (PaymentStore) Void(ctx context.Context, p domain.Payment) error {
	q, err := txOf(ctx)
	if err != nil {
		return err
	}
	var by *string
	if p.VoidedBy != nil {
		text := p.VoidedBy.String()
		by = &text
	}
	tag, err := q.Exec(ctx, voidPayment, p.ID.String(), p.VoidedAt, p.VoidReason, by)
	if err != nil {
		return fmt.Errorf("void payment: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return application.ErrConcurrentModification
	}
	return nil
}

// OfDue reads every payment of a due, oldest first, with who recorded and voided it.
func (PaymentStore) OfDue(ctx context.Context, due domain.DueID) ([]application.PaymentRecord, error) {
	q, err := txOf(ctx)
	if err != nil {
		return nil, err
	}
	rows, err := q.Query(ctx, paymentsOfDue, due.String())
	if err != nil {
		return nil, fmt.Errorf("payments: %w", err)
	}
	records, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (application.PaymentRecord, error) {
		var p paymentRow
		var recordedBy, voidedBy string
		if err := scan(row, append(p.dests(), &recordedBy, &voidedBy)...); err != nil {
			return application.PaymentRecord{}, err
		}
		payment, err := p.payment()
		record := application.PaymentRecord{Payment: payment,
			RecordedBy: application.PersonRef{Person: payment.RecordedBy, Name: recordedBy}}
		if payment.VoidedBy != nil {
			record.VoidedBy = &application.PersonRef{Person: *payment.VoidedBy, Name: voidedBy}
		}
		return record, err
	})
	if err != nil {
		return nil, fmt.Errorf("payments: %w", err)
	}
	return records, nil
}

// paymentRow is a payment's columns as scanned.
type paymentRow struct {
	id, due, method, recordedBy string
	amount                      int64
	paidOn, recordedAt          time.Time
	note, voidReason, voidedBy  *string
	voidedAt                    *time.Time
}

func (r *paymentRow) dests() []any {
	return []any{&r.id, &r.due, &r.amount, &r.paidOn, &r.method, &r.note, &r.recordedBy, &r.recordedAt, &r.voidedAt,
		&r.voidReason, &r.voidedBy}
}

func (r *paymentRow) payment() (domain.Payment, error) {
	read := reader{}
	p := domain.Payment{
		ID: domain.PaymentID(read.uuid(r.id)), Due: domain.DueID(read.uuid(r.due)), PaidOn: r.paidOn.UTC(),
		Note: r.note, RecordedBy: domain.PersonID(read.uuid(r.recordedBy)), RecordedAt: timestamp(r.recordedAt),
		VoidReason: r.voidReason,
	}
	if r.voidedAt != nil {
		at := timestamp(*r.voidedAt)
		p.VoidedAt = &at
	}
	if r.voidedBy != nil {
		by := domain.PersonID(read.uuid(*r.voidedBy))
		p.VoidedBy = &by
	}
	var err error
	if p.Amount, err = domain.NewAmount(r.amount); err != nil {
		read.fail(err)
	}
	if p.Method, err = domain.ParsePaymentMethod(r.method); err != nil {
		read.fail(err)
	}
	if read.err != nil {
		return domain.Payment{}, fmt.Errorf("stored payment %s: %w", r.id, read.err)
	}
	return p, nil
}

const (
	anyDue        = "select exists (select 1 from finance.due where tenant_id = app.current_tenant())"
	plansWithDues = `select distinct fee_plan_id from finance.due
		where tenant_id = app.current_tenant() and fee_plan_id = any($1::uuid[])`
)

// AnyDue reports whether the bound tenant has a due.
func (DueStore) AnyDue(ctx context.Context) (bool, error) {
	q, err := txOf(ctx)
	if err != nil {
		return false, err
	}
	var exists bool
	if err := q.QueryRow(ctx, anyDue).Scan(&exists); err != nil {
		return false, fmt.Errorf("any due: %w", err)
	}
	return exists, nil
}

// PlansWithDues reports which of ids have dues.
func (DueStore) PlansWithDues(ctx context.Context, ids []domain.FeePlanID) (map[domain.FeePlanID]bool, error) {
	out := map[domain.FeePlanID]bool{}
	if len(ids) == 0 {
		return out, nil
	}
	q, err := txOf(ctx)
	if err != nil {
		return nil, err
	}
	texts := make([]string, len(ids))
	for i, id := range ids {
		texts[i] = id.String()
	}
	rows, err := q.Query(ctx, plansWithDues, texts)
	if err != nil {
		return nil, fmt.Errorf("plans with dues: %w", err)
	}
	found, err := pgx.CollectRows(rows, pgx.RowTo[string])
	if err != nil {
		return nil, fmt.Errorf("plans with dues: %w", err)
	}
	for _, text := range found {
		id, err := domain.ParseUUID(text)
		if err != nil {
			return nil, fmt.Errorf("plan id %q: %w", text, err)
		}
		out[domain.FeePlanID(id)] = true
	}
	return out, nil
}

// TenantDirectory implements application.TenantDirectory on finance.replica_tenant: a global table of tenant ids
// (no tenant content, ADR-0037 amendment WP82) that finance_app may read without a bound tenant.
type TenantDirectory struct{ Pool *pgxpool.Pool }

const selectTenants = "select id::text from finance.replica_tenant order by id"

// Tenants lists the academies the replica holds rows of; a nil id is never returned.
func (d TenantDirectory) Tenants(ctx context.Context) ([]domain.TenantID, error) {
	rows, err := d.Pool.Query(ctx, selectTenants)
	if err != nil {
		return nil, fmt.Errorf("tenants: %w", err)
	}
	texts, err := pgx.CollectRows(rows, pgx.RowTo[string])
	if err != nil {
		return nil, fmt.Errorf("tenants: %w", err)
	}
	tenants := make([]domain.TenantID, 0, len(texts))
	for _, text := range texts {
		tenant, err := domain.ParseTenantID(text)
		if err != nil {
			return nil, fmt.Errorf("tenant %q: %w", text, err)
		}
		tenants = append(tenants, tenant)
	}
	return tenants, nil
}

// optional is an id's text, or nil (no filter).
func optional[T interface{ String() string }](id *T) *string {
	if id == nil {
		return nil
	}
	text := (*id).String()
	return &text
}

// Income sums the dues of a season's plans by status.
func (DueStore) Income(ctx context.Context, season domain.SeasonID) (domain.IncomeTotals, error) {
	q, err := txOf(ctx)
	if err != nil {
		return domain.IncomeTotals{}, err
	}
	var income domain.IncomeTotals
	if err := q.QueryRow(ctx, seasonIncome, season.String()).Scan(&income.PaidMinor, &income.OpenMinor,
		&income.WaivedMinor); err != nil {
		return domain.IncomeTotals{}, fmt.Errorf("season income: %w", err)
	}
	return income, nil
}
