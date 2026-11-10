# WP101 — Web: jersey preference and assignment dialogs, roster and audit export buttons

Model: Sonnet · effort medium. Wave 3 (2026-11-10, sixth round): starts after WP96, WP97 and WP99 are merged; runs
alongside WP100 (chart and kind only). You own `apps/web/lib/features/roster/**`,
`apps/web/lib/features/my_players/**`, the player part of `apps/web/lib/features/profile/**`
(`me_player_screen.dart`), the export buttons in `apps/web/lib/features/audit/**`, in the platform audit trail
screen and on the team screen, `apps/web/packages/core` (regenerate with `scripts/gen-api.sh core` only, to core
3.5.0), the core part of `apps/web/lib/core/mock`, their tests and goldens. `apps/web/lib/l10n/*.arb`: keys next to
the related feature's keys, never at the end. `apps/web/pubspec.lock`: only the core package bump. Depends on:
decisions 67, 68, 70; WP96's handover (endpoint shapes, audit actions); WP97 (`lib/core/export`: reuse its download
adapter, file-name rule and export menu; do not copy them). Skills: flutter-feature, clean-code,
test-driven-development, verification-before-completion. Worktree: `~/code/hoops-wt/wp101-web-jersey-exports`,
branch `wp101-web-jersey-exports`.

## Scope
1. **Preferred number**: shown on the player; edited by ADMIN and COACH on the player screen, by a PARENT for a
   linked player (`my_players`) and by a PLAYER for the own player (`me_player_screen`), labelled as a wish for the
   last two; `clear` removes it (ADR-0032). Validation `^[0-9]{1,2}$`.
2. **Assignment**: after assigning a player the dialog tells which rule applied (`jerseySource`): the requested
   number, the preferred one, the previous team's one, or none, and when none was free it says so and offers
   `JerseyDialog` at once. `JerseyDialog` shows the taken numbers with their players and the free ones
   (`GET /teams/{teamId}/jersey-numbers`); a 409 clash names the player holding the number.
3. **Roster export** (team screen; ADMIN and the team's COACH only, hidden for everyone else): downloads the
   server's CSV through the generated client with the app's language; an error Problem is shown as the other
   screens show errors; offline the button is disabled with a hint (the export is server-side).
4. **Audit log export** (academy audit screen and platform audit trail): the server's CSV with the filters the
   screen has; the "more than 10,000 rows" Problem asks the user to narrow the range.
5. **Audit labels** for `team.roster_exported` and `audit.exported` in es / en / id (the test of WP95 that every
   action has a label must stay green).
6. Mock parity for the new operations; es / en / id; goldens for the dialogs and the buttons.

## Acceptance
- [ ] Red tests committed before each change; role visibility tests for the two export buttons and the wish edit
- [ ] Dart core package 3.5.0 regenerated and committed (only yours)
- [ ] `flutter analyze` clean; `just web-format-check` clean; `just web-test` green (fresh; totals)
- [ ] Handover appended: what the admin, coach, parent and player guides must say

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the line
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Never restart the Podman machine or its API service, never
  run `just down` or remove volumes: other agents use the same VM and compose stack.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/guides; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words: what was built, the
  fresh verification totals, versions and ADRs, open points, anything another WP must know.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
- **Built** (red tests committed before each slice; `apps/web` only):
  - **Core Dart package 3.5.0** regenerated with `scripts/gen-api.sh core` (`pubspec.lock`: only that bump).
  - **Data**: `TeamsRepository.assign` answers `AssignedTeamPlayer` (`jerseySource`), `jerseyNumbers`, `exportRoster`;
    `PlayersRepository.setPreferredJersey` (`clear` for empty); `AuditRepository.exportAcademy` / `exportPlatform`.
    `AppError.fromResponse` now reads a Problem that arrives as bytes (the exports are requested as bytes, so
    `EXPORT_TOO_LARGE` would otherwise be lost; touches `lib/core/errors`, one function, tested).
  - **Preferred number**: `PreferredJerseyCard` on the player screen (ADMIN, COACH edit; ASSISTANT_COACH reads only)
    and in `PlayerHub` (PARENT of a linked player, PLAYER for himself: titled "wish", with the hint that the coach
    decides). Dialog validates `^[0-9]{1,2}$`, empty clears (ADR-0032). Rights in `roster/application/roster_rights.dart`.
  - **Assignment**: team screen and player screen show an outcome dialog with the rule (requested / preferred /
    previous); for `NONE` the `JerseyDialog` opens at once with the explanation. `JerseyDialog` (moved to
    `jersey_dialog.dart`, now takes `teamId` / `playerId`) lists taken numbers with their players and the free ones
    (0-99, tap to fill), refuses a taken number naming the holder, and after a 409 re-reads the list and names the holder.
  - **Exports**: new `lib/core/export/server_csv_export.dart` (`ServerCsvExportButton`; reuses `exportFileName`,
    `fileDownloaderProvider`, `exportDay`): app language in `Accept-Language`, offline = disabled with a hint, Problems
    through `AppError`, `EXPORT_TOO_LARGE` asks to narrow the filters. Roster button in the team screen app bar for
    ADMIN and the team's COACH (also a former coach of an ended season); audit button in `AuditLogView` (academy audit
    and platform audit trail, with the screen's filters, not the page).
  - **Labels**: `auditActionTeamRosterExported`, `auditActionAuditExported`, `auditTargetTeam` (+ icon) in es / en / id;
    the "one distinct label per action" test stays green.
  - **Mock parity** (`mock_core_api.dart`, `mock_platform_api.dart`, `mock_api_adapter.dart`): `PATCH /players/{id}`,
    `jerseySource` with the carry-over rule, 409 on a taken requested number, `GET /teams/{id}/jersey-numbers`,
    the three `:export` operations (CSV with BOM, `Content-Disposition`, `no-store`, language, 403/404 rules).
- **Verified** (fresh, last commit): `flutter analyze` no issues; `dart format --output=none --set-exit-if-changed lib test
  integration_test tool` 444 files, 0 changed; `flutter test` (= `just web-test`) **1435 passed, 0 failed** (1372 on main
  before). `tool/offline_cold_start.sh`: **OK** (212 files precached, landing and live match render offline).
  `tool/excel_on_demand_check.py` not run (not touched). Not run: anything against the real stack or a browser export.
- **Goldens**: new `jersey_dialog_360x780` (+ `_dark`, `_1024x768`), `assignment_outcome_360x780`,
  `assignment_none_360x780`, `preferred_jersey_wish_360x780`. Re-recorded (export icon / preferred card now shown):
  `team_detail_360x780`, `player_detail_360x780`, `audit_activity_{360x780,360x780_dark,1024x768}`. Landing screenshots
  (`assets/landing/*`) not recaptured.
- **Decisions/ADRs**: none (ADR-0048 covers the server side). Roster export button uses the team name in the file name.
- **User guides must say**:
  - *Admin*: the preferred number is set on the player screen ("Preferred jersey number"); when assigning a player the
    app says which rule chose the number (requested, preferred, the previous team's, none) and, if none, opens the
    number picker with the taken and free numbers; a taken number names its holder. The team screen has a download
    icon (roster CSV, with guardians and staff, in the app language, needs a connection); the activity screen has one
    too (CSV of everything the filters select, at most 10,000 rows: narrow the dates or actions otherwise).
  - *Coach*: same preferred number and assignment behaviour for the teams; roster export only for own teams (also past
    seasons); assistant coaches see the preferred number but cannot change it and have no export.
  - *Parent*: "My players" shows "Jersey number wish" for each linked child, editable, empty removes it; it is a wish,
    the coach decides and uses it if free when the child joins a team.
  - *Player*: "Me" shows the same wish for himself.
- **Open points**: (1) the 409 message names the holder only from the re-read taken list (the server's Problem text is
  not used); (2) the audit `team` target shows the type "Team" without a name until core resolves team names (WP96
  open point); (3) mock roster/audit CSVs have only a few columns, not the full ADR-0048 layout; (4) the 10,000-row
  Problem cannot be provoked in the demo mock (covered by a widget test with a fake); (5) `Capabilities` unchanged:
  the new rights are extensions in `roster_rights.dart`.
