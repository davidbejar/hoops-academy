# WP59 — Core 3.0.0: remove the deprecated `resendTenantAdminInvitation` alias

Model: Opus. Wave 2 (2026-11-06, fourth round): starts after WP58 is merged (same contract); runs alongside WP53
(web mock), WP55, WP57, WP61, WP65. You own `libs/contracts/openapi/core.yaml`, `apps/web/packages/core`, the
core-service resource and tests of the alias, the web callers (`apps/web/lib/features/admin` platform admin
actions; WP53 owns `apps/web/lib/core/mock`, so if the mock serves the alias tell the orchestrator instead of
editing it), `docs/adr/0035-*.md`. Depends on: WP24/ADR-0024, WP29/ADR-0027 (versioning policy in
`libs/contracts/README.md`). Skills: quarkus-hexagonal-service, test-driven-development, verification-before-
completion. Worktree: `~/code/hoops-wt/wp59-core-3`, branch `wp59-core-3`.

Decision 41 of 2026-11-06: the alias goes; a removal is a major bump (core 3.0.0) with an ADR and a migration note
(ADR-0016 is the template). ADR-0035 reserved for you.

## Scope
1. **Contract**: remove the operation; `info.version` 3.0.0; every other operation unchanged. The contracts tests
   that pin "core ≥ 2.x" keep passing; `./mvnw -pl libs/contracts verify`; `just gen-api`, commit only the core
   package (and `apps/web/pubspec.lock` with the version).
2. **Service**: remove the resource method and its tests; `issueTenantAdminTemporaryPassword` keeps its tests.
3. **Web**: no caller of the alias remains (grep the generated package usage); the platform admin screen uses the
   temporary-password action.
4. **ADR-0035**: why removed now, what clients must change (none outside this repo), the migration note format from
   ADR-0016; row at the end of `docs/adr/README.md`; `docs/runbooks/release.md` contract-version row is the docs
   pass's (note it in the handover).

## Acceptance
- [ ] Contract 3.0.0 validated; Dart core package regenerated and committed; `pubspec.lock` updated
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals); `flutter analyze` clean;
      `just web-format-check` clean; `just web-test` green (fresh; totals)
- [ ] ADR-0035 written and indexed; handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits (`feat(contracts)!: …` for the breaking change). A Claude Code hook runs a ~40 s
  tenant-isolation test before every commit (it resyncs the Podman VM clock itself); it is expected, do not try to
  bypass it. End every commit message with the line `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
- Built: `libs/contracts/openapi/core.yaml` 3.0.0 without the path `…/admins/{personId}/resend-invitation` /
  operation `resendTenantAdminInvitation` (removal noted in `info.description`); every other operation unchanged.
  `PlatformAdminResource` lost the alias method (the shared helper is inlined into `issueTemporaryPassword`).
  Tests: `TemporaryPasswordContractTest.theDeprecatedResendAliasIsRemovedInCore300` (version ≥ 3.0.0, no path, no
  operation; the alias row left the read-only/no-store table) and
  `PlatformAdminResourceTest.theRemovedResendInvitationAliasIsNotFoundAndChangesNothing` (404, no Keycloak call, no
  audit row) replace the alias tests; the `issueTenantAdminTemporaryPassword` tests are untouched. `just gen-api`:
  only `apps/web/packages/core` (3.0.0) and `apps/web/pubspec.lock` committed (athlete/game output reverted). Web: no
  caller of the alias; the platform admin screen (`features/platform/data/platform_repository.dart`) already calls
  `issueTenantAdminTemporaryPassword`; nothing in `features/admin` used it. Commits: red test, `feat(contracts)!`,
  docs.
- Verified: `./mvnw -B -ntp -pl libs/contracts verify` 156/0/0. `./mvnw -B -ntp -T 1C verify
  -Dquarkus.http.test-port=0`: common 186, contracts 156, core 823, game 324, e2e 27 (23 skipped), all 0 failures,
  coverage met; athlete hit a Testcontainers "Could not create/start container" boot error under parallel load
  (`AthleteDatabaseRoleTest`, no code of mine), re-run alone `-pl services/athlete-service verify` 653/0/0, coverage
  met. `flutter analyze` no issues; `just web-format-check` 0 changed; `just web-test` 708 passed.
- Decisions/ADRs: ADR-0035 (why now, migration note in the ADR-0016 form, alternatives), indexed at the end of
  `docs/adr/README.md`; ADR-0024's status line says "amended by ADR-0035".
- Open points / follow-ups:
  - The web demo mock still serves the old path: `apps/web/lib/core/mock/mock_platform_api.dart:495`
    (`rest[1] == 'resend-invitation'`), WP53's file; drop that alternative (unreachable from the generated client).
  - Docs pass: `docs/runbooks/release.md` contract-version row (core 3.0.0); `docs/runbooks/onboard-tenant.md` lines
    71 and 83 still describe the alias as deprecated; `docs/wp/FOLLOW-UPS.md` item "Remove
    `resendTenantAdminInvitation`" can be closed.

