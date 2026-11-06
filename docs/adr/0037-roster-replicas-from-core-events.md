# ADR-0037: Roster replicas in game and athlete, fed by core's events, behind `RosterPort`

- Status: Accepted (game: WP68; athlete: WP69, its section at the end)
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
   resumes from the last committed offset, which is still before the failed event. A valid event is never parked or
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
- core publishes a snapshot of the aggregates that existed before WP67 (a backfill that appends one `.changed` per
  aggregate to the outbox). Until then a replica only knows what changed after core's publisher went live, which is
  enough for fresh environments (compose after a reset, kind, e2e) but not for data that predates WP67.
- the chart wires the services' Kafka client (bootstrap, SASL user and Secret, `events.enabled`).
- the replica has run in the shadow in an environment for a while with `hoops_roster_replica_parked_total` at 0 and
  the lag metric in seconds, and `just e2e` is green with `replica` for both services.
Then the default flips; the REST adapter stays as the fallback switch until a later decision removes it.

## Consequences
- Roster and authorisation answers become eventually consistent: a change in core reaches game/athlete after the
  publisher's poll (1 s) plus the consumer's fetch, typically one to two seconds (the REST path had up to 30 s of
  cache for successful answers already). A member removed in core keeps access in game for that window.
- game/athlete need no call to core on the request path in `replica` mode; core's `/internal` roster endpoints stay
  for `rest` mode and other consumers.
- `applied_event` grows by one row per event; it can be pruned of rows older than the topics' tombstone retention
  (7 days) without losing idempotency for live delivery (follow-up, not automated).
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
