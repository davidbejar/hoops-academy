# WP127 — Athlete: roster reads per request, tenant zone from the context, the 90 % domain gate, one test group

Model: Opus · high. Wave 1 (2026-11-23, ninth round): runs alongside WP126 (game), WP128 (core), WP129 (web). You own
`services/athlete-service/**` including its `pom.xml`; nobody else touches it. You do not touch `libs/**`, the other
services or the root `pom.xml`. Depends on: ADR-0037, WP98. Skills: work-package, quarkus-hexagonal-service,
tenant-isolation-testing, test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp127-athlete-roster-reads-zone-gate`, branch `wp127-athlete-roster-reads-zone-gate`.

Decision 104 of 2026-11-23: everything confirmed in athlete-service is fixed. ADR-0059 is reserved for you if a
decision is needed.

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings: `athlete-service.md`
(ATH-01..19), verification `verify-game-athlete.md`; X-03 in `cross-cutting.md`, verification
`verify-cross-cutting-libs.md`, all under `~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Roster reads (ATH-01)**: on the replica path the roster is re-read per request with no cache (160 statements for
   a parent's plan list). A request-scoped memo with a fallback outside requests, or a `teamsOf(players)` query. Do
   **not** use `playerTeamIds` for parents: it hides teams whose season ended.
2. **Authz resolver (ATH-04)**: two season queries on every request; game has a `seasonEnds` map. Keep the rule itself
   as it is: WP134 moves it to the library.
3. **Tenant zone (ATH-03, with its bug)**: take the zone from `AuthzContext.timezone()`, drop the read of
   `tenant_registry` per call and the "older core" fallback (the contract requires `timezone`); keep a last-resort
   default for a zone the JVM does not know; the API tests must exercise the real branch.
4. **Domain gate (X-03)**: the pom has only the parent's 80 % rule: add the >= 90 % `domain` rule as game has it, with
   the tests it needs. Say in the handover that `docs/conformance.md:163` was wrong until now.
5. **Test groups (ATH-07)**: the 17 Postgres-only test classes join the main group, as game did.
6. **Locale (from CORE-09)**: `PlanJpaRepository` lower-cases without a fixed locale: failing test, fix.
7. **The rest**: every other ATH finding of your scope, and ATH-19 (the service README).

Not yours: ATH-02 and ATH-05 (WP130), ATH-06, ATH-08, ATH-09, ATH-13, ATH-17 (WP137), ATH-15 (ADR-0037 keeps the REST
client as the fallback: leave).

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals)
- [ ] the jacoco check fails when a `domain` class drops below 90 % (show it once, red)
- [ ] `just mutation athlete-service` at or above the baseline (record the score)
- [ ] `just isolation-check` and `just db-role-check` run by hand in the worktree (results in the handover)
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
