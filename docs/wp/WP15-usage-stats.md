# WP15 — Usage statistics aggregation

Model: Sonnet. Depends on: WP3, WP6, WP8. Skills: quarkus-hexagonal-service, test-driven-development.

## Scope
- core: `GET /platform/tenants/{id}/usage` aggregating core counts (members by role, players by status, teams, seasons)
  with game (`matches`, `events`) and athlete (`sessions`, `attendance`, `injuries`, `test results`) via `/internal/usage`
  with client-credentials; nightly `usage_snapshot` job; list endpoint for trends.
- game/athlete: implement/complete `/internal/usage/{tenantId}` counts.

## Acceptance
- [x] WireMock tests for peer failures (partial data flagged via the contract's `unavailableServices`, 200); snapshot job idempotent per day (`TenantUsageResourceTest.oneDownPeer…`, `bothPeersDown…`, `aPeerSlowerThanTheTimeout…`, `UsageSnapshotJobTest`)
- [x] super_admin only; contract validation; verify green (`tenantAdminsAreForbidden`, `serviceAccountsAreForbidden`, `anonymousCallersAreUnauthorized`; `Contract.CORE` on every call; verify 398 tests green)

## Handover

### Built
Most of the aggregation already existed from WP3 (`GET /platform/tenants/{id}/usage`, `AggregateTenantUsage`, game/athlete REST
clients with `ServiceTokenClientFilter`, 2 s read timeout, `unavailableServices`); game and athlete already implement
`/internal/usage` (WP6/WP8, zeros for unknown tenants), so nothing changed there. WP15 added, in `services/core-service` only:
- **Counters**: `membersAdmin|Coach|AssistantCoach|Parent|Player`, `playersPendingApproval|Orphan|Withdrawn` (next to `members`,
  `players`, `activePlayers`, `teams`, `seasons`) and `pendingApprovals` (`ApprovalUsageCounter`). The UsageReport schema allows additive counters.
- **Flyway `V7__usage_snapshot_daily.sql`**: generated column `snapshot_date` (UTC date of `collected_at`), unique
  `(tenant_id, snapshot_date)`, older same-day rows reduced to the latest (owner steps out of FORCE RLS for the dedupe), `grant update` to `core_platform`.
  `PlatformUsageSnapshotRepository` now upserts; **a report with unavailable services never replaces a complete one** of the same day.
- **`UsageSnapshotJob`** (`@Scheduled`, `hoops.core.usage-snapshot-cron`, default `0 30 2 * * ?` UTC, `off` in tests) ->
  `SnapshotTenantUsage` (all ACTIVE tenants via the new shared `ActiveTenants`, which `EligibilitySweep` now uses too; failing tenants logged and skipped).
- Tests: `TenantUsageResourceTest` (10), `UsageSnapshotJobTest` (3); `UsageStubs` helpers `bothAnswer/down/unreachable/slow`.

### How verified (fresh, 2026-11-02)
Same full run as WP5: `clean verify` BUILD SUCCESS, 398 tests, 0 failures, lines 98.7 %, `application.usage` 94.6 %, `adapters.in.scheduler` 100 %.
Happy path (core + game + athlete, counters), game 503 / athlete connection reset -> 200 with the service listed, both down -> core only,
a 3.5 s peer -> unavailable within the 2 s timeout, service token + tenant path verified on the peers, snapshot upsert (one row per day, partial never
replaces complete, complete replaces partial), job run three times -> one row per ACTIVE tenant, SUSPENDED tenant skipped, 403 for
tenant users and service accounts, 401 anonymous, 404 unknown tenant. Mutation: removing the "never replace complete" guard fails
`theDaysSnapshotIsUpsertedAndAPartialOneNeverReplacesACompleteOne` (restored). The upsert/job code was written before its tests in this WP;
the mutation check is the evidence the tests bite.

### Decisions
- The contract's `TenantUsage` has **no `partial` field**; it reports failures in `unavailableServices` (enum core|game|athlete). The contract was
  not changed (lane rule); `unavailableServices.length > 0` is the "partial" flag, and the job logs a `partial` count.
- **No trends/history endpoint**: `core.yaml` has none, so none was added; snapshots accumulate (one per tenant per day) for it.
- The on-demand endpoint keeps writing the snapshot (WP3 behaviour) but through the same daily upsert, so it cannot create duplicates.

### Open points
- A history/trend endpoint needs a contract addition (WP2b owner); the UsageReport counters list in `common.yaml` could document the new core keys.
- The job aggregates tenants sequentially (2 s peer timeout each); fine for tens of tenants, parallelise if it grows.
- Snapshot rows of a tenant are never pruned.
