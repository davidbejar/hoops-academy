# WP118 — finance-service in Go: toolchain, isolation harness, whole contract, settings and fee plans, chart

Model: Opus · effort high. Wave 2 (2026-11-15, eighth round): starts after WP111 (pdf-service: copy its toolchain
wiring, read its handover) and WP114 (base image) are merged; runs alongside WP116 (core) and WP117 (game), which
touch only their service, contract and Dart package. You own `services/finance-service/**`,
`libs/contracts/openapi/finance.yaml`, the new generated `apps/web/packages/finance` (and `scripts/gen-api.sh`),
`deploy/containers/finance.Containerfile`, `deploy/helm/**` (chart 0.11.0 → 0.12.0), `deploy/kind/**`, `Tiltfile`,
`infra/compose/**`, `infra/db/**`, `infra/keycloak/realm-academy.json`, `justfile`, `scripts/doctor.sh`,
`scripts/bootstrap.sh`, `scripts/build-images.sh`, `scripts/hooks/**`, `.github/workflows/*.yml`,
`.github/dependabot.yml`, a new skill `.claude/skills/go-hexagonal-service/`, the lines of `CLAUDE.md` that name the
new service, `docs/adr/0055-*.md`, `docs/adr/0056-*.md`, and the finance section of `docs/domain/authz-matrix.md`
(append at the end; WP116 / WP117 append one row each). You are the wave's only kind user. Depends on: ADR-0051,
ADR-0006 / ADR-0011, ADR-0017, ADR-0031 / ADR-0033, ADR-0034, ADR-0036 / ADR-0037, ADR-0043, ADR-0045, ADR-0046,
ADR-0048, decisions 92–99. Skills: tenant-isolation-testing, owasp-security, test-driven-development, clean-code,
podman-dev-env, verification-before-completion. Worktree: `~/code/hoops-wt/wp118-finance-foundation`, branch
`wp118-finance-foundation`.

Decisions of 2026-11-15 (owner): **93** each fee plan chooses its cadence (monthly, quarterly, once per season);
**94** one ISO 4217 currency per academy, amounts in minor units, fixed once the first due exists; **95** a due is
paid in full by one hand-recorded payment, a wrong payment is voided with a reason, no partial payments, no refunds;
**96** ADMIN manages everything, PARENT reads the dues and payments of linked players, PLAYER their own, a team's
current COACH reads who of the team is up to date (status only, no amounts), ASSISTANT_COACH nothing; **97** a due
for every period in which the player is on the roster on any day, full amount, ADMIN may waive an open due or change
its amount with a reason; **98** a daily job creates dues and ADMIN can generate them by hand (idempotent, preview);
**99** expense categories are a fixed list (court rental, salaries, kit, tournament fees, travel, other).
ADR-0055 is reserved for the Go stack and harness, ADR-0056 for the finance domain model.

## Scope
1. **Toolchain**: Go pinned (`go.mod` toolchain line, `go.sum` committed); bootstrap and doctor; `just test` gains
   the Go gates (`gofmt`, `golangci-lint` with a committed configuration: complexity, duplication, unused code, error
   handling; tests; coverage ≥ 80 % lines and ≥ 90 % in `domain`; a vulnerability check). ADR-0055 records the HTTP,
   SQL, Kafka and OpenAPI libraries, the migration tool (files `V<nn>__<snake_case>.sql`) and what is done about
   mutation testing of the rule code.
2. **Isolation harness before the first endpoint** (rule 2): schema `finance`, roles `finance_app` (non-owner, no
   `BYPASSRLS`) and `finance_migrator` in `infra/db/init` and the chart's databases; the tenant bound inside each
   transaction (ADR-0011); a schema meta test and a generic isolation test equal in strength to `RlsSchemaMetaTest`
   and `GenericRlsIsolationTest`, never connected as owner or superuser; a layering check (the ArchUnit counterpart);
   `just isolation-check` and `just db-role-check` cover finance (the hook's case table in `just test-hooks` first).
3. **Whole contract first**: `finance.yaml` 1.0.0 for the entire service, so the web can start in wave 3: settings
   (currency), fee plans (per team or category, amount, cadence, season, first and last period, automatic generation
   on / off), dues (list with filters, generate with preview, change amount, waive, pay, void a payment), team status
   for the coach, a player's dues for the family, expenses (fixed category enum), season balance, CSV exports of dues
   and expenses (ADR-0048). Problem+JSON, paging and naming as the three existing contracts (`common.yaml`).
   ADR-0056 fixes the model: how a period is identified per cadence, the states of a due (open, paid, waived), what
   voiding does, what is immutable. Endpoints not built in this WP answer 501 Problem and are listed in the handover.
4. **Build in this WP**: settings and fee plans end to end: authz in the application layer (non-members 404, never
   403; role-matrix tests from the matrix rows you add), audit records for writes (ADR-0017: say how finance writes
   them without `libs/common-quarkus`), security events and `hoops_authz_denied_total` (ADR-0043), OTLP traces and
   logs, responses validated against the contract.
5. **Delivery**: audience `finance-service` (client, mapper on `web`), gateway route with rate limits in chart and
   compose nginx, image (non-root, read-only root FS, Trivy gate, SBOM), compose service on port 8085, sub-chart
   behind a switch with NetworkPolicy, and already now the broker user, ACLs and environment the roster consumer of
   WP119 needs (WP119 cannot touch the chart: WP120 has it); Tilt; CI job; Dependabot for Go modules; SAST for Go.
6. **Kind proof**: `up.sh --deploy` with finance on; a fee plan created through the gateway as ADMIN; academy B
   cannot read it; the service's database role is not owner. Stop compose while proving on kind.
7. **Docs**: ADR-0055, ADR-0056, the authz-matrix section, the skill for agents working on the Go service,
   `CLAUDE.md` lines, the Dart package generated and committed (`apps/web/packages/finance`; add it to the web's
   `pubspec.yaml` so `flutter analyze` and `just web-test` stay green).

## Acceptance
- [ ] `finance.yaml` 1.0.0 complete and validated; Dart package generated and committed
- [ ] Red tests committed before each change; the Go RLS suites and the layering check fail on a planted violation
- [ ] `just test` green (fresh; Maven, Rust and Go totals, coverage); `just test-hooks`, `just isolation-check`,
      `just db-role-check` green with finance in them; `actionlint` clean; chart tests green
- [ ] Trivy 0 HIGH / CRITICAL on the image; kind proof recorded
- [ ] Handover appended: what WP119 and WP123 build on (packages, test helpers, migration numbers used and reserved:
      V1–V9 yours, V10–V19 WP119, V20–V29 WP123), the 501 endpoints, what WP121 needs (package name, audience,
      routes), chart version

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
