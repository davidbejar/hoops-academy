# WP45 — Game adopts the `clear` list (ADR-0032)

Model: Sonnet. Wave 2 (2026-11-06, third round): starts after wave 1 is merged; runs alongside WP44 (core). You own
`libs/contracts/openapi/game.yaml`, `apps/web/packages/game`, `services/game-service`, the web match feature's edit
dialog and the game part of the demo mock (`apps/web/lib/core/mock/` game file; not `mock_core_api.dart`). In the
shared contracts test `UpdateRequestClearListContractTest` add the game entry as the LAST line of the list (WP44
owns the file and adds core above it). `apps/web/lib/l10n/*.arb`: keys next to the match keys, never at the end.
Depends on: WP39 (ADR-0032, the athlete implementation to mirror). Skills: quarkus-hexagonal-service,
flutter-feature, test-driven-development, verification-before-completion. Worktree:
`~/code/hoops-wt/wp45-game-clear`, branch `wp45-game-clear`.

Decision 26 of 2026-11-06: every service follows ADR-0032 (null = unchanged, `clear` names the fields to empty).

## Scope
1. **Contract** (`game.yaml`, minor bump 2.1.0 → 2.2.0): `clear` on `UpdateMatchRequest` for its optional
   nullable-in-storage properties (venue, notes, opponent details… whatever the schema has; list them). `./mvnw -pl
   libs/contracts verify`, `just gen-api`, commit only `apps/web/packages/game`.
2. **Service**: mirror WP39's `PatchBody` handling (400 `CLEAR_CONFLICT`, null = unchanged); switch any test that
   relied on null-clears. Test first.
3. **Web**: the match edit dialog sends `clear` for emptied optional fields; the game mock honours it. Widget test
   first; goldens only if a screen changed.
4. **Docs**: ADR-0032 "Adoption" line for game (WP44 adds core's; put yours on its own line to avoid a conflict).

## Acceptance
- [ ] Contract 2.2.0 validated; Dart game package regenerated and committed
- [ ] Red tests committed before each change
- [ ] `./mvnw -B -ntp -pl services/game-service -am verify -Dquarkus.http.test-port=0` green (totals) and
      `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals); `flutter analyze` clean;
      `just web-test` green (fresh; totals)
- [ ] `just mutation game-service` at or above baseline (record the score)
- [ ] Handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- Built:
  - Contract game **2.2.0**: `clear` (enum `[venue]`) on `UpdateMatchRequest`. `venue` is the only optional nullable-in-storage
    property of the only update request in game.yaml (opponentName, homeAway, scheduledAt, periodCount, periodMinutes are
    not null in storage). `UpdateRequestClearListContractTest`: `game` appended last to `ADOPTED` (now one entry per
    line, so WP44 adds `core` above it) plus one game test at the end of the file. Dart package `apps/web/packages/game`
    regenerated; generator whitespace-only noise reverted, core/athlete regenerations not committed.
  - game-service: `UpdateMatchRequest.clearedProperties()` validates `clear` (non-list, unknown/non-clearable, duplicate:
    400 `INVALID_VALUE` on `clear`; value plus `clear`: 400 `CLEAR_CONFLICT`); `venue: null` is now unchanged. New
    `InvalidRequestException` + `GameExceptionMappers` (problem+json with a violation code). `[]` alone is an empty patch (400).
  - Web: there was no match edit dialog in the app (only create), so none was changed. `MatchesRepository.update` (full-form,
    sends `clear` for an emptied venue via `clearList`) is the ready hook; the demo mock (`mock_game_api.dart`) now answers
    `PATCH` with the ADR-0032 semantics. No screen changed, no goldens changed.
  - ADR-0032 "Adoption" line for game.
- Verified: `./mvnw -pl libs/contracts verify` green; `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` fresh,
  BUILD SUCCESS (game-service 259 tests, 0 failures; module totals 154, 186, 259 (game-service), 653, 773, e2e 25
  with 21 skipped by design); `flutter analyze` no issues; `flutter test` 653 passed; `just mutation game-service`
  399/401 killed (99.5 %), equal to the baseline.
- Decisions/ADRs: ADR-0032 adoption line only.
- Open points: a UI to edit a match (opponent, date, venue) does not exist yet; wire it to `MatchesRepository.update`
  (the request already clears the venue). Seeded `pubspec.lock` drift from flutter was reverted, not committed.
