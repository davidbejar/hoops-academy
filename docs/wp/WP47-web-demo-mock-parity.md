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

## Handover
- Built (all in `apps/web`, mocks and their tests only):
  1. **One roster source per academy**: `MockCoreApi` owns teams, players, assignments and guardian links; the athlete and
     game mocks read rosters, names, birth years, genders and jerseys from it (`rosterOf`, `playerFacts`), so a player added,
     moved or withdrawn in the demo shows up (or goes) in attendance sheets, norm bands and match rosters; ids match across
     the three mocks. Mini A now has 7 players (the game mock's former extra players p-sara, p-iker, p-noa, p-hugo, p-lia
     moved into the core seed).
  2. **Role filtering** via `lib/core/mock/mock_authz.dart` (`MockCoreApi.authz`, computed from roles + live roster + links):
     ADMIN all; COACH / ASSISTANT_COACH their staff team (sessions, attendance, health writes; other teams' players 404);
     PARENT the linked players' team sessions, their absences / injuries / measurements (write), results read-only, no
     attendance (403); PLAYER himself (reads own health, records own absences and completions only); test types and norms
     write ADMIN only; plans / schedules / sessions / assignments write staff only. Not visible = 404, visible but not allowed
     = 403. Game mock: matches of visible teams only, feed (ADR-0030), box score and season stats limited to linked / own
     players for non-managers, PLAYER cannot enter events. Core mock: members, guardian links, audit trail ADMIN only;
     tenant / seasons / categories writes ADMIN; approvals decisions ADMIN; assigning players ADMIN or the team's staff.
  3. **Every academy**: Club Norte now has its own core, athlete and game data (team Norte A with 5 players, sessions,
     attendance, absences, an open injury, measurements, results, three matches); the demo user is PARENT there, linked to
     Nora Vega. `/me` authz (staff / linked / player team ids) is computed from the same data. Platform usage / history /
     audit already existed per academy and is now asserted for both.
  4. **Roles to exercise**: `HOOPS_MOCK_ROLES` still switches the roles in Academia Demo (PLAYER = Leo Gil, PARENT = Ana Ruiz,
     COACH = staff of Mini A); Club Norte is the PARENT case through the existing switcher. No extra membership added.
- Verified (fresh): `flutter analyze` no issues; `just web-test` 668 passed, 0 failed (l10n parity included);
  `tool/web_smoke.sh` mock mode "All tests passed". Red tests committed first (`b6d2305`, 9 failing). New cases:
  `mock_athlete_platform_api_test.dart` group "WP47" (shared roster, ADMIN, COACH, ASSISTANT_COACH, PARENT, PLAYER, game
  feed per role, Club Norte, platform per academy, non-member 404) and `mock_mode_test.dart` (Norte training week and the
  parent's hub; the test overrides the match store with an in-memory one because the Norte parent now lands on a match
  list). Two counts in `mock_core_api_test.dart` changed 2 -> 7 (Mini A roster).
- Goldens changed: none.
- Decisions/ADRs: none. Smoke not extended with a role switch (the app has one login per run; the widget test covers it).
- Still not mirrored: core reads are not role-filtered (teams / players lists show everything to PARENT / PLAYER, the
  service may narrow them); COACH staff of the demo is always Mini A (the staff list does not include the demo user);
  PARENT + PLAYER on one login is only partly handled; plan completions and assignment progress filter by visible players
  but not by "team" for a coach of another team beyond that; no tenant-status (suspended) behaviour for tenant APIs;
  `HOOPS_MOCK_ROLES` still applies to Academia Demo only; no `/internal/usage`; mock new matches / players are not
  persisted across reloads.
