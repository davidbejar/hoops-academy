# WP101 — Web: jersey preference and assignment dialogs, roster and audit export buttons

Model: Sonnet · effort medium. Wave 3 (2026-11-10, sixth round): starts after WP96, WP97 and WP99 are merged; runs
alongside WP100 (chart and kind only). You own `apps/web/lib/features/roster/**`,
`apps/web/lib/features/my_players/**`, the player part of `apps/web/lib/features/profile/**`
(`me_player_screen.dart`), the export buttons in `apps/web/lib/features/audit/**`, in the platform audit trail
screen and on the team screen, `apps/web/packages/core` (regenerate with `scripts/gen-api.sh core` only, to core
3.5.0), the core part of `apps/web/lib/core/mock`, their tests and goldens. `apps/web/lib/l10n/*.arb`: keys next to
the related feature's keys, never at the end. `apps/web/pubspec.lock`: only the core package bump. Depends on:
decisions 67, 68, 70; WP96's handover (endpoint shapes, audit actions); WP97 (`lib/core/export`: reuse its download
adapter, file-name rule and export menu; do not copy them). Skills: flutter-feature, clean-code,
test-driven-development, verification-before-completion. Worktree: `~/code/hoops-wt/wp101-web-jersey-exports`,
branch `wp101-web-jersey-exports`.

## Scope
1. **Preferred number**: shown on the player; edited by ADMIN and COACH on the player screen, by a PARENT for a
   linked player (`my_players`) and by a PLAYER for the own player (`me_player_screen`), labelled as a wish for the
   last two; `clear` removes it (ADR-0032). Validation `^[0-9]{1,2}$`.
2. **Assignment**: after assigning a player the dialog tells which rule applied (`jerseySource`): the requested
   number, the preferred one, the previous team's one, or none, and when none was free it says so and offers
   `JerseyDialog` at once. `JerseyDialog` shows the taken numbers with their players and the free ones
   (`GET /teams/{teamId}/jersey-numbers`); a 409 clash names the player holding the number.
3. **Roster export** (team screen; ADMIN and the team's COACH only, hidden for everyone else): downloads the
   server's CSV through the generated client with the app's language; an error Problem is shown as the other
   screens show errors; offline the button is disabled with a hint (the export is server-side).
4. **Audit log export** (academy audit screen and platform audit trail): the server's CSV with the filters the
   screen has; the "more than 10,000 rows" Problem asks the user to narrow the range.
5. **Audit labels** for `team.roster_exported` and `audit.exported` in es / en / id (the test of WP95 that every
   action has a label must stay green).
6. Mock parity for the new operations; es / en / id; goldens for the dialogs and the buttons.

## Acceptance
- [ ] Red tests committed before each change; role visibility tests for the two export buttons and the wish edit
- [ ] Dart core package 3.5.0 regenerated and committed (only yours)
- [ ] `flutter analyze` clean; `just web-format-check` clean; `just web-test` green (fresh; totals)
- [ ] Handover appended: what the admin, coach, parent and player guides must say

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the line
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Never restart the Podman machine or its API service, never
  run `just down` or remove volumes: other agents use the same VM and compose stack.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/guides; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words: what was built, the
  fresh verification totals, versions and ADRs, open points, anything another WP must know.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
