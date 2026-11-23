# WP130 — Library, game, athlete: roster replica pipeline once in `common-quarkus`

Model: Opus · high. Wave 2 (2026-11-23, ninth round): starts after wave 1 is merged; runs alongside WP131 (finance),
WP132 (pdf), WP133 (CI, scripts). You own `libs/common-quarkus/**`, `services/game-service/**`,
`services/athlete-service/**`; nobody else touches them in this wave. Not the root `pom.xml`, not core. Depends on:
WP126, WP127; ADR-0037, ADR-0053, WP98. Skills: work-package, quarkus-hexagonal-service, tenant-isolation-testing,
test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp130-replica-pipeline-in-common`, branch `wp130-replica-pipeline-in-common`.

Decision 106 of 2026-11-23: decoder envelope, consumer loop (one retry and metric policy, one reason limit) and
history store move into `common-quarkus`; the retention job stays per service (WP98), at most a small shared helper
behind each service's own `@Scheduled`. ADR-0062 is reserved for you (write it; it amends ADR-0037).

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings: `cross-cutting.md`
(X-01), `libs.md` (LIB-01), `game-service.md` (GAME-05, GAME-06), `athlete-service.md` (ATH-02, ATH-05); verifications
`verify-cross-cutting-libs.md` and `verify-game-athlete.md`, all under `~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Characterise first**: tests that pin today's behaviour of both consumers (retry, park, replay, metrics, reason
   cap), then choose one policy for the points where they differ and say which in the ADR.
2. **Move**: the envelope half of the core-event decoders, the consumer retry / park / metrics loop and the
   replica-history repository into the library's `replica` package; each service keeps its own projection (what an
   event means for its tables) and its schema. `parked_event` has the same shape in both schemas afterwards
   (migrations per service).
3. **Runbook**: `docs/runbooks/events.md` describes one procedure instead of two.
4. **Tests**: the library part is unit-tested and inside the PIT scope; the services' `RlsSchemaMetaTest` /
   `GenericRlsIsolationTest` stay green.

Not yours: the authorisation rule (X-02) is WP134; test-support copies are WP137.

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals)
- [ ] `just mutation` for common-quarkus, game-service and athlete-service at or above baseline
- [ ] `just isolation-check` and `just db-role-check` run by hand in the worktree
- [ ] lines removed from the two services vs added to the library (in the handover)
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
