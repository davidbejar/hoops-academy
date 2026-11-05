# WP28 — Web bugs: PLAYER's own line in the live box score; REJECTED player label

Model: Sonnet. Depends on: WP14, WP17. Skills: flutter-feature, test-driven-development,
verification-before-completion. Worktree: `~/code/hoops-wt/wp28-web-bugs`, branch `wp28-web-bugs`.

Two small defects in `apps/web`, both from the WP20 review.

## Scope
1. **Own line in the live box score.** `lib/features/match/domain/scoring_rights.dart:35`
   `canSeeLine(playerId) => staff || linkedPlayerIds.contains(playerId)` ignores the viewer's own player. The server
   already returns a PLAYER's own line, and `lib/core/session/capabilities.dart` knows `ownPlayerId` and has
   `isSelf(playerId)`. A PLAYER must see their own line (and still no other player's). Write the failing test first
   (scoring rights unit test + the box-score widget test for a PLAYER session), then fix.
2. **REJECTED label.** `lib/core/ui/labels.dart:56` maps `PlayerStatus.REJECTED` to `statusWithdrawn`. Add
   `statusRejected` to `app_es.arb` (template), `app_en.arb`, `app_id.arb` ("Rechazado" / "Rejected" / "Ditolak"),
   run `flutter gen-l10n`, map it, and fix the label test. Check the roster / player screens that render the status
   for a golden that changes; regenerate only the affected goldens and say which.

## Acceptance
- [ ] Failing tests committed before each fix (TDD, two commits each: `test(web): …` then `fix(web): …`)
- [ ] `cd apps/web && flutter analyze` clean, l10n parity test green, `just web-test` green (fresh run; total count
      in the handover)
- [ ] No change outside `apps/web` (generated packages untouched)
- [ ] Handover appended

## Working rules (all WPs of this wave)
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Other agents work in parallel in sibling worktrees; another one (WP35) will later build on your branch, so keep
  the changes minimal and local.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected,
  do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md (WP26 owns them); notes go in this file's Handover.
- Finish per the `work-package` skill: fresh full verification, checklist with evidence, `## Handover` appended.
- Final report to the orchestrator, at most 300 words: built, verified (commands and numbers), left out and why.

## Handover
- Built: `ScoringRights` gained `ownPlayerId` (set from `Capabilities` only when `isSelf`), so `canSeeLine` lets a PLAYER see their own line and no other (box score and share text; `canScore`/`canRecordFor` unchanged). `PlayerStatus.REJECTED` now maps to new `statusRejected` (es "Rechazado", en "Rejected", id "Ditolak"); `flutter gen-l10n` regenerated `lib/l10n/gen`.
- Tests (each committed red before the fix): `scoring_rights_test.dart` (PLAYER own line), `match_screens_test.dart` (PLAYER box score widget test), new `test/core/labels_test.dart` (all statuses distinct, REJECTED in 3 languages).
- Verified: `flutter analyze` no issues; `flutter test` full run 541 tests, 540 pass, 1 fails. The failure, `test/golden/training_health_golden_test.dart` "week calendar, ADMIN, 360x780" (1.61 % pixel diff), also fails without my changes (checked via git stash), so it is pre-existing and unrelated (training week calendar). l10n parity test green. No golden affected by this WP, none regenerated. Nothing changed outside apps/web (plus this file).
- Open points: the training week golden is red on this branch base; needs its own fix (possibly date-dependent).
