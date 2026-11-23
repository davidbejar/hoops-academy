# WP137 — Library, services, build: Problem exceptions, paging, language, clock, shared properties, poms, test support, vectors

Model: Opus · high. Wave 4 (2026-11-23, ninth round): starts after wave 3 is merged; runs alongside WP138 (web). You
own `libs/**`, `services/core-service/**`, `services/game-service/**`, `services/athlete-service/**`, the root
`pom.xml`, `e2e/pom.xml`, and in the web app only `apps/web/test/fixtures/vectors/**` with the one test that reads it
(WP138 does not touch those). Depends on: WP130, WP134; ADR-0032, ADR-0053. Skills: work-package,
quarkus-hexagonal-service, tenant-isolation-testing, test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp137-common-plumbing-properties-poms-test-support`, branch
`wp137-common-plumbing-properties-poms-test-support`.

Decision 104 of 2026-11-23: generic plumbing that exists per service moves to `common-quarkus`; domain code stays per
service. ADR-0069 is reserved for you (write it: what is shared, what stays per service and why; it amends ADR-0053
where needed).

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings: `libs.md`
(LIB-02..LIB-13 except LIB-09), `cross-cutting.md` (X-04, X-06, X-07, X-09, X-10, X-12, X-13), verification
`verify-cross-cutting-libs.md` (its section "Overlaps between files" lists the per-service IDs of each: CORE-07,
CORE-08, CORE-15, CORE-18, CORET-07, GAME-07, GAME-09..12, ATH-06, ATH-08, ATH-09, ATH-13, ATH-17), all under
`~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Problem plumbing (LIB-03)**: one `InvalidRequestException`, `ProblemType` gains 415 and 502, the unreadable-JSON
   mapper for all three, no hand-built URN; answers validated against the contracts.
2. **Small shared types**: Accept-Language negotiation and the es/en/id enum (X-07), paging result / `PageMeta`
   (LIB-04), the `Clock` producer (X-12), the two pdf-service clients' keys and checks (X-06).
3. **Properties (X-04)**: the 25 keys identical in the three `application.properties` move to the library's file;
   restated defaults and the stale comment go; show with a test that each service still sees them.
4. **Poms (LIB-10)**: assertj, wiremock, json-schema-validator and the surefire / jacoco / `keycloak-it` boilerplate
   managed once in the root pom; athlete's 90 % domain rule (WP127) stays.
5. **Test support (LIB-05, X-10)**: contract filters, LogCapture, WireMock resources, core-event fixtures,
   tenant-bound JDBC into the test-jar; core gets the built-in-credentials test it lacks.
6. **Dead and tripled**: LIB-06 (`TenantHeaderPropagationFilter` with its tests and PIT entries), LIB-02 (projection
   vectors: one copy in `libs/contracts/vectors`, game and the web read it or a generated copy; the two sync tests and
   the script go if nothing is left to sync).
7. **The rest**: LIB-07, LIB-08, LIB-12, LIB-13 and whatever else of your scope is confirmed.

Not yours: X-08 / CORE-06 (`PatchBody` copies: FOLLOW-UPS and ADR-0053): leave. The realm variables (X-05) are WP139:
do not rename them while moving properties.

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals)
- [ ] `just web-test` green if the vectors moved
- [ ] `just mutation` for common-quarkus and the three services at or above baseline
- [ ] `just isolation-check` and `just db-role-check` run by hand
- [ ] contract versions bumped only if an answer really changed (say which)
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
