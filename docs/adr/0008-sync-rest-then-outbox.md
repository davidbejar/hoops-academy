# ADR-0008: Synchronous REST behind a RosterPort for v1; outbox + Redpanda for v2

- Status: Accepted
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
