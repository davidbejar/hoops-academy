# ADR-0016: WP2c consolidation — contracts 2.0, shared core client, cluster-wide job lock

- Status: Accepted
- Date: 2026-11-02
- Amends: ADR-0014 §1 (reused event id), ADR-0008 (where the RosterPort REST code lives)

## Context
The WP2a–WP15 handovers collected cross-cutting gaps (docs/wp/FOLLOW-UPS.md): game and athlete each had a copy of the
core `/internal` client, cache and authz resolver; jobs ran on every replica; the contracts lacked responses and
fields the services already produced (503, 502, availability, plan archive/progress, `bandStatus`), or carried fields
nothing produces (`BoxScore.opponentFouls`); `AuthzContext` had no tenant time zone and no "teams of my players".
Several fixes change response shapes, which the contracts' versioning policy calls *major*.

## Decision
1. **Contracts 2.0.0** (core, game, athlete; common 1.1.0), released together with the services and the web app from
   the monorepo (no parallel `/v2` paths, per the README policy). Breaking items:
   - core: `PlayerStatus` gains `REJECTED` (a rejected ADD_PLAYER request; WITHDRAWN stays "left the academy" or
     "cancelled by the requester"); the reject body is `RejectApprovalRequest` with a required non-blank `note`;
     `AuthzContext` / `AuthzSummary` require `timezone` and `playerTeamIds` (`ownPlayerId` already existed and is the
     "own player id" — no second `playerId` field).
   - game: `BoxScore.opponentFouls` is **removed** (it had no source event type; adding `OPPONENT_FOUL` would have
     needed a new event type in the JSON Schema, the domain, the projector, the DB check and the shared vectors);
     `StatLine` requires `technicalFouls` and `unsportsmanlikeFouls`; `MatchEventRejectionReason` gains
     `EVENT_ID_REUSED` (replaces `CLIENT_SEQ_CONFLICT` for an id stored for another match — amends ADR-0014 §1) and
     `MATCH_NOT_STARTED` (reserved; v1 keeps accepting SCHEDULED matches as ADR-0014 §3 decided).
   - athlete: `PhysicalTestResult.ageAtMeasurement` is nullable and `bandStatus` is required.
   Additive: 503 `ServiceUnavailable` on every `/api/game/**` and `/api/athlete/**` operation (their tenant filter
   calls core), 502 `UpstreamIdentityProvider` on `createTenant` / `inviteMember`, `GET
   /platform/tenants/{id}/usage/history`, `GET /api/athlete/players/{id}/availability`, `:archive` / `:unarchive`,
   `GET /plan-assignments/{id}/progress`, `TrainingPlanSummary.archived`. `/internal/usage/{tenantId}` answers 200 with
   zero counters for an unknown tenant in all three services (core changed to match).
2. **Discriminable match events.** Each `<Type>Event` fixes `type` as `{allOf: [{$ref: MatchEventType}], enum:
   [<TYPE>]}`. The plain `{type: string, enum: [<TYPE>]}` spelling breaks dart-dio (lost import, 135 analyzer errors);
   swagger-request-validator drops the sibling `enum` when it resolves combinators, so game's tests validate events
   against a derived copy using the plain spelling (same constraint). JSON Schema is unchanged.
3. **Shared core client in common-quarkus** (`com.hoopsacademy.common.client`): `CoreInternalClient` (REST client,
   configKey `core`, defaults `quarkus.rest-client.core.url=${hoops.core.url}`, 2 s timeouts — no class-level
   `@Path`, which would be scanned as a server root resource and shadow `/internal/**`), `CoreRosterClient` (Caffeine,
   `hoops.core.cache-ttl` 30 s, negatives never cached, 404 → NotFound, anything else → `UpstreamUnavailableException`
   → 503) and `RosterAuthzResolver` as a `@DefaultBean` (core keeps its database resolver). Services keep their own
   `RosterPort` interfaces and thin mapping adapters.
4. **`TenantScope.runExclusive(lockKey, work)`**: `pg_try_advisory_xact_lock(<first 8 bytes of SHA-256(lockKey)>)` in
   a dedicated transaction that is **suspended** while the work runs and rolled back afterwards. The work therefore
   runs without a transaction (its own `runAs` / `@Transactional` / second-datasource transactions are unaffected —
   core's snapshot job writes through the platform datasource), the lock is released on completion, failure, process
   death, or after `hoops.tenancy.exclusive-lock-timeout` (6 h). Never waits; a skipped run returns false. Used by
   core's eligibility sweep and usage snapshot and athlete's materialisation.
5. **Tenant-exempt `/api` paths** are configuration (`hoops.tenancy.exempt-paths`, default `/api/core/me`, exact paths),
   replacing core's pre-matching path rewrite. common maps `UnauthorizedException` → 401, optimistic-lock failures
   (also wrapped) → 409 `CONCURRENT_MODIFICATION`, `UpstreamUnavailableException` → 503.
6. **Shared global+tenant tables** get a test hook, `nullableTenantTables()` (table → owner column), checked for
   forced RLS, a tenant policy and one policy per command; WP9/WP10 keep their `owner_tenant_id` columns.

## Consequences
- The Dart packages must be regenerated (`just gen-api`) and the web app adapted: `PlayerStatus.REJECTED`, no
  `BoxScore.opponentFouls` (also in `apps/web` mocks), new `StatLine` counters, `RejectApprovalRequest`, nullable
  `ageAtMeasurement`, new reasons. Generation was checked in a scratch directory: 0 analyzer errors for all three.
- Rows rejected before core's `V8__player_rejected.sql` stay WITHDRAWN (no backfill; pre-release data).
- A job skipped by the lock waits for the next trigger; jobs are idempotent, so nothing is lost.
- Advisory lock keys are a 64-bit hash: a collision between two lock names would only serialise unrelated jobs.

## Alternatives considered
- Keep `opponentFouls` and add `OPPONENT_FOUL` end to end — rejected as not cheap (see 1).
- Session-level `pg_try_advisory_lock` on a held connection — workable, but a pooled connection returned with the lock
  still held (failed unlock) would block the job cluster-wide; the transaction-scoped lock cannot leak.
- Running the work inside the lock transaction — rejected: jobs that use a second datasource would enlist two non-XA
  resources, and one tenant's failure would mark the whole run rollback-only.
- A per-variant named enum schema (`ShotEventType`) — not tried: it would redeclare `type` with a different type than `MatchEventBase.type` in the generated Dart classes.
