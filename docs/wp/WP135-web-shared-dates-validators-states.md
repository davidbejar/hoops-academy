# WP135 — Web: one home for dates, validators, export buttons, error messages, section states

Model: Sonnet · high. Wave 3 (2026-11-23, ninth round): starts after wave 2 is merged; runs alongside WP134 (library
and services), WP136 (chart, kind). You own `apps/web/**` except `apps/web/packages/**`; nobody else touches the app.
Depends on: WP129; ADR-0030, ADR-0032, ADR-0040, ADR-0042. Skills: work-package, flutter-feature,
test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp135-web-shared-dates-validators-states`, branch `wp135-web-shared-dates-validators-states`.

Decision 104 of 2026-11-23: everything confirmed in the web app is fixed. ADR-0067 is reserved for you if a decision
is needed.

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings: `apps-web.md`
(WEB-04..WEB-17 except WEB-13), verification `verify-apps-web.md`, all under `~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Dates (WEB-04)**: one `core/time/dates.dart`, the dead helpers deleted; goldens re-recorded only where the text
   really changes, each listed in the handover.
2. **Forms (WEB-07)**: `core/ui/validators.dart` (email, decimal, blank-to-null) and one `formatMeasure`; the
   0/1/2-decimal disagreement in health is a bug: failing test first.
3. **Exports (WEB-06)**: one `ServerExportButton` for the CSV and PDF buttons with one handling of `EXPORT_TOO_LARGE`
   and 503.
4. **Errors and states (WEB-08, WEB-05)**: one code-to-message table; one section loading / error / empty widget in
   place of the seven variants.
5. **Providers (WEB-09, as corrected)**: low impact: `autoDispose` where it is plainly right; `auditQueryProvider` and
   `playerNameProvider` stay as they are.
6. **The rest**: every other WEB finding of your scope, including the copied test set-up and the Python browser-test
   helpers under `apps/web/tool`.

Not yours: WEB-02 (WP138). `apps/web/lib/l10n/*.arb`: keys next to the related feature's keys, never at the end.

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `flutter analyze` clean; `just web-test` green (fresh; totals); `just web-format-check` clean
- [ ] golden files re-recorded: the list and the reason for each
- [ ] Handover appended, with the ID table

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- The audit files are in the main checkout, untracked, at `~/code/hoops-academy/audit/2026-11-23/` (they are not in your
  worktree). Read the findings file(s) named above **and** their verification file: where the two disagree, the verification is right.
  Do every finding of your scope whose verdict is CONFIRMED or PARTLY (as corrected); skip REFUTED, ALREADY KNOWN and
  the exclusions named above. A finding you judge not worth doing or unsafe after reading the code: leave it, and say
  why in the handover. Do not copy the audit files into the repository.
- Behaviour must not change except where a finding is a bug; a bug fix starts with its failing test.
- Commit: `gitleaks protect --staged`, then plain `git commit` with explicit paths (never `git add -A`, never
  `--no-verify`: the session refuses it). The pre-commit hooks run and may trim whitespace: re-add and commit again.
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected, do
  not try to bypass it; if it times out under load, retry when a build has finished. End every commit message with a
  `Co-Authored-By:` line naming the model that did the work (for example
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`).
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/conformance.md, docs/roadmap.md,
  docs/architecture.md; what they need goes in this file's Handover. `docs/adr/README.md`: append your ADR line at the
  end, one line.
- Finish per the `work-package` skill. The Handover ends with a table `| ID | Done / Skipped | What changed or why
  not |` with one row per finding ID of your scope. Final report to the orchestrator, at most 300 words.

## Handover
- **Built** (all under `apps/web`; ADR-0067)
  - **Dates (WEB-04).** `core/time/dates.dart` (pure Dart): ISO, compact `yyyyMMdd`, `dd/MM`, `dd/MM/yyyy`, `dd/MM/yy`
    (charts), `displayDate` / `displayDateTime` (locale `yMMMd`), `toApiDate` / `toAthDate` / `toFinDate`. The private
    `padLeft` formatters, dead `formatAthDate` / `athDateText`, `two`, `DateField.format`, the `toAthDate` of
    `training_providers.dart` (health imported training for it) and the seven `DateFormat.yMMMd` copies are gone.
    What is on screen is unchanged: no golden moved.
  - **Forms (WEB-07).** `core/ui/validators.dart` (kit export): `requiredValidator` (moved), `isValidEmail`,
    `emailValidator`, `optionalEmailValidator`, `decimalValidator`, `optionalDecimalValidator({positive})`,
    `parseDecimal`, `blankToNull`, `formatMeasure`. 5 email patterns, 8 decimal parses and 15 inline blank-to-null
    copies replaced; `platform_validators.dart` deleted. **Bug fixed**: a measurement was written with 0, 1 or 2
    decimals depending on the widget (growth chart table 37.55 -> "37.5", list "37.55", norm tile full precision); red
    test in `charts_test.dart`, now one text (whole number without decimals, else at most two, no trailing zero).
  - **Exports (WEB-06).** `ServerExportButton.csv` / `.pdf` (+ `BusyIconButton`, `showExportMessage` shared with
    `ExportMenu`); one handling: `EXPORT_TOO_LARGE` shows the screen's message or the narrow-the-request text (the PDF
    button used to show the generic text of its kind), 503 shows the try-later message. Tests: `server_export_button_test.dart`.
  - **Errors (WEB-08).** One code table in `AppError.message` (26 codes + 501); `financeErrorText`, `adminErrorText`,
    `academyRequestErrorText`, `exerciseErrorText`, `AppErrorText` and 20 `errorText:` arguments gone.
    `memberErrorText` (own words for `EMAIL_TAKEN`, `INVITATION_NOT_PENDING`) moved to `member_error_text.dart`.
    Tests: `error_messages_test.dart` (red first). One existing test used `EMAIL_TAKEN` as "an unworded 409": now an
    unknown code.
  - **States (WEB-05).** `AsyncSection` in `core/ui/async_body.dart` (compact spinner, mapped message + optional label
    + retry, muted empty text, `hideWhen`, keys for tests); replaces `AsyncBodyInline` (was in `members_screen.dart`),
    the admins section, the due status card, the usage trend and the guardians of a player (which gain a retry). The
    assign-player dialog's failed search showed `errorUnknown`: now the mapped message (red test first).
  - **Providers (WEB-09).** 16 per-id families made `autoDispose` (with the live match of WP129: `provider_lifetime_test.dart`).
  - **Rest.** WEB-10: the teams selector stores null for the current season (red test). WEB-11: `Reloading` mixin
    (`core/state/reloading.dart`) on 26 notifiers, 11 pure `_reload` helpers and ~25 invalidate+await pairs gone.
    WEB-12: counts with `count(*)` / `selectOnly(distinct)` / `watchSingle` in `match_store.dart`. WEB-14:
    `ResultDialog` is a `FormDialog` (+ `afterClose` shows the band). WEB-15: `mockProblem` / `mockApplyUpdate` in the
    game and finance mocks. WEB-16: `tool/webdriver.py`. WEB-17: `pumpAsSuperAdmin`, `localizedApp`.
  - Also: `test/core/mock_athlete_platform_api_test.dart` failed on `main` today (it looked 3 days back from the host's
    local date while the mock reads "today" in the academy zone; WIB vs Madrid on a Tuesday): window is 7 days back now.
- **Verified** (fresh, 2026-11-24): `flutter analyze` no issues; `just web-format-check` 522 files, 0 changed;
  `flutter test` (the whole `just web-test`) **1921 passed, 0 failed** (WP129 baseline 1861). Red first, committed
  before the change: `validators_test` + growth table (WEB-07), `error_messages_test` (WEB-08), `async_section_test`
  (WEB-05), `server_export_button_test` (WEB-06), the failed player search (WEB-05), the teams selector (WEB-10).
  Pure moves/deletions rely on the existing suites (dates, `Reloading`, match store counts, mocks, set-up helpers).
  Python tools: `tool/offline_cold_start.sh` (builds the mock bundle, drives Chrome through `webdriver.py`) ended
  `OK: offline cold start`, and `excel_on_demand_check.py` passed; `browser_login_check.py` needs the compose stack and
  was only compiled (`py_compile`), it uses the same `WebDriver` class.
- **Goldens re-recorded**: none. Every text is unchanged where a golden shows it (the three golden files that touch
  the set-up helpers, `app_admin`, `platform_requests`, `growth_chart`, pass as recorded).
- **Decisions/ADRs**: ADR-0067 (appended to `docs/adr/README.md`); `flutter-feature` skill got a "shared helpers" rule.
- **Open points / not done**
  - WEB-04 did not unify the display styles (ISO / `dd/MM/yyyy` / `yMMMd`): each kind of screen keeps its own, only
    the code is shared; unifying changes visible text and goldens in three languages (owner's call).
  - WEB-05: `FinanceBody` (page level, with `needs`) is left as it is: it already wraps `AsyncBody` and the 501 text
    now comes from the central table.
  - WEB-10: the two selectors are not merged: the teams dropdown is shown to every role, `SeasonBar` only to those
    who can browse seasons; replacing it would hide the selector from coaches and parents.
  - WEB-14: `AssignPlayerDialog` stays a two-step dialog (pick, check, assign, with "back"); `PickerDialog` is
    single-step, so a conversion needs a kit extension (a stateful search header) first.
  - WEB-15: the folder moves ("one `core/api/<svc>_api.dart` / `core/mock/mock_<svc>_api.dart` per service") not done:
    about 60 imports, and WP138 works in the same files.
  - WEB-09: only per-id detail families; the other 12 families (week sessions, assignments, audit page, ...) keep
    their lifetime (filters or derived state).
  - WEB-17: the helpers of `audit_test`, `academy_requests_test` and `platform_users_test` also pump non-super-admin
    users and keep their own `Harness` set-up.
  - The tenant-isolation commit hook failed once under load (Keycloak container, 379 s); retried when the machine was
    quieter.

| ID | Done / Skipped | What changed or why not |
|---|---|---|
| WEB-04 | Done | `core/time/dates.dart`; private formatters, dead helpers and per-client Date constructions gone; display styles kept (see open points) |
| WEB-05 | Done | `AsyncSection` replaces `AsyncBodyInline` and four ad-hoc blocks; assign dialog's failed search mapped; `FinanceBody` kept |
| WEB-06 | Done | `ServerExportButton.csv/.pdf`, `BusyIconButton`; one `EXPORT_TOO_LARGE` / 503 handling |
| WEB-07 | Done | `core/ui/validators.dart`, `formatMeasure`; the 0/1/2-decimal disagreement fixed (red test first) |
| WEB-08 | Done | one code table in `AppError.message`; five mappers and `AppErrorText` gone; members override two codes |
| WEB-09 | Done (as corrected) | 16 per-id families `autoDispose`; `auditQueryProvider`, `playerNameProvider` untouched |
| WEB-10 | Done (part) | teams selector stores null for the current season; not merged with `SeasonBar` (role visibility) |
| WEB-11 | Done | `Reloading` mixin; pure `_reload` helpers gone, extras keep a short `_reload` |
| WEB-12 | Done | `count(*)`, distinct `selectOnly`, `watchSingle` |
| WEB-14 | Done (part) | `ResultDialog` -> `FormDialog` + `afterClose`; `AssignPlayerDialog` left (two-step) |
| WEB-15 | Done (part) | `mockProblem` / `mockApplyUpdate` in the game and finance mocks; folder moves skipped |
| WEB-16 | Done | `tool/webdriver.py`, three scripts import it |
| WEB-17 | Done (part) | `pumpAsSuperAdmin`, `localizedApp`; three helpers with non-super-admin variants kept |
