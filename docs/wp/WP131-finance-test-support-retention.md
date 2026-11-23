# WP131 — Finance: test support once, one Postgres per test run, `applied_event` retention, small clean-ups

Model: Opus · medium. Wave 2 (2026-11-23, ninth round): starts after wave 1 is merged; runs alongside WP130 (library,
game, athlete), WP132 (pdf), WP133 (CI). You own `services/finance-service/**`; nobody else touches it. Depends on:
ADR-0055, ADR-0056, ADR-0037. Skills: work-package, go-hexagonal-service, tenant-isolation-testing,
test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp131-finance-test-support-retention`, branch `wp131-finance-test-support-retention`.

Decisions 104 and 112 of 2026-11-23: everything confirmed in finance-service is fixed; the token clock leeway takes
the Java services' value (find it in `libs/common-quarkus` or the services' configuration and cite it). ADR-0063 is
reserved for you if a decision is needed.

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings: `finance-service.md`
(FIN-01..15), verification `verify-pdf-finance.md`; X-11 in `cross-cutting.md`, verification
`verify-cross-cutting-libs.md`, all under `~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Test support (FIN-02)**: one home for the UUID, `set_config` and port-wiring helpers; `main.go` and the tests
   build the ports through the same constructor so a forgotten port cannot compile.
2. **Contract guard (FIN-15, bug)**: the dead 501 branch in the contract helper: failing test, remove.
3. **Containers and keys (FIN-03, FIN-05)**: one Postgres per `just test-go` run (template databases) instead of one
   per test binary; one RSA key per test binary instead of one per test.
4. **Retention (FIN-11)**: already in FOLLOW-UPS: add the retention job for `applied_event` on the ADR-0037 pattern;
   keep the index, the job uses it.
5. **Leeway (X-11)**: the token clock leeway equals the Java services'; a test states the number.
6. **The rest**: FIN-04, FIN-07, FIN-08 and every other FIN finding of your scope; the skill `go-hexagonal-service`
   (`rest/later.go` is gone; `export` and `job` packages) is yours to correct.

Not yours: FIN-01 (the two transactions per request are deliberate): leave. FIN-06 and FIN-13 are the Go twins of Java
plumbing: leave unless the verification says otherwise.

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `just test-go` green (fresh; totals; wall-clock before and after)
- [ ] the RLS and isolation suites of finance green
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
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points, ID table (work-package skill). -->

- Built (branch `wp131-finance-test-support-retention`, 16 commits from `3f17f4d5` to the handover commit):
  - Contract guard (FIN-15, bug): `api.do` no longer skips 501, and kin-openapi's default of letting an **undeclared
    status** pass is switched off (`IncludeResponseStatus`), so the guard was weaker than the audit said. Red test
    `TestEveryAnswerIsCheckedAgainstTheContract`. finance.yaml declares no 413 / 415 (core.yaml does): the two calls in
    `TestInvalidRequestsAreProblemsNamingFieldsNeverValues` are marked `outside` until it does (open point).
  - Leeway (X-11): `oidc.Leeway = 0`, the Java value: no service sets `quarkus.oidc.token.lifespan-grace`;
    quarkus-oidc 3.40.1.2's `OidcProvider` calls `setAllowedClockSkewInSeconds` only when it is set (bytecode
    checked) and jose4j 0.9.6's `NumericDateValidator` defaults to 0. Test `TestTheClockLeewayIsTheJavaServicesZeroSeconds`
    (exp 2 s ago refused, nbf in 2 s refused). Same value as WP132's pdf-service.
  - Test support (FIN-02): `persistence.NewPorts` (unkeyed literal: a new `Ports` field fails to compile until wired)
    used by `main.go`, the API and the job tests; `pgtest.InTenant / Exec / Rows / Value` replace six hand-written
    `set_config` transactions (rest, seed, job, persistence, rls); the four UUID generators give way to `ids.V7`;
    `platform/clock.System` replaces main's and the API tests' clocks, the job tests keep one clock type.
  - One Postgres per run (FIN-03): `check.sh` starts `pgtest/serve` once and exports `PGTEST_TEMPLATE_URL`; each
    binary copies `hoops` (with hoops' database ACL) and drops its copy. Without the variable a binary starts its own
    container (checked).
  - One RSA key per binary (FIN-05): `realm.Start` shares a key; `StartWithOwnKey` for the foreign-key case.
  - Retention (FIN-11): `application.ReplicaRetention` + `ReplicaStore.DeleteAppliedBefore` + `job.Retention` (daily,
    lock `finance.replica-retention`, 7 days, batches of 1000, metric `hoops_roster_replica_pruned_total`); index kept.
  - FIN-04 season cache, FIN-07, FIN-08, FIN-09, FIN-10, FIN-14 (see table); the `go-hexagonal-service` skill
    corrected; the `events` package comment refreshed.
- Verified: `just test-go` green, fresh: 167 top-level tests pass (158 before), coverage 88.73 % module / 98.84 %
  domain, govulncheck clean; wall-clock 37.2 s before, 24.8 s and 29.9 s after (two runs; other worktrees were
  building). RLS / isolation / role suites of finance green (15 top-level tests). `just isolation-check` green (6 Java
  + 4 Go tests); `just db-role-check` green (13 Java + 2 Go tests).
- Decisions/ADRs: ADR-0063 (retention constants, 0 s leeway, one test database per run).
- Open points / follow-ups: finance.yaml should declare 413 and 415 on its JSON-body operations (contract owner; then
  drop `outside` in the test). `parked_event` has no retention in finance (no `inspected_at`, the app role may not
  delete; ADR-0063). The audit's "pgx can scan `[16]byte` uuids" lead was not tried.

| ID | Done / Skipped | What changed or why not |
|----|----------------|-------------------------|
| FIN-01 | Skipped | Excluded by the brief (two transactions per request are deliberate). |
| FIN-02 | Done | `persistence.NewPorts`, `pgtest` tenant helpers, `ids.V7` in tests, `clock.System`. |
| FIN-03 | Done | One server per `just test-go`, a template copy per test binary. |
| FIN-04 | Done (part) | Season dates cached per academy and run; skipping already-generated windows left out (verification: M with risk of missing a late-joining player; the cost is small at this scale). |
| FIN-05 | Done | One RSA key per test binary. |
| FIN-06 | Skipped | Excluded by the brief (Go twin of Java plumbing); the verification did not say otherwise. Only `readClearList` moved to `patch.go` (FIN-14). |
| FIN-07 | Done | `optional`, `optionalText`, `idTexts`; `PlansWithDues` through `ids()`. |
| FIN-08 | Done | `missing` and `required(field...)` in `problem.go` for all seven sites. |
| FIN-09 | Done | `DueQueries` merged into `DueStore`; `Ports.Dues` is the due store. |
| FIN-10 | Done | gofmt formatter dropped from `.golangci.yml`; the `gofmt -l` step stays first. |
| FIN-11 | Done | Retention job on the ADR-0037 pattern; index kept and used. |
| FIN-12 | Skipped | Verification: low value, medium risk (contract-validated page/total semantics); the audit ties it to FIN-01, which stays. |
| FIN-13 | Skipped | Excluded by the brief; ADR-0048 pins the parser's behaviour. |
| FIN-14 | Done | dues export with the dues routes, `exports.go`, `balance.go`, `listPlans` through `writeItems`. |
| FIN-15 | Done | 501 exception removed and undeclared statuses now fail the guard. |
| X-11 | Done | Leeway 0 s, as the Java services (finance part; pdf in WP132). |
