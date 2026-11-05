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
