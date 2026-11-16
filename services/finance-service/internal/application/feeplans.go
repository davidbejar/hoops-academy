package application

import (
	"context"
	"time"

	"hoopsacademy.local/finance/internal/domain"
)

const feePlanTarget = "fee_plan"

// CreateFeePlan validates and stores a new plan (the currency must be chosen first).
func (f *Finance) CreateFeePlan(ctx context.Context, caller domain.Membership, command FeePlanCommand) (FeePlanView, error) {
	var view FeePlanView
	err := f.asAdmin(ctx, caller, func(ctx context.Context) error {
		plan, err := domain.NewFeePlan(domain.FeePlanID(f.p.IDs.New()), command.Input, f.p.Clock.Now())
		if err != nil {
			return err
		}
		currency, err := f.currency(ctx)
		if err != nil {
			return err
		}
		if err := f.p.FeePlans.Insert(ctx, plan); err != nil {
			return err
		}
		view = FeePlanView{Plan: plan, Currency: currency}
		return f.audit(ctx, caller, "fee_plan.created", feePlanTarget, plan.ID.String(),
			map[string]any{"cadence": string(plan.Cadence), "season": plan.Season.String()})
	})
	return view, err
}

// FeePlan reads one plan.
func (f *Finance) FeePlan(ctx context.Context, caller domain.Membership, id domain.FeePlanID) (FeePlanView, error) {
	var view FeePlanView
	err := f.asAdmin(ctx, caller, func(ctx context.Context) error {
		plan, hasDues, err := f.existing(ctx, id)
		if err != nil {
			return err
		}
		view, err = f.view(ctx, plan, hasDues)
		return err
	})
	return view, err
}

// ListFeePlans reads a page of plans.
func (f *Finance) ListFeePlans(ctx context.Context, caller domain.Membership, filter FeePlanFilter, page Page) (FeePlanPage, error) {
	var result FeePlanPage
	err := f.asAdmin(ctx, caller, func(ctx context.Context) error {
		plans, total, err := f.p.FeePlans.List(ctx, filter, page)
		if err != nil {
			return err
		}
		ids := make([]domain.FeePlanID, len(plans))
		for i, p := range plans {
			ids[i] = p.ID
		}
		withDues, err := f.p.Dues.PlansWithDues(ctx, ids)
		if err != nil {
			return err
		}
		result = FeePlanPage{Total: total, Items: make([]FeePlanView, len(plans))}
		if len(plans) == 0 {
			return nil
		}
		currency, err := f.currency(ctx)
		if err != nil {
			return err
		}
		for i, p := range plans {
			result.Items[i] = FeePlanView{Plan: p, Currency: currency, HasDues: withDues[p.ID]}
		}
		return nil
	})
	return result, err
}

// UpdateFeePlan changes the editable fields; audited with the changed field names when something changed.
func (f *Finance) UpdateFeePlan(ctx context.Context, caller domain.Membership, id domain.FeePlanID, changes domain.FeePlanChanges) (FeePlanView, error) {
	var view FeePlanView
	err := f.asAdmin(ctx, caller, func(ctx context.Context) error {
		plan, hasDues, err := f.existing(ctx, id)
		if err != nil {
			return err
		}
		changed, fields, err := plan.Change(changes, hasDues, f.p.Clock.Now())
		if err != nil {
			return err
		}
		if len(fields) > 0 {
			if changed, err = f.p.FeePlans.Update(ctx, changed); err != nil {
				return err
			}
			if err := f.audit(ctx, caller, "fee_plan.updated", feePlanTarget, id.String(),
				map[string]any{"fields": fields}); err != nil {
				return err
			}
		}
		view, err = f.view(ctx, changed, hasDues)
		return err
	})
	return view, err
}

// ArchiveFeePlan stops a plan (idempotent).
func (f *Finance) ArchiveFeePlan(ctx context.Context, caller domain.Membership, id domain.FeePlanID) (FeePlanView, error) {
	return f.toggleArchive(ctx, caller, id, "fee_plan.archived", domain.FeePlan.Archive)
}

// UnarchiveFeePlan makes an archived plan active again (idempotent).
func (f *Finance) UnarchiveFeePlan(ctx context.Context, caller domain.Membership, id domain.FeePlanID) (FeePlanView, error) {
	return f.toggleArchive(ctx, caller, id, "fee_plan.unarchived", domain.FeePlan.Unarchive)
}

type archiveStep func(domain.FeePlan, time.Time) (domain.FeePlan, bool)

func (f *Finance) toggleArchive(ctx context.Context, caller domain.Membership, id domain.FeePlanID, action string, step archiveStep) (FeePlanView, error) {
	var view FeePlanView
	err := f.asAdmin(ctx, caller, func(ctx context.Context) error {
		plan, hasDues, err := f.existing(ctx, id)
		if err != nil {
			return err
		}
		next, changed := step(plan, f.p.Clock.Now())
		if changed {
			if next, err = f.p.FeePlans.Update(ctx, next); err != nil {
				return err
			}
			if err := f.audit(ctx, caller, action, feePlanTarget, id.String(), map[string]any{}); err != nil {
				return err
			}
		}
		view, err = f.view(ctx, next, hasDues)
		return err
	})
	return view, err
}

// DeleteFeePlan removes a plan without dues.
func (f *Finance) DeleteFeePlan(ctx context.Context, caller domain.Membership, id domain.FeePlanID) error {
	return f.asAdmin(ctx, caller, func(ctx context.Context) error {
		plan, hasDues, err := f.existing(ctx, id)
		if err != nil {
			return err
		}
		if err := plan.CheckDeletable(hasDues); err != nil {
			return err
		}
		if err := f.p.FeePlans.Delete(ctx, id); err != nil {
			return err
		}
		return f.audit(ctx, caller, "fee_plan.deleted", feePlanTarget, id.String(), map[string]any{})
	})
}

// existing reads a plan of the bound tenant (404 otherwise, also for another academy's id) and whether it has dues.
func (f *Finance) existing(ctx context.Context, id domain.FeePlanID) (domain.FeePlan, bool, error) {
	plan, found, err := f.p.FeePlans.Get(ctx, id)
	if err != nil {
		return domain.FeePlan{}, false, err
	}
	if !found {
		return domain.FeePlan{}, false, domain.NotFound("no such fee plan")
	}
	withDues, err := f.p.Dues.PlansWithDues(ctx, []domain.FeePlanID{id})
	if err != nil {
		return domain.FeePlan{}, false, err
	}
	return plan, withDues[id], nil
}

func (f *Finance) view(ctx context.Context, plan domain.FeePlan, hasDues bool) (FeePlanView, error) {
	currency, err := f.currency(ctx)
	if err != nil {
		return FeePlanView{}, err
	}
	return FeePlanView{Plan: plan, Currency: currency, HasDues: hasDues}, nil
}
