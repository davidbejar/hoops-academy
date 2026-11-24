# WP141 — Web: the season rollover wizard sends a real source and target

Model: Opus. Runs alone (2026-11-24, after the ninth round's docs pass WP140). You own the rollover wizard
(`apps/web/lib/features/admin/presentation/seasons_screen.dart`, the seasons repository and notifier), the demo mock's
rollover handler (`apps/web/lib/core/mock/mock_core_api.dart`) and their tests; the shared file
`docs/adr/README.md`: append at the end, one entry per line. `apps/web/lib/l10n/*.arb`: add keys next to the related
feature's keys, never at the end of the file. Depends on: ADR-0015, ADR-0070. Skills: work-package, flutter-feature,
test-driven-development, systematic-debugging, verification-before-completion. Worktree:
`~/code/hoops-wt/wp141-rollover-wizard`, branch `wp141-rollover-wizard`.

Open item of WP138 part 2 (FOLLOW-UPS "Season rollover wizard"): the wizard sends the opened season as both the
rollover's target (path) and source (`fromSeasonId`); core refuses that with `ROLLOVER_SAME_SEASON`, so the wizard
works only against the demo mock. ADR-0072 reserved in case the fix needs a decision.

## Scope
1. **Facts first**: what `core.yaml` and core's `RolloverSeason` say source and target are, what the wizard sends,
   what the mock accepts. Core and the contract are the oracle and do not change (stop and report if core contradicts
   its contract).
2. **Red first, committed first**: a test that the demo mock refuses what core refuses (status and Problem code), a
   wizard test that the request carries the right source and target. Then the mock, then the wizard; the smallest
   screen change that fits the wizard and the design kit if the user has to choose a season (es / en / id).
3. **Docs**: ADR-0072 if a decision is made (line at the end of `docs/adr/README.md`), this brief's Handover.

## Acceptance
- [x] Facts established and written down (Handover)
- [x] Red tests committed before each change
- [x] `flutter analyze` clean; `just web-format-check` clean; full `flutter test` green (fresh; totals)
- [x] Real request shape shown accepted by core's own tests (no stack started)
- [x] Handover appended with what README / HANDOVER / FOLLOW-UPS / conformance need

## Working rules
- Work only in the worktree on its branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then a plain `git commit` with explicit paths, one at a time (never
  `--no-verify`). Conventional Commits, `Co-Authored-By:` the model that did the work.
- Do not start or stop the compose stack, do not read `.env`. Do not edit README.md, docs/HANDOVER.md,
  docs/wp/FOLLOW-UPS.md, docs/conformance.md, docs/roadmap.md; notes go in this file's Handover.

## Handover
- **Facts (the report was right):**
  - `core.yaml` `rolloverSeason`: "`{seasonId}` is the target season. Clones the teams of `fromSeasonId`"; 409 when
    the target already has teams; 422 listed. Core's `RolloverSeason` agrees with it (no contradiction): target from
    the path, source from the body; 422 `ROLLOVER_SAME_SEASON`, 422 `ROLLOVER_BACKWARDS` (source does not start
    before the target), 409 `ROLLOVER_TARGET_NOT_EMPTY`, 404 for an unknown season, 400 without `fromSeasonId`
    (`RolloverResourceTest.invalidRollovers`); it never creates a season. The 422 codes are named in ADR-0015, not
    in the contract (the contract names no Problem codes for this operation).
  - The wizard (`RolloverScreen` → `SeasonsNotifier.rollover` → `ApiSeasonsRepository.rollover(fromSeasonId)`) put
    the opened season in both the path and `fromSeasonId`: always `ROLLOVER_SAME_SEASON` against core. Its intro
    promised "the next season will be created".
  - The demo mock took the path as the source, ignored the body, created a season "Temporada siguiente" (2027/28)
    and cloned into it: it accepted exactly what core refuses.
- **Built** (commits on `wp141-rollover-wizard`):
  - `25f7b241` test (red): `mock_core_api_test` "rollover: the path is the target, fromSeasonId the source, and the
    mock refuses what core refuses" (422 SAME_SEASON, 422 BACKWARDS, 409 TARGET_NOT_EMPTY, 404 both ways, 400
    without `fromSeasonId`, the accepted call clones into the existing target and creates no season, a second run is
    409); wizard tests in `seasons_categories_test`: the opened season is the source and the chosen later season the
    path (the next one offered first, a past one not offered), no later season → hint and disabled run, a target with
    teams → worded 409. `season()` fixture gained optional `startsOn` / `referenceYear`.
  - `e362900b` fix: the mock's rollover follows core (path = target, the refusals above with core's status and code,
    orphans by the target's reference year and only from the source's teams, no season created). Between this commit
    and the next the four earlier rollover tests that sent the same season twice are red (expected; fixed next).
  - `af385ad1` fix: the wizard names the source in its intro and offers a **target season** dropdown (kit's
    `DropdownButtonFormField`, as `season_bar`): the seasons starting after the opened one, the next by default; none
    → `rollover-no-target` text and the run button disabled. Repository and notifier take `rollover(target,
    fromSeasonId: source)`. `ROLLOVER_TARGET_NOT_EMPTY` worded once in `AppError.message`. ARB keys
    `rolloverTarget`, `rolloverNoTarget` (after `@rolloverIntro`), `rolloverErrorTargetNotEmpty` (after
    `rolloverConfirm`), `rolloverIntro` reworded, in es / en / id. The earlier tests (wizard confirm, failing
    rollover, no orphans, notifier, mock repository) now seed the next season and send to it; no assertion removed
    or loosened (the confirm test's `fromSeasonId == seasonId` now checks a different path).
- **Real call**: not checked against the running stack or in a browser. The shape the wizard now sends
  (`POST /seasons/{later season}/rollover` with `fromSeasonId` = an earlier season) is the one core's
  `RolloverResourceTest.rolloverClonesTeamsStaffAndPlayersAndReturnsTheOrphans` and the e2e
  `JourneyTest.rolloverIntoTheNextSeasonProducesAnOrphanWhichIsResolved` (create the next season, roll the current
  one into it) accept with 200; neither was run in this package (core unchanged).
- **Verified** (fresh, 2026-11-24, in the worktree): `flutter analyze` no issues; `just web-format-check` 531 files,
  0 changed; `flutter test` **1958 passed, 0 failed** (WP138's last total 1954; +4 new tests, none removed). No golden
  re-recorded (the wizard has none).
- **Decisions/ADRs**: ADR-0072 (`199cca47`; the opened season is the source; target chosen from later seasons, the next by
  default; no later season, no rollover; a target with teams left to core's worded 409; the mock refuses like core).
- **For the docs pass** (files this package must not edit):
  - FOLLOW-UPS: "Season rollover wizard" (WP138 part 2) → Resolved by WP141 / ADR-0072.
  - HANDOVER / conformance: the rollover wizard now works against core by its contract (not browser-checked); in the
    demo a rollover needs a new season first (create 2027/28, then roll 2026/27 into it). ADR index 0072 added.
  - `apps/web/README.md` route list `/admin/seasons[/:id/rollover]` stays right (`:id` is the source).
- **Open points**:
  - The demo mock still ignores `cloneStaff` / `clonePlayers` (core with `clonePlayers=false` opens no case and
    reports every former player as an orphan with empty reasons; the mock always opens cases for over-age players)
    and its case points at the source team, core's at the copy. Not changed: outside this package's refusals; the
    wizard test unticks "copy rosters" and still sees a case, which only the mock produces.
  - The seasons list offers "Roll over" on every row, also on a season with no later season (the wizard then says to
    create one).
  - Browser check of the wizard against the real stack (owner).
