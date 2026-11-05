# WP35 — Web UX gaps

Model: Sonnet. Wave 3: starts after WP28, WP29 and WP33 are merged (same screens, regenerated packages). Depends on:
WP14, WP14b, WP25. Skills: flutter-feature, test-driven-development, verification-before-completion. Worktree:
`~/code/hoops-wt/wp35-web-ux`, branch `wp35-web-ux`.

Decision 14 of 2026-11-05: the open web items from FOLLOW-UPS, in this order (stop and hand over if the budget runs
out; each item is its own commit pair, test first):

1. **Signed in without any academy**: `/api/core/me` answers 404 for a Keycloak user with no person / membership;
   the app shows the generic "not found" error with Retry / Sign out. Show a dedicated "You are not a member of an
   academy yet. Ask an academy administrator to add you with this e-mail: <e-mail>" state (es/en/id) with Sign out.
2. **Calendar timezone**: times are shown in the device zone; `/me` carries the tenant `timezone`; use it for
   sessions and matches (display and the date pickers' day boundaries), with the zone shown once in the screen.
3. **Usage trend chart** on the platform console: `getTenantUsageHistory` is generated and unused; a small line chart
   (fl_chart or the package already in `pubspec.yaml`; add nothing heavy) of the counters over time, with a
   loading / empty / error state.
4. **Training session**: plan picker on ad-hoc sessions and a session edit screen (`SessionDetailNotifier.edit`
   exists); edit/delete measurements and test results; update test types; edit absences — each behind the existing
   API operations only (no contract change in this WP; if an operation is missing, list it in the handover).
5. **Availability badge** in team roster rows and match setup (needs the athlete fake in those tests).
6. **Demo mock** gaps (`/api/athlete/*`, `/platform/*`) only as far as the items above need them.

## Acceptance
- [ ] Each item: failing widget test committed, then the change; l10n parity green; goldens regenerated only where
      the screen changed (list them)
- [ ] `cd apps/web && flutter analyze` clean; `just web-test` green (fresh; totals)
- [ ] Browser smoke `apps/web/tool/web_smoke.sh` in mock mode green (needs chromedriver on PATH; if absent, say so)
- [ ] Handover appended with the items done, the items left and the missing API operations

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected,
  do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- Built (all in `apps/web`, each item a red-test commit followed by the change; no contract or generated-package change):
  1. **No academy**: a 404 from `/me` shows a dedicated state (`NotAMember`, key `not-a-member`) with the sign-in e-mail
     and Sign out, no Retry; other errors keep Retry. The e-mail is the `email` claim of the access token
     (`core/auth/signed_in_email.dart`; `/me` is a 404 and carries none). Falls back to a text without e-mail.
     l10n `notMemberTitle/Body/BodyNoEmail` (es/en/id).
  2. **Academy time zone**: `/me` does NOT carry the zone (`TenantSummary` has none); it comes from the tenant profile
     (`getTenantProfile.timezone`, now in `TenantProfile.timezone`). `core/time/tenant_zone.dart` (`TenantZone`, new
     dependency `timezone` 0.11.2 with the 10-year data set) converts instants <-> academy wall clock; unknown/missing
     zone = device zone. Used by the week calendar (day grouping, "today", week start), session tiles/detail/create/edit,
     match list/create/season stats and the date pickers' "today". The zone is named once per screen (`TimezoneNote`,
     training + matches) and only when the academy zone is known. Not applied to the platform console (not tenant-scoped).
  3. **Usage trend**: `UsageTrend` on the tenant detail (`getTenantUsageHistory`, `tenantUsageHistoryProvider`): counter
     picker + the existing `GrowthChart` line chart (+ table view); loading / empty / error with retry.
  4. **Training/health**: plan picker on ad-hoc sessions; session edit dialog (`session-edit`, planned sessions, staff of
     the team); edit and delete of body measurements (new list rows) and of physical test results; edit of custom test types
     (global ones read-only); edit of planned absences.
  5. **Availability badge** (`AvailabilityBadge`) in team roster rows and match setup (information only).
  6. **Demo mock**: nothing added. The mock adapter serves no `/platform/*` and no `/api/athlete/*` at all, so the demo has
     neither the trend chart nor the training/health screens; that needs its own WP (all of those screens are unreachable in
     mock mode, so none of the items above needed it).
- Goldens regenerated: `platform_admins_1024x768.png`, `temporary_password_1024x768.png` (tenant detail page behind the
  dialog gained the trend section). No other golden changed (no zone in golden fixtures).
- Verified (fresh): `flutter analyze` no issues; `flutter test` 587 passed, 0 failed (l10n key parity test included);
  `apps/web/tool/web_smoke.sh` (mock mode, chromedriver present) "All tests passed".
- Navigation: none changed (no router, shell or destination edits), so WP34's Activity screen will not conflict.
- Missing / limiting API operations (for a contract WP):
  - `UpdateTrainingSessionRequest` cannot clear `planId`, `location` or `notes` (null = unchanged): a plan cannot be detached
    and a location emptied in the edit dialog is not sent as cleared. Same for the other `Update*Request`s used here (e.g.
    absence reason, result notes, measurement values: a value can be changed but not removed).
  - `/me` memberships carry no tenant `timezone`; the app needs the extra profile call.
  - No operation to change the role-less "not a member" state (by design: an admin must add the e-mail).
- Left out: mock-mode support for platform/athlete (item 6); editing the test-type code (not in the contract); delete of
  test types.
- Notes: `AvailabilityBadge` is imported from `features/health` into roster and match (cross-feature import; the health
  module is a deferred library, so the badge code now loads with roster/match: move it to `core/ui` if that matters).
  Existing tests adjusted only for layout: `test types` create test uses a 360x1200 viewport (rows grew with the edit
  button). Commits carry the brief's `Co-Authored-By: Claude Fable 5.1` line.
