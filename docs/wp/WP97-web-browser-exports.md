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
