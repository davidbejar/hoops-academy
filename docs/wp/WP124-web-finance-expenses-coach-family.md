# WP124 — Web: finance expenses, balance, exports; coach status view; family dues

Model: Sonnet · effort high. Wave 4 (2026-11-15, eighth round): starts after WP121 and WP122 are merged and `ci` is
green on them; runs alongside WP123 (Go service, e2e). You are the only web WP of the wave: you own `apps/web/**`
except the generated packages. Depends on: the WP121, WP119 and WP118 handovers, ADR-0056, decisions 96, 99. Skills:
flutter-feature, test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp124-web-finance-rest`, branch `wp124-web-finance-rest`.

Decision 96 of 2026-11-15 (owner): PARENT reads the dues and payments of linked players, PLAYER their own; a team's
current COACH reads who of the team is up to date (status only); ASSISTANT_COACH nothing. Decision 99: fixed expense
categories, localised in the web.

## Scope
1. **ADMIN**: expenses (list, create, edit, delete; category labels es / en / id), season balance (figures and one
   chart from the kit's chart card), export buttons for dues and expenses with the existing export button pattern.
2. **COACH**: on the team's screen, who is up to date (a marker per player, no amounts); only for the team's
   current coach.
3. **PARENT / PLAYER**: the dues of each linked player (or their own) with state and payment date, where the
   family's player screens live (`features/my_players`, `features/me`).
4. **Capabilities**: the visibility rules in one place, tested per role; the demo mock extended.
5. If WP123 bumped the contract, use the regenerated package after the orchestrator says it is on `main`.

## Acceptance
- [x] Red tests committed before each change; goldens for the new screens in light and dark
- [x] `flutter analyze` clean; `just web-test` green (fresh; totals); `just web-format-check` clean; `just mutation`
      for the web tool unchanged if you touched files in its manifest (no manifest file touched)
- [x] Handover appended: the routes per role, what nobody checked in a real browser

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first (JDK 25). Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then a plain `git commit` with explicit paths (never `git add -A`, never
  `--no-verify`: the session refuses it). The pre-commit hooks run and may trim whitespace in generated files: re-add
  and commit again. Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit
  (it resyncs the Podman VM clock itself); under load it can time out: retry when a build has finished, never bypass
  it. End every commit message with a `Co-Authored-By:` line that names the model you are.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Gate rules: constant SQL with bound parameters (CodeQL), no nil-tenant bind without a dated acceptance (Semgrep), no
  environment-derived program names in scripts and tests (Semgrep taint). Since WP113 the PMD / CPD gate runs in
  `verify`: stay inside its thresholds, add no exclusion without a reason.
- An OpenAPI generator run can leave whitespace-only diffs in the Dart packages: discard them. Regenerate only your
  package (`scripts/gen-api.sh <svc>`). `apps/web/pubspec.lock`: commit it only with a generated package's version
  bump; revert other drift. `apps/web/lib/l10n/*.arb`: keys next to the feature's existing keys, never at the end.
- Shared index files (`docs/adr/README.md`, `docs/domain/authz-matrix.md`): append at the end, one entry per line.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- Built (all under `apps/web`, no generated package, no contract, no pubspec.lock touched):
  - **Routes per role**: ADMIN: `/admin/finance/expenses` (list, filters category / from / to, pages of 25, create, edit
    only what changed, delete after confirming, CSV export), `/admin/finance/balance` (season picker, paid / open / waived,
    expenses, result, one bar chart in `ChartCard`), export button on `/admin/finance/dues` (the filters on screen); hub rows
    `finance-expenses`, `finance-balance`. COACH (the team's current COACH only): a "Cuotas al día" section on
    `/teams/:teamId` (`DueStatusSection`): marker + text per player, count, no amounts; hidden for ASSISTANT_COACH, a COACH
    who is only assistant of that team (checked against the team's staff list), another team's coach, parent, player, a
    plain ADMIN, and on a 403. PARENT / PLAYER: a "Cuotas" tab (`hub-tab-dues`) in the player hub (`/my-players`, `/me`,
    `FamilyDues`): plan, period, state, amount, and day + method when paid; amounts use the due's own currency (the family
    cannot read the settings). Rules in one place: `finance/application/finance_rights.dart` (`FinanceRights` on
    `Capabilities`), tested per role in `finance_rights_test`.
  - Data: `FinanceRepository` + `ApiFinanceRepository` gain expenses CRUD, balance, `teamDueStatus`, `playerDues`,
    `exportDues`, `exportExpenses`; providers `expensesProvider`, `expenseQueryProvider`, `seasonBalanceProvider`,
    `teamDueStatusProvider`, `playerDuesProvider`; `ExpenseQuery`; `expenseCategories` + localised labels es / en / id.
  - Shared: `ChartCard` moved from the health charts (was private) to `core/ui/chart_card.dart` and the kit;
    `ServerCsvExportButton.errorText` (optional) so a 501 reads "not available on the server yet"; `NoCurrencyNotice`
    extracted from the plans screen.
  - Demo mock: `mock_finance_reads.dart` (part of `MockFinanceApi`): 8 expenses, CRUD with the contract's validation,
    balance, coach status (current COACH / ADMIN), family dues (linked PARENT / own PLAYER / ADMIN, else 403), CSV exports
    with BOM, header and labels in es / en / id and the formula guard. The mock no longer answers 501 for these.
  - l10n: 52 keys after `financeErrorConcurrentModification` in the three `.arb` files; generated files committed.
- Verified (2026-11-16, fresh, this worktree): `flutter analyze` no issues; `dart format --set-exit-if-changed lib test
  integration_test tool` (= `just web-format-check`) 506 files, 0 changed; `flutter test` (= `just web-test`) **1,801
  passed, 0 failed** (1,652 after WP121; 1,507 on main). TDD: red commits (mock reads, rights + providers, screens) before
  their code. Not run: `just mutation` (no manifest file touched), `tool/offline_cold_start.sh`, a browser, the real stack,
  CI, `just e2e`.
- Goldens added (light / dark; 360 and 1024 wide): `finance_expenses_*`, `finance_balance_360x1400*` / `_1024x768*`,
  `finance_coach_360x1250*` / `_1024x768*`, `finance_family_*`. Re-recorded because the screen really changed:
  `finance_dues_{360x780,360x780_dark,1024x768,1024x768_dark}` (export icon in the app bar) and
  `preferred_jersey_wish_360x780` (the hub has a fourth tab chip). `test/app/mock_mode_test.dart` was adapted: the demo
  coach now also sees the status section on Mini A.
- Only tested against the mock: every call of the new operations (WP123 is not merged; on `main` they answer 501). 501 is
  tested with a fake: lists show "not available yet" with a retry, writes and exports show it in a snack bar, the coach
  section shows it inline, the family tab shows the not-yet state. The demo mock follows finance.yaml 1.0.0 and the
  handovers, not the Go service: e.g. the mock answers `CURRENCY_NOT_SET` (409) for the balance without a currency, which
  the contract does not list. Nobody opened any of this in a real browser, with Keycloak, or downloaded a real CSV (the
  button saves under the shared file-name rule, not the server's `Content-Disposition` name).
- Decisions / ADRs: none. Open points: (1) Coach section is not shown to a plain ADMIN (dues screens cover it; the service
  would allow it). (2) Staff check uses the team's staff list, so a coach whose list failed to load sees nothing. (3) The
  family tab lists the first 50 dues (no paging; a player has few). (4) IDR minor digits as in WP121 (service table says 2).
  (5) After WP123 merges, re-check the balance / 404 / 422 `EXPORT_TOO_LARGE` against the real service. (6) User guides
  should mention the new rows, the two CSV icons and the coach / family views.
