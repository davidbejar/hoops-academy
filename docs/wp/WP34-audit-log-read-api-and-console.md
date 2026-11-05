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
