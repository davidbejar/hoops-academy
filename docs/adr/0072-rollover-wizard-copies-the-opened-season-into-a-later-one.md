# ADR-0072: The rollover wizard copies the opened season into a later one

- Status: Accepted
- Date: 2026-11-24
- Records: WP141 (open item of WP138 part 2, "Season rollover wizard")
- Related: ADR-0015 (rollover follows the contract), ADR-0070 (web tests on the seeded demo mock),
  [WP141](../wp/WP141-rollover-wizard.md)

## Context
`POST /api/core/seasons/{seasonId}/rollover` (`core.yaml`, `rolloverSeason`) takes the **target** season in the path
and the **source** in `fromSeasonId`. Core's `RolloverSeason` (ADR-0015) refuses a target equal to the source (422
`ROLLOVER_SAME_SEASON`), one that does not start after the source (422 `ROLLOVER_BACKWARDS`) and one that already
has teams (409 `ROLLOVER_TARGET_NOT_EMPTY`); it never creates a season. The web wizard, opened from a row of the
seasons list (`/admin/seasons/:seasonId/rollover`, "Pasar a nueva temporada"), sent that row's season as both, and
its intro promised that "the next season will be created". It worked only against the demo mock, which accepted the
same season twice and created a season of its own.

The wizard therefore has to name two seasons where it named one, and someone has to decide which of the two the
opened row is, and which season is chosen when the user does not choose.

## Decision
1. **The opened season is the source.** The row's action keeps the meaning its label and the old intro gave it:
   "move this season's teams on". The wizard names the source in its intro.
2. **The target is chosen in the wizard**, from the seasons that start after the source (sorted by start date). By
   default it is the **next** one (the earliest of them); the user may pick a later one. Earlier seasons and the
   source itself are never offered, so the wizard cannot send what core refuses with `ROLLOVER_SAME_SEASON` or
   `ROLLOVER_BACKWARDS`.
3. **No later season: no rollover.** The wizard says to create the next season first and the run button stays
   disabled. The wizard does not create seasons (core does not either; the season dialog does).
4. **A target with teams is left to the server**: the wizard does not read every season's teams to filter the list;
   core's 409 `ROLLOVER_TARGET_NOT_EMPTY` is worded once in `AppError.message` ("the target season already has
   teams") and the confirm step stays.
5. **The demo mock follows core** (ADR-0070): path = target, `fromSeasonId` = source, the same refusals with the same
   status and code, no season created.

## Alternatives
- **The opened season is the target** and the user picks the source (default: the season before it). It mirrors
  the path of the API, and a target with teams could be spotted on the row. Rejected: the row action and its label
  read as "move on from this season", the admin's season-end flow starts from the current season, and the follow-up
  already described the fix as "offer a target season". The route keeps its shape either way.
- **Create the target season inside the wizard** (name, dates, reference year), then roll over. One step fewer for
  the admin, but it duplicates the season dialog and its validation, and makes the wizard two writes that can fail
  half way. Not worth it for a once-a-year action.
- **Filter out targets that already have teams** (a teams read per candidate season). More reads for a rare case
  the server already refuses in words.

## Consequences
- The wizard's request matches the contract: `POST /seasons/{later season}/rollover` with `fromSeasonId` = the opened
  season, the shape core's `RolloverResourceTest` and the e2e `JourneyTest` (create the next season, roll the
  current one into it) already accept.
- In the demo (2025/26 and 2026/27, both with teams) a rollover now needs a new season first: create 2027/28 with the
  season dialog, then roll 2026/27 into it.
- The mock still ignores `cloneStaff` / `clonePlayers` (it always reports the over-age players as orphans with a
  case); that difference is outside this decision and listed in WP141's handover.
