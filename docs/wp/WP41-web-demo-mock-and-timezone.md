# WP41 — Web: demo mock for platform and athlete, academy time zone from `/me`

Model: Sonnet. Wave 2 (2026-11-06): starts after WP38 and WP39 are merged (regenerated core and athlete packages,
new athlete operations). Depends on: WP35 (its handover), WP38, WP39. Skills: flutter-feature,
test-driven-development, verification-before-completion. Worktree: `~/code/hoops-wt/wp41-web-mock`, branch
`wp41-web-mock`.

Decisions 19 and 21 of 2026-11-06: the demo (mock mode) must reach every screen, including the platform console and
the training / health screens; the academy time zone comes from `/me`, without the extra tenant-profile call.

## Scope
1. **Time zone from `/me`** (web only, no contract change): `Me.memberships[].authz.timezone` already carries the
   IANA zone of each academy (core.yaml `AuthzSummary.timezone`, required); WP35 took it from `getTenantProfile`
   instead. Make `tenantZoneProvider` (`apps/web/lib/features/tenant/application/tenant_providers.dart`) read the
   current membership's `authz.timezone` and drop the profile dependency; keep the device-zone fallback. Test
   first; no golden should change.
2. **Demo mock** (`apps/web/lib/core/mock/mock_core_api.dart`, `apps/web/lib/core/http/mock_api_adapter.dart`):
   serve `/platform/*` (tenants list/detail/usage history/admins/audit, enough for the console screens) and
   `/api/athlete/*` (schedules, sessions, attendance, absences, plans, injuries, measurements, test types, results,
   norms) with a small coherent data set for the demo academy, every operation the screens call, including the WP39
   `clear` semantics and test-type rename/delete, and the super admin's view of the platform audit list. Shape the
   data so the screens show something (a week of sessions, two injuries, a few test results, a usage history of a
   few months). Mock responses must validate against the generated models (the typed clients parse them: a test that
   calls every mock route through the generated client and asserts a 2xx parse is the cheapest guard).
3. **Browser smoke**: extend `apps/web/tool/web_smoke.sh` (mock mode) with one step through the platform console
   and one through training, if chromedriver is on PATH; if not, say so.
4. Items not in scope: new screens, contract changes, real-mode behaviour.

## Acceptance
- [ ] Red test committed before each change; l10n parity green; goldens regenerated only where a screen changed
      (list them)
- [ ] `cd apps/web && flutter analyze` clean; `just web-test` green (fresh; totals)
- [ ] `apps/web/tool/web_smoke.sh` in mock mode green (or chromedriver absence stated)
- [ ] Handover appended with the mock routes added and anything still unreachable in mock mode

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- Built (all in `apps/web`; no contract, service or generated-package change):
  1. **Time zone from `/me`**: `TenantMembership.timezone` (from `authz.timezone`); `tenantZoneProvider` reads the current
     membership in the session and no longer depends on `tenantProfileProvider` (device-zone fallback kept). Tests: the two
     zone tests in `tenant_timezone_test.dart` now set the zone on the membership (`pumpAs(timezone:)`), `mock_mode_test`
     asserts `Europe/Madrid` without a profile call. `FakeTenantRepository.timezone` removed.
  2. **Demo mock** (`lib/core/mock/mock_platform_api.dart`, `mock_athlete_api.dart`, helper `mock_query.dart`, wired in
     `core/http/mock_api_adapter.dart`). The demo user is now a super admin by default
     (`--dart-define=HOOPS_MOCK_SUPER_ADMIN=false` turns it off) so the profile menu opens the platform console.
     - `/platform/*` (super admin only, else 403): tenants list (status, q) / create (temporary password once) / get /
       patch / suspend / reactivate / withdraw (retainUntil); admins list / add / patch / delete / temporary-password /
       resend-invitation (409 `INVITATION_NOT_PENDING`, `TENANT_WITHDRAWN`); usage; usage history (6 snapshots over four
       months, one partial); audit-events (paged, tenantId / action / from / to filters, platform actor unmasked).
       Data: Academia Demo, Club Norte, Academia Sur (suspended).
     - `/api/athlete/*` (demo academy only, others 404): training-schedules, training-sessions (+ cancel, attendance
       GET/PUT with absence and injury overlay, LATE needs minutes), planned-absences, training-plans (+ `:copy`,
       `:archive`, `:unarchive`, items add / update / delete / reorder; templates read-only), plan-assignments (+ progress,
       completions PUT), plan-completions, injuries, players/{id}/availability, body-measurements, physical-test-types
       (create, rename code with 409, delete incl. `TEST_TYPE_HAS_RESULTS` 409, global = 404), physical-test-results (band
       computed from norms at read time), physical-test-norms (EFFECTIVE / GLOBAL / TENANT, create, replace, delete). Every
       update honours the WP39 `clear` list (400 if a property is both given and cleared). Seed: two weeks back and three
       weeks ahead of sessions for Mini A and Infantil A, attendance on finished ones, 2 absences, 1 template-copy plan +
       2 templates, 2 injuries (one open), 5 measurements, 3 test types with norms, 6 results.
  3. **Browser smoke**: `integration_test/journey_smoke_test.dart` (run by `tool/web_smoke.sh`) now continues after the
     match event with the training week calendar and the platform console (profile menu -> tenant list -> tenant detail).
- Verified (fresh): `flutter analyze` no issues; `just web-test` 646 passed, 0 failed (l10n parity included);
  `tool/web_smoke.sh` mock mode (chromedriver at /opt/homebrew/bin) "All tests passed". Guard test:
  `test/core/mock_athlete_platform_api_test.dart` (18 tests) calls every route through the generated clients and the
  repositories; `test/app/mock_mode_test.dart` has a second test that opens training, plans, absences, assignments, player
  health, test types, norms, platform list / detail (with the usage trend) and activity in the full app.
- Goldens changed: none.
- Still unreachable or simplified in mock mode: `/api/athlete` serves the demo academy only (Club Norte is PARENT with no
  data); no role-based authorization in the athlete mock (a PARENT/PLAYER sees what the screens show, the real service
  filters); team rosters in the athlete mock are fixed (Mini A: Ana, Leo; Mini B: Mía; Infantil A: Dani), not read from
  the core mock, so new players added in the demo do not appear in attendance sheets; the game mock's roster ids differ
  from the athlete ones; `updateTenant` (PATCH) exists in the mock but no screen calls it; no `/internal/usage`.
- Open points: the new mock files were formatted with `dart format -l 120` (long, unjoined lines); the repo's own
  mock files use long lines, a repo-wide `dart format` policy is not decided. Commits carry the brief's Fable 5.1 line.
