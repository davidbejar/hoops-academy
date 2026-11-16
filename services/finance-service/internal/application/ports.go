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
	// Generating reads the plans the daily job generates (automatic, not archived), by name.
	Generating(ctx context.Context) ([]domain.FeePlan, error)
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

// Academy is the bound academy as the replica knows it: whether it is ACTIVE (and not removed) and its time zone
// (UTC when unknown or not a zone).
type Academy struct {
	Active bool
	Zone   *time.Location
}

// RosterPlayer is a player of a team's roster with the name the lists show.
type RosterPlayer struct {
	Player domain.PlayerID
	Name   string
}

// RosterReads answers from the roster replica (ADR-0037 rules: removed rows count as absent) what the dues and the
// finance access rules need, in the bound tenant.
type RosterReads interface {
	Academy(ctx context.Context) (Academy, bool, error)
	// Relations are person's links on today (the academy's date): teams of seasons not ended that person coaches
	// (staff role COACH), linked players, the own player.
	Relations(ctx context.Context, person domain.PersonID, today time.Time) (domain.Relations, error)
	SeasonDates(ctx context.Context, season domain.SeasonID) (domain.SeasonDates, bool, error)
	// Candidates are the players on the roster of target's teams of season on any day of window (valid assignments
	// overlapping it), in the order they joined, then by team and player.
	Candidates(ctx context.Context, season domain.SeasonID, target domain.Target, window domain.DueWindow) ([]domain.Candidate, error)
	// TeamRoster is the team's roster today (open, valid assignments), by name; found is false for an unknown team.
	TeamRoster(ctx context.Context, team domain.TeamID) ([]RosterPlayer, bool, error)
}

// DueFilter narrows the due list; nil fields do not filter. From and To bound the period start (dates).
type DueFilter struct {
	Plan     *domain.FeePlanID
	Team     *domain.TeamID
	Player   *domain.PlayerID
	Season   *domain.SeasonID
	Period   *string
	Status   *domain.DueStatus
	From, To *time.Time
}

// PersonRef names a member (who recorded or voided a payment); Name is empty when the replica has none.
type PersonRef struct {
	Person domain.PersonID
	Name   string
}

// PaymentRecord is a payment with the names of who recorded and who voided it.
type PaymentRecord struct {
	Payment    domain.Payment
	RecordedBy PersonRef
	VoidedBy   *PersonRef
}

// DueRecord is a due as read: with its plan's and player's names and its valid payment (none unless PAID). The
// player's name is empty once the player is removed from the roster.
type DueRecord struct {
	Due        domain.Due
	PlanName   string
	PlayerName string
	Payment    *PaymentRecord
}

// DueStore keeps the bound tenant's dues.
type DueStore interface {
	// Existing reports the players who have a due of plan and period.
	Existing(ctx context.Context, plan domain.FeePlanID, period string) (map[domain.PlayerID]bool, error)
	// Insert stores new dues, leaving out any whose (plan, player, period) exists meanwhile; it returns the stored ones.
	Insert(ctx context.Context, dues []domain.Due) ([]domain.DueID, error)
	// Lock reads a due and locks it until the transaction ends.
	Lock(ctx context.Context, id domain.DueID) (domain.Due, bool, error)
	// Update writes due if its Version is still the stored one (else ErrConcurrentModification).
	Update(ctx context.Context, due domain.Due) error
	Record(ctx context.Context, id domain.DueID) (DueRecord, bool, error)
	// List orders by period start, then player name, then id.
	List(ctx context.Context, filter DueFilter, page Page) ([]DueRecord, int64, error)
	// OfPlayer orders by period start descending (newest first), then plan name, then id.
	OfPlayer(ctx context.Context, player domain.PlayerID, page Page) ([]DueRecord, int64, error)
	// Behind reports which of players have an OPEN due of a period started on or before today.
	Behind(ctx context.Context, players []domain.PlayerID, today time.Time) (map[domain.PlayerID]bool, error)
}

// PaymentStore keeps the bound tenant's payments.
type PaymentStore interface {
	Insert(ctx context.Context, payment domain.Payment) error
	// Lock reads a payment and locks it until the transaction ends.
	Lock(ctx context.Context, id domain.PaymentID) (domain.Payment, bool, error)
	// Void writes a payment's void (when, why, by whom).
	Void(ctx context.Context, payment domain.Payment) error
	// OfDue reads every payment of a due, oldest first.
	OfDue(ctx context.Context, due domain.DueID) ([]PaymentRecord, error)
}

// TenantDirectory lists the academies the replica holds rows of (finance.replica_tenant: ids only), so a job can
// enter each one; it reads no tenant data.
type TenantDirectory interface {
	Tenants(ctx context.Context) ([]domain.TenantID, error)
}

// Exclusive runs work only while this instance holds the cluster-wide lock (a database advisory lock); false when
// another instance holds it (the run is skipped, never waited for).
type Exclusive interface {
	Run(ctx context.Context, lock string, work func(ctx context.Context) error) (bool, error)
}

// ErrConcurrentModification is a lost optimistic-locking race (409 CONCURRENT_MODIFICATION).
var ErrConcurrentModification = domain.Conflict("CONCURRENT_MODIFICATION", "changed by someone else meanwhile; reload")

// ErrNoTenantTransaction is a store used outside Transactions.InTenant: a programming error, never a silent
// unscoped query.
var ErrNoTenantTransaction = errors.New("no tenant transaction in the context")
