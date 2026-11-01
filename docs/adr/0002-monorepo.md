# ADR-0002: Single monorepo for services, frontend and infrastructure

- Status: Accepted
- Date: 2026-11-01

## Context
Three Quarkus services, a Flutter app, API contracts, Helm charts and compose files must evolve together; the work is executed by multiple AI agents that need shared conventions, skills and CI.

## Decision
One git repository with a Maven multi-module parent, `apps/web` for Flutter and `infra/` + `deploy/` for infrastructure. Each service remains independently buildable, containerised and deployable.

## Consequences
Atomic cross-cutting changes (contract + service + client) are possible; CI uses per-module matrices to keep feedback fast. Splitting a service out later is a directory move.
