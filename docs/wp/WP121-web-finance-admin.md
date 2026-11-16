# WP121 — Web: Finance area for ADMIN (settings, fee plans, dues, payments)

Model: Sonnet · effort high. Wave 3 (2026-11-15, eighth round): starts after WP118 is merged (contract `finance.yaml`
1.0.0 and `apps/web/packages/finance`); runs alongside WP119 (the Go service behind the same contract), WP120
(observability) and WP122 (web PDF buttons: `features/roster` and `features/match` export buttons only). You own
`apps/web/lib/features/finance/**` with its tests and goldens, the shell's navigation entry and route for Finance,
the finance part of the demo mock, and the finance keys in `apps/web/lib/l10n/*.arb` (a new block next to the admin
feature's keys, never at the end). You do not regenerate any package. Depends on: the WP118 handover, ADR-0056,
decisions 93–99, the design-system kit (WP95). Skills: flutter-feature, test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp121-web-finance-admin`, branch `wp121-web-finance-admin`.

Decision 92 of 2026-11-15 (owner): the finance web screens land this round. This WP: what ADMIN does with settings,
fee plans, dues and payments. WP124 adds expenses, balance, exports, the coach's and the family's views.

## Scope
1. **Finance area** for ADMIN only (other roles do not see the entry; WP124 adds theirs): settings (currency, locked
   with an explanation once dues exist), fee plans (list, create, edit, archive; cadence; team or category),
   dues (list with filters by team, period and state; generate with the preview count; change amount and waive with
   a reason; record a payment; void a payment with a reason).
2. **Money**: amounts shown from minor units with the academy's currency and the user's locale (IDR has no decimals);
   input parsed the same way; unit tests first.
3. **Offline**: read-only when offline (no queued finance writes); say so in the UI as the other admin screens do.
4. **Demo mock**: finance endpoints in the mock with a small seed so the demo and the widget tests have data.
5. **l10n** es / en / id; kit components (`SectionCard`, `ListRow`, `PickerDialog`, `runAction`), no new dialog kinds.

## Acceptance
- [x] Red tests committed before each change; goldens for the main screens in light and dark, phone and wide
- [x] `flutter analyze` clean; `just web-test` green (fresh; totals); `just web-format-check` clean
- [x] Endpoints the service still answers 501 for (WP118 handover) degrade to a clear message, not a crash
- [x] Handover appended: the routes, what WP124 builds on (providers, money formatting), what was only tested against
      the mock

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
- Built (all under `apps/web`, no generated package touched):
  - **Routes** (ADMIN only: they live under `/admin`, whose destination the router guard gives to ADMIN; a COACH is
    redirected, tested): `/admin/finance` (hub: currency, plans, dues), `/admin/finance/settings`, `/admin/finance/plans`,
    `/admin/finance/dues`, `/admin/finance/dues/:dueId`. Entry: a "Finanzas / Finance / Keuangan" row (`admin-finance`) in
    the admin hub. **Decision**: no sixth bottom-bar destination; five already fill the 360 px budget that
    `nav_labels_test` guards (72 px a slot), so the entry is in the hub like seasons and members. `AppDestination` is unchanged.
  - **Screens** (`lib/features/finance/presentation`, one deferred library `finance_screens.dart`): hub; settings (currency
    shown, `currencyLocked` explained, picker with search over `financeCurrencies`, confirm, 409 / 422 worded); fee plans
    (list with target, season, cadence, amount, archived / has-dues chips; "show archived"; create / edit dialog; row menu:
    edit, generate, archive / reactivate, delete only without dues; without a currency a notice leads to settings and the
    "new plan" button is hidden); dues (filters plan / team / period / state, count, pages of 25, "generate" dialog with a
    **preview count before the button is enabled**); due detail (amount, plan amount if changed, reason, every payment
    including voided ones, actions: record payment, change amount, waive, void a payment; reasons are required, 200
    characters, with the "no health or family details" hint).
  - **Money** (`domain/money.dart`, `MoneyFormat`): `format`, `inputText`, `parse`, `example` over `amountMinor` + the
    settings' `minorDigits` + the user's locale; parsing reads the locale's separators, tolerates the other one as a decimal
    point when it cannot be grouping (`45.50` in es), refuses more decimals than the currency has, 0 and above 10^11. A whole
    amount of a currency written without decimals (IDR, intl default 0) shows none.
  - **Periods** (`domain/periods.dart`, `Period`): month / calendar quarter / SEASON keys, a plan's periods inside its season,
    the period to offer first (today in the academy's zone). `domain/currencies.dart` copies the service's table (the contract has
    no list); `currencies_test` compares it with `currencies.go` and skips when the Go sources are not checked out.
  - **Offline**: `FinanceOfflineNote` banner and disabled write buttons (nothing is queued). **501**: `FinanceBody` /
    `NotYetServed` show "not available on the server yet" with a retry on every read, `financeErrorText` does the same in
    the snack bar of any write; other business codes are worded (`DUE_NOT_OPEN`, `CURRENCY_LOCKED`, `PAID_ON_IN_FUTURE`...).
  - **Demo mock**: `features/finance/data/mock_finance_api.dart` (`MockFinanceApi`, hooked into `MockApiAdapter` for
    `/api/finance/**`): EUR, a monthly plan of Mini A with 21 dues (Sep paid, one waived, Oct half paid, Nov open), a season plan
    of the Mini category without dues, an archived plan; every operation of settings, plans, dues and payments with the ADR-0056
    rules and codes; expenses, balance, team / player views and exports answer 501 like the service. Roster, teams and
    seasons come from `MockCoreApi`.
  - **l10n**: 127 keys in one block after `adminCases` in `app_es / en / id.arb` (+ regenerated `lib/l10n/gen/*`).
- What WP124 builds on: `financeRepositoryProvider` / `FinanceRepository` (add expenses, balance, exports, the coach's and
  the family's reads there and in `ApiFinanceRepository`), `financeSettingsProvider`, `moneyFormatProvider` (null until a
  currency exists), `financeLookupsProvider` (names of seasons, categories, teams of every season), `isNotYetServed`,
  `FinanceBody(needs: ...)` (loads until the currency and names are there, so amounts never flash as raw numbers),
  `financeErrorText`, `FinanceOfflineNote` / `financeOnline`, `moneyField`, `periodLabel`, `DueStatusChip`. Add hub rows in
  `finance_screen.dart` and routes in `feature_modules.dart` (`finance/expenses`, `finance/balance`); keep the export
  buttons to the existing pattern in `core/export`. Tests: `test/support/fake_finance.dart` is the real repository over the
  demo mock plus hooks (`failOn`, `hang`, `last`, `notYetServed()`), `finance_pump.dart` (`pumpFinance`, `pickDropdown`,
  `settleMock`, `academyToday`).
- Verified (2026-11-16, fresh, on this branch):
  - `flutter analyze`: no issues. `just web-format-check` (`dart format --set-exit-if-changed lib test integration_test tool`):
    483 files, 0 changed. `flutter test` (`just web-test`): **1,652 passed, 0 failed** (baseline of `main` before this WP: 1,507;
    +145 = 129 in `test/features/finance` and 16 finance goldens). Finance tests: money 17, periods 20, currencies 3, mock
    contract 31, providers 14, screens 44.
  - Goldens (light / dark, 360x780 / 1024x768): settings, plans, dues, a paid due; the admin hub goldens (home shell, avatar menu,
    context switcher) were regenerated because the hub has one more row.
  - TDD order: red commits for money, periods, the mock contract, the providers and the screens before their code
    (`git log` of this branch); the exceptions are the currency table (data, checked against the Go source by a test) and
    the goldens (recorded after the screens).
- Only tested against the mock (WP119 had not landed): every call to `/api/finance/**`. The generated client, the repository
  and the screens were exercised against `MockFinanceApi`, which follows finance.yaml 1.0.0 and ADR-0056 but is not the Go
  service; the 501 states were driven by a fake that throws the `AppError` the interceptors build from a 501 problem, not by
  the real service. Nobody opened the area in a browser, with Keycloak, or through `just e2e`.
- Decisions / ADRs: none new. Open points / follow-ups:
  - **`lib/l10n/gen/*.dart` conflict with WP122** (both add keys): after the merge resolve the `.arb` files by hand and run
    `flutter gen-l10n`; the generated files are not hand-mergeable.
  - **IDR decimals**: the service's table (and so `minorDigits`) says 2 for IDR (ISO 4217), the brief says "IDR has no decimals".
    The screens follow `minorDigits` for what a minor unit is (15000000 minor = Rp150.000) and drop the decimals of whole amounts
    (intl's default for IDR), so a family sees `Rp150.000`; the owner may want the service's table to say 0.
  - The period filter of the dues list offers the periods of the active plans; dues of an archived plan are found through the
    plan filter only when "show archived" is on in the plans screen (the filter list uses `feePlansProvider`).
  - `financeLookupsProvider` asks for the teams of every season (one call per season); fine for an academy, revisit with many seasons.
  - Dues pages are 25 rows with previous / next; no "jump to page".
  - The demo mock's `_today` is the real clock in Europe/Madrid; its seeded payment days are fixed in 2026.
  - Tests that call the demo mock directly inside `testWidgets` must use `tester.runAsync` (it answers after a real 150 ms).
