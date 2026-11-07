# WP82 — Game + athlete: replica housekeeping (applied/parked retention) and `.removed` for every aggregate

Model: Opus. Wave 3 (2026-11-06, fifth round): starts after wave 2 is merged (WP80 touched the three services);
runs alongside WP76 (web), WP85 (`libs/common-quarkus`, realm, `images.yml`), WP90 (core). You own
`services/game-service` and `services/athlete-service` (consumers, replica apply rules, jobs), Flyway game `V6`,
athlete `V9` (reserved), `docs/runbooks/events.md` game and athlete sections, `docs/adr/0037-*.md` amendment.
Depends on: WP68/WP69 (replicas), WP81 (the new `.removed` types for every aggregate in `libs/contracts/events`;
read its handover), ADR-0037. Skills: quarkus-hexagonal-service, tenant-isolation-testing, test-driven-development,
verification-before-completion. Worktree: `~/code/hoops-wt/wp82-replica-housekeeping`, branch
`wp82-replica-housekeeping`.

Decision 59 of 2026-11-06 (continued): the replica `applied_event` and `parked_event` tables get retention jobs; the
replicas apply the `.removed` events WP81 added for persons, players, teams, team-player and tenants.

## Scope
1. **`.removed` handling**: red tests per aggregate (soft removal in the `*_ref` row, tombstone skipped, tenant
   removal cascades its refs or marks the tenant removed: decide, same in both services; authz resolvers treat
   removed rows as absent).
2. **Retention**: a scheduled job per service (Quarkus scheduler, `runExclusive`-style guard or `SKIP LOCKED`)
   deletes `applied_event` rows older than the tombstone retention (7 days, configurable; never below it: a replay
   relies on them) and `parked_event` rows older than N days after they were inspected (metric + log of what was
   deleted); config keys `hoops.roster.replica.retention.*`; tests with a clock.
3. **Docs**: runbook sections (what is pruned, how to inspect parked rows before they go), ADR-0037 amendment.

4. **Athlete test flake, last path** (WP78/WP87): `ReplicaAuthzRulesTest` still fails under load because Quarkus's
   Kafka Dev Services starts the Redpanda container outside WP87's `ContainerStarts` ping. Give the athlete (and game)
   tests a Redpanda `QuarkusTestResource` started through `ContainerStarts` (or turn Kafka Dev Services off for the
   groups that need no broker); prove the athlete module 3/3 green under load.

## Acceptance
- [ ] Red tests first; `./mvnw -B -ntp -pl services/game-service,services/athlete-service -am verify
      -Dquarkus.http.test-port=0` green (totals); `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green
      (fresh; totals)
- [ ] `just mutation game-service` and `athlete-service` at or above baseline (record)
- [ ] `GAME_ROSTER_SOURCE=replica ATHLETE_ROSTER_SOURCE=replica just e2e` 23/23 on compose (tell the orchestrator
      before: WP90 also needs the stack)
- [ ] Handover appended with the config keys

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the lines
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01Fuaj1aLz4Zxsb2XaUQBcMq`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Keep the Mac awake for long runs: `caffeinate -dims -t 14400 &`,
  kill it before reporting.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
- **Built:**
  - **Every removal applied (soft).** game `V6__replica_housekeeping.sql`, athlete `V9__replica_housekeeping.sql`:
    `removed` on `tenant_ref`, `person_ref`, `player_ref`, `team_ref`, `team_player_ref` (state columns nullable). The
    decoders map `person|player|team|team-player|tenant.removed` to `RosterEvent.Removed(envelope, Aggregate)` (game) /
    `RosterChange.Removed(RosterTopic)` (athlete); a tenant removal about another tenant is invalid (parked).
    `Decoded.Ignored` / `DecodedEvent.Ignored` and the `ignored` outcome are gone. A removal keeps only the identity,
    `occurred_at`, `event_id` (a removed person keeps no name/login/roles); the `occurred_at` guard keeps a late older
    `.changed` stale; a newer one brings the aggregate back. Tombstones still skipped.
  - **Reads treat removed rows as absent** (game `JdbcRosterReplicaRepository`, athlete `ReplicaMembershipRepository`,
    `ReplicaRosterRepository`): removed tenant = not found; removed person = no member; removed player off own/linked
    players, rosters, player batches (links to it ignored); removed assignment grants no team; removed team not found
    and neither current nor historic staff team; athlete roster staff without removed persons.
  - **Tenant removal: marked, not cascaded** (same in both); athlete's `tenant_registry` untouched.
  - **Retention:** `ReplicaRetention` (application, `@Startup`, refuses applied-events < 7 days, negative
    parked-events, batch < 1) + `ReplicaHistory` port + `Jdbc`/`ReplicaHistoryRepository` + `adapters.in.job.ReplicaRetentionJob`
    (`@Scheduled`, `concurrentExecution=SKIP`, `TenantScope.runExclusive` lock `game.replica-retention` /
    `athlete.replica-retention`). Per tenant (new global `<svc>.replica_tenant`, filled on every applied event and
    backfilled from `applied_event` by the migration) batches of `delete ... where ctid in (... for update skip locked)`;
    parked rows deleted only when `inspected_at` (new, set by operators as the owner) is older than the retention. Log
    line with positions (`topic-partition@offset`, never key/reason), counter `hoops_roster_replica_pruned_total{table}`.
    Grants: app role may delete `parked_event` and read only `topic`, partition, offset, `parked_at`, `inspected_at`;
    `replica_tenant` select+insert only. game gained `quarkus-scheduler`.
  - **Test flake (item 4):** `%test` turns Kafka Dev Services off (both services; game's consumer off in `%test` like
    athlete's). `support/RosterBrokerResource` (one per service, pinned image via `ContainerStarts`, 7 topics, consumer
    on) on game `RosterEventConsumerTest`, `RosterReplayTest`, `RosterConsumerFailureTest` and athlete `ReplicaProfile`
    (`testResources()`). `testcontainers-redpanda` (test scope) in both poms.
  - Docs: ADR-0037 amendment WP82; runbook `events.md` game "Housekeeping" and athlete "Athlete housekeeping" (inspect,
    mark, what goes). `spotbugs-exclude.xml`: `CT_CONSTRUCTOR_THROW` for the two `ReplicaRetention` (as WP81's).
- **Verified:**
  - Red first: `6772611` (game removals, run red with a stub: 10 failures + 1 error), `c6e4f68` (game retention, did
    not compile), `22aa8cd` (athlete removals, 14 failures), `6575f21` (athlete retention + grants, did not compile).
    The game schema-test changes (`RosterReplicaSchemaTest`) were written with V6, not run red separately.
  - `./mvnw -B -ntp -pl services/game-service,services/athlete-service -am verify -Dquarkus.http.test-port=0`: BUILD
    SUCCESS 7:36 min; common 201, contracts 272, game 450 (was 423), athlete 870 (was 855), coverage met.
  - `./mvnw -B -ntp -T 1C clean verify -Dquarkus.http.test-port=0` (fresh): BUILD SUCCESS 12:52 min; contracts 272,
    common 201, core 892, game 450, athlete 870, e2e 27 (23 skipped offline), 0 failures, coverage and SpotBugs met.
  - Athlete under load (host load average 40-57 from parallel WPs): athlete green 3 of 3 with `ReplicaAuthzRulesTest` included: the module run
    above (870/870), the `-T 1C` run below (870/870), and a third `-pl services/athlete-service -am verify` at load
    average 53 (870/870, BUILD SUCCESS). No "localhost:2375" failure in any run; Kafka Dev Services no longer start in
    tests (only the three ReplicaProfile classes start a broker, through `ContainerStarts`).
  - `just mutation game-service`: 469/471 killed (99.6 %, test strength 99 %; baseline 95, was 447/449); the scope gained
    `ReplicaRetention*`, `ParkedPosition*` with the pure `ReplicaRetentionRulesTest` (22 mutants: 21 killed, 1 timed
    out = detected). `just mutation athlete-service`: 495/495 (100 %, scope unchanged: domain only).
  - compose: `GAME_ROSTER_SOURCE=replica ATHLETE_ROSTER_SOURCE=replica just e2e`: first run JourneyTest 22/23
    (`secondTenantCannotSeeTheFirstTenantsData`: game listed matches for tenant B 0.9 s after its creation; core's
    outbox published B's `tenant`/`person` events 0.87 s after they occurred and game applied them 5 ms later, so the
    request came before the replica knew B: the replica lag race, not WP82); second run 23/23 (27 with MailSinkTest).
    Logs "Roster source: replica" / "REPLICA (replica consumer on)", V6/V9 applied; afterwards parked 0 in both.
    Found on compose: `replica_tenant` held only tenants with events after V6, so the migrations now backfill it from
    `applied_event` (`4cffe68`); applied by hand on compose (game 6 = `tenant_ref` 6, athlete 6, FORCE RLS restored),
    checksums realigned with one `QUARKUS_FLYWAY_REPAIR_AT_START=true` start of game and athlete.
- **Decisions/ADRs:** ADR-0037 amendment WP82: soft removal for every aggregate with nulled state; tenant removal
  marked, not cascaded (order guard, only failed onboardings today); retention minimum = tombstone retention (7 days),
  startup refuses less; parked rows only after an explicit inspection mark; global `replica_tenant` + coordinate-only
  column grant instead of a cross-tenant policy or a BYPASSRLS / SECURITY DEFINER role; Dev Services off in tests.
- **Open points / follow-ups:**
  - Config keys (both services, env names by Quarkus mapping): `hoops.roster.replica.retention.cron` (game
    `0 40 3 * * ?`, athlete `0 45 3 * * ?`, `%test` `off`), `hoops.roster.replica.retention.applied-events` (`P7D`,
    minimum `P7D`), `hoops.roster.replica.retention.parked-events` (`P30D` after `inspected_at`),
    `hoops.roster.replica.retention.batch-size` (`1000`). The chart sets none (defaults fit).
  - e2e: `secondTenantCannotSeeTheFirstTenantsData` races the replica lag in `replica` mode (game/athlete see a new
    tenant 1-2 s after core); an await on the first game/athlete call for tenant B would make it deterministic (e2e
    module, not mine).
  - Soft-removed rows are kept for ever (they guard against late older events, only needed for the tombstone
    retention); pruning removed rows older than that is a possible later step. Uninspected parked rows are never
    deleted (by design).
  - `RosterBrokerResource` exists twice (game, athlete; ownership): the common-quarkus test-jar could host one.
  - Docs pass: `docs/quality/mutation.md` game row (471 mutants, scope + `ReplicaRetention`, `ParkedPosition`),
    `docs/architecture.md` (retention job, `replica_tenant`).

