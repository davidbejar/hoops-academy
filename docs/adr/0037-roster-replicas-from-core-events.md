# ADR-0037: Roster replicas in game and athlete, fed by core's events, behind `RosterPort`

- Status: Accepted (game: WP68; athlete: WP69, its section at the end); amended 2026-11-07 (WP81: shadow evidence and
  done items in "When rest flips"; WP82: every removal applied, replica housekeeping, at the end)
- Date: 2026-11-06
- Related: decision 48 of 2026-11-06, ADR-0008 (v1 sync REST, v2 outbox + events; amended in WP67), ADR-0036 (Redpanda:
  topics, keys, compaction, ACLs), ADR-0006 / ADR-0011 (RLS, tenant binding per transaction), WP19 brief, WP67
  (contracts `libs/contracts/events/core.<aggregate>.schema.json`, publisher)

## Context
game and athlete ask core's `/internal` API for every roster read and every request's authorisation context (cached
30 s, ADR-0008 v1). Decision 48 replaces that, step by step, with local replicas fed by core's roster events (WP67:
state transfer on compacted topics, at least once, outbox order per key, `<aggregate>.changed` / `.removed` +
tombstone). The REST path must stay available until the replica has been proven, so the switch is a configuration
key, and both paths must give the same answers.

## Decision (shared by game and athlete)
1. **A replica per consuming service, in its own schema** (`<service>.<aggregate>_ref`), holding only the columns
   its `RosterPort` and the authorisation context need. Every table is a tenant table (`tenant_id`, `ENABLE` +
   `FORCE` RLS through `app.enable_tenant_rls`, the generic RLS suites), primary key `(tenant_id, id)` so two tenants'
   ids can never meet in an upsert (the same reason ADR-0036 puts the tenant into the Kafka key). No foreign keys
   between the replica tables: the topics are independent, so a team assignment may arrive before its player; reads
   join and leave out what has not arrived yet.
2. **Idempotent, order-safe apply.** Each event is applied in a transaction bound to the event's `tenantId`
   (`TenantScope.runAs`, never a request's tenant): first `insert ... on conflict do nothing` into
   `<service>.applied_event (tenant_id, event_id)`; a known `eventId` is a duplicate and changes nothing. Then an
   upsert of the aggregate row guarded by `where <row>.occurred_at <= excluded.occurred_at`: an older event never
   overwrites a newer one (equal timestamps: the later delivery wins, it is later in outbox order). Each row keeps the
   `occurred_at` and `event_id` that wrote it.
3. **Removals are soft.** `team-staff.removed` / `guardian-link.removed` keep the row with `removed = true` and the
   removal's `occurred_at`, so a late or replayed older `.changed` cannot bring the entry back; the tombstone that
   follows (null value) is skipped. Reads ignore removed rows.
4. **Invalid events are parked, never applied and never blocking.** Every record is validated against the topic's
   JSON Schema from the contracts jar, and its key must be `<tenantId>:<aggregateId>` (and a tenant event's
   aggregate id its tenant id). A violation is written to `<service>.parked_event` (topic, partition, offset, key,
   event id if readable, reason; not the value), counted, and the record is acknowledged. `parked_event` is the one
   table without `tenant_id` (a broken record may not name a tenant): the app role may only `insert` into it, so no
   tenant can read what another tenant's broken record said; operators read it as the schema owner. A parked event is
   repaired by the aggregate's next event (state transfer) or by a replay once the producer is fixed.
5. **Other failures stop the consumer and lose nothing.** Offsets are committed after processing (at least once).
   A failure that is not a contract violation (database unreachable) is retried a few times in place, then fails the
   channel: the messaging health checks (liveness and readiness) turn DOWN, the orchestrator restarts the pod, and it
   resumes from the last committed offset, which is still before the failed event (WP68 proved it:
   `RosterConsumerFailureTest`, readiness and liveness 503 while the database is UP). The consumer runs in both
   modes (7), so a stopped consumer takes the pod out of service in `rest` mode as well. A valid event is never parked or
   skipped. The broker being unreachable is not a failure: the Kafka connector's readiness check is off, the client
   reconnects, and the replica stays readable but stale, visible in the lag metric. The consumer can be switched off
   (escape hatch) without touching the REST path.
6. **Reads reproduce core's `/internal` rules** (contract tests run the same cases against the REST adapter, with
   WireMock answering like core, and against the replica): a team roster and a player batch only in an ACTIVE tenant
   (else not found); roster = open (`leftOn` null) and valid (`invalidReason` null) assignments in `joinedOn` order,
   only players with birth date and gender; the authorisation context of an active person with that login in an
   ACTIVE tenant: roles, own player (PLAYER role), linked players (PARENT role), staff teams, teams of the own and
   linked players' open valid assignments, both team sets without teams whose season ended before today in the
   academy's time zone, plus that zone. No cache: the replica is a local indexed read.
7. **`hoops.roster.source=rest|replica`** (runtime, default `rest`) selects both the `RosterPort` adapter and the
   authorisation context resolver. The consumer runs in both modes, so in `rest` mode the replica fills up in the
   shadow and can be compared before the switch.
8. **Replay = rebuild from the compacted topics.** Stop the service (the group must have no members), empty the
   replica tables and `applied_event` (otherwise every replayed event is a known duplicate), seek the group to the
   start, start the service. The compacted topics hold the latest event of every key, so the replica equals core's
   state once the consumer has caught up (`docs/runbooks/events.md`).

## When `rest` flips to `replica` (default)
Not in WP68/WP69. All of:
- ~~core publishes a snapshot of the aggregates that existed before WP67 (a backfill that appends one `.changed` per
  aggregate to the outbox)~~ — done in WP81: `POST /platform/events/backfill` / `just events-backfill` (ADR-0008
  amendment WP81, runbook "Backfill and shadow period"). Until it has run in an environment, a replica there only knows
  what changed after core's publisher went live.
- ~~the chart wires the services' Kafka client (bootstrap, SASL user and Secret, `events.enabled`)~~ — done in WP71
  (chart 0.7.0): behind `events.enabled` together with `global.events.enabled`, which must match (a subchart sees only
  `global`; the render refuses a release where the two differ); `game.rosterSource` / `athlete.rosterSource` set the
  switch, and `replica` without events is refused. The athlete flip is proven on kind (WP71), the game flip too (WP86,
  chart 0.9.0: `game.rosterSource=replica`, `smoke.sh` passed with "roster source replica").
- ~~core's producer recovers when the broker users appear after it started~~ — done in WP81: the publisher replaces
  a producer after consecutive failed sends (`ProducerRecoveryTest`); the restart in `deploy/kind/up.sh` can go.
- ~~`just e2e` is green with `replica` for both services~~ — done in WP81 on compose (JourneyTest 23/23 with
  `GAME_ROSTER_SOURCE=replica ATHLETE_ROSTER_SOURCE=replica`, parked 0 and both groups' lag 0 afterwards).
- ~~the game flip on kind~~ — done in WP86 (above).
- **still open:** the replica has run in the shadow in a shared environment (kind or a staging cluster) over days with
  `hoops_roster_replica_parked_total` at 0 and the lag metric in seconds; run the backfill there first.
Then the default flips; the REST adapter stays as the fallback switch until a later decision removes it.

Evidence so far (WP81, compose, 2026-11-07): the backfill completed the topics of 46 academies (416 events; every topic's
live keys equal core's rows, both replicas hold exactly core's counts), parked 0, lag under 1 s, both groups' lag 0, and
`just e2e` with `replica` for both services: JourneyTest 23/23. Still missing (2026-11-07, after the fifth round): only the shadow period over days in a shared environment (kind or
a staging cluster); then the owner decides the flip. Since WP81 core also publishes `person.removed`, `player.removed`,
`team.removed`, `team-player.removed` and `tenant.removed`; game and athlete accept them as valid but do not apply them
yet (`outcome="ignored"`, never parked; the row stays): their soft removal is WP82 (wave 3) — done, see the amendment
WP82 at the end.

## Consequences
- Roster and authorisation answers become eventually consistent: a change in core reaches game/athlete after the
  publisher's poll (1 s) plus the consumer's fetch, typically one to two seconds (the REST path had up to 30 s of
  cache for successful answers already). A member removed in core keeps access in game for that window.
- game/athlete need no call to core on the request path in `replica` mode; core's `/internal` roster endpoints stay
  for `rest` mode and other consumers.
- `applied_event` grows by one row per event; it can be pruned of rows older than the topics' tombstone retention
  (7 days) without losing idempotency for live delivery (automated in WP82, see the amendment).
- Each service gets the Kafka client and Dev Services Redpanda (the pinned image from common-quarkus) in its tests.

## Alternatives considered
- **Hard deletes on `.removed` or on the tombstone**: simpler tables, but an older redelivered `.changed` would
  resurrect the entry; the soft delete costs one boolean.
- **Foreign keys between the replica tables**: would reject an assignment that arrives before its player, or need a
  waiting room; the reads' joins give the same answers without it.
- **A dead-letter topic**: needs a topic, its ACL and a producer in each consumer (ADR-0036 grants read only); a
  write-only table holds the same information and is visible to operators with SQL.
- **Fallback to REST when the replica misses** (read-through): hides lag for new records but not for changed ones,
  and keeps core on the request path; rejected for a clean cutover.

## game-service (WP68)
- Tables (`V4__roster_replica.sql`): `game.tenant_ref`, `person_ref`, `player_ref`, `team_ref`, `team_player_ref`,
  `team_staff_ref`, `guardian_link_ref`, `applied_event`, `parked_event`.
- One incoming channel `core-roster` subscribed to the seven `core.*` topics, consumer group `game-service.roster`
  (ADR-0036 ACL prefix), `auto.offset.reset=earliest`, processing blocking and ordered. One channel and one group
  instead of one per topic: a single `rpk group seek` replays everything, and per-key order only needs each topic's
  partition order, which one consumer keeps.
- `hoops.roster.source` = `GAME_ROSTER_SOURCE`; the consumer can be switched off with `GAME_ROSTER_CONSUMER_ENABLED=false`.
- Metrics: `hoops_roster_replica_events_total{topic,outcome}` (outcome `applied`, `duplicate`, `stale`, `tombstone`),
  `hoops_roster_replica_parked_total{topic}`, `hoops_roster_replica_lag_seconds{topic}` (age of the last processed
  event when it was processed), plus the Kafka client's own `kafka_consumer_fetch_manager_records_lag*`.

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
  (`source=replica` through the API without any core-service). On kind (WP71) `athlete.rosterSource=replica` replaced
  only the athlete pod and kept answering with core scaled to 0.

## Amendment 2026-11-07 (decision 59, WP82): every removal applied, replica housekeeping
Applies to game and athlete alike (game `V6__replica_housekeeping.sql`, athlete `V9__replica_housekeeping.sql`).
- **Point 3 for every aggregate.** The five removals WP81 added (`person.removed`, `player.removed`, `team.removed`,
  `team-player.removed`, `tenant.removed`, empty payload) are applied, not ignored: the `*_ref` row of the event's
  aggregate id is kept (or created, for a removal of an aggregate never seen) with `removed = true`, the removal's
  `occurred_at` / `event_id`, and every state column null (a removed person keeps no name, login or roles, a removed
  player no birth date). The `occurred_at` guard applies as before: a late older `.changed` is `stale`, a newer one
  brings the aggregate back (`removed = false`, the whole state). Tombstones stay skipped. The `ignored` outcome is
  gone; a tenant removal must name its own tenant like a tenant change (else parked).
- **Reads treat removed rows as absent**, as core's `/internal` answers once the row is deleted: a removed tenant is not
  found (like a suspended one), a removed person is no member, a removed player is neither own nor linked player nor on
  a roster or in a player batch (a guardian link to a removed player does not count), a removed assignment is off the
  roster and grants no team, a removed team is not found and counts neither as current nor as historic staff team;
  athlete's roster staff leaves out staff whose person was removed. Proof on both sources: game
  `AuthzContextContractTest` / `RosterPortContractTest` (REST and replica), athlete `ReplicaAuthzRulesTest` /
  `ReplicaRosterRulesTest`, and `ReplicateRosterTest` / `ApplyRosterEventTest`.
- **Tenant removal: marked, not cascaded.** `tenant.removed` sets `tenant_ref.removed`; the tenant's other rows stay
  (every read needs an ACTIVE, not removed tenant, so they are unreachable) and their own removals, if core sends them,
  apply as usual. Cascading would write every row of the tenant under one event and break the per-aggregate order
  guard; today the only tenant removal is a failed onboarding (no members, nothing to cascade). athlete keeps the
  tenant in `tenant_registry` (the nightly job finds nothing to materialise).
- **Retention.** A daily job per service (`ReplicaRetentionJob`, Quarkus scheduler, `hoops.roster.replica.retention.cron`,
  `TenantScope.runExclusive` under the advisory locks `game.replica-retention` / `athlete.replica-retention`) deletes
  `applied_event` rows older than `hoops.roster.replica.retention.applied-events` (default and minimum 7 days, the
  topics' tombstone retention: the service refuses to start with less) per tenant in batches
  (`retention.batch-size`, `for update skip locked`), and `parked_event` rows an operator marked inspected
  (`inspected_at`, set as the schema owner) longer than `retention.parked-events` (30 days) ago; uninspected rows are
  never deleted. An applied id older than the tombstone retention is not needed: a redelivery cannot come later than the
  topic keeps the record, and an older redelivery is `stale` anyway (`ReplicaRetentionTest`). What went is logged
  (topic-partition@offset for parked rows, never key or reason) and counted in
  `hoops_roster_replica_pruned_total{table}`.
- **Two new grants, one new global table.** `applied_event` is a tenant table, so the job needs the list of tenants:
  `<service>.replica_tenant` (global, tenant ids only, filled with every applied event; the app role may read and
  insert). The app role may now delete from `parked_event` and read only the columns the job filters on and logs
  (`topic`, partition, offset, `parked_at`, `inspected_at`; never `record_key`, `event_id`, `reason`).
  Alternatives rejected: a permissive policy letting the app role see every tenant's `applied_event` rows (a
  cross-tenant read on the request path), a `BYPASSRLS` or `SECURITY DEFINER` maintenance role (ADR-0006: no service
  bypasses RLS).
- **Tests without Kafka Dev Services.** Dev Services started a Redpanda container at every Quarkus boot outside
  `ContainerStarts` (WP87), the last source of the "localhost:2375 failed to respond" flake (athlete
  `ReplicaAuthzRulesTest`). The test profiles turn Dev Services off; the classes that run the consumer get
  `RosterBrokerResource` (the pinned image through `ContainerStarts`, the seven topics, consumer on). Dev mode keeps
  Dev Services.
