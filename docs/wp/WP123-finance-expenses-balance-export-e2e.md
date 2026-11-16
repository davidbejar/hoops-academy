# WP123 — Finance: expenses, season balance, CSV exports; e2e journey and ZAP for finance and the PDFs; demo data

Model: Opus · effort high. Wave 4 (2026-11-15, eighth round): starts after WP119 is merged; runs alongside WP124
(web). You own `services/finance-service/**` (migrations V20–V29), `e2e/**`, `.github/workflows/e2e.yml`,
`scripts/zap-*.{sh,py}`, `.zap/**`, `infra/keycloak/seed-academy.sh`. `libs/contracts/openapi/finance.yaml`: additive
changes only (minor bump, regenerate `apps/web/packages/finance`, tell the orchestrator). No chart or compose
change. Depends on: the WP118, WP119, WP116, WP117 and WP107 handovers, ADR-0048, ADR-0056, ADR-0045, decisions 96,
99. Skills: go-hexagonal-service, tenant-isolation-testing, owasp-security, test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp123-finance-expenses`, branch `wp123-finance-expenses`.

Decisions of 2026-11-15 (owner): **99** expense categories are a fixed list; **96** expenses, balance and exports are
ADMIN only.

## Scope
1. **Expenses**: create, edit, delete (say in ADR-0056 whether delete is soft), list with filters; category enum,
   amount in minor units, date, note. Audit records.
2. **Season balance**: income paid, outstanding, waived, expenses by category, net; computed in the academy's
   currency; property-style tests on the arithmetic.
3. **CSV exports** of dues and expenses by the ADR-0048 spec (columns, encoding, formula-injection guard, file name,
   the 10,000-row limit with `EXPORT_TOO_LARGE`, an audit record per export, the caller's language).
4. **No endpoint left 501**; the contract's examples match real answers.
5. **e2e journey**: steps for finance (ADMIN creates a plan, generates dues, records and voids a payment; a parent
   sees the linked player's due; a coach sees status without amounts; academy B sees nothing) and for the two PDFs
   (roster from core, match sheet from game; the answer is a PDF). ZAP API scan of finance through the existing gate.
6. **Demo data**: the demo phase of `just seed-academy` adds a currency, two fee plans, dues and a few payments and
   expenses to the Test Academy (idempotent, as WP107).

## Acceptance
- [ ] Red tests committed before each change; RLS suites green for the new tables
- [ ] `just test` green (fresh; totals per language, coverage); `just isolation-check` green
- [ ] The journey's new steps green on compose (`just up`, `just services-up`); ZAP gate green; `actionlint` clean
- [ ] Handover appended: contract version, what the web (WP124) must know, the seed's finance rows

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
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->

- Built:
  - **finance-service, no operation left 501** (`rest/later.go` removed; `TestEveryContractOperationIsServed` calls all 26
    operations of finance.yaml: never 501/405, non-member 404, anonymous 401). V20 `finance.expense` (fixed categories,
    RLS suites), V21 `tenant_ref.slug`, V22 `team_ref.name` (decoded from `tenant.changed` / `team.changed`).
  - **Expenses**: create (409 `CURRENCY_NOT_SET` first), list (newest first; `from`/`to`/`category`, pages), get, correct
    (`clear: [note]`, row lock, no-change = no audit), delete (hard). Audit `expense.created|updated|deleted` (category /
    field names only). The first expense locks the currency, like the first due.
  - **Season balance** (`domain.NewSeasonBalance`, property test over 2,000 random cases): income by status (PAID by the
    valid payment), expenses within the season by all six categories, net. Unknown season or no currency yet: 404.
  - **CSV exports** (`adapters/in/export`, pure): BOM, CRLF, RFC 4180, formula guard, `Accept-Language` (es/en/id, `in`,
    q=0, ties), labels following the ARB texts, `hoops-<slug>-dues|expenses-<yyyyMMdd>.csv`, 10,000 rows else 422
    `EXPORT_TOO_LARGE` (no audit), audit `dues.exported` / `expenses.exported` (rows + filter). Never reasons or notes.
  - **e2e**: journey steps 14-18 and 55 (roster PDF + 403 + audit `format=pdf`; match sheet for coach and parent;
    finance plan/dues/pay/void/pay, family view, coach status, expenses, balance, both CSVs spaced under the export
    limit; academy B 404s; finance in the suspension step). `services-up.sh` also starts pdf-service and
    finance-service in compose (finance roles first; `E2E_WITHOUT_PDF_FINANCE=1` skips), `services-down.sh` stops them.
    `e2e.yml`: ZAP scans core, game, athlete **finance**; pdf/finance logs on failure; timeout 130 min.
    `scripts/zap-api-scan.sh` takes `finance`; `.zap/api-finance.conf` pre-accepts the rate-limit "SQL Injection" false
    positive on the two export paths only (`:` and `%3A`), expiring 2027-05-16 (checked against a synthetic report: the
    list path still blocks).
  - **Seed** (`seed-academy.sh` demo phase, `ensure_finance`): EUR; "Cuota mensual" (Test Team, 4500, last three months,
    by hand) and "Matrícula de temporada" (U14 category, 12000, SEASON); payments (players 1-2 up to date, 4 and 7 behind
    since two months, enrolment of 10 waived "Beca deportiva"); five expenses (court 36000, kit 54000, tournament 15000,
    travel 22000, other 4500). Idempotent: plans by name, expenses by description, only OPEN dues touched.
- Contract: **finance.yaml unchanged, 1.0.0**; `apps/web/packages/finance` untouched.
- For WP124 (web): CSV answers are `text/csv; charset=utf-8` with `Content-Disposition` (CORS exposes only ETag/Location,
  as core); send `Accept-Language` = app locale. Balance 404 also means "no currency yet". Expense category labels I used
  in the CSV (the web may pick its own): es Alquiler de pista, Salarios, Equipación, Inscripciones de torneos, Viajes,
  Otro; id Sewa lapangan, Gaji, Perlengkapan, Biaya turnamen, Perjalanan, Lainnya. `currencyLocked` is now also true
  after the first expense.
- Verified (2026-11-16, fresh, this worktree): `just test` exit 0: Maven 3,556 tests, 0 failures, 0 errors, 32 skipped
  (surefire reports; e2e 38 of which the 32 journey steps skip without a base URL); Rust 100 tests, 95.41 % / domain
  99.80 %, cargo deny ok; Go 204 tests (158 top-level), coverage 89.05 % module / 98.84 % domain, golangci-lint 0 issues,
  govulncheck none reachable. `just isolation-check`: 6 Java + 4 Go passed; `just db-role-check`: 13 Java + 2 Go passed;
  `just test-hooks`: 55/55 + 5/5 + 3/3, Python 43 OK (1 skipped); `actionlint` clean; shellcheck clean on the changed
  scripts; `./mvnw -pl e2e verify` compiles the journey (38 tests: 6 MailSink pass, 32 skipped).
- **Not run**: the journey, the real core -> pdf-service and game -> pdf-service calls, the ZAP finance scan and the seed
  on compose. The worktree `.env` holds `.env.example` values and the shared compose database refuses them
  (`finance_app` and `core_app` password authentication failed); per instructions I did not take the main checkout's
  values. CodeQL/Semgrep: CI only.
- Compose stack: untouched by this WP (no service started from this worktree, nothing listening on 8081-8085; the
  `finance` schema is as main left it, V20-V22 not applied). After merge: `just finance-up` (migrates to V22), then
  `just events-backfill force` (slug, team names; game's academy names), then `just e2e` / `just seed-academy`.
- Decisions/ADRs: ADR-0056 amendment WP123 (hard delete; expense locks the currency; balance 404s; export details;
  replica slug/name); authz-matrix note; e2e and local-stack runbooks.
- Open points: (1) run the journey, ZAP finance and the seed on compose with the real `.env` (first real PDF calls);
  drop the ZAP acceptances if the scan never raises them; (2) the `currencyLocked` description in finance.yaml names
  only dues (docs-only follow-up, next contract bump); (3) the CI e2e job now builds the Rust and Go images (slower);
  (4) TDD: `TestAnExpenseFixesTheCurrencyAsADueDoes` and the journey steps were committed with or after their code, not
  as separate red commits.
