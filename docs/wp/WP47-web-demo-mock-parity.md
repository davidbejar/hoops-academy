# WP47 — Web: demo mock parity (shared rosters, role filtering)

Model: Sonnet. Wave 3 (2026-11-06, third round): starts after WP44 and WP45 are merged (final contracts and mocks
for core and game). You own `apps/web/lib/core/mock/*`, `apps/web/lib/core/http/mock_api_adapter.dart` and their
tests; nobody else edits `apps/web` in this wave. Depends on: WP41 (its handover lists the gaps), WP44, WP45,
`docs/domain/authz-matrix.md`. Skills: flutter-feature, test-driven-development, verification-before-completion.
Worktree: `~/code/hoops-wt/wp47-web-mock-parity`, branch `wp47-web-mock-parity`.

Decision 28 of 2026-11-06: the demo mock behaves like the services for every role, not only for the super admin.

## Scope
1. **One roster source**: the athlete and game mocks read teams, players and assignments from the core mock
   (`mock_core_api.dart`), so a player added or moved in the demo appears in attendance sheets, match setup and
   health screens; the ids match across the three mocks.
2. **Role filtering**: the mocks apply `docs/domain/authz-matrix.md` for the demo memberships (ADMIN, COACH,
   ASSISTANT_COACH, PARENT, PLAYER): a PARENT sees only linked players' sessions, attendance, health and the filtered
   match feed (ADR-0030); a PLAYER their own; COACH staff teams; non-members 404 as the services do. The demo needs a
   way to exercise each role: use the existing memberships (Club Norte PARENT; add a PLAYER and a COACH membership to
   the demo data if missing) and the existing academy switcher; no new screens.
3. **Every academy**: `/api/athlete/*` and `/platform/*` data exists for each demo academy the user can switch to
   (small sets are fine), not only Academia Demo.
4. **Tests**: extend `mock_athlete_platform_api_test.dart` and `mock_mode_test.dart` with one case per role that
   asserts what is visible and what is 404/403, mirroring the matrix rows; browser smoke `tool/web_smoke.sh` extended
   with one role switch if cheap.

## Acceptance
- [ ] Red tests committed first; l10n parity green (no new keys expected); goldens unchanged (or listed)
- [ ] `flutter analyze` clean; `just web-test` green (fresh; totals); `tool/web_smoke.sh` mock mode green
- [ ] Handover appended: what the mock still does not mirror

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not run `dart format` on files you did not change (WP49 reformats the whole app after you).
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.
