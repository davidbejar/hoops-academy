# ADR-0015: Roster eligibility engine — season non-overlap, sticky invalidation, orphan scope, rollover

- Status: Accepted
- Date: 2026-11-02
- Context: WP4 (core-service), plan §2 "Roster & eligibility", ADR-0006, ADR-0010

## Context
WP4 had to settle five things the plan leaves open:
1. Seasons of a tenant must not overlap. The natural tool is an exclusion constraint
   `exclude using gist (tenant_id with =, daterange(start_date, end_date, '[]') with &&)`, which needs the
   `btree_gist` extension for the uuid equality. `core_migrator` cannot create it: the bootstrap
   (`infra/db/init/01_roles_schemas.sql`) revokes database privileges from public and grants only CONNECT
   (verified: `permission denied to create extension "btree_gist" — Must have CREATE privilege on current database`).
2. When is an assignment re-evaluated, and what happens to an assignment that fails?
3. ORPHAN ⇔ "ACTIVE player without a valid open assignment" — in which seasons?
4. What exactly does `POST /seasons/{id}/rollover` do? The contract (`core.yaml`) says `{seasonId}` is the existing
   target season, the body names `fromSeasonId`, and `cloneStaff` / `clonePlayers` default to `true` (players are
   carried over, then eligibility-checked). The WP4 lane brief instead described "create the next season from the
   body and do not auto-assign players".
5. How often must the "nightly" job run when tenants live in different time zones?

## Decision
1. **Non-overlap without an extension.** The use case checks overlap first (409 `SEASON_OVERLAP`, readable error);
   the database guarantees it with a `BEFORE INSERT OR UPDATE` trigger `core.season_no_overlap` that takes a
   per-tenant transaction advisory lock (`pg_advisory_xact_lock(hashtextextended('core.season:'||tenant_id, 0))`)
   and raises SQLSTATE `23P01` (exclusion_violation) on an overlapping row of the same tenant. The trigger runs as
   the invoker, so RLS scopes the lookup to the bound tenant. No unique `(tenant_id, reference_year)` was added: the
   trigger already enforces the real invariant and a second short season in the same reference year is legitimate.
2. **Re-evaluation is sticky and idempotent.** Re-evaluation only looks at open, *valid* assignments of current and
   upcoming seasons (`end_date >= today` in the tenant time zone), evaluated as of today. A failing assignment gets
   `invalidated_at` + its primary reason (never deleted) and exactly one OPEN `eligibility_case` (partial unique
   index). It stays invalid until a person resolves the case (REASSIGNED → checked assignment to the target team +
   the invalid one is closed; REMOVED_FROM_TEAM → closed; DISMISSED → decision only, stays invalid). Triggers: the
   sweep, rollover (per cloned assignment), tenant settings (age rule / play-up limit, same transaction via
   `TenantSettingsListener`), team category / gender policy, category max age / rank, season dates / reference year.
3. **Orphan scope.** A player is ACTIVE iff they have ≥ 1 valid open assignment to a team of a season that has not
   ended; ACTIVE/ORPHAN flip both ways, PENDING_APPROVAL and WITHDRAWN are never touched. Re-derived by every command
   that changes assignments and by the sweep, so drift self-heals. Consequence: a rollover into a season that starts
   while the previous one is still running lists orphans immediately (the result is about the target season), but
   their `status` flips to ORPHAN only once the previous season has ended (the next sweep after that day).
4. **Rollover follows the contract**, not the lane brief (contracts are the source of truth, `libs/` is not ours to
   change): the target season must exist and have no teams (409 `ROLLOVER_TARGET_NOT_EMPTY`), start after the source
   season (422 `ROLLOVER_BACKWARDS`, `ROLLOVER_SAME_SEASON`). Every source team is cloned (name, alias, category,
   gender policy, staff when `cloneStaff`). With `clonePlayers` (default) each open assignment of an ACTIVE/ORPHAN
   player is copied (`joinedOn` = target start, jersey kept) and evaluated with the target reference year as of
   max(today, target start); ineligible copies are invalidated with a case. With `clonePlayers=false` nothing is
   assigned (the lane brief's behaviour), no case is opened, and every previously assigned active player is
   reported as an orphan with empty `reasons`; staff/admin then assign through `eligible-teams`. The source season
   is never modified (history).
5. **Sweep cadence.** `NightlyEligibilityJob` runs on `hoops.core.eligibility-cron`, default hourly
   (`0 15 * * * ?`), so each tenant is evaluated within an hour after its own local midnight; `off` disables it.
   It lists ACTIVE tenants through the platform datasource and runs each in its own `TenantScope.runAs`
   transaction; a failing tenant is logged and skipped.

Smaller rules fixed along the way: a 29 February birthday counts on 1 March in non-leap years (`Period.between`);
play-up levels count ladder positions, not rank values; the ladder requires distinct ranks and a strictly growing
`maxAge` with at most one unlimited (senior) category at the top (422 `AGE_CATEGORY_ORDER`); "COACH of the team" =
COACH tenant role + a `team_staff` row for the team (the staff row's own role is not consulted).

## Consequences
Two concurrent season inserts of one tenant serialise on the advisory lock (seasons are rare writes). Hourly sweeps
cost one small transaction per ACTIVE tenant per hour; if that becomes noticeable the job can select only tenants
whose local time just passed midnight. A DISMISSED case leaves the assignment invalid (it does not count as
"valid" for status or roster) — re-validating requires a new assignment. If `btree_gist` is ever installed by the
bootstrap, the trigger can be replaced by the exclusion constraint without changing the use case.
