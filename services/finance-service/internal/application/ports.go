// Package application holds finance-service's use cases and the ports its adapters implement. Every use case runs
// in one database transaction bound to the caller's tenant (ADR-0011) and authorises the caller first (rule 3:
// authorization in the application layer).
package application

import (
	"context"
	"errors"
	"time"

	"hoopsacademy.local/finance/internal/domain"
)

// Clock is the time source.
type Clock interface{ Now() time.Time }

// IDs makes new identifiers.
type IDs interface{ New() domain.UUID }

// Transactions runs work inside one database transaction bound to tenant: every store call made with the context
// work receives sees only that tenant's rows (row-level security on app.current_tenant()).
type Transactions interface {
	InTenant(ctx context.Context, tenant domain.TenantID, work func(ctx context.Context) error) error
}

// SettingsStore keeps the bound tenant's settings.
type SettingsStore interface {
	Get(ctx context.Context) (domain.Settings, bool, error)
	// Save inserts or updates; an update whose Version is stale fails with ErrConcurrentModification.
	Save(ctx context.Context, settings domain.Settings) error
}

// FeePlanFilter narrows the plan list; zero values do not filter.
type FeePlanFilter struct {
	Season          *domain.SeasonID
	Team            *domain.TeamID
	AgeCategory     *domain.AgeCategoryID
	IncludeArchived bool
}

// Page is a 0-based page of Size items.
type Page struct{ Index, Size int }

// FeePlanStore keeps the bound tenant's fee plans.
type FeePlanStore interface {
	Get(ctx context.Context, id domain.FeePlanID) (domain.FeePlan, bool, error)
	Insert(ctx context.Context, plan domain.FeePlan) error
	// Update writes plan if its Version is still the stored one (else ErrConcurrentModification) and returns it with
	// the next Version.
	Update(ctx context.Context, plan domain.FeePlan) (domain.FeePlan, error)
	Delete(ctx context.Context, id domain.FeePlanID) error
	// List orders by name, then id.
	List(ctx context.Context, filter FeePlanFilter, page Page) ([]domain.FeePlan, int64, error)
}

// DueQueries answers what the settings and plan rules need to know about dues.
type DueQueries interface {
	AnyDue(ctx context.Context) (bool, error)
	PlansWithDues(ctx context.Context, ids []domain.FeePlanID) (map[domain.FeePlanID]bool, error)
}

// AuditEvent is one record of the audit trail (ADR-0017): ids, enum values and field names only, never personal
// data, reasons or notes (P-12).
type AuditEvent struct {
	Actor      domain.Membership
	Action     string
	TargetType string
	TargetID   string
	Metadata   map[string]any
}

// AuditLog records audit events in the transaction of the change.
type AuditLog interface {
	Record(ctx context.Context, event AuditEvent) error
}

// MembershipSource reads the caller's membership in the bound tenant from the roster replica: an active person with
// that login in an ACTIVE academy (ADR-0037 §6).
type MembershipSource interface {
	Membership(ctx context.Context, tenant domain.TenantID, subject string) (domain.Membership, bool, error)
}

// ErrConcurrentModification is a lost optimistic-locking race (409 CONCURRENT_MODIFICATION).
var ErrConcurrentModification = domain.Conflict("CONCURRENT_MODIFICATION", "changed by someone else meanwhile; reload")

// ErrNoTenantTransaction is a store used outside Transactions.InTenant: a programming error, never a silent
// unscoped query.
var ErrNoTenantTransaction = errors.New("no tenant transaction in the context")
