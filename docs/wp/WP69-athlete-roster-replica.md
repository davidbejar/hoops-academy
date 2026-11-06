# WP69 — Athlete: roster replica from core events behind `RosterPort`

Model: Opus. Wave 5 (2026-11-06, fourth round): starts after WP67 is merged; runs alongside WP68 (game, same
design, disjoint files). You own `services/athlete-service` and Flyway `V6` (reserved), the athlete section of
`docs/adr/0037-*.md` (WP68 writes the ADR; append your section at the end; if the file does not exist yet when you
need it, write your section in your handover and the orchestrator merges it) and of `docs/runbooks/events.md`.
Depends on: WP67 (event contracts, publisher), WP19 brief, `RosterPort` (`services/athlete-service/.../
application/RosterPort.java`), the membership cache. Skills: quarkus-hexagonal-service, tenant-isolation-testing,
test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp69-athlete-replica`, branch `wp69-athlete-replica`.

Decision 48 of 2026-11-06 (continued): athlete keeps a local replica of the roster data it reads from core, fed by
the events, selectable with `hoops.roster.source=rest|replica` (default `rest`).

## Scope
Mirror WP68 for athlete:
1. `V6__roster_replica.sql`: the `*_ref` tables `RosterPort` and the authz context need (tenant tables with RLS,
   covered by the generic suites) plus the idempotency table.
2. Consumer per topic: upsert by `aggregateId` with `occurredAt` ordering, duplicate `eventId` ignored, tenant
   binding from the event, schema validation against `libs/contracts/events`, park on violation, metrics.
3. `RosterPort` replica adapter; port contract tests parameterised over both adapters; `hoops.roster.source`.
4. Replay command/documentation; test: replica equals the fixture after replay from empty.
5. Docs: your ADR-0037 section; runbook section.

## Acceptance
- [ ] Red tests first; RLS suites green for the new tables; `./mvnw -B -ntp -pl services/athlete-service -am verify
      -Dquarkus.http.test-port=0` green (totals); `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green
      (fresh; totals)
- [ ] Port contract tests green on both adapters; replay, duplicate and out-of-order tests green
- [ ] `just mutation athlete-service` at or above baseline; `just e2e` 21/21 on compose with `replica` for athlete
      (evidence; coordinate the compose stack with WP68 through the orchestrator); handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- **Built:**
  - `V6__roster_replica.sql` (V5 unused): `athlete.tenant_ref`, `person_ref`, `player_ref`, `team_ref`,
    `team_player_ref`, `team_staff_ref`, `guardian_link_ref` (state per aggregate, primary key `(tenant_id, id)`, each
    with the `occurred_at`/`event_id` that wrote it, soft `removed` for staff and links), `applied_event`
    (idempotency), all tenant tables via `app.enable_tenant_rls`; `parked_event` global, insert-only for `athlete_app`.
  - `application.replica`: `RosterTopic`, `RosterEvent`/`RosterChange` (sealed, athlete's value objects),
    `ApplyRosterEvent` (`TenantScope.runAs(event.tenant)`, `markApplied` then a guarded upsert; outcome APPLIED /
    DUPLICATE / STALE; a tenant event also refreshes `tenant_registry`), ports `RosterReplicaStore`, `ParkedEvents`,
    `ReplicaMembershipReads`, and `ReplicaAuthzResolver` (core's `MembershipLookup` rules on the replica).
  - `adapters.in.messaging`: `CoreEventDecoder` (schema from the contracts jar, key = `<tenantId>:<aggregateId>`, a
    tenant event's aggregate = its tenant, bounded reasons, never throws), `CoreRosterConsumer` (channel
    `core-roster`, tombstones skipped, violations parked, database failures retried with backoff then the channel
    fails; metrics).
  - `adapters.out.persistence`: `RosterReplicaRepository` (upserts `... as r ... where r.occurred_at <=
    excluded.occurred_at`), `ReplicaRosterRepository` (`RosterPort`, InternalRoster rules), `ReplicaMembershipRepository`,
    `ParkedEventRepository` (JDBC, `on conflict do nothing`).
  - `adapters.config.RosterSourceProducer` + `RosterSource`: `hoops.roster.source` produces the `RosterPort` and the
    `AuthzContextResolver`; `CoreRosterAdapter` is now `@Typed(CoreRosterAdapter.class)`.
  - pom: `quarkus-messaging-kafka`, `contracts` (now compile scope), `json-schema-validator` 2.0.8. Config, README,
    `docs/runbooks/events.md` section "Athlete replica (WP69)" with the replay procedure.
- **Verified:**
  - Red first: `b050122` (tests only, did not compile), then `bc2d48e`.
  - `./mvnw -B -ntp -pl services/athlete-service -am verify -Dquarkus.http.test-port=0`: BUILD SUCCESS; contracts 223,
    common 186, athlete 790 (was 679), 0 failures, coverage gates met.
  - `./mvnw -B -ntp -T 1C clean verify -Dquarkus.http.test-port=0` (fresh, WP68 building at the same time): contracts
    223, common 186, core 871, game 324, e2e 27 (23 skipped offline) green; athlete 773 run with 1 error, a container
    start failure (`localhost:2375 failed to respond`, Testcontainers under load) booting `ReplicaAuthzRulesTest`;
    athlete re-run alone: 790/790, BUILD SUCCESS, coverage met.
  - RLS: `AthleteGenericRlsIsolationTest` 17 tables (8 new, `roles` fixture override), `AthleteRlsSchemaMetaTest`
    (`parked_event` declared global); `CoreRosterConsumerTest.theAppRoleCannotReadWhatParkedRecordsSaid` (42501).
  - Contracts on both adapters: `RestRosterPortContractTest` / `ReplicaRosterPortContractTest` 6+6,
    `RestMembershipContractTest` / `ReplicaMembershipContractTest` 6+6; replica rules `ReplicaRosterRulesTest` 10,
    `ReplicaAuthzRulesTest` 10; `ApplyRosterEventTest` 11 (duplicate, stale, same instant, removal vs late change,
    removal never seen, re-add, tenant per event, registry); `CoreEventDecoderTest` 33 (every contract example).
  - On Dev Services Redpanda: `CoreRosterConsumerTest` 7 (all topics, redeliveries + late older events counted,
    parked and next applied, forged key parked, tombstone, lag + Kafka records-lag metrics), `RosterReplayTest`
    (replica emptied, group seeked to the start, same answers incl. removals, duplicates, stale events),
    `ReplicaSourceApiTest` 3 (`source=replica`, no core: 200/201, non-member 404, suspended 404).
  - Mutating the `occurred_at` guard (`where true`) fails 4 of `ApplyRosterEventTest`.
  - `just mutation athlete-service`: 471/471 killed (100 %, baseline 100; PIT scope unchanged, domain only).
  - `ATHLETE_ROSTER_SOURCE=replica just e2e`: JourneyTest 23/23 (27 with MailSinkTest); athlete log "Roster source:
    REPLICA (replica consumer on)", 0 parked, 0 retries; afterwards tenant_ref 4, person_ref 16, player_ref 6, team_ref 4,
    team_player_ref 12, team_staff_ref 4, guardian_link_ref 2, applied_event 58, parked_event 0.
- **Decisions/ADRs:** ADR-0037 is WP68's (not on this branch); my athlete section for the orchestrator to append at
  its end:

  ## athlete-service (WP69)
  - Tables (`V6__roster_replica.sql`; V5 stays unused): `athlete.tenant_ref` (primary key `tenant_id`), `person_ref`,
    `player_ref`, `team_ref`, `team_player_ref`, `team_staff_ref`, `guardian_link_ref`, `applied_event` (all tenant
    tables, generic RLS suites), `parked_event` (global, primary key `(topic, partition, kafka_offset)`, so a replay
    parks a record once; `athlete_app` may only insert).
  - Same channel layout as game: `core-roster` on the seven `core.*` topics, group `athlete-service.roster`,
    `auto.offset.reset=earliest`, blocking and ordered, connector readiness check off. A database failure is retried
    `hoops.roster.replica.max-attempts` times (5, backoff 0.5 s doubling) before the channel fails.
  - `hoops.roster.source` = `ATHLETE_ROSTER_SOURCE`; consumer `hoops.roster.consumer.enabled` =
    `ATHLETE_ROSTER_CONSUMER_ENABLED` (default true, off in the default test profile); `replica` with the consumer off
    fails at startup. `RosterSourceProducer` produces both the `RosterPort` and the `AuthzContextResolver` (it replaces
    common's `@DefaultBean` `RosterAuthzResolver`, which it still builds for `rest`), so `CoreRosterAdapter` and
    `ReplicaRosterRepository` are `@Typed` to their classes.
  - A tenant event also refreshes `athlete.tenant_registry` (the nightly materialisation knows the tenant and its zone
    before anyone calls). A tenant event whose aggregate id is not its tenant id is parked.
  - Metrics: the names of game's (`hoops_roster_replica_events_total{topic,outcome}`, `..._parked_total{topic}`,
    `..._lag_seconds{topic}`).
  - Proof: `RosterPortContract` and `MembershipContract` run on both sources (REST: WireMock core; replica: core
    events built against the contracts), `ApplyRosterEventTest` (duplicate, stale, same instant, soft removals, tenant
    per event), `CoreRosterConsumerTest` and `RosterReplayTest` on Dev Services Redpanda, `ReplicaSourceApiTest`
    (`source=replica` through the API without any core-service).

- **Open points / follow-ups:**
  - Config keys: `hoops.roster.source` (`ATHLETE_ROSTER_SOURCE`, `rest`), `hoops.roster.consumer.enabled`
    (`ATHLETE_ROSTER_CONSUMER_ENABLED`, `true`; `%test` false), `hoops.roster.replica.max-attempts`
    (`ATHLETE_ROSTER_REPLICA_MAX_ATTEMPTS`, 5), `hoops.roster.replica.first-backoff` (`PT0.5S`),
    `%prod.kafka.bootstrap.servers` (`KAFKA_BOOTSTRAP_SERVERS`, `localhost:19092`), `KAFKA_SECURITY_PROTOCOL`
    (`PLAINTEXT`), `KAFKA_SASL_USERNAME` (`athlete-service`), `KAFKA_SASL_PASSWORD`; `mp.messaging.incoming.core-roster.*`.
  - Chart (not mine): athlete's Deployment needs `KAFKA_BOOTSTRAP_SERVERS=redpanda.<ns>.svc.cluster.local:9092`,
    `KAFKA_SECURITY_PROTOCOL=SASL_PLAINTEXT`, `KAFKA_SASL_PASSWORD` from `hoops-redpanda-athlete-service` behind
    `events.enabled`, else `ATHLETE_ROSTER_CONSUMER_ENABLED=false`: with the consumer on by default and no broker,
    the pod stays ready and live but the Kafka client logs connection warnings. kind not run.
  - The flip to `replica` by default needs core's backfill of pre-WP67 aggregates (ADR-0037 "When rest flips").
  - `applied_event` grows one row per event (prune older than 7 days, not automated); `parked_event` has no retention.
  - Eventual consistency: a change in core reaches athlete in about 1-2 s; e2e passed without changes.
  - docs pass: `docs/architecture.md`, ADR-0037 athlete section and index, `docs/quality/mutation.md` (athlete row
    unchanged: 471 mutants, scope domain only).
