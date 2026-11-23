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
