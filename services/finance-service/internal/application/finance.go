package application

import (
	"context"

	"hoopsacademy.local/finance/internal/domain"
)

// DeniedByRole is the code of a refusal for a missing tenant role (security event kind `role`, 403).
const DeniedByRole = "ROLE"

// Ports are the use cases' dependencies.
type Ports struct {
	Clock        Clock
	IDs          IDs
	Transactions Transactions
	Settings     SettingsStore
	FeePlans     FeePlanStore
	Dues         DueQueries
	Audit        AuditLog
	Members      MembershipSource
	Roster       RosterReads
	DueStore     DueStore
	Payments     PaymentStore
}

// Finance holds the use cases of settings, fee plans, dues and payments.
type Finance struct{ p Ports }

// NewFinance wires the use cases.
func NewFinance(ports Ports) *Finance { return &Finance{p: ports} }

// SettingsView is the settings as answered: no currency before ADMIN chose one; Locked once a due exists.
type SettingsView struct {
	Currency *domain.Currency
	Locked   bool
}

// FeePlanView is a plan with the academy's currency and whether it has dues.
type FeePlanView struct {
	Plan     domain.FeePlan
	Currency domain.Currency
	HasDues  bool
}

// FeePlanPage is one page of plans and the total.
type FeePlanPage struct {
	Items []FeePlanView
	Total int64
}

// FeePlanCommand creates a plan.
type FeePlanCommand struct{ Input domain.FeePlanInput }

// ResolveMembership is the tenant filter's question: is subject an active member of tenant, and with which roles?
func (f *Finance) ResolveMembership(ctx context.Context, tenant domain.TenantID, subject string) (domain.Membership, bool, error) {
	var member domain.Membership
	var found bool
	err := f.p.Transactions.InTenant(ctx, tenant, func(ctx context.Context) error {
		var err error
		member, found, err = f.p.Members.Membership(ctx, tenant, subject)
		return err
	})
	return member, found, err
}

// asAdmin authorises the caller as ADMIN and runs work in a transaction bound to the caller's tenant.
func (f *Finance) asAdmin(ctx context.Context, caller domain.Membership, work func(ctx context.Context) error) error {
	if !domain.CanManageFinance(caller) {
		return domain.Forbidden(DeniedByRole, "finance is managed by ADMIN")
	}
	return f.p.Transactions.InTenant(ctx, caller.Tenant(), work)
}

// Settings reads the academy's finance settings.
func (f *Finance) Settings(ctx context.Context, caller domain.Membership) (SettingsView, error) {
	var view SettingsView
	err := f.asAdmin(ctx, caller, func(ctx context.Context) error {
		var err error
		view, err = f.settingsView(ctx)
		return err
	})
	return view, err
}

func (f *Finance) settingsView(ctx context.Context) (SettingsView, error) {
	settings, found, err := f.p.Settings.Get(ctx)
	if err != nil {
		return SettingsView{}, err
	}
	locked, err := f.p.Dues.AnyDue(ctx)
	if err != nil {
		return SettingsView{}, err
	}
	view := SettingsView{Locked: locked}
	if found {
		view.Currency = &settings.Currency
	}
	return view, nil
}

// UpdateSettings chooses or changes the currency (decision 94).
func (f *Finance) UpdateSettings(ctx context.Context, caller domain.Membership, code string) (SettingsView, error) {
	var view SettingsView
	err := f.asAdmin(ctx, caller, func(ctx context.Context) error {
		currency, err := domain.ParseCurrency(code)
		if err != nil {
			return err
		}
		current, found, err := f.p.Settings.Get(ctx)
		if err != nil {
			return err
		}
		locked, err := f.p.Dues.AnyDue(ctx)
		if err != nil {
			return err
		}
		var before *domain.Settings
		if found {
			before = &current
		}
		changed, err := domain.ChangeCurrency(before, currency, locked)
		if err != nil {
			return err
		}
		if !found || changed.Currency != current.Currency {
			if err := f.p.Settings.Save(ctx, changed); err != nil {
				return err
			}
			if err := f.audit(ctx, caller, "finance.settings_changed", "finance_settings", caller.Tenant().String(),
				map[string]any{"fields": []string{"currency"}}); err != nil {
				return err
			}
		}
		view = SettingsView{Currency: &changed.Currency, Locked: locked}
		return nil
	})
	return view, err
}

func (f *Finance) audit(ctx context.Context, caller domain.Membership, action, targetType, targetID string, metadata map[string]any) error {
	return f.p.Audit.Record(ctx, AuditEvent{
		Actor: caller, Action: action, TargetType: targetType, TargetID: targetID, Metadata: metadata,
	})
}

func (f *Finance) currency(ctx context.Context) (domain.Currency, error) {
	settings, found, err := f.p.Settings.Get(ctx)
	if err != nil {
		return domain.Currency{}, err
	}
	if !found {
		return domain.Currency{}, domain.Conflict("CURRENCY_NOT_SET", "choose the academy's currency first")
	}
	return settings.Currency, nil
}
