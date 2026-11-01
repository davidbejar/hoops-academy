# ADR-0008: Synchronous REST behind a RosterPort for v1; outbox + Redpanda for v2

- Status: Accepted
- Date: 2026-11-01

## Context
game- and athlete-service need roster and authz data owned by core-service. A broker on day one adds operational weight; agents building in parallel need a stable seam.

## Decision
v1: `RosterPort` interface in each consumer, implemented by a REST client to core `/internal/**` with client-credentials token, 30 s cache and 2 s timeout → 503. Game denormalises names at roster creation. v2 (optional WP19): transactional outbox in core polled and published to Redpanda, local `*_ref` replicas, adapter swapped behind a flag.

## Consequences
Runtime coupling to core and up to 30 s authz staleness are accepted for v1. The port keeps the domain unchanged when moving to events; billing will consume the same outbox.
