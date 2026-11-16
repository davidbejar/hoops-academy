# WP119 — Finance: roster replica, dues (manual and job), payments, coach and family reads

Model: Opus · effort high. Wave 3 (2026-11-15, eighth round): starts after WP118 is merged; runs alongside WP120
(observability: chart, compose, kind), WP121 (web Finance area, built on the same contract) and WP122 (web PDF
buttons). You own `services/finance-service/**` and migrations V10–V19. `libs/contracts/openapi/finance.yaml`: the
contract is 1.0.0 and WP121 builds on it; change it only additively (minor bump, regenerate
`apps/web/packages/finance`) and tell the orchestrator in your report. You touch no chart, compose or realm file
(WP118 wired the consumer's broker user and environment; if something is missing, report it). Depends on: the WP118
handover, ADR-0055, ADR-0056, ADR-0037, decisions 93, 95–98. Skills: go-hexagonal-service, tenant-isolation-testing,
owasp-security, test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp119-finance-dues`, branch `wp119-finance-dues`.

Decisions of 2026-11-15 (owner): **93** cadence per plan; **95** full payment only, void with a reason; **96** ADMIN
manages, PARENT and PLAYER read their own, a team's current COACH reads status only; **97** a due for every period
with the player on the roster on any day, ADMIN may waive or change the amount with a reason; **98** daily job and
manual generation.

## Scope
1. **Roster replica** behind a port, from core's events by the rules of ADR-0037 (idempotent upserts, soft removals
   with their dates, parked invalid events, the start guard); players, teams, guardians' links, team staff. The new
   tables pass the RLS suites.
2. **Dues**: generation for a plan and period (preview and apply, idempotent: a re-run adds only the missing ones);
   the daily job in each academy's time zone, safe with several replicas (a database lock) and following the pattern
   the Java services use for cross-tenant jobs (no nil-tenant bind without a dated acceptance); list with filters;
   change amount and waive on an open due with a reason.
3. **Payments**: pay a due in full (date, method, note); void with a reason, the due open again, the voided payment
   kept. Audit records for every write.
4. **Reads**: the coach's team status (current staff only, booleans, no amounts), the family's dues (a linked player
   only; a parent of another player gets 404-style no existence leak as the matrix says). Role-matrix tests from the
   matrix; a denial is a security event.
5. **Docs**: ADR-0056 amendment for anything the model needed, the matrix rows if they changed.
6. **Privacy** (WP112, `docs/security/privacy-threat-model.md` P-10, P-12): the roster replica stores no birth date
   and no gender (a test on the decoder proves they are dropped); reasons and notes are never logged or put on a
   span.

## Acceptance
- [ ] Red tests committed before each change; RLS suites green for the new tables
- [ ] `just test` green (fresh; totals per language, coverage); `just isolation-check` green
- [ ] The job proven idempotent and single-run with two instances in a test
- [ ] Handover appended: endpoints still 501, contract changes (if any), what WP123 builds on, what WP124 must know
      about statuses and empty states

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
- Built:
  - **Roster replica** (V10): `player_ref`, `team_ref`, `team_player_ref`, `team_staff_ref`, `guardian_link_ref`
    (ADR-0037 rules: idempotent per event id, `occurred_at` guard, soft removals without state, invalid records parked);
    the consumer reads all seven `core.*` topics (schemas copied, drift test). V11 `person_ref.display_name` (for
    `recordedBy` / `voidedBy`), V12 index of a due's payments. No birth date or gender: the decoder never reads them
    (`TestAPlayerEventDropsBirthDateAndGender`). `RosterStore` answers candidates, a team's roster today, a coach's
    current teams (staff role COACH, season not ended), linked players, own player, season dates, the academy's zone.
  - **Domain**: `Due` (change amount / waive with a reason, pay in full, reopen after a void), `Payment` (void with a
    reason, kept), `DueWindow` (period ∩ season), `StartedWindows` (the job's), `OncePerPlayer`, `Today(zone)`,
    `SystemActor`.
  - **Use cases + REST** (9 operations off the 501 list): `generateDues` (preview, idempotent), `listDues` (filters,
    pages), `getDue` (every payment), `changeDueAmount`, `waiveDue`, `payDue`, `voidPayment`, `getTeamDueStatus`,
    `listPlayerDues`. Audit `dues.generated`, `due.amount_changed`, `due.waived`, `payment.recorded`, `payment.voided`
    (ids, period, method, count only).
  - **Daily job** (`application.DuesJob`, `adapters/in/job.Runner`): every instance ticks hourly
    (`FINANCE_DUES_JOB_INTERVAL`, `FINANCE_DUES_JOB_ENABLED`), `pg_try_advisory_xact_lock('finance.dues-generation')` in
    a lock transaction binding no tenant (`persistence.Exclusive`), academies from `finance.replica_tenant`
    (`TenantDirectory`), each in its own `InTenant` transaction, ACTIVE only, on its own date (tzdata embedded); audit
    actor `system` with no person.
- Verified (2026-11-16, fresh, in this worktree):
  - `just test`: the first run stopped in athlete-service on `RealResolverApiTest` "Port already bound: 8081" (another
    agent's build; this branch changes no Java). Re-run of the same steps with `./mvnw -q -T 1C verify
    -Dquarkus.http.test-port=0`: exit 0, 3,550 tests, 0 failures, 0 errors, 26 skipped (surefire reports); `just test-rust`
    exit 0: 100 tests, coverage 95.41 % / domain 99.80 %, cargo deny ok; `just test-go` exit 0: gofmt clean,
    golangci-lint 0 issues, 165 Go tests (138 top-level) all passing, coverage 88.27 % module / 98.60 % domain,
    govulncheck: no vulnerabilities in reachable code.
  - RLS suites: the schema inspection and the isolation suite cover the five new tables (13 tenant tables).
  - The job: `TestTheDuesJobRunsOnceAcrossInstancesAndIsIdempotent` (lock held by one instance: the other skips; both at
    once: 3 dues, 2 audit records; a re-run creates 0), `TestTheJobUsesEachAcademysTimeZone`.
  - `just isolation-check`: 6 Java + 3 Go tests passed (the new `TestCrossTenantDuesAndPaymentsAreRefused` included);
    `just db-role-check`: 13 Java + 2 Go passed.
  - Not run: the service against the shared compose database or kind (see open points), CodeQL / Semgrep (CI), `just e2e`.
- Decisions/ADRs: ADR-0056 amendment "WP119" (who owes: valid assignments, `left_on` inclusive; generation order; the
  job; locks; reads; audit metadata); matrix note appended (current coach = staff role COACH; family 403 before lookup).
  Choices: an unknown or unlinked player is 403 for PARENT / PLAYER (the matrix's oracle; no existence leak since the
  check comes before any read); ADMIN gets an empty page for a player without dues and 404 for an unknown team; a season
  whose teams are unknown is 422 `PERIOD_OUTSIDE_SEASON`; the job also fills earlier started periods (late roster
  changes). Families still see no reasons (ADR-0056 choice kept).
- **No contract change**: `finance.yaml` stays 1.0.0, `apps/web/packages/finance` untouched; no chart, compose or realm
  file changed (the consumer needs no new ACL: `core.*` read is granted).
- Still 501: `exportDues`, `listExpenses`, `createExpense`, `exportExpenses`, `getExpense`, `updateExpense`,
  `deleteExpense`, `getSeasonBalance` (WP123; `rest/later.go`, `NotImplemented` in `feeplans_test.go`, `built` = 18).
- For WP123: reuse `application.DueFilter` + `DueStore.List` for the dues export (same filters; ask for the 10,001st row
  to detect `EXPORT_TOO_LARGE`), `DueRecord` carries plan and player names and the valid payment; the balance can sum
  `finance.due` by status joined to `fee_plan.season_id` (PAID by the valid payment's amount); `Exclusive` /
  `TenantDirectory` exist for any job; migrations from V20.
- For WP124 (web): statuses `OPEN`, `PAID`, `WAIVED`; `upToDate` is false only for an OPEN due whose period has started
  (a WAIVED or future due never makes a player behind); empty states: a team without players `players: []`, a player
  without dues `items: []`; `paidOn` / `paymentMethod` null unless PAID (a WAIVED due has none); `playerName` can be ""
  (player removed in core), `recordedBy.displayName` "" (member without an event since V11, until a replay); a coach of
  another team and a parent of another player get 403.
- Open points / follow-ups:
  - The commit hook ran in the main checkout, not on this branch: the checks above were run here by hand.
  - Not run against the shared compose database: starting this binary there would migrate `finance` to V12 and the
    main-branch binary (V1-V9) would then refuse to start (history without files) for the other agents; the Go suites
    run on their own Testcontainers PostgreSQL. After merge: `just finance-up` migrates compose.
  - Existing replicas (compose, kind) lack `display_name` and the new aggregates until core's events arrive again: run
    `just events-backfill` (or reset the group `finance-service.roster`) after deploying, before relying on the dues.
  - `docs/security/privacy-threat-model.md` P-10 / P-12 can be marked mitigated for finance by the docs pass (WP125).
  - Not done: lag metric of the replica (from WP118), mutation testing for Go, replica retention job for
    `applied_event` (ADR-0037 WP82 pattern) — follow-ups.
