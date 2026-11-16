# WP125 — Docs pass, eighth round

Model: Opus · effort medium. Wave 5 (2026-11-15, eighth round): runs last and alone, after WP111–WP124 are merged.
You own README.md, `docs/HANDOVER.md`, `docs/wp/FOLLOW-UPS.md`, `docs/conformance.md`, `docs/roadmap.md`,
`docs/architecture.md`, `docs/adr/README.md`, `docs/PLAN.md` status box and the user guides (es / en / id). The
rule "do not edit README, HANDOVER, FOLLOW-UPS" below does not apply to you. Depends on: every handover of the
round. Skills: verification-before-completion. Worktree: `~/code/hoops-wt/wp125-docs-pass`, branch `wp125-docs-pass`.

## Scope
Follow the Close-out checklist of `.claude/skills/wp-round/SKILL.md`:
1. **FOLLOW-UPS**: plan table statuses; the TODO items now built (pdf-service, finance-service, PMD, LINDDUN,
   observability, the small fixes, `images` red) moved to Resolved with their WP; the LINDDUN findings (WP112) and
   every handover's Open points as new open items.
2. **HANDOVER**: State (merge order with commits, contract and chart versions, test totals per language), Pending,
   Working conventions (environment facts only: Rust and Go toolchains, the new gates), Next candidates.
3. **README, conformance, roadmap, architecture** (five deployables, the finance bounded context, the PDF path),
   the ADR index, the user guides (Finance area per role, PDF buttons).
4. **CI state** on `main` observed with `gh run list -b main` (run ids in HANDOVER), `images` included.
5. **Orchestrator fixes of the round** (no work package; put them in HANDOVER and FOLLOW-UPS): 4d10d7cf the compose
   nginx limit counts only the public POST of `/platform/academy-requests`; 54e7a2da `tenant_timezone_test.dart`
   failed late on Sundays in UTC; a new dated ZAP acceptance in `.zap/api-core.conf` (40018 on
   `/platform/academy-requests`, until 2027-05-16: the 429 of the WP115 limit, as WP83's for `events:batch`) goes
   into "Acceptances with an expiry".
6. **More orchestrator notes** (2026-11-16): the realm audience mappers for `pdf-service` (dd54179d) and the web's
   `finance-service` audience line in `RealmTokenPolicyTest` were added at merge time; 0c9309aa (finance image
   check's cleanup) and a9649e02 (Go before CodeQL init) fixed the workflows; the commit hook's isolation check runs
   in the session's directory (the main checkout), so in a worktree it never checks the branch (open item: make it
   follow the commit's worktree); the owner's `.env` got `FINANCE_MIGRATOR_PASSWORD`, `FINANCE_APP_PASSWORD` and
   `REDPANDA_FINANCE_SERVICE_PASSWORD` copied from WP118's worktree; a network outage stopped wave 2 for about five
   hours (the watchdog resumed the agents); P-07 of the privacy threat model and `release.md`'s Jaeger line are out
   of date since WP120; database spans are missing in every service (WP120 handover); game's academy names need
   `just events-backfill force` (WP117 handover).
7. **Wave 4 notes** (orchestrator, 2026-11-16): WP123's agent could not run the journey (its worktree `.env` could
   not sign in to the shared database); the orchestrator ran `just e2e` on compose from the main checkout with WP123
   merged: 38 tests, 0 failures, `JourneyTest` 32 with none skipped, which is also the first real core → pdf-service
   and game → pdf-service call on compose. Not run by anyone: the finance ZAP scan outside CI (see the `e2e` run on
   the WP123 merge), whether its two pre-accepted export lines in `.zap/api-finance.conf` ever match (drop them if
   not). A usage limit stopped wave 4 once (resumed after the reset). Owner decision still open: IDR is stored with
   2 minor digits (ISO 4217) and shown without decimals for whole amounts (WP121 handover).

## Acceptance
- [ ] Every claim checked against a handover, a commit or a command you ran
- [ ] Links resolve (the repository's link check, if any; otherwise grep)
- [ ] Handover appended

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
