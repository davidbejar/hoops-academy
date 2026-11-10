# WP98 — Events flip: `replica` by default in game and athlete, drift check, shared replica code

Model: Opus · effort high. Wave 2 (2026-11-10, sixth round): starts after WP92 is merged; runs alongside WP96
(core-service, core contract: you do not touch either), WP97 and WP99 (web). You own
`services/game-service`, `services/athlete-service` (configuration and replica code only), `libs/common-quarkus`,
`e2e`, the compose environment of the two services (`infra/compose*` / `.env.example` keys for the roster source),
`scripts/events-drift.sh` (new), the `justfile` recipe `events-drift` (next to the other `events-*` recipes),
`docs/adr/0037-*.md` (amendment), `docs/runbooks/events.md`. You do NOT touch `deploy/helm` or `deploy/kind`
(WP100 flips the chart default in wave 3). Flyway game `V7` and athlete `V11` are reserved for you if needed.
Depends on: decision 66, ADR-0037 ("When rest flips"), ADR-0036, WP81, WP82, WP88 (PIT baselines). Skills:
quarkus-hexagonal-service, tenant-isolation-testing, systematic-debugging, test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp98-events-flip`, branch `wp98-events-flip`.

Decision 66 of 2026-11-10: `replica` becomes the default roster source of game and athlete now, without the shadow
period over days (a pet project without production data; the journey and a 46-academy backfill already matched
core). In exchange a drift check compares core's rows with each replica on demand. `rest` stays as the fallback.

## Scope
1. **Default flip**: `hoops.roster.source` defaults to `replica` in both services (`GAME_ROSTER_SOURCE`,
   `ATHLETE_ROSTER_SOURCE` still override). `replica` with the consumer off refuses to start, so decide and test
   what the test profiles and dev mode do (tests that do not run the consumer pin `rest` or the in-memory path
   explicitly; dev mode keeps Dev Services). Compose runs both services on `replica` without overrides. Both sources
   keep their contract tests (`RosterPortContract`, `MembershipContract`, the authz context contract).
2. **Drift check** (`just events-drift`, `scripts/events-drift.sh`): an operator tool, read-only, that compares per
   aggregate (tenant, person, player, team, team player, team staff, guardian link) core's rows with
   `game.*_ref` and `athlete.*_ref`: missing in the replica, present and not removed in the replica but gone in
   core, and rows whose replicated columns differ. It runs SQL as the database operator the runbooks already use
   for inspection (compose: `podman exec` + `psql` as the superuser; kind: the CNPG primary), in one
   `REPEATABLE READ READ ONLY` transaction; no service role gains any grant and `just db-role-check` stays green.
   Output: counts per aggregate and service, the first differing ids (ids only, no personal data), exit 0 when
   equal, 1 on drift, 2 when it could not run. Allow for lag: retry a differing row once after a short wait before
   calling it drift. Test it against a database with a planted difference of each kind.
3. **Shared code** (FOLLOW-UPS "Duplicated test and job code"): one `RosterBrokerResource` in the common-quarkus
   test-jar; one `ReplicaRetention` with its rules test in common-quarkus (pure rule code, in PIT scope); game and
   athlete keep only their wiring. Mutation baselines move with the code: update `docs/quality/mutation.md` numbers
   only for the modules you changed and say so in the handover.
4. **e2e**: `secondTenantCannotSeeTheFirstTenantsData` waits for the replica to know tenant B before the first game
   or athlete call (an await with a deadline, not a sleep); the journey runs on `replica` by default.
5. **Decoders on a missing contracts jar** fail with a clear `IllegalStateException` at startup again (WP88 note).
6. **Docs**: ADR-0037 amendment "Flip of 2026-11-10" (what was skipped and why, the drift check, how to go back to
   `rest`: one setting, no data loss); `runbooks/events.md`: the default, the drift check, rollback.

## Acceptance
- [ ] Red tests committed before each change
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals per module)
- [ ] `just mutation common-quarkus`, `game-service`, `athlete-service` at or above the baselines (record scores)
- [ ] On compose (coordinate the stack with the orchestrator; never `just down`): `just events-backfill`, then
      `just events-drift` exits 0; `just e2e` green with no roster-source override
- [ ] After rebasing on `main`: `just diagrams` and commit the regenerated model pages if they changed (WP94)
- [ ] Handover appended: what WP100 must change in the chart and its tests (`deploy/helm/tests/run.sh` asserts
      `rest` today), the drift check's kind variant

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the line
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Never restart the Podman machine or its API service, never
  run `just down` or remove volumes: other agents use the same VM and compose stack.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/guides; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words: what was built, the
  fresh verification totals, versions and ADRs, open points, anything another WP must know.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
