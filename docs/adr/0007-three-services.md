# ADR-0007: Three services for v1: core, game, athlete

- Status: Accepted
- Date: 2026-11-01

## Context
An earlier draft had six deployables (platform, academy, game, training, athlete, gateway). Tenant sign-up must atomically create a tenant and its first admin; training and health data share actors and authz shape; a custom gateway adds a service to secure and test.

## Decision
`core-service` (tenancy, identity & membership, roster & eligibility, approvals, platform stats, billing seams), `game-service` (offline-first match events and projections), `athlete-service` (training, attendance, health, fitness). Routing by nginx/ingress; each service validates JWTs itself.

## Consequences
Fewer charts, contracts and test harnesses; each service is a self-contained agent lane. game-service keeps distinct non-functional traits (idempotent batch ingest, event sourcing).
