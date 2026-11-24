# WP145 — athlete-service, database bootstrap, chart: a trigram index for the exercise search

Model: Opus · medium. Wave 3 (2026-11-24, tenth round): starts after WP144 is merged; runs alongside WP146 (kind and
CI hardening), which is the wave's kind user. You own `services/athlete-service/**`, the extension lines in
`infra/db/init/**` and in the `databases` sub-chart's bootstrap (WP146 owns `deploy/kind/**` and the workflows; if the
kind values need a line for the extension, say so in the handover and to the orchestrator, who passes it to WP146).
Depends on: WP144 (the PostgreSQL version and the bootstrap files as it left them); ADR-0041. Skills: work-package,
quarkus-hexagonal-service, tenant-isolation-testing, test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp145-trigram-index-for-the-item-search`, branch
`wp145-trigram-index-for-the-item-search`.

Decision 116 of 2026-11-24: the exercise search of athlete-service (WP78, ADR-0041) gets its trigram index now that
the round touches the database bootstrap anyway. ADR-0075 is reserved for you (an amendment of ADR-0041 if that is all
it is).

## Scope
1. **Facts first**: find the search query (the catalogue and the search inside templates), what it matches on (`ILIKE
   '%…%'`, `unaccent`, lower-casing, which columns and languages) and show its plan on a table of realistic size (a
   few thousand exercises across tenants) before any change. If the plan is already an index scan, or the query cannot
   use a trigram index as written, report that instead of adding an index nobody uses.
2. **Extension**: `pg_trgm` cannot be created by `athlete_migrator` (not a superuser, and it stays that way): it is
   created by the bootstrap, once, in the place the one role list lives (`infra/db/init`) and in the chart's database
   init for CloudNativePG, in a schema the app role can use without new privileges. A stack that already exists needs
   it too: the idempotent role script (`infra/compose/db-roles.sh`) or its sibling creates it there. `just
   db-role-check` stays green: no new role attribute, no ownership change.
3. **Migration**: red test first: an athlete Flyway migration `V<nn>__…` creating the GIN (or GiST, argued) trigram
   index on the searched expression, exactly the expression the query uses; a test that fails when the extension is
   missing with a message that says what to run; `RlsSchemaMetaTest` and the isolation suite unchanged and green (an
   index does not weaken RLS: the plan must still filter by tenant; show it).
4. **Proof**: the plan before and after on the realistic table, in the ADR. Search results identical before and after
   for the existing search tests (accents, case, three languages).

## Acceptance
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals); `just db-role-check` and `just
      isolation-check` green in the worktree
- [ ] `deploy/helm/tests/run.sh` green (snapshots re-recorded only for the extension line)
- [ ] The query plan before and after is in ADR-0075
- [ ] The handover says what the orchestrator runs on the owner's existing stack to get the extension
- [ ] Red tests committed before each change
- [ ] Handover appended: what was built, fresh verification with totals, what was not run, open points

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then a plain `git commit` with explicit paths, one at a time and not from a
  helper script (never `git add -A`, never `--no-verify`: the session refuses it). The pre-commit hooks run and may
  trim whitespace: re-add and commit again. Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation
  test before every commit (it resyncs the Podman VM clock itself); it is expected, do not try to bypass it; if it
  times out under load, retry when a build has finished. End every commit message with a `Co-Authored-By:` line
  naming the model that did the work.
- If your context runs low, stop at a green commit, append a handover part (what is done, what comes next in order)
  and report; a fresh agent continues in this worktree.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.
- Do not read, copy or print any `.env`. The compose stack that is running is the owner's: do not `just down` it, do
  not remove or recreate its volumes. What needs the real stack or the owner's database comes back "not run" in the
  handover; the orchestrator runs it from the main checkout at merge time.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
