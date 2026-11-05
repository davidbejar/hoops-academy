# WP31 — A login's e-mail change reaches every academy that shares the login

Model: Opus. Depends on: WP22 (ADR-0023), WP23. Skills: test-driven-development, tenant-isolation-testing,
quarkus-hexagonal-service, owasp-security, verification-before-completion. Worktree:
`~/code/hoops-wt/wp31-shared-login-email`, branch `wp31-shared-login-email`.

Decision 7 of 2026-11-05: one person, one e-mail. Today, when the super admin changes the e-mail of a login used in
several academies (`/platform/tenants/{id}/admins/{personId}`, and any other path through
`application/members/LoginEmailSync`), Keycloak and `core.app_user.email` get the new address but only the edited
academy's `core.person.email` changes; the other academies keep the old one.

## Scope
- Read `LoginEmailSync`, its callers (`ManageTenantAdmins`, member update) and the WP22 handover first.
- Behaviour: in the same transaction that updates Keycloak and `app_user`, update `core.person.email` for every
  person row that links the same login, in every academy. The academy-admin path is unchanged (it is already
  refused with 409 `LOGIN_SHARED` when the login is shared; keep that).
- Tenancy: those rows live under other tenants' RLS. Use the existing platform mechanism (`core_platform` role /
  `TenantScope` platform scope / per-tenant `runAs`, whichever `/platform/**` already uses for cross-tenant work);
  never bypass RLS and never widen the app role. One audit row (`member.login_email_changed`) per affected academy,
  with no e-mail in the metadata.
- Tests first: an integration test with a login shared by academies A and B, super admin changes it via A ⇒ B's
  person row has the new e-mail, B's audit log has a row, and an academy admin of A still gets 409. A GenericRls /
  schema test change is not expected (no new table).
- Contract: no new operation. If the response or the docs describe the per-tenant behaviour, fix the wording
  (`libs/contracts/core.yaml` description, `docs/guides/super-admin.*.md`).

## Acceptance
- [x] Failing test committed first, then the change (Conventional Commits)
- [x] `./mvnw -pl services/core-service -am verify` green (fresh; totals in the handover); the keycloak-tagged
      suite too if you touch the Keycloak adapter (`-Pkeycloak-it`)
- [x] Authz matrix untouched or consciously updated (`docs/domain/authz-matrix.md`)
- [x] Handover appended; ADR only if you had to choose between mechanisms (say which and why)

## Working rules (all WPs of this wave)
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Other agents work in parallel in sibling worktrees and share the Podman machine; retry a container start once
  before calling it a failure.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected,
  do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md (WP26 owns them); notes go in this file's Handover.
- Finish per the `work-package` skill: fresh full verification, checklist with evidence, `## Handover` appended.
- Final report to the orchestrator, at most 300 words: built, verified (commands and numbers), left out and why,
  anything WP32/WP34 (which also touch core members/admins code) must know.

## Handover
- Built:
  - `LoginEmailSync` (super admin path, `SharedLogin.SYNC`): `plan` lists the active persons of other academies that
    link the login (`MembershipRepository.inOtherTenants`, membership index read through the `own_memberships`
    subject policy, `app.subject` restored; shares `asSubject` with the `LOGIN_SHARED` probe) and refuses with 409
    `EMAIL_TAKEN` when another member of such an academy already uses the address; `apply` (after `app_user` and the
    edited academy's audit row, before Keycloak) sets each linked person's e-mail via the new port `SharedLoginPersons`.
  - Adapter `JpaSharedLoginPersonRepository`: flushes the bound tenant's pending writes, binds `app.tenant_id` to the
    other academy (`set_config(…, true)`), runs two native statements as core_app under that academy's RLS (`exists`
    another person with the e-mail; `update core.person … where id = :person and user_id = :login and active`), writes
    that academy's `member.login_email_changed` row via the new `AuditLog.recordFor(tenant, event)` (actor = super admin
    `sub`, no person, metadata `{}`), and restores the bound tenant (also on failure, cause kept). Refuses the bound
    tenant itself. No migration, no grants, no change to `TenantScope`/common.
  - Academy-admin path unchanged (409 `LOGIN_SHARED`, never rebinds). Contract: `updateTenantAdmin` description only
    (core.yaml stays 2.3.0). Docs: ADR-0026, ADR-0023 status/consequence amended, `super-admin.{en,es,id}.md`.
- Verified:
  - Red first (commit 34a6c4f): `theSuperAdminMovesASharedLoginInEveryAcademyThatUsesIt` (B kept the old e-mail) and
    `anEmailUsedByAnotherMemberOfAnAcademySharingTheLoginIsTaken` (200 instead of 409); guards
    `aKeycloakFailureLeavesEveryAcademyOfASharedLoginUnchanged`, `anAcademyAdminStillCannotMoveASharedLogin` passed.
    `SharedLoginPersonsTest` (7, `@Tag("rls")`) red by compilation, then green.
  - Mutation: not restoring the home binding fails `theHomeBindingIsRestoredAndItsPendingWritesKeepTheirTenant`.
    Removing the explicit `em.flush()` does not (Hibernate's AUTO flush runs before the first native statement); kept
    so the order does not depend on the flush mode.
  - `./mvnw -pl services/core-service -am clean verify -Dquarkus.http.test-port=0`: BUILD SUCCESS, common-quarkus 172,
    contracts 120, core-service 701 tests, 0 failures/errors/skips, coverage checks met (ArchUnit and RLS suites
    included). The first run without the port override failed in common-quarkus only on
    `Port already bound: 8081` (a sibling worktree's test run on the shared machine), not a code failure.
  - Keycloak adapter untouched, so `-Pkeycloak-it` not run; the commit hook's isolation check passed on both commits.
- Decisions/ADRs: ADR-0026. `TenantScope.runAs` always opens its own transaction (`requiringNew`), so it cannot meet
  "same transaction" (a Keycloak 502 would leave B ahead); `core_platform` has no rights on `core.person`. Chosen:
  per-statement tenant binding of the same core_app connection in a narrow adapter. Only active memberships (index
  rows) are updated: an academy the person left keeps its record and does not learn the new address (same definition
  as `LOGIN_SHARED`). Withdrawn/suspended academies with an active index row are updated too.
- Authz matrix: consciously untouched (who may do what is unchanged).
- Open points:
  - FOLLOW-UPS item "shared login moved by the super admin keeps the other tenants' `person.email`" can be closed (WP26
    owns that file).
  - The generated Dart client's doc comment for `updateTenantAdmin` still has the old description; `just gen-api` was
    not run because regeneration also rewrites ~10 files with whitespace drift under `apps/web` (WP28's area).
  - ADR number 0026 assumes WP26 takes 0025.

