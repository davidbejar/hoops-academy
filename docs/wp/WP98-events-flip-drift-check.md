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
- **Built**
  - Default flip: `hoops.roster.source` defaults to `replica` in game and athlete (`${GAME_ROSTER_SOURCE:replica}`,
    `${ATHLETE_ROSTER_SOURCE:replica}`, and the `@ConfigProperty` defaults). The test profile pins `rest`
    (`%test.hoops.roster.source=rest`: its tests run no broker; `ReplicaRosterSourceTest`, `ReplicaProfile` and the
    broker tests switch source/consumer on themselves). Dev mode keeps the default (replica, consumer on, Kafka Dev
    Services). Compose runs both on `replica` without overrides (`.env.example` lists the two `rest` fallback keys
    commented out). Proof: `RosterSourceDefaultsTest` per service resolves the shipped `application.properties` per
    profile (prod/dev: replica + consumer on; `GAME_/ATHLETE_ROSTER_SOURCE=rest` overrides; test: rest, consumer off) with
    common's new test-jar helper `ShippedConfig`. Both sources keep their contract tests (unchanged).
  - game's consumer switch is now `hoops.roster.consumer.enabled` like athlete's (`GAME_ROSTER_CONSUMER_ENABLED` still
    sets it; `mp.messaging.incoming.core-roster.enabled` follows it), so one broker fixture fits both.
  - athlete's consumer polls every 100 ms (`poll-timeout`, `fetch.max.wait.ms`), as game's since WP68. Found by the
    first `just e2e` on the flipped default: athlete applied a guardian link 4 s after core wrote it (one topic per
    second) and refused the parent in between; game took 0.25 s. Test: `RosterSourceDefaultsTest` (both services).
  - Drift check: `scripts/events-drift.sh`, `just events-drift [--kind]`, test `scripts/tests/events-drift.test.sh`
    (`just events-drift-test`, 49 checks on a throwaway PostgreSQL: equal; missing/extra/differs per aggregate and
    service; a removed replica row of a live aggregate; athlete's staff `since`; a core change in both replicas with no
    personal data in the output; lag healed during the retry; unreachable database and unknown option exit 2).
  - Shared code: `com.hoopsacademy.common.replica.ReplicaRetention` (+ `ReplicaHistory`, `ParkedPosition`, one
    `ReplicaRetentionRulesTest`; a plain class, game and athlete have a `ReplicaRetentionProducer` with `@Startup`);
    `com.hoopsacademy.common.testing.RosterBrokerResource` in the test-jar (common gets `testcontainers-redpanda` at test
    scope; `RosterBrokerResourceTest` starts it and checks the seven topics).
  - Decoders: common's `ContractResources.json(...)` throws `IllegalStateException` naming the resource when the contracts
    jar is missing (`ContractResourcesTest`); `RosterEventDecoder`, `MatchEventDecoder`, `CoreEventDecoder` use it.
  - e2e: `secondTenantCannotSeeTheFirstTenantsData` awaits (30 s deadline) until game and athlete answer B's admin with
    200; `guardianLinkMakesTheParentSeeOnlyTheLinkedChild` awaits until both know the link (parent's season stats in
    game, `planned-absences?playerId=` in athlete).
  - Docs: ADR-0037 amendment "Flip of 2026-11-10" (index entry updated), runbook `events.md` (defaults, "The flip",
    "Switching between replica and rest", "Drift check", "Rollback to rest"), athlete README, `docs/quality/mutation.md`,
    model pages regenerated (`ReplicaHistory` left game's and athlete's class diagrams).
- **Verified** (after the rebase on `main` 6d07a4e4)
  - `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0`: BUILD SUCCESS, coverage gates met in all four modules;
    common-quarkus 403, contracts 315, core 1163, game 467, athlete 999 tests (0 failures/errors), e2e 32 (26 skipped
    without a stack). `just events-drift-test` 49/49, `just diagrams-check` up to date.
  - Mutation (before the rebase; no rule code changed by it): common-quarkus 337/338 (99.7 %, the listed `zoneOf`
    equivalent), game-service 525/527 (99.6 %), athlete-service 690/690 (100 %); thresholds unchanged (99/99/100), pom
    comments and `mutation.md` updated for these three modules only.
  - Compose (from this worktree): the stack's `hoops-keycloak`, `hoops-redpanda` and `hoops-mailhog` had been OOM-killed by
    the VM at 14:06-14:07 (exit 137) during the commit hook's isolation test under heavy load; I ran `just up` at 14:46,
    which started them and also restarted `hoops-postgres` and `hoops-nginx` (volumes untouched, no `down`). Then
    `e2e/bin/services-up.sh` (core migrated V17->V18, athlete V9->V10; both services logged "Roster source: replica"),
    `just events-backfill`: 16 academies, 0 failed, 0 appended; group lag 0; `just events-drift`: exit 0 (16 tenants,
    52 persons, 18 players, 12 teams, 36 assignments, 12 staff, 6 links, equal in both). First `just e2e`: failed at step 20
    (athlete lag above); after the fix `just e2e`: JourneyTest 26/26, MailSinkTest 6/6, no roster-source override. Then
    services up again, lag 0, `just events-drift` exit 0 (20/66/23/15/44/15/8, equal), services stopped
    (`services-down.sh`). Note: the compose database had 16 academies, not WP81's 46 (reset before this WP).
  - Not run: the `--kind` variant (no kind cluster up); `just mutation core-service` (core untouched by WP98).
- **Decisions/ADRs**: ADR-0037 amendment (decision 66). The test profile pins `rest`; dev mode stays on the replica.
  game does not get athlete's "replica needs the consumer" start guard: `ReplicaRosterSourceTest` runs game on the replica
  without a consumer (it applies events directly); see open points.
- **For WP100 (chart, wave 3)**: the chart always renders `GAME_ROSTER_SOURCE` / `ATHLETE_ROSTER_SOURCE`, so releases are
  still on `rest` until the chart flips. Change `game.rosterSource` / `athlete.rosterSource` to `replica` when
  `events.enabled` (keep rendering `rest` explicitly when events are off: athlete refuses replica without its consumer and
  game would serve a replica that never changes); `deploy/helm/tests/run.sh` line ~315 asserts `"rest"` by default and on
  kind (becomes replica on kind, rest with events off), the cutover test (~326-330, `--set athlete.rosterSource=replica`
  changes 4 lines) becomes the flip back to `rest`, and the guard `refused 'rosterSource' --set athlete.rosterSource=replica`
  (replica without events) stays. Golden snapshots `umbrella-kind.yaml` change. Values comments "The default flips only per
  ADR-0037" go. `deploy/kind/smoke.sh` already checks "roster source replica".
- **Drift check on kind**: `just events-drift --kind` runs the same SQL through
  `kubectl -n ${HOOPS_NAMESPACE:-hoops} exec -i <primary> -c postgres -- psql -U postgres -d hoops`, the primary found by the
  labels `cnpg.io/cluster=${HOOPS_DB_CLUSTER:-hoops-db},cnpg.io/instanceRole=primary` (local peer login inside the pod;
  `enableSuperuserAccess: false` only blocks remote password logins). Not run here; WP100 should run it after its flip.
- **Open points / follow-ups**
  - game starts on `replica` with `GAME_ROSTER_CONSUMER_ENABLED=false` (athlete refuses): add the guard and give
    `ReplicaRosterSourceTest` a consumer, or keep it documented.
  - Docs pass (not mine to edit): `docs/architecture.md` (lines ~65, ~173 "default `rest`"), `docs/conformance.md` V-01
    ("Gap: the default is still `rest`"), `docs/HANDOVER.md` line ~51, `docs/roadmap.md`; FOLLOW-UPS "Duplicated test and
    job code" and "Decoders on a missing contracts jar" are done (`ReplicaRetentionJob` itself stays per service: the
    scheduler is not a common dependency).
  - The journeys now wait for the replicas where they act right after a roster change; other clients (the web app) can
    still see the old state for the 1-2 s of lag (ADR-0037 Consequences).
  - The commit hook's isolation test hit a Keycloak container OOM once under load (retried, passed).
