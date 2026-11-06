# WP48 — Web: injury edit dialog

Model: Sonnet. Wave 1 (2026-11-06, third round): runs alongside WP43 (Java), WP46 (deploy/) and WP50 (workflows);
you are the only agent in `apps/web` this wave. Depends on: WP35, WP39 (`UpdateInjuryRequest.clear`), WP41.
Skills: flutter-feature, test-driven-development, verification-before-completion. Worktree:
`~/code/hoops-wt/wp48-web-injury-edit`, branch `wp48-web-injury-edit`.

Decision 29 of 2026-11-06: injuries can be edited in the app (today: create and close only).

## Scope
1. On the player health screen (`apps/web/lib/features/health/presentation/player_health_view.dart` and friends) an
   edit action per injury opens a dialog with the fields `UpdateInjuryRequest` offers (read the generated model in
   `apps/web/packages/athlete`); emptied optional fields go into `clear` (ADR-0032); the mock
   (`mock_athlete_api.dart`) already honours `clear`.
2. Roles per `docs/domain/authz-matrix.md` (who may edit an injury): the action is shown only to them; the server
   re-checks.
3. l10n es/en/id (keys next to the health keys); widget tests first (dialog opens with current values, submit sends
   the right request incl. `clear`, validation errors); golden only if the health screen layout changed (list it).

## Acceptance
- [ ] Red test committed first; l10n parity green
- [ ] `flutter analyze` clean; `just web-test` green (fresh; totals)
- [ ] Handover appended (fields editable, fields clearable, anything the contract lacks)

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not run `dart format` on files you did not change (WP49 reformats the whole app later).
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- Built: `InjuryEditDialog` (player_health_view.dart) behind an "Edit injury" button (`injury-edit-<id>`) on every injury card (open and recovered), shown only when `canWriteHealth` (ADMIN, COACH, ASSISTANT_COACH, linked PARENT; PLAYER read-only, per authz-matrix); `InjuriesNotifier.edit`; l10n `injuryEdit`, `injuryReturnBeforeInjury` (es/en/id).
- Fields editable: body part (required), severity, injury date, description, expected return, actual return (only on recovered injuries). `status` is not in the dialog (the existing "Mark recovered" action owns it). Description, expected return and (recovered) actual return are clearable; empty ones are named in `clear` via `clearList` (project convention, also when they were already empty). Return dates before the injury date are rejected client-side.
- Verified: `flutter analyze` no issues; `flutter test` (full, fresh) 651 passed, 0 failed. Red tests committed first (5 new widget tests in test/features/health/health_test.dart; fake_athlete `updateInjury` now honours all fields and `clear`).
- Goldens: none changed (no golden covers the injury card; none regenerated).
- Open points: the contract does not let the edit reopen a recovered injury (status transitions stay with the recover action); `dart format` deliberately not run (WP49).
