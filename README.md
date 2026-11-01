# Hoops Academy

Multitenant web platform (mobile-first PWA) for basketball academies: rosters and age-category eligibility,
live match statistics with offline entry, training calendar and attendance, athlete health and fitness
tracking with age norms. Spanish, English and Indonesian UI.

- Plan and architecture: `docs/PLAN.md`, decisions in `docs/adr/`
- Agent conventions: `CLAUDE.md`
- Setup: `scripts/bootstrap.sh`, then `source scripts/env.sh && just doctor`
- Run locally: `just up` then `./mvnw -pl services/core-service quarkus:dev`

## Layout
```
libs/common-quarkus   tenancy, RLS, authz, Problem+JSON, shared test fixtures
libs/contracts        OpenAPI specs + event JSON Schemas (source of truth for clients)
services/*            core-service, game-service, athlete-service (Quarkus)
apps/web              Flutter Web PWA
infra/                compose stack, DB init SQL, Keycloak realm
deploy/               Helm charts, kind scripts, Tiltfile
e2e/                  journey tests against the running stack
```
