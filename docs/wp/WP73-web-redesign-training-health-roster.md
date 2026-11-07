# WP73 — Web redesign: training, plans, sessions, health, fitness and roster screens

Model: Opus. Wave 2 (2026-11-06, fifth round): starts after wave 1 is merged (WP72 design system, WP78 training
changes); runs alongside WP74 (match), WP75 (admin/platform/auth), WP80, WP86, WP89. You own
`apps/web/lib/features/{training,health,my_players,roster}/**`, their tests, and the goldens
`test/golden/training_health_golden_test.dart`, `roster_golden_test.dart` (+ files under `test/golden/goldens/` for
those). Shared: `lib/core/ui` only as the rule below says; `lib/l10n/*.arb` keys next to the feature's keys, never at
the end. Depends on: WP72 (ADR-0040), WP78 (the session plan picker and search you restyle, do not change their
behaviour). Skills: flutter-feature, test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp73-web-redesign-training`, branch `wp73-web-redesign-training`.

Decision 52 of 2026-11-06: every screen takes the design system of WP72 (ADR-0040; tokens in `lib/core/design`,
kit in `lib/core/ui`, the wave 2 checklist in the WP72 handover). Rules for every redesign WP: no behaviour change
(the existing widget tests stay green unless they assert on looks); replace ad-hoc styling with the kit widgets and
tokens (no colours, sizes or paddings inline); every screen in light and dark; responsive (phone width 360 to desktop);
goldens of your features re-recorded and reviewed (describe what changed); the demo mock is the data source for
goldens; `apps/web/assets/landing/*.png` are the reference and must not be modified (decision 57). If the kit lacks a
widget you need, add it to `lib/core/ui` in a SEPARATE commit named `feat(web): kit: <widget>` so the other redesign WPs
can cherry-pick it, and tell the orchestrator.

## Scope
1. **Training**: training week / schedule, sessions list and session screen, attendance, planned absences, plans
   list, plan detail with items, templates, plan assignments and progress, the WP78 picker and search; the "training
   week" screen must match the landing mock-up `training_week.png` closely (it is one of the four showcased screens).
2. **Health and fitness**: injuries, availability, body measurements, physical test types / results / norms; the
   "player health" screen must match `player_health.png` closely.
3. **Roster**: teams, players, approvals, eligibility cases, guardian dialog; `my_players` (parent view).
4. Widget tests kept green; goldens re-recorded; `apps/web/README.md` not yours (WP72 wrote the design section).

## Acceptance
- [ ] Every screen of your features uses the kit and tokens (no inline colour/size literals: grep proof in the handover)
- [ ] Training week and player health screens visually match their mock-ups (golden images attached to the handover
      as paths)
- [ ] `flutter analyze` clean; `just web-format-check` clean; `just web-test` green (fresh; totals); goldens listed
- [ ] `tool/web_smoke.sh` green; handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the lines
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01Fuaj1aLz4Zxsb2XaUQBcMq`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Keep the Mac awake for long runs: `caffeinate -dims -t 14400 &`,
  kill it before reporting.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- Built:
  - **Kit** (separate commit `07e9750 feat(web): kit: ListRow details slot`, cherry-pickable): `ListRow(details:)`, an
    optional widget under title and subtitle (chips, inline actions) so rows with several chips do not squeeze the title
    on a phone; default null, existing rows and kit goldens unchanged; widget test added.
  - **Training week** (`training_screen.dart`) as in `assets/landing/training_week.png`: week switcher with the week in
    `accentText`, the academy zone note, the shortcut chips (brand icons), team filter, day headings (today orange +
    "Hoy" chip, reusing the unused `trainingToday` key), sessions as `ListRow`s (time range, team, place line with an
    icon, `StatusChip`: done = success, cancelled = danger, chevron), every block in a `ContentFrame`.
  - **Player health** (`player_health_view.dart`) as in `player_health.png`: availability `StatusChip`, tab chips,
    "Registrar lesión", injuries as `SectionCard`s (body part, open/recovered chip, severity chip + date, description,
    expected return, edit / change return / mark recovered). Growth and test results as `ListRow`s (results carry the
    band / reference-pending chips in `details`), charts unchanged in look.
  - **Rest of training**: session detail (`SectionCard` with icon facts, plan items and the own-plan chip, actions,
    attendance `SectionCard` with dividers), plan library (`ListRow` + `IconTile`, "Usar" under the template), plan editor
    (summary chip, template hint card, exercises as `ListRow`s; the item menu is now `showActionSheet`), the WP78 plan
    picker and exercise search restyled only (eyebrow group headers, muted hints, same keys, texts and behaviour),
    schedules, absences, assignments and progress (`ListRow`, `CompletionControl` in `details`), `EmptyNotFound` →
    `EmptyState`. Health: test types and norms as `ListRow`s with chips. Roster: players list (`ListRow` +
    `InitialsAvatar`, capped status chip), filter chips tinted when set, player detail (avatar header, `SectionCard`s for
    basics / teams / guardians), player form in a `ContentFrame`, teams list (category-code tile + chips), team detail
    (staff and roster `SectionCard`s, roster actions on `showActionSheet`), approvals and cases as `SectionCard`s,
    eligibility / play-up badges as `StatusChip`s, guardian dialog spacing. `my_players` is a wrapper over the profile
    hub (WP75): nothing to change.
  - Grep proof (`lib/features/{training,health,my_players,roster}`): 0 hits each for `AppTokens`, `InfoChip`,
    `ChipTone`, `Color(0x`, `colorScheme.`, `CircleAvatar`, `EmptyView`, `fontSize: <number>`, `EdgeInsets.*(<number>`,
    `SizedBox(width|height: <number>`. Kit use: HoopsSpace 144, HoopsTone 53, StatusChip 36, ListRow 17, ContentFrame 17,
    SectionCard 11, IconTile 9, PageBody 8, InitialsAvatar 7. Left on purpose: 5 `ListTile`s inside picker dialogs
    (plan picker, eligible / reassign / assign-player lists: selection lists in an `AlertDialog`), the chart card's
    `Card` and its dataviz sizes (now named in `_ChartSize`).
- Verified (2026-11-07, worktree `wp73-web-redesign-training`, all fresh):
  - `flutter analyze`: no issues. `just web-format-check`: 333 files, 0 changed.
  - `flutter test`: **898 passed**, 0 failed (baseline on 2cfb54e: 890; +1 kit test, +7 goldens).
  - `tool/web_smoke.sh` (mock mode, Chrome): All tests passed.
  - Goldens (demo-mock data: the Mini A / Infantil A week in Madrid time, Leo Gil's left knee; "today" pinned to
    Thu 2026-11-05): new `test/golden/goldens/training_week_360x780_dark.png`, `training_week_1024x768.png`,
    `player_health_360x780.png`, `player_health_360x780_dark.png`, `session_detail_360x780.png`,
    `teams_list_360x780_dark.png`, `team_detail_360x780.png`; re-recorded `training_week_360x780.png`,
    `teams_list_360x780.png`, `player_detail_360x780.png`. `growth_chart_360x780.png` and every golden outside my
    features (platform usage, home, live match) unchanged. Reviewed in real fonts (Roboto, light/dark, 360 and 1024)
    with a throw-away comparator that wrote the same scenarios to a scratch folder (not committed), plus players, plans,
    plan editor, tests tab, types, norms, assignments and schedules. Training week and player health match the mock-up
    layouts (same blocks and order; colours are the WP72 tokens, so "Realizada" is green and buttons orange 700).
  - Red/green: the kit test failed to compile before `ListRow.details`; four widget tests failed on the restyle
    because they asserted looks or interaction geometry (`Card` order in the plan editor, `Card` on the demo
    assignments page, a snack bar over the new actions sheet, `tapKey` hitting before the scroll was laid out) and were
    adapted, every other existing widget test passed unchanged.
- Decisions/ADRs: none new (ADR-0040 applies). Item and roster menus use the actions sheet (wave 2 checklist). Status
  tones: session done = success, cancelled = danger; injury open = danger, severe = danger else warning; player active
  = success, withdrawn = neutral, others = warning; coach chip = info. Long or several chips go in `ListRow.details`, a
  single status chip in `trailing` capped at 120 px. Short detail pages (player, team, approvals) build their sections
  in one `PageBody` section so tests and screen readers see the whole page. Chart cards keep their look so the platform
  usage goldens (WP75) do not move. `fabClearance` (FAB room under lists) lives in `training_labels.dart`, roster keeps a
  private copy.
- Open points / follow-ups:
  - Shared test helper touched: `test/support/pump_helpers.dart` `tapKey` now scrolls the target to the middle
    (`Scrollable.ensureVisible(alignment: 0.5)`) and pumps once before tapping (the fix WP74 suggested); full suite green
    with it. On a merge conflict keep both lines.
  - Kit: `PageBody` / `ContentFrame` still centre a narrower section (WP74 note); worked around with `Align` /
    `SizedBox(width: double.infinity)` / stretched columns here. A kit fix (stretch sections) is still worth doing.
  - Kit candidate: a fab-clearance constant (`HoopsSize`) instead of per-feature copies (WP74 has its own too).
  - Picker dialogs (`AlertDialog` + `ListTile`) could get a kit `PickerDialog` later; widths are named constants now.
  - The chart card could become a `SectionCard` once the platform usage goldens can be re-recorded with it.
