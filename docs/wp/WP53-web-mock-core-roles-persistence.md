# WP53 — Web: demo mock role-filtered core reads, COACH on staff, persistence across reloads

Model: Sonnet. Wave 2 (2026-11-06, fourth round): starts after WP52 is merged; runs alongside WP55 (`apps/web/tool`
and workflows only), WP57, WP59, WP61, WP65. You own `apps/web/lib/core/mock/*`, `apps/web/lib/core/http/
mock_api_adapter.dart`, their tests and the profile-menu entry for the reset action; nobody else edits
`apps/web/lib` this wave. `apps/web/lib/l10n/*.arb`: keys next to the profile/settings keys, never at the end.
Depends on: WP47 (its handover lists the gaps), `docs/domain/authz-matrix.md`. Skills: flutter-feature,
test-driven-development, verification-before-completion. Worktree: `~/code/hoops-wt/wp53-web-mock-roles`, branch
`wp53-web-mock-roles`.

Decision 35 of 2026-11-06: the demo mock filters core reads per role like the services, the demo COACH appears on
the staff list, and demo changes survive a reload (browser storage) with a reset action.

## Scope
1. **Core reads per role** (`mock_core_api.dart`, `mock_authz.dart`): teams, players, members, guardian links and
   approvals lists narrowed per the matrix (PARENT: linked players and their teams; PLAYER: own; COACH: staff teams;
   ADMIN: all); non-visible = 404 like the services.
2. **COACH on staff**: the demo COACH membership is a staff row of Mini A (and shown in the team staff list); a
   PARENT + PLAYER login handled fully (both visibilities union).
3. **Persistence**: mock state (the three mocks) kept in IndexedDB (the app already uses Drift/sqlite for the match
   DB; use the lighter option that needs no new heavy dependency: `shared_preferences`/`idb` already in
   `pubspec.yaml`? check; add nothing heavy) keyed by academy; loaded on start; a "Reset demo data" entry in the
   profile menu (mock mode only) that clears it. Mock tests keep using the in-memory store (an injectable backend).
4. `HOOPS_MOCK_ROLES` applies to every demo academy, not only Academia Demo.

## Acceptance
- [ ] Red tests committed first: one case per role for core reads, COACH staff, persistence round trip (save → new
      adapter → same state), reset; l10n parity green; goldens unchanged (or listed)
- [ ] `flutter analyze` clean; `just web-format-check` clean; `just web-test` green (fresh; totals);
      `tool/web_smoke.sh` mock mode green
- [ ] Handover appended: what the mock still does not mirror

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Format only the files you change; `pubspec.lock` is committed only if a dependency changes.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
