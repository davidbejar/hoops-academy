# WP97 — Web: browser-built exports (player stats, box score, team calendar)

Model: Sonnet · effort high. Wave 2 (2026-11-10, sixth round): starts after wave 1 is merged; runs alongside WP99
(it owns `features/platform`, `features/profile`, `app/router.dart`, `app/shell.dart`, the core Dart package and the
core mock), WP96 (core), WP98 (game, athlete, common). You own `apps/web/lib/core/export/**` (new),
the export buttons and their tests and goldens in `apps/web/lib/features/match/**` and on the sessions list of
`apps/web/lib/features/training/**` (WP92 is merged), the new dependency in `apps/web/pubspec.yaml`, and the
precache exclusion for the deferred part. `apps/web/lib/l10n/*.arb`: keys next to the related feature's keys, never
at the end. `apps/web/pubspec.lock`: you commit the lines of your new dependency; WP99 commits the core package
bump (the orchestrator resolves the overlap). No contract changes: you build every file from JSON the app already
loads. Depends on: decisions 67, 68, 69; the generated game and athlete clients as they are on `main`. Skills:
flutter-feature, owasp-security (formula injection), test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp97-web-browser-exports`, branch
`wp97-web-browser-exports`.

## Scope
1. **Pure builders first** (`lib/core/export`, no Flutter imports, unit-tested before anything else): a table model
   (headers, typed cells), `CsvWriter`, `IcsWriter`, `XlsxWriter`, the formula-injection guard and the file-name
   rule, all per the spec below.
2. **XLSX on demand** (decision 69): choose a maintained pure-Dart package with a permissive licence (no Node, no
   JS interop bundle); reach it only through `import '...' deferred as xlsx;` and `await xlsx.loadLibrary()` when
   the user picks Excel. Prove it: a test or script over `flutter build web` output that the main bundle does not
   contain the library and that a deferred part does; leave that part out of the service worker precache. When it
   cannot be loaded (offline, first use) show a message and keep CSV available.
3. **Download**: one small web adapter (Blob + anchor through `package:web`), behind an interface so widget tests
   use a fake.
4. **Player stats** (`season_stats_screen`): one row per match plus the season totals; CSV and XLSX.
5. **Box score** (match screen): both teams, every player line, team totals; CSV and XLSX.
6. **Team calendar**: the team's matches (game) and training sessions (athlete) of the selected season merged and
   sorted, with venue and cancel state; CSV, XLSX and ICS. Reachable from the matches list and from the training
   sessions list of a team. Uses the lists the app already has or can fetch; offline it uses the cached reads and
   says when one of the two sources is missing.
7. **UI**: one kit-consistent export menu (icon button with CSV / Excel / Calendar entries), es / en / id labels,
   visible to every role that sees the screen (the data is what they already see). Goldens for the menu.
8. **Docs**: nothing outside your handover (WP96 writes ADR-0048; tell it through the handover if the web side
   deviates from the spec, e.g. UTC times in ICS).

### Export spec (decisions 67–69; the same text is in WP96, WP97 and WP101; ADR-0048 is written by WP96)
- **CSV**: UTF-8 with BOM, `,` separator, RFC 4180 quoting (quote a field that holds `,`, `"`, CR or LF; double the
  quote), CRLF line ends, one header row. Media type `text/csv; charset=utf-8`.
- **Formula-injection guard** (CSV and XLSX text cells): a text value that starts with `=`, `+`, `-`, `@`, TAB or CR
  gets a leading `'`. Numbers written as numbers are exempt (a negative score stays `-3` only in a numeric column).
- **Language**: header labels in the user's language (es / en / id; server: `Accept-Language` as the rest of the
  API; web: the app locale). Values are not translated except enum labels (role, status).
- **Dates and times**: ISO `yyyy-MM-dd` and `HH:mm` in the academy's time zone, in separate columns; the zone id in
  its own column where a time is present. XLSX uses typed date cells.
- **File name**: `hoops-<academy-slug>-<what>-<yyyyMMdd>.<ext>`, ASCII only (`Content-Disposition: attachment` on
  the server; the download attribute in the web).
- **ICS** (team calendar): RFC 5545; `PRODID:-//Hoops Academy//EN`; one `VEVENT` per match and per training session
  with a stable `UID` (`<kind>-<id>@hoops-academy`), `DTSTAMP`, `DTSTART`/`DTEND` with `TZID` of the academy zone
  plus the matching `VTIMEZONE` (or UTC `Z` times when the zone data is not at hand: say which in the ADR),
  `SUMMARY`, `LOCATION` (venue), `STATUS:CANCELLED` for cancelled ones; text escaped (`\\`, `\;`, `\,`, `\n`) and
  lines folded at 75 octets.
- **XLSX**: only for the browser-built exports; the library is reached only through `import ... deferred as` and
  `loadLibrary()` at the moment the user picks Excel; it is not part of the main bundle and is left out of the
  service worker precache; when it cannot be fetched (offline, first use) the user gets a message and CSV still works.
- **Limits**: one file, no paging; the server refuses more than 10,000 rows with a Problem that asks for a narrower
  filter. Responses carry `Cache-Control: no-store`.

## Acceptance
- [ ] Red tests committed before each change; builders covered for quoting, BOM, CRLF, formula guard, ICS escaping
      and folding, cancelled events, typed XLSX date cells
- [ ] Evidence that the XLSX library is in a deferred part only and not precached
- [ ] `flutter analyze` clean; `just web-format-check` clean; `just web-test` green (fresh; totals);
      `tool/offline_cold_start.sh` still passes
- [ ] An ICS file from the mock data imported into a real parser of your choice available offline (or validated
      line by line against RFC 5545 in a test)
- [ ] Handover appended: the package and version chosen and why, bundle sizes before and after

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

## Handover
- Built:
  - `lib/core/export/` (builders have no Flutter import; a test enforces it): `export_table.dart` (typed cells: text, number, date, time, empty), `formula_guard.dart`, `csv_writer.dart` (BOM, `,`, RFC 4180 quoting, CRLF, whole decimals without `.0`), `export_file_name.dart` (`hoops-<slug>-<what>-<yyyyMMdd>.<ext>`, ASCII), `ics_writer.dart` (RFC 5545, `TZID` + generated `VTIMEZONE`, UTC `Z` times when the academy zone is unknown, escaping, folding at 75 octets, `STATUS:CANCELLED`), `xlsx_writer.dart` + `xlsx_loader.dart` (deferred), `file_downloader*.dart` (interface; Blob + anchor through `package:web`; stub for tests), `export_runner.dart` (formats, outcomes, providers), `export_menu.dart` (icon button opening the kit action sheet: CSV / Excel / Calendar), `export_context.dart` (slug, clock).
  - Features: `match/presentation/match_exports.dart` + `match_export_actions.dart` (player stats: one row per match plus the totals row; box score: every visible line, our totals, the opponent as a score line), `training/application/team_calendar.dart` (loader: matches from game, sessions from athlete, selected season, matches fall back to the offline cache the list fills, a missing source is reported) + `training/presentation/calendar_exports.dart` (table and ICS events). Buttons: season stats app bar, match screen app bar (roster present), matches list header, training week (next to the time-zone note). Every role that sees the screen sees the button (the data is what the role already sees; the box score uses the same `canSeeLine` rule as the screen).
  - es / en / id labels (`export*` keys right after `matchShareLine`; generated l10n files regenerated).
- Package: **excel_community 2.6.2** (MIT, verified publisher, published 2026-10-25, pure Dart, web / wasm ready, `archive` 4.6 and `xml` 7.0 already in the lock). Rejected: `excel` 4.0.6 (same API but last release 2024-08, needs `archive` 3.x / `xml` < 7, i.e. downgrades), `syncfusion_flutter_xlsio` (commercial licence), `excel_plus` (2.x, fewer users, pulls a CSV package). Only `xlsx_writer.dart` imports it.
- Excel is deferred, proof: (1) `import 'xlsx_writer.dart' deferred as xlsx` in `xlsx_loader.dart` only; `loadLibrary()` runs when the person picks Excel; test `export_runner_test.dart` fails if anything else imports the writer or the package. (2) `flutter build web` output: `main.dart.js` has no `xl/workbook.xml`; dart2js maps the `xlsx` import to three parts, `main.dart.js_124.part.js` (521,120 bytes, only this import loads it, holds the library) and two tiny parts shared with screens (448 and 2,481 bytes, stay precached). (3) `tool/sw_manifest.dart` `onDemandParts()` reads that map from `main.dart.js` and leaves the exclusive parts out of the precache (same mechanism for any future `onDemandLibraries` entry). (4) `tool/verify_deferred_excel.dart` runs in `tool/build_web.sh` after the manifest and fails the build unless: import present, main bundle clean, library found in an exclusive part, neither that part nor any precached `.js` holds it. (5) Real Chrome, `tool/excel_on_demand_check.py` (mock bundle): 58 deferred parts loaded while using the matches list, the Excel part not among them; offline first use shows the "could not be loaded" message and downloads nothing; online the part is fetched at the click and `hoops-demo-calendar-20261110.xlsx` is handed to the browser. After the first online use the worker's runtime cache keeps the part for offline use.
- Bundle sizes (release build, before = main at start of this WP, after = this branch): `main.dart.js` 5,524,097 -> 5,538,371 B (+14 KB: the export code); deferred parts 169 files / 1,438,206 B -> 203 / 2,199,466 B (+761 KB: 521 KB Excel, the rest is dart2js re-partitioning the new shared code of matches / training / export); precache 201 files / 23,172,345 B -> 234 files / 23,427,229 B (+255 KB, mostly the shared parts; the Excel part is not in it; without the exclusion it would be 23.95 MB, 235 files).
- Verified (fresh, last commit before this handover): `flutter analyze` no issues; `dart format --output=none --set-exit-if-changed lib test integration_test tool` 420 files, 0 changed; `flutter test` (= `just web-test`) 1268 passed, 0 failed (1091 on main before); after the rebase see "Rebase onto WP99" below. `tool/offline_cold_start.sh`: OK (208 files cached, landing and live match render offline). `tool/excel_on_demand_check.py`: OK.
- Deviations from the export spec:
  - ICS: `TZID` times with a generated `VTIMEZONE` (baseline observance at 1 January of the first event's year plus every transition up to the last event, from the `timezone` package data); UTC `Z` times only when the academy zone is unknown. Match end = start + periods x minutes (the real finish is not known ahead). Also emits `CALSCALE`, `STATUS:CONFIRMED` for active events and `DESCRIPTION` with the cancel reason / session notes. WP96: the server side can use the same shape; there is no web-specific deviation to record in ADR-0048 beyond "UTC when zone unknown".
  - ICS validated line by line by a test helper (`test/support/ics_validator.dart`) over fixtures and over the mock data in es / en / id; no real parser (icalendar, vobject) is available offline here, so none was run.
  - Box score: "both teams" = our players and totals plus the opponent as one line with its score (the app records the opponent's score, not its players). Period scores are not in the file.
  - Minutes are a number (minutes with two decimals), not `mm:ss` text; FG / 3P / FT are made and attempted in separate numeric columns.
  - Dates are the academy's wall date; XLSX date and time cells are typed (`DateCellValue`, `TimeCellValue`); the zone id has its own column. The 10,000-row limit is not applied on the web (the data is already loaded; a season has far fewer rows).
  - Calendar fetch: per team (all teams for an admin, own teams for staff, one unfiltered call for others); a team's sessions are one call of up to 200 rows, which a season does not reach.
- Open points / notes for the merge:
  - Goldens re-recorded because the matches list, match screen, season stats and training week now show the export icon: `training_week_*` (3), `match/*` (box score, live match 4, stat sheet 2, match list 3, season stats 2), `home_parent_360x780`; new `export_menu_*` (3). The landing screenshots (`assets/landing/*`) were NOT recaptured (`training_week_*` and its manifest hashes are WP92 / orchestrator's: recapture after the round with `flutter test test/golden/landing_screens_capture.dart` if the training week should show the icon).
  - `apps/web/lib/l10n/*.arb` and `lib/l10n/gen/*` conflict with WP99 by construction: keep both key blocks and regenerate with `flutter gen-l10n`. `pubspec.lock`: my change is the `excel_community` entry only.
  - Excel offline on first use fails by design (message + CSV). The xlsx part is only cached after the first online use.
  - No ADR written (WP96 owns ADR-0048).

### Rebase onto WP99 (main d818e603)
- Conflicts: only two binary goldens, `match/live_match_1024x768.png` and `..._dark.png` (both WPs re-recorded them). ARB files, `lib/l10n/gen`, `pubspec.lock` and the other goldens merged without conflict: `flutter gen-l10n` and `flutter pub get` after the rebase produced no diff; the lock holds WP99's core package 3.4.0 and my `excel_community` 2.6.2 entry; the ARB files have the same 970 keys in es / en / id.
- Re-recorded on the combined tree: only `live_match_1024x768` and `live_match_1024x768_dark` (the only two that failed in the full run); looked at both: the new shell of WP99 (left navigation, context header) and the export icon next to the staff menu in the app bar.
- Tooling fix outside my files: `tool/offline_cold_start.py` waited for the old chooser heading "Cambiar de academia"; WP99 renamed it "Cambiar de contexto", so the check timed out on main's flow. It now accepts both (`PICKER`); `tool/excel_on_demand_check.py` uses the same constant.
- Fresh after the rebase: `flutter analyze` no issues; format check 433 files, 0 changed; `flutter test` 1372 passed, 0 failed; `tool/build_web.sh` OK with the verifier ("Excel library: deferred (521,183 bytes in main.dart.js_118.part.js), not in main.dart.js, not precached"; main.dart.js 5,594,245 B, 210 deferred parts 2,385,590 B, precache 241 files / 23,669,824 B); `tool/offline_cold_start.sh` OK; `tool/excel_on_demand_check.py` OK (54 deferred parts loaded before the export, the Excel part not among them; offline message; part fetched at the click).
- The tenancy commit hook failed once (surefire fork crash in the main checkout under load); the retry of the same commit went through.
