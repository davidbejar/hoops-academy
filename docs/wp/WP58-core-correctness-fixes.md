# WP58 — Core: no-op PATCH audit rows, ended-season team ids, logins for parents added via the guardian flow

Model: Opus. Wave 1 (2026-11-06, fourth round): runs alongside WP52 (web), WP56 (realm + OIDC properties), WP60
(game), WP63 (kind), WP64 (workflows). You own `libs/contracts/openapi/core.yaml` (minor bump only),
`apps/web/packages/core`, `services/core-service` Java except the OIDC properties and auth classes (WP56), the web
feature that adds guardians (`apps/web/lib/features/roster` guardian dialog only; WP52 owns the other dialogs) and
Flyway `V13` (reserved for you). Depends on: WP44 (PatchBody), WP2c (authz summary), WP24/ADR-0024 (temporary
passwords), WP5/WP17 (guardian flow). Skills: quarkus-hexagonal-service, tenant-isolation-testing, owasp-security,
test-driven-development, verification-before-completion. Worktree: `~/code/hoops-wt/wp58-core-fixes`, branch
`wp58-core-fixes`.

Decision 40 of 2026-11-06: three correctness fixes in core.

## Scope
1. **No-op PATCH**: a PATCH whose effective change set is empty (every given value equals the stored one, nothing
   cleared) writes no audit row and returns the unchanged resource (200). Test first on `member.updated`,
   `tenant.profile_changed` and the team/category/player PATCHes; `docs/domain/audit-events.md` row note.
2. **Ended seasons**: `AuthzSummary.staffTeamIds` / `playerTeamIds` (and `/internal/authz`) exclude teams whose
   season has ended, even while a staff row or assignment is still open; the role-matrix tests in game/athlete that
   rely on the summary must stay green (they use the fake; check the fake's contract). Contract description updated
   (core 2.8.0 together with item 3).
3. **Parents via the guardian flow get a login**: adding a guardian with an e-mail creates (or links, ADR-0025) a
   login with a temporary password returned once (`Cache-Control: no-store`), like the member flow; existing
   guardians without a login get the "issue temporary password" action on the person; audit `member.temporary_password_issued`
   (or the existing action) per academy. Contract: the guardian create response carries `temporaryPassword` (core
   2.8.0); web guardian dialog shows it once (reuse the member dialog's component). Migration `V13` only if a column
   is needed.
4. **Docs**: `docs/domain/authz-matrix.md` (guardian login row, append at the end), ADR-0024 amendment line (no new
   number), `docs/domain/audit-events.md`.

## Acceptance
- [ ] Contract 2.8.0 validated; Dart core package regenerated and committed (only yours)
- [ ] Red tests committed before each change (resource tests, authz summary, guardian flow incl. the shared-login
      case of ADR-0025/0026, widget test for the dialog)
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals); `flutter analyze` clean;
      `just web-format-check` clean; `just web-test` green (fresh; totals)
- [ ] `just mutation core-service` at or above baseline (record the score); handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. `just gen-api` regenerates every package: commit only core.
- `apps/web/lib/l10n/*.arb`: keys next to the roster/guardian keys, never at the end. Format only files you change.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
