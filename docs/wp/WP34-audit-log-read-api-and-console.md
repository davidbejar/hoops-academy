# WP34 — Audit log: read API for academy admins and the super admin, console screens

Model: Opus. Wave 3: starts after WP32 is merged (core contract, audit events). Depends on: WP17 (ADR-0017,
`core.audit_event`), WP23, WP32. Skills: test-driven-development, tenant-isolation-testing,
quarkus-hexagonal-service, owasp-security, flutter-feature, verification-before-completion. Worktree:
`~/code/hoops-wt/wp34-audit-log`, branch `wp34-audit-log`.

Decision 8 of 2026-11-05. `core.audit_event` (V9: `tenant_id`, `actor_sub`, `actor_person_id`, `action`,
`target_type`, `target_id`, `metadata jsonb`, `at`; index `(tenant_id, at desc)`; RLS) is written by ~20 actions
(`AuditEvent.of("member.invited", …)` etc.) and read by nothing. Metadata holds no personal data by rule
(`AuditEvent` javadoc): names are resolved at read time.

## Notes from WP31 (merged)
- `AuditLog.recordFor(tenant, event)` writes a row for another academy (native SQL, immediate); `WP32` adds
  `member.temporary_password_expired` the same way.

## Scope
- **Contract** (core, minor bump): `GET /api/core/audit-events?from&to&action&page&size` for ADMIN (own academy
  only; non-members 404 as always) and `GET /platform/audit-events?tenantId&from&to&action&page&size` for
  super_admin (all academies). Response item: `at`, `action`, `actor` (person id + display name when resolvable,
  else the subject), `target` (type, id, display name when the type is person / player / team / tenant and the row
  still exists), `metadata`. `action` filter accepts one or several values; publish the list of action names as an
  enum in the contract (one source: a Java enum or constants class that every `AuditEvent.of` uses, so a new action
  cannot be added without appearing in the contract; ArchUnit or a test enforces it).
- **Missing events**: add `member.invitation_accepted` (first login, where `GetMe` flips PENDING → ACCEPTED; WP32
  touched that code) and `player.approved` / `player.rejected` if absent. Check the list in the handover.
- **Persistence**: paged query under RLS for the tenant path; the platform path uses the existing platform mechanism
  (`/platform/**` already lists tenants cross-tenant — reuse it, never bypass RLS otherwise). Index for
  `(tenant_id, action, at desc)` if the filter needs it (measure with EXPLAIN on a seeded table, note the result).
- **Web**: an "Activity" screen in the academy admin area and in the platform console (date range, action filter,
  paging, localized action names es/en/id — one label per action, l10n parity test); widget tests; goldens 360x780
  and 1024x768.
- **Docs**: authz matrix rows for both operations (ADMIN only; PARENT/PLAYER/COACH 403? — follow the matrix
  convention for role-only denials), guides, `docs/domain/audit-events.md` listing every action with its target and
  metadata keys.
- **Retention**: none (v2 purge job); say so in the contract description.

## Acceptance
- [ ] Failing tests first: role matrix (ADMIN 200, other roles per matrix, non-member 404, super_admin on
      `/platform` 200, super_admin without membership on `/api` 404), filters, paging, cross-tenant isolation (A
      never sees B's rows: API + RLS), name resolution, enum completeness test
- [ ] `./mvnw -B -ntp -T 1C verify` green (fresh; totals), `just web-test` green, `just isolation-check` green
- [ ] Contract validated in tests; Dart packages regenerated; handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected,
  do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- Built:
  - Contract core **2.5.0** (additive): `GET /api/core/audit-events` (tag Audit, `X-Tenant-Id`, ADMIN) and
    `GET /platform/audit-events` (Platform, optional `tenantId`, super_admin); query `from` (inclusive) / `to` (exclusive)
    as `date-time`, `action` repeated (`explode`, array of the `AuditAction` enum, 28 values), `page` / `size`; schemas
    `AuditAction`, `AuditTargetType`, `AuditActorKind` (PERSON / PLATFORM / SYSTEM), `AuditActor` (`subject`, nullable
    `personId` / `displayName`), `AuditTarget` (`type`, `id`, nullable `displayName`), `AuditEvent`, `AuditEventPage`,
    `PlatformAuditEvent` (`x-extends: [AuditEvent]` + `tenantId`, `tenantName`), `PlatformAuditEventPage`. Retention "none
    in v1" in the info and both operation descriptions. Dart core client regenerated (`scripts/gen-api.sh core`, no drift).
  - One source of action names: `AuditAction` (with its `AuditTargetType`) in `application.port`; `AuditEvent.of` takes
    only the enum (every writer, `ApprovalOutbox` and `TenantLifecycle` use the wire name for the outbox type).
    `AuditActionCompletenessTest` keeps enum = contract enums = `docs/domain/audit-events.md` (new catalogue: action,
    target, metadata keys, writer).
  - Missing events: `member.invitation_accepted` added (first `/me` that flips PENDING → ACCEPTED, actor = that person via
    the new `AuditLog.recordAs`). `player.approved` / `player.rejected` already existed (ApprovalOutbox).
  - Read side: `ReadAuditTrail` (core_app, RLS + explicit `tenant_id`; names of persons, players' persons and the academy
    resolved in the same scope by `JpaAuditNameRepository`) and `ReadPlatformAuditTrail` (registry 404 for an unknown
    `tenantId`; rows through `PlatformJpaAuditTrail` on the platform datasource joined to `core.tenant`; names only for
    academies and active administrators, per academy inside `TenantScope.runAs`). Shared paged SQL
    `AuditEventQueryRepository` (order `at desc, seq desc`). Bad `from`/`to`/`action`/`tenantId` → 400 Problem.
  - Migrations: `V11__audit_event_platform_read.sql` (policy `audit_event_platform_read` for select to core_platform +
    `grant select`; no other grant, no BYPASSRLS); `V12__audit_event_read_indexes.sql` (`(tenant_id, action, at desc)`,
    `(at desc)`).
  - Web: feature `lib/features/audit` (domain `AuditEntry` / `AuditPage` / `AuditQuery`, `ApiAuditRepository`,
    providers per `AuditScope`, `AuditLogView` with date range, multi-action dialog, pager). Admin hub entry
    **Activity** (`/admin/activity`); platform console chip **Academies' activity** (`/platform/activity`) and a clock
    icon on an academy's page (`/platform/:tenantId/activity`). 50 ARB keys in es/en/id (one label per action). Mock API
    serves a demo trail.
  - Docs: ADR-0029 (+ index, ADR-0017 status amended), authz matrix rows for both operations, `docs/domain/audit-events.md`,
    guides `admin.*` §10 and `super-admin.*` "Activity" (en/es/id), threat model row R updated.
- EXPLAIN ANALYZE (postgres:17, 1,000,000 rows, 50 academies with one holding 40 %, 20 actions over two years, plus 20
  rows of a rare action): before V12 — academy page unfiltered 0.4 ms (index `(tenant_id, at desc)`), rare action page
  65 ms / count 81 ms (parallel seq scan), common action + 30 days 2.5 ms, platform page 300 ms (top-N sort of all rows),
  counts 92 ms (academy) / 218 ms (platform). After V12 — rare action page 0.05 ms / count 0.03 ms, common action + 30 days
  0.1 ms, platform page 0.2 ms, platform page with a rare action 0.7 ms; unfiltered counts unchanged (scan).
- Verified (fresh, 2026-11-06):
  - Red first: `test(contracts)` 357ba7e (9 failures: no operations/schemas, version), `test(core)` c8228a3 (red by
    compilation: no `AuditAction`; after the first implementation pass the catalogue test failed until
    `docs/domain/audit-events.md` existed, the platform RLS test and a 404-instead-of-400 on a malformed `tenantId` were
    fixed), `test(web)` d16f2e0 (red by compilation) — each before its `feat`.
  - `./mvnw -B -ntp -T 1C clean verify -Dquarkus.http.test-port=0`: BUILD SUCCESS — contracts 146, common-quarkus 172,
    game 196, athlete 586, core 760 = **1,860 tests**, 0 failures/errors/skips; all JaCoCo coverage checks met; ArchUnit,
    RLS meta, generic RLS, `AuditEventRlsTest` (4) and `DatabaseRoleMetaTest` included. New core tests:
    `AuditEventResourceTest` 16 (matrix: ADMIN and ADMIN+COACH 200, COACH / ASSISTANT_COACH / PARENT / PLAYER /
    COACH+PARENT 403, non-member 404, super_admin without membership 404, anonymous 401; filters, paging, names, a forged
    foreign id never resolves, another academy's rows never listed and its header 404), `PlatformAuditEventResourceTest` 8
    (every academy with names, `tenantId` narrowing, unknown academy 404, admin-only names, other academy's admin not
    named, 400s, 403 for academy users, 401), `AuditActionCompletenessTest` 4, `AuditFilterTest` 3,
    `AuditActorKindTest` 3, `MeResourceTest` (invitation_accepted once, actor = person).
  - `just web-test` (`flutter test`): **565 passed**; `flutter analyze`: no issues. New: `audit_test.dart` 16 (loading,
    error/retry, empty, populated, action filter, paging, date range as UTC, picker, platform list, one academy, forbidden
    without super_admin, one distinct label per action in es/en/id), `audit_repository_test.dart` 2, mock API 1, goldens
    `audit_activity_360x780` / `_1024x768`. Re-recorded (reviewed: only the new entry points differ): `home_admin_*`,
    `platform_admins_*`, `platform_admin_add_360x780`, `temporary_password_*`.
  - `just isolation-check`: 6 passed; `just db-role-check`: 13 passed.
- Decisions/ADRs: ADR-0029 (one enum for the names; platform read policy instead of a per-academy merge; platform names
  limited to academies and active administrators; no `team` target type until an action targets a team; no retention).
  ADR-0017 status amended. Core contract 2.4.0 → **2.5.0**.
- Open points:
  - Pre-existing exception to "no personal data in metadata": `tenant.suspended` / `tenant.withdrawn` carry the super
    admin's free-text `reason` (documented in the catalogue and ADR-0029); worth a decision (drop it from the audit row or
    accept it).
  - Retention/purge job (v2). Unfiltered counts scan the trail (~0.1–0.2 s per million rows).
  - `actor.subject` (the super admin's Keycloak `sub`) is visible to academy admins on PLATFORM rows; harmless id, noted.
  - Other resources (`ApprovalRequestResource`, `PlayerResource`, …) still answer 404 for a malformed UUID query
    parameter (JAX-RS default); the audit endpoints answer 400 via `Params.uuid`.
  - The date range picker is Material's; at 360 px with the square test font its header overflows (test uses 1024 px).
  - e2e `JourneyTest` not run (not in the acceptance).
  - Commits end with `Co-Authored-By: Claude Opus 5.5` (the model that did the work), as WP32 did.
