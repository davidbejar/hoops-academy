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
