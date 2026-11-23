package application

import (
	"context"
	"time"

	"hoopsacademy.local/finance/internal/domain"
)

// The audit records' target types of dues and payments.
const (
	dueTarget     = "due"
	paymentTarget = "payment"
)

// GeneratedDue is a due a generation created (or would create, in a preview) and its player's name.
type GeneratedDue struct {
	Due        domain.Due
	PlayerName string
}

// Generation is what a generation of one plan and period did.
type Generation struct {
	Plan     domain.FeePlanID
	Window   domain.DueWindow
	Preview  bool
	Created  []GeneratedDue // by player name
	Existing int            // dues of the period that were there already
}

// DueView is a due as ADMIN reads it, in the academy's currency.
type DueView struct {
	DueRecord
	Currency domain.Currency
}

// DueDetail is a due with every payment recorded for it, voided ones included.
type DueDetail struct {
	DueView
	Payments []PaymentRecord
}

// DuePage is one page of dues and the total.
type DuePage = Paged[DueRecord]

// PlayerStatus is whether a player of a team is up to date: no OPEN due of a started period (decision 96).
type PlayerStatus struct {
	Player   domain.PlayerID
	Name     string
	UpToDate bool
}

// Denials of a member who has the role but not the relation (security event kind fine_grained, 403).
const (
	DeniedNotTeamCoach    = "NOT_TEAM_COACH"
	DeniedNotLinkedPlayer = "NOT_LINKED_PLAYER"
)

// GenerateDues creates (or previews) the missing dues of one period of a plan: one per player on the roster of the
// plan's target on any day of the period within the season, at the plan's amount (decisions 97, 98).
func (f *Finance) GenerateDues(ctx context.Context, caller domain.Membership, id domain.FeePlanID, period string, preview bool) (Generation, error) {
	var generation Generation
	err := f.asAdmin(ctx, caller, func(ctx context.Context) error {
		plan, _, err := f.existing(ctx, id)
		if err != nil {
			return err
		}
		if plan.Archived {
			return domain.Conflict("FEE_PLAN_ARCHIVED", "an archived plan creates no dues")
		}
		if _, err := domain.ParsePeriod(plan.Cadence, period); err != nil {
			return err
		}
		season, found, err := f.p.Roster.SeasonDates(ctx, plan.Season)
		if err != nil {
			return err
		}
		if !found {
			return domain.RuleViolation("PERIOD_OUTSIDE_SEASON", "the season's dates are not known yet")
		}
		window, err := plan.Window(period, season)
		if err != nil {
			return err
		}
		generation, err = f.generate(ctx, caller, plan, window, preview)
		return err
	})
	return generation, err
}

// generate is the generation of one window, shared by ADMIN's request and the daily job (actor: the system).
func (f *Finance) generate(ctx context.Context, actor domain.Membership, plan domain.FeePlan, window domain.DueWindow, preview bool) (Generation, error) {
	candidates, err := f.p.Roster.Candidates(ctx, plan.Season, plan.Target, window)
	if err != nil {
		return Generation{}, err
	}
	existing, err := f.p.Dues.Existing(ctx, plan.ID, window.Period.Key())
	if err != nil {
		return Generation{}, err
	}
	now := f.p.Clock.Now()
	var fresh []GeneratedDue
	for _, candidate := range domain.OncePerPlayer(candidates) {
		if !existing[candidate.Player] {
			due := domain.NewDue(domain.DueID(f.p.IDs.New()), plan, window, candidate, now)
			fresh = append(fresh, GeneratedDue{Due: due, PlayerName: candidate.Name})
		}
	}
	if err := domain.CheckGenerationSize(len(fresh)); err != nil {
		return Generation{}, err
	}
	generation := Generation{Plan: plan.ID, Window: window, Preview: preview, Created: fresh, Existing: len(existing)}
	if preview || len(fresh) == 0 {
		return generation, nil
	}
	return f.store(ctx, actor, generation)
}

// store inserts a generation's dues; a due another run stored meanwhile counts as existing.
func (f *Finance) store(ctx context.Context, actor domain.Membership, generation Generation) (Generation, error) {
	dues := make([]domain.Due, len(generation.Created))
	for i, g := range generation.Created {
		dues[i] = g.Due
	}
	stored, err := f.p.Dues.Insert(ctx, dues)
	if err != nil {
		return Generation{}, err
	}
	kept := map[domain.DueID]bool{}
	for _, id := range stored {
		kept[id] = true
	}
	var created []GeneratedDue
	for _, g := range generation.Created {
		if kept[g.Due.ID] {
			created = append(created, g)
		}
	}
	generation.Existing += len(generation.Created) - len(created)
	generation.Created = created
	if len(created) == 0 {
		return generation, nil
	}
	return generation, f.audit(ctx, actor, "dues.generated", feePlanTarget, generation.Plan.String(), map[string]any{
		"plan": generation.Plan.String(), "period": generation.Window.Period.Key(), "count": len(created),
	})
}

// ListDues reads a page of dues.
func (f *Finance) ListDues(ctx context.Context, caller domain.Membership, filter DueFilter, page Page) (DuePage, error) {
	return adminPage(ctx, f, caller, func(ctx context.Context) ([]DueRecord, int64, error) {
		return f.p.Dues.List(ctx, filter, page)
	})
}

// Due reads a due with every payment recorded for it.
func (f *Finance) Due(ctx context.Context, caller domain.Membership, id domain.DueID) (DueDetail, error) {
	var detail DueDetail
	err := f.asAdmin(ctx, caller, func(ctx context.Context) error {
		view, err := f.dueView(ctx, id)
		if err != nil {
			return err
		}
		payments, err := f.p.Payments.OfDue(ctx, id)
		detail = DueDetail{DueView: view, Payments: payments}
		return err
	})
	return detail, err
}

func (f *Finance) dueView(ctx context.Context, id domain.DueID) (DueView, error) {
	record, found, err := f.p.Dues.Record(ctx, id)
	if err != nil {
		return DueView{}, err
	}
	if !found {
		return DueView{}, domain.NotFound("no such due")
	}
	currency, err := f.currency(ctx)
	return DueView{DueRecord: record, Currency: currency}, err
}

// ChangeDueAmount sets another amount on an open due, with a reason.
func (f *Finance) ChangeDueAmount(ctx context.Context, caller domain.Membership, id domain.DueID, amountMinor int64, reason string) (DueView, error) {
	return f.changeDue(ctx, caller, id, "due.amount_changed", func(due domain.Due, now time.Time) (domain.Due, error) {
		return due.ChangeAmount(amountMinor, reason, now)
	})
}

// WaiveDue waives an open due for good, with a reason.
func (f *Finance) WaiveDue(ctx context.Context, caller domain.Membership, id domain.DueID, reason string) (DueView, error) {
	return f.changeDue(ctx, caller, id, "due.waived", func(due domain.Due, now time.Time) (domain.Due, error) {
		return due.Waive(reason, now)
	})
}

type dueChange func(due domain.Due, now time.Time) (domain.Due, error)

func (f *Finance) changeDue(ctx context.Context, caller domain.Membership, id domain.DueID, action string, change dueChange) (DueView, error) {
	var view DueView
	err := f.asAdmin(ctx, caller, func(ctx context.Context) error {
		due, err := f.lockedDue(ctx, id)
		if err != nil {
			return err
		}
		changed, err := change(due, f.p.Clock.Now())
		if err != nil {
			return err
		}
		if err := f.p.Dues.Update(ctx, changed); err != nil {
			return err
		}
		if err := f.audit(ctx, caller, action, dueTarget, id.String(), dueMetadata(changed)); err != nil {
			return err
		}
		view, err = f.dueView(ctx, id)
		return err
	})
	return view, err
}

// dueMetadata names a due in the audit trail: ids and the period, never the reason (P-12).
func dueMetadata(due domain.Due) map[string]any {
	return map[string]any{"due": due.ID.String(), "plan": due.Plan.String(), "period": due.Period}
}

func (f *Finance) lockedDue(ctx context.Context, id domain.DueID) (domain.Due, error) {
	due, found, err := f.p.Dues.Lock(ctx, id)
	if err != nil {
		return domain.Due{}, err
	}
	if !found {
		return domain.Due{}, domain.NotFound("no such due")
	}
	return due, nil
}

// PayDue records the payment of an open due's whole amount (decision 95); the day may not lie after today in the
// academy's time zone.
func (f *Finance) PayDue(ctx context.Context, caller domain.Membership, id domain.DueID, input domain.PaymentInput) (DueView, error) {
	var view DueView
	err := f.asAdmin(ctx, caller, func(ctx context.Context) error {
		due, err := f.lockedDue(ctx, id)
		if err != nil {
			return err
		}
		today, err := f.today(ctx)
		if err != nil {
			return err
		}
		paid, payment, err := due.Pay(domain.PaymentID(f.p.IDs.New()), input, caller.Person(), today, f.p.Clock.Now())
		if err != nil {
			return err
		}
		if err := f.p.Payments.Insert(ctx, payment); err != nil {
			return err
		}
		if err := f.p.Dues.Update(ctx, paid); err != nil {
			return err
		}
		if err := f.audit(ctx, caller, "payment.recorded", paymentTarget, payment.ID.String(), map[string]any{
			"due": id.String(), "payment": payment.ID.String(), "method": string(payment.Method),
		}); err != nil {
			return err
		}
		view, err = f.dueView(ctx, id)
		return err
	})
	return view, err
}

// VoidPayment voids a wrong payment with a reason; it is kept and its due is OPEN again.
func (f *Finance) VoidPayment(ctx context.Context, caller domain.Membership, id domain.PaymentID, reason string) (DueView, error) {
	var view DueView
	err := f.asAdmin(ctx, caller, func(ctx context.Context) error {
		payment, found, err := f.p.Payments.Lock(ctx, id)
		if err != nil {
			return err
		}
		if !found {
			return domain.NotFound("no such payment")
		}
		voided, err := payment.Void(reason, caller.Person(), f.p.Clock.Now())
		if err != nil {
			return err
		}
		due, err := f.lockedDue(ctx, payment.Due)
		if err != nil {
			return err
		}
		reopened, err := due.Reopen(f.p.Clock.Now())
		if err != nil {
			return err
		}
		if err := f.p.Payments.Void(ctx, voided); err != nil {
			return err
		}
		if err := f.p.Dues.Update(ctx, reopened); err != nil {
			return err
		}
		if err := f.audit(ctx, caller, "payment.voided", paymentTarget, id.String(), map[string]any{
			"due": due.ID.String(), "payment": id.String(),
		}); err != nil {
			return err
		}
		view, err = f.dueView(ctx, due.ID)
		return err
	})
	return view, err
}

// today is the bound academy's date (UTC when its zone is unknown).
func (f *Finance) today(ctx context.Context) (time.Time, error) {
	academy, _, err := f.p.Roster.Academy(ctx)
	if err != nil {
		return time.Time{}, err
	}
	return domain.Today(f.p.Clock.Now(), academy.Zone), nil
}

// withRelations is caller with the roster relations it has on the academy's today (ADMIN needs none).
func (f *Finance) withRelations(ctx context.Context, caller domain.Membership) (domain.Membership, time.Time, error) {
	today, err := f.today(ctx)
	if err != nil || caller.Has(domain.Admin) {
		return caller, today, err
	}
	relations, err := f.p.Roster.Relations(ctx, caller.Person(), today)
	return caller.WithRelations(relations), today, err
}

// TeamDueStatus reads who of a team's roster today is up to date: ADMIN, or a COACH who is current staff of the team
// (decision 96). Status only: no amounts, plans or reasons.
func (f *Finance) TeamDueStatus(ctx context.Context, caller domain.Membership, team domain.TeamID) ([]PlayerStatus, error) {
	if !caller.Has(domain.Admin) && !caller.Has(domain.Coach) {
		return nil, domain.Forbidden(DeniedByRole, "a team's dues status is read by ADMIN and its coach")
	}
	var statuses []PlayerStatus
	err := f.p.Transactions.InTenant(ctx, caller.Tenant(), func(ctx context.Context) error {
		caller, today, err := f.withRelations(ctx, caller)
		if err != nil {
			return err
		}
		if !domain.CanReadTeamStatus(caller, team) {
			return domain.Forbidden(DeniedNotTeamCoach, "not a current coach of this team")
		}
		players, found, err := f.p.Roster.TeamRoster(ctx, team)
		if err != nil {
			return err
		}
		if !found {
			return domain.NotFound("no such team")
		}
		ids := make([]domain.PlayerID, len(players))
		for i, p := range players {
			ids[i] = p.Player
		}
		behind, err := f.p.Dues.Behind(ctx, ids, today)
		statuses = make([]PlayerStatus, len(players))
		for i, p := range players {
			statuses[i] = PlayerStatus{Player: p.Player, Name: p.Name, UpToDate: !behind[p.Player]}
		}
		return err
	})
	return statuses, err
}

// PlayerDues reads a player's dues as the family sees them: ADMIN, a PARENT linked to the player, the PLAYER
// themself (decision 96). The relation is checked before anything is read: no answer tells whether a player exists.
func (f *Finance) PlayerDues(ctx context.Context, caller domain.Membership, player domain.PlayerID, page Page) (DuePage, error) {
	if !caller.Has(domain.Admin) && !caller.Has(domain.Parent) && !caller.Has(domain.Player) {
		return DuePage{}, domain.Forbidden(DeniedByRole, "a player's dues are read by ADMIN and the family")
	}
	var result DuePage
	err := f.p.Transactions.InTenant(ctx, caller.Tenant(), func(ctx context.Context) error {
		caller, _, err := f.withRelations(ctx, caller)
		if err != nil {
			return err
		}
		if !domain.CanReadPlayerDues(caller, player) {
			return domain.Forbidden(DeniedNotLinkedPlayer, "not linked to this player")
		}
		items, total, err := f.p.Dues.OfPlayer(ctx, player, page)
		if err != nil {
			return err
		}
		result = DuePage{Items: items, Total: total}
		result.Currency, err = f.currencyOfPage(ctx, len(items))
		return err
	})
	return result, err
}
