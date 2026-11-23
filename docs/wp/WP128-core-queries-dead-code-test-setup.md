# WP128 — Core: guardian-link N+1, outbox sends, one paged-query builder, dead code, test profiles and helpers

Model: Opus · high. Wave 1 (2026-11-23, ninth round): runs alongside WP126 (game), WP127 (athlete), WP129 (web). You
own `services/core-service/**`; nobody else touches it. You do not touch `libs/**`, the other services or the root
`pom.xml`. Depends on: ADR-0015, ADR-0048, ADR-0053. Skills: work-package, quarkus-hexagonal-service,
tenant-isolation-testing, test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp128-core-queries-dead-code-test-setup`, branch `wp128-core-queries-dead-code-test-setup`.

Decision 104 of 2026-11-23: everything confirmed in core-service is fixed. ADR-0060 is reserved for you if a decision
is needed.

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings:
`core-service-main.md` (CORE-01..20) and `core-service-tests.md` (CORET-01..10), verification
`verify-core-service.md`, all under `~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Queries**: CORE-01 (one `personOf` query per guardian link: batch it as the sibling view builders do), CORE-04
   (outbox sends are serial, 100 acks per batch under row locks: pipeline them), CORE-02 as corrected (the
   verification's numbers), CORE-12 (drop `usage_snapshot_tenant_idx`, no reader).
2. **One paged-query builder (CORE-03)**: the paged-list query building is copied into 9 repositories in 4 styles;
   `AuditEventQueryRepository` has the builder: share it inside core.
3. **Dead code**: CORE-13 (dead port methods, the `StaffTeams` pass-through) and the stale `RejectRequest` Javadoc;
   `LikePattern.contains` (CORE-09) inside core only.
4. **Test set-up**: CORET-01 (five non-default profiles each restart Quarkus, Postgres and Flyway: drop the avoidable
   ones, `RequireSub` first), CORET-02 (two Keycloak tests share `KeycloakContainerResource`), CORET-03..06 (the
   tenant-header `request()` in 24 classes, `directGrant` three times although `RealmTokens.password` exists in the
   test-jar, `TestRealm.locate`, `sqlState` / `count`). The fixed sleeps guard negative assertions: leave them.
5. **MailHog pin**: the test resource uses `mailhog:latest`: pin it as the other images are pinned (the compose side
   is WP139).
6. **The rest**: every other CORE / CORET finding of your scope.

Not yours: CORE-06 (ADR-0053) and CORE-11 (ADR-0048): leave. CORE-07, CORE-08, CORE-15, CORE-18, CORET-07 (WP137).

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals)
- [ ] the number of Quarkus boots in a default `verify` of core before and after (in the handover)
- [ ] `just mutation core-service` at or above the baseline (record the score)
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
