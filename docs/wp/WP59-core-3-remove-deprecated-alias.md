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
