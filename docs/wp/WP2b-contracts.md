# WP2b — libs/contracts: OpenAPI ×3, event JSON Schemas, Dart generation

Model: Opus. Depends on: WP0. Parallel with WP1, WP2a. Reads: docs/PLAN.md §1.2–1.5, §2; docs/domain/authz-matrix.md.

## Scope
- `openapi/common.yaml`: Problem schema (RFC 9457), `X-Tenant-Id` header param, pagination params/envelope, ids as uuid,
  standard error responses, security scheme `bearer` (JWT).
- `openapi/core.yaml`: /platform/tenants (CRUD + suspend/withdraw + usage), /api/core/me, /api/core/tenant (profile,
  settings, logo PUT/GET/DELETE multipart/binary), members & roles, guardian links, seasons (+rollover), age categories,
  teams, team players (assign/unassign/validate), team staff, players (+approval flow), approval requests,
  eligibility cases, /internal/authz/{tenantId}/{sub}, /internal/usage/{tenantId}, /internal/teams/{id}/roster,
  /internal/players (batch by ids).
- `openapi/game.yaml`: matches (CRUD, start/finish/cancel), roster, `POST /matches/{id}/events:batch` (per-event
  results), `GET /matches/{id}/events?after=`, box score, player season stats, /internal/usage.
- `openapi/athlete.yaml`: schedules, sessions, attendance, absences, plans/templates/items, assignments, completions,
  injuries, measurements, test types, results (+expected band), norms, /internal/usage.
- `events/match-event.schema.json` + one `$defs` entry per event type (discriminator `type`), shared by game-service
  validation and Flutter.
- Maven module `contracts`: packages YAML/JSON as resources; `openapi-generator-maven-plugin` `validate` goal in
  `verify`; optional `spectral`-free lint via generator validation; Dart `dart-dio` generation config
  (`scripts/gen-api.sh` using the brew `openapi-generator` CLI, output `apps/web/lib/api/<svc>`).
- `README.md` describing versioning (`info.version`, breaking-change policy) and how to regenerate.

## Acceptance
- [ ] `./mvnw -pl libs/contracts verify` validates all three specs + JSON Schema syntax
- [ ] every operation has `operationId`, tags, security, 401/403/404 Problem responses; tenant endpoints declare `X-Tenant-Id`
- [ ] `scripts/gen-api.sh` produces Dart that compiles (`dart analyze` on the generated package) — may be verified in WP11 if Flutter not yet installed; note it
- [ ] event schema rejects an unknown type and a SHOT without `points`
