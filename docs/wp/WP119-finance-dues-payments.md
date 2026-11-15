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
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
