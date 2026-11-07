# ADR-0008: Synchronous REST behind a RosterPort for v1; outbox + Redpanda for v2

- Status: Accepted; amended 2026-11-06 (decision 48, WP67: the outbox and its publisher in core) and (decision 59,
  WP81: the producer recovers by itself, every deletion publishes a removal, backfill)
- Date: 2026-11-01

## Context
game- and athlete-service need roster and authz data owned by core-service. A broker on day one adds operational weight; agents building in parallel need a stable seam.

## Decision
v1: `RosterPort` interface in each consumer, implemented by a REST client to core `/internal/**` with client-credentials token, 30 s cache and 2 s timeout → 503. Game denormalises names at roster creation. v2 (optional WP19): transactional outbox in core polled and published to Redpanda, local `*_ref` replicas, adapter swapped behind a flag.

## Consequences
Runtime coupling to core and up to 30 s authz staleness are accepted for v1. The port keeps the domain unchanged when moving to events; billing will consume the same outbox.

## Amendment 2026-11-06 (decision 48, WP67): the outbox and its publisher are implemented in core

Status: implemented in WP67 (core side only; the replicas and the `RosterPort` switch are WP68/WP69, ADR-0037). Broker,
topics, keys and retention: ADR-0036. Contracts: `libs/contracts/events/core.<aggregate>.schema.json` (README "Events").

1. **Where events are written.** The repositories are the only writers of the roster tables, so they report each
   aggregate they change (person, player, team, team assignment, team staff entry, guardian link, the tenant's own
   record, and a season, whose dates are part of its teams' state) to `RosterChanges`, the application-layer
   collector. It keeps the changes per JTA transaction and, in a synchronization that runs just before the commit
   (before Hibernate's flush synchronization), appends one outbox row per aggregate in that same transaction:
   `<aggregate>.changed` with the whole current state (state transfer, because the topics are compacted), or
   `<aggregate>.removed` with the identity when the record is gone (team staff, guardian links). Use cases do not know
   about events; a new use case publishes through the repository it writes with. Derived state follows: a person's
   change republishes their player (name, birth date, gender), a season's its teams. Platform lifecycle and master data
   changes (platform datasource, no tenant bound) append `tenant.changed` from the registry row they update.
2. **State read under the writers' lock.** The state is read with native SQL after a flush (never the session cache),
   after locking the row every writer of that state holds: the person row for person and player events, the season
   row (`FOR SHARE`) for team events, the registry row (`FOR SHARE`) for the tenant. So two transactions that change
   one aggregate append in commit order and the later one sees the earlier one's change; `occurred_at` is the
   insert's `clock_timestamp()` (V14), not the transaction start, so the consumers' "older `occurredAt` never wins"
   rule holds per aggregate.
3. **V14.** `core.outbox.topic` (null = an internal v1 notification such as `player.approved`, kept but never
   published), `seq` (insert order), the pending index. The publisher reads and marks a tenant's rows as `core_app`
   under the tenant policy; it finds the tenants with a backlog through `core_platform`, which may now read the queue
   columns (`tenant_id`, `topic`, `occurred_at`, `published_at`) of every tenant but never the payload, the aggregate
   id or the event type, and still cannot update or delete.
4. **Publisher.** Every `hoops.outbox.poll-interval` (1 s), per tenant with a backlog (oldest first), in the tenant's
   own transaction: lock the next `hoops.outbox.batch-size` rows `FOR UPDATE SKIP LOCKED`, send each to its topic keyed
   `<tenant id>:<aggregate id>` (a removal is followed by a tombstone), wait for every acknowledgement (acks=all,
   idempotent producer, `hoops.outbox.send-timeout`), then set `published_at`. At least once: a crash or broker failure
   before the commit sends the same rows again with the same `eventId`. **No cluster lock** (`runExclusive`) is
   needed: the row locks give each row to exactly one publisher, and a publisher never sends an aggregate's event while
   an older unpublished event of that aggregate exists outside its batch (locked by another replica), so several
   replicas never reorder a key; they only share the work.
5. **Broker down.** The HTTP API only writes the outbox, so it keeps working; the backlog grows. The readiness check
   `outbox-publisher` stays UP with `state: DEGRADED` (the Kafka connector's own check is off), and /q/metrics shows
   `hoops_outbox_pending`, `hoops_outbox_lag_seconds`, `hoops_outbox_broker_available`, `hoops_outbox_published_total`.
   When the broker is back the next runs drain the backlog in order.

## Amendment 2026-11-06 (decision 59, WP81): the producer recovers by itself; every deletion publishes a removal

Status: implemented in WP81.

1. **The failure (WP71).** On a fresh Helm install the broker users are created by a post-install Job, after core has
   started. The idempotent producer's first producer-id request (`InitProducerId`) then fails SASL authentication and
   the client never asks again: every later record waits for a producer id and expires ("Expiring 1 record(s) ...
   since batch creation"), the outbox backlog grows and the publisher stays `DEGRADED` until the pod restarts, although
   the login works by then. Reproduced in `ProducerRecoveryTest` on a SASL/SCRAM broker of the pinned Redpanda image
   (Testcontainers, the user created after core started): red before the fix (backlog still 1 after 90 s); with
   `enable.idempotence=false` the same client recovers by itself, which locates the fault in the idempotent producer's
   state, not in the login or the broker.
2. **In-process recovery.** The publisher no longer sends through the SmallRye channel (whose producer lives as long as
   the application) but through a plain `KafkaProducer` owned by `KafkaEventBroker` (`quarkus-kafka-client`: the
   `kafka.*` configuration and Dev Services as before; acks=all, idempotence and the serializers are fixed in code).
   After `hoops.outbox.producer-reset-after` (3) consecutive failed sends it closes that producer and creates a new one
   at the next send, which requests a new producer id; `hoops_outbox_producer_resets_total` counts the replacements and
   each is logged (WARN). A successful send resets the count. A producer is created at the first send, so a core with
   the publisher off never connects. The Kafka client's metrics (`kafka_producer_*`) are bound per producer.
3. **Why not liveness.** A liveness check that fails after a long `DEGRADED` with a backlog would also restart core
   during an ordinary broker outage, taking the HTTP API down for something it does not depend on (the API only writes
   the outbox) and repeating the restart for as long as the broker is away; it would also need a threshold that is
   either slow to heal or quick to flap. Replacing the producer costs a reconnect, keeps the API up, and also covers a
   plain outage harmlessly (one new producer per three failed runs). So no liveness signal was added; the restart
   workaround of `deploy/kind/up.sh` (WP71) can go.
4. **Idempotence stays.** Turning it off would also have healed the failure, but the idempotent producer is what keeps
   a retried record from being written twice or out of order within a partition; the reset keeps that guarantee.
5. **Removals for every aggregate.** Every topic now has `<aggregate>.removed` (additive contract change: person,
   player, team, team-player and tenant join team-staff and guardian-link), followed by a tombstone. The appender
   publishes a removal for any aggregate that a repository reported changed and that is gone when the transaction
   commits, whatever deleted it; where the aggregate id is the identity the payload is empty. Today's delete paths:
   team staff and guardian links (since WP67) and the tenant registry row of an onboarding that never finished
   (`TenantRegistration.unregister`: the saga's compensation and the repair job), which appends `tenant.removed`
   through the platform datasource. Persons, players, teams and assignments have no delete path; a future one only has
   to report the change through its repository.
6. **Backfill.** Roster data older than the publisher has no event. `POST /platform/events/backfill` (super admin;
   `just events-backfill` on compose) reports every live aggregate without a roster event (with `force`: every live
   aggregate, a fresh snapshot) to the same collector, per academy and in chunks of `hoops.outbox.backfill.chunk-size`
   (200), so the `.changed` events are written from the current state under the writers' locks and published like any
   change. Idempotent without `force`; one audit row `tenant.events_backfilled` per academy that got events; counter
   `hoops_outbox_backfill_appended_total{topic}`. V15 indexes `core.outbox (tenant_id, topic, aggregate_id, seq)` for
   the "has an event" lookup.
