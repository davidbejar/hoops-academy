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
