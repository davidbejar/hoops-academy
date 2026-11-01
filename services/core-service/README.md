# core-service

Tenancy, identity & membership, platform endpoints, academy profile and logo (WP3); seasons, age categories, teams,
staff, eligibility-checked assignments, eligibility cases, rollover and the eligibility sweep (WP4, ADR-0015).
Approvals (WP5) are added to this module later. Contract: `libs/contracts/openapi/core.yaml`.
Port **8081** (nginx routes `/api/core/**` and `/platform/**` here; `/internal/**` is blocked at the proxy).

## Run locally

```bash
just up                                   # Postgres, Keycloak (http://localhost:8080/auth), nginx, MailHog
set -a; source .env; set +a               # role passwords + CORE_SERVICE_CLIENT_SECRET (copy .env.example first)
source scripts/env.sh
./mvnw -pl services/core-service quarkus:dev
```

| Variable | Default | Used for |
|---|---|---|
| `CORE_DB_URL` | `jdbc:postgresql://localhost:5432/hoops` | both datasources |
| `CORE_APP_PASSWORD` | – (required) | default datasource, role `core_app` (RLS-bound, non-owner) |
| `CORE_PLATFORM_PASSWORD` | – (required) | `platform` datasource, role `core_platform` (registry, usage, billing only) |
| `CORE_MIGRATOR_PASSWORD` | – (required) | Flyway, role `core_migrator` (schema owner) |
| `CORE_SERVICE_CLIENT_SECRET` | – (required) | OIDC token validation, service tokens, Keycloak Admin API |
| `OIDC_AUTH_SERVER_URL` | `http://localhost:8080/auth/realms/academy` | issuer |
| `KEYCLOAK_URL` | `http://localhost:8080/auth` | Keycloak Admin API base |
| `GAME_SERVICE_URL` / `ATHLETE_SERVICE_URL` | `http://localhost:8082` / `:8083` | `/internal/usage` aggregation |
| `CORE_ELIGIBILITY_CRON` | `0 15 * * * ?` (hourly) | eligibility sweep over ACTIVE tenants (`off` disables it) |

The Keycloak Admin API calls need the `core-service` service account to hold realm-management `manage-users`
(and `view-users`); the realm export does not grant it yet (see WP3 handover). OpenAPI: `/q/openapi`,
health: `/q/health`, metrics: `/q/metrics`.

## Layout (hexagonal, enforced by `ArchitectureTest`)

```
com.hoopsacademy.core
├── domain/{tenant,identity,membership,logo,roster,eligibility,shared}   pure Java (value objects, rules)
├── application/{platform,tenant,members,me,authz,usage,roster,port,shared}   use cases + ports
└── adapters/
    ├── in/rest       /api/core/** (tenant API, /me)      in/platform  /platform/**      in/internal  /internal/**
    ├── in/shared     merge-patch reader, Problem mappers, caller identity     in/scheduler  eligibility sweep trigger
    ├── out/persistence  default PU (core_app, @TenantId entities)   out/platform  "platform" PU (core_platform)
    └── out/keycloak, out/client (usage of game/athlete), out/billing (noop entitlements)
```

## Tests

```bash
source scripts/env.sh
./mvnw -pl services/core-service verify                 # everything except @Tag("keycloak"); coverage gates
./mvnw -pl services/core-service verify -Pkeycloak-it   # ONLY the @Tag("keycloak") tests (Keycloak container)
```

- Postgres via `PostgresRlsResource` (Testcontainers, production init SQL, app connects as `core_app`).
- Keycloak Admin API, the service-token endpoint and game/athlete `/internal/usage` via WireMock
  (`WireMockResource`, stubs in `KeycloakStubs` / `UsageStubs`).
- Roster fixtures: `RosterDb` (seasons around the real "today", default ladder, teams, staff, players, assignments,
  cases); `Members.signInAs(tenant, person, roles, staffTeams)` for staff-relative authz.
- Every REST-assured exchange is validated against `core.yaml` (`Contract.CORE`, `allOf` flattened); negative tests that send bodies
  the contract forbids use `Contract.RESPONSES_ONLY`, failure-path tests (502/500) use `Contract.FAILURES`.
- `@Tag("keycloak")` tests import `infra/keycloak/realm-academy.json` into `quay.io/keycloak/keycloak:26.8.1`; they are
  excluded from the default surefire run (`surefire.excludedGroups=keycloak`) and meant for CI.

## Approvals and usage (WP5, WP15)
- `POST /api/core/players` and `…/withdraw`: ADMIN acts at once and leaves an auto-approved `approval_request` row;
  a COACH creates a PENDING request (`202`), an ADMIN decides it through `/api/core/approval-requests/{id}/approve|reject`;
  the requester may `cancel`. Rules in `domain.approvals`, use cases in `application.approvals`
  (`CreatePlayer`, `WithdrawPlayer`, `ApproveRequest`, `RejectRequest`, `CancelRequest`), reads in `application.players`.
- Outbox: `player.requested`, `player.approved`, `player.rejected`, `player.withdrawn`.
- `GET /platform/tenants/{id}/usage` aggregates core (counters from every `UsageCounter`), game and athlete; peers that
  fail or exceed 2 s are listed in `unavailableServices`. Each call upserts the day's `usage_snapshot`
  (one row per tenant and UTC day); `UsageSnapshotJob` does it for all ACTIVE tenants (`hoops.core.usage-snapshot-cron`,
  default 02:30 UTC).
