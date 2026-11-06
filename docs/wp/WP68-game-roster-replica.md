# WP68 — Game: roster replica from core events behind `RosterPort`

Model: Opus. Wave 5 (2026-11-06, fourth round): starts after WP67 is merged; runs alongside WP69 (athlete, same
design, disjoint files). You own `services/game-service` and Flyway `V4` (reserved), `docs/adr/0037-*.md` (shared
with WP69: you write it, WP69 appends its "athlete" section at the end), the game part of `docs/runbooks/events.md`.
Depends on: WP67 (event contracts, publisher), WP19 brief, `RosterPort` (`services/game-service/.../application/
RosterPort.java`), the WP2c/WP22 membership cache. Skills: quarkus-hexagonal-service, tenant-isolation-testing,
test-driven-development, clean-code, verification-before-completion. Worktree: `~/code/hoops-wt/wp68-game-replica`,
branch `wp68-game-replica`.

Decision 48 of 2026-11-06 (continued): game keeps a local replica of the roster data it reads from core, fed by the
events, selectable with `hoops.roster.source=rest|replica` (default `rest` until proven; the ADR says when it
flips). ADR-0037 reserved (replica design, idempotency, replay, cutover).

## Scope
1. **Tables** `V4__roster_replica.sql`: `game.person_ref`, `player_ref`, `team_ref`, `team_player_ref`,
   `team_staff_ref`, `guardian_link_ref`, `tenant_ref` as needed by `RosterPort` and the authz context; every one a
   tenant table (`app.enable_tenant_rls`), covered by `RlsSchemaMetaTest` and `GenericRlsIsolationTest`; a
   `consumer_offset`/`applied_event` table for idempotency.
2. **Consumer**: `quarkus-messaging-kafka` incoming channels per topic, upsert by `aggregateId` with `occurredAt`
   ordering (older event never overwrites newer), duplicate `eventId` ignored, tenant binding per event
   (`TenantScope` with the event's tenant, never the request's), dead-letter or park on schema violation (validate
   against `libs/contracts/events`), metrics (lag, applied, parked).
3. **Adapter**: `RosterPort` replica implementation; the existing contract tests of the port run against both
   adapters (parameterised); `hoops.roster.source` switch; the REST adapter stays the default.
4. **Replay**: `just events-replay game` (or a documented `rpk` + offset reset) rebuilds the replica from the topic
   start; test: replica equals core after replay from empty (Dev Services Redpanda + a core fixture that publishes
   the fixture events through the WP67 contracts, not through core itself).
5. **Docs**: ADR-0037; `docs/runbooks/events.md` game section; `docs/architecture.md` is the docs pass's.

## Acceptance
- [x] Red tests first; RLS suites green for the new tables; `./mvnw -B -ntp -pl services/game-service -am verify
      -Dquarkus.http.test-port=0` green (totals); `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green
      (fresh; totals)
- [x] Port contract tests green on both adapters; replay test green; duplicate and out-of-order delivery tests green
- [x] `just mutation game-service` at or above baseline; `just e2e` 21/21 on compose with `replica` for game
      (evidence); ADR-0037 written and indexed (append at the end of `docs/adr/README.md`); handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. The compose stack: coordinate with WP69 by running `just e2e`
  only after your module verify is green (one at a time; tell the orchestrator before you start it).
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- **Built:**
  - `V4__roster_replica.sql`: `game.tenant_ref`, `person_ref`, `player_ref`, `team_ref`, `team_player_ref`,
    `team_staff_ref`, `guardian_link_ref` (tenant tables, PK `(tenant_id, id)`, each row keeps `occurred_at` +
    `event_id`, soft `removed`, no FKs between them), `applied_event` (idempotency), `parked_event` (global,
    `game_app` insert only; declared in `GameRlsSchemaMetaTest.globalTables()`).
  - Consumer (`adapters.in.messaging`): `RosterEventDecoder` (JSON Schema from the contracts jar, key
    `<tenantId>:<aggregateId>`, tenant event = own tenant, known zone), `RosterEventConsumer` (channel `core-roster` over
    the 7 topics, group `game-service.roster`, `@Blocking` ordered; tombstone skipped, invalid parked + acked, valid
    applied with 3 attempts then fail-stop), `ReplicaMetrics` (`hoops_roster_replica_events_total{topic,outcome}`,
    `_parked_total{topic}`, `_lag_seconds{topic}`).
  - Application (`application.replica`): `ReplicateRoster` (`TenantScope.runAs(event tenant)`, eventId dedup,
    `occurred_at <=` guard: APPLIED/DUPLICATE/STALE; park), `ReplicaRosterPort` and `ReplicaAuthzResolver` with core's
    `/internal` rules, `RosterReplicaQueries`/`RosterReplica` ports, `JdbcRosterReplicaRepository`.
  - `hoops.roster.source` (`GAME_ROSTER_SOURCE`, default `rest`): `RosterSourceSelection` produces both `RosterPort` and
    `AuthzContextResolver` (common's `RosterAuthzResolver` stays the REST one; adapters are `@Typed`).
  - `just events-replay game|athlete` (`infra/compose/events-replay.sh`: refuses while the group has members, truncates
    `<svc>.*_ref` + `applied_event` as the owner, seeks every `<svc>-service.*` group to start). ADR-0037, runbook section.
- **Verified:**
  - `./mvnw -B -ntp -pl services/game-service -am verify -Dquarkus.http.test-port=0`: BUILD SUCCESS, 3:37 min, game 411
    tests (was 324), coverage met.
  - `./mvnw -B -ntp -T 1C clean verify -Dquarkus.http.test-port=0` (fresh): BUILD SUCCESS, 4:13 min; common 186,
    contracts 223, core 871, game 411, athlete 679, e2e 27 (23 skipped offline), 0 failures, all coverage gates met.
  - RLS: `GameRlsIsolationTest` 14 tables (8 new), `GameRlsSchemaMetaTest`, `RosterReplicaSchemaTest` (parked rows
    unreadable/unchangeable by `game_app`, 42501), `GameDatabaseRoleTest`.
  - Port contract on both adapters: `RosterPortContractTest` 6 cases x {REST, REPLICA}, `AuthzContextContractTest` 10 cases
    x {REST, REPLICA}; `ReplicaRosterSourceTest` (replica mode: authorised + match created, 0 calls to core).
  - Duplicates/out-of-order/tenant per event: `ReplicateRosterTest` (10), `RosterEventConsumerTest` (6, Dev Services
    Redpanda v26.2.6), `RosterConsumerFailureTest` (retry, then fail-stop: liveness + readiness 503, DB UP),
    `RosterConsumerSwitchedOffTest`. Replay: `RosterReplayTest` (history of 2 academies with renames, closed assignment,
    removals + tombstones, redeliveries; answers equal core's, then truncate + seek to start, rebuilt rows equal).
  - `just mutation game-service`: 438/440 killed (99.5 %, baseline 95); scope now includes `ReplicaAuthzResolver`,
    `ReplicaRosterPort`, `ReplicaPlayer`, `ReplicaTenant`, `ReplicaPerson` (39/39 killed).
  - `GAME_ROSTER_SOURCE=replica just e2e`: JourneyTest 23/23 (27 with MailSinkTest), game log "Roster source: replica";
    replica of the e2e tenant 32 events, consume lag avg 6 ms / max 30 ms, end to end max 0.97 s, 0 parked, group lag 0.
    First attempt failed step 10 (404): consume lag was 1 to 4 s (connector pause + 1 s poll timeout); fixed with
    `poll-timeout=100`, `fetch.max.wait.ms=100`. Then `just events-replay game` + restart: row counts and content hashes
    identical before/after. (Ran with `QUARKUS_FLYWAY_IGNORE_MIGRATION_PATTERNS='*:future'` because WP69's athlete V6 was
    already applied to the shared compose DB; not needed after both merges.)
- **Decisions/ADRs:** ADR-0037 (shared design + game section; point 5 records the fail-stop health semantics: the
  generic messaging readiness check also turns DOWN on a failed channel). One channel/one group instead of one per
  topic (single seek). Removals soft, tombstones skipped. No REST fallback on a replica miss.
- **Open points / follow-ups:**
  - Config keys: `hoops.roster.source` (`GAME_ROSTER_SOURCE`, `rest`), `mp.messaging.incoming.core-roster.enabled`
    (`GAME_ROSTER_CONSUMER_ENABLED`, `true`), `hoops.roster.replica.apply-attempts` (3), `%prod.kafka.bootstrap.servers`
    (`KAFKA_BOOTSTRAP_SERVERS`, `localhost:19092`), `KAFKA_SECURITY_PROTOCOL` (`PLAINTEXT`), `KAFKA_SASL_USERNAME`
    (`game-service`), `KAFKA_SASL_PASSWORD`.
  - Chart (not touched): game's Deployment needs `KAFKA_BOOTSTRAP_SERVERS=redpanda.<ns>.svc.cluster.local:9092`,
    `KAFKA_SECURITY_PROTOCOL=SASL_PLAINTEXT`, `KAFKA_SASL_PASSWORD` from `hoops-redpanda-game-service`, behind
    `events.enabled`; without it the consumer only retries connecting (pods stay ready, `rest` unaffected); without
    `events.enabled` set `GAME_ROSTER_CONSUMER_ENABLED=false`. kind not run.
  - Flip to `replica` needs a core backfill of aggregates older than WP67 (core-service, not here) and the chart wiring.
  - `applied_event` grows one row per event: pruning older than 7 days is a follow-up.
  - Docs pass: `docs/quality/mutation.md` game row (classes, 440 mutants), `docs/architecture.md`; the `justfile`
    recipe and `infra/compose/events-replay.sh` are generic for athlete too (tell WP69/merge).
