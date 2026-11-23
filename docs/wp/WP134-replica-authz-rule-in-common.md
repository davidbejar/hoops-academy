# WP134 — Library, core, game, athlete: replica authorisation rule once in `common-quarkus`, under mutation testing

Model: Opus · high. Wave 3 (2026-11-23, ninth round): starts after wave 2 is merged; runs alongside WP135 (web), WP136
(chart, kind). You own `libs/common-quarkus/**`, `services/core-service/**`, `services/game-service/**`,
`services/athlete-service/**`; nobody else touches them in this wave. Not the root `pom.xml`. The Go service keeps its
own copy (another language): add nothing there. Depends on: WP130; ADR-0053, ADR-0037, `docs/domain/authz-matrix.md`.
Skills: work-package, quarkus-hexagonal-service, tenant-isolation-testing, owasp-security, test-driven-development,
clean-code, verification-before-completion. Worktree: `~/code/hoops-wt/wp134-replica-authz-rule-in-common`, branch
`wp134-replica-authz-rule-in-common`.

Decision 107 of 2026-11-23: the rule that builds the authorisation context in replica mode is written once in
`common-quarkus` and used by core, game and athlete, under mutation testing once. ADR-0066 is reserved for you (write
it; it amends ADR-0053).

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings: `cross-cutting.md`
(X-02), verification `verify-cross-cutting-libs.md`; ATH-04 in `athlete-service.md` for the runtime side, all under
`~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Characterise first**: one table-driven pure unit test of the rule over its ports, taken from the authz matrix,
   run against the three existing copies before anything moves; every difference between the copies is listed and
   resolved in the ADR (a difference may be a bug: failing test first).
2. **Move**: the rule into the library behind ports each service implements over its own tables; non-members still get
   404; nothing about a tenant leaks through the shared code.
3. **Mutation testing**: the library class is in the PIT scope with a baseline at least as strict as game's was; the
   services' PIT entries for the removed copies go.

Not yours: Problem / paging / language plumbing is WP137.

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals)
- [ ] `just mutation` for common-quarkus and the three services at or above baseline (scores)
- [ ] `just isolation-check` and `just db-role-check` run by hand in the worktree (results in the handover)
- [ ] the role-matrix tests of the three services unchanged and green
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
