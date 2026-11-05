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
