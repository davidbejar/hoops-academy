# core-service

Tenancy, identity & membership, platform endpoints, academy profile and logo (WP3). Roster & eligibility (WP4)
and approvals (WP5) are added to this module later. Contract: `libs/contracts/openapi/core.yaml`.
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

The Keycloak Admin API calls need the `core-service` service account to hold realm-management `manage-users`
(and `view-users`); the realm export does not grant it yet (see WP3 handover). OpenAPI: `/q/openapi`,
health: `/q/health`, metrics: `/q/metrics`.

## Layout (hexagonal, enforced by `ArchitectureTest`)

```
com.hoopsacademy.core
├── domain/{tenant,identity,membership,logo,shared}   pure Java (value objects, rules)
├── application/{platform,tenant,members,me,authz,usage,port,shared}   use cases + ports
└── adapters/
    ├── in/rest       /api/core/** (tenant API, /me)      in/platform  /platform/**      in/internal  /internal/**
    ├── in/shared     merge-patch reader, Problem mappers, caller identity
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
- Every REST-assured exchange is validated against `core.yaml` (`Contract.CORE`); negative tests that send bodies
  the contract forbids use `Contract.RESPONSES_ONLY`, failure-path tests (502/500) use `Contract.FAILURES`.
- `@Tag("keycloak")` tests import `infra/keycloak/realm-academy.json` into `quay.io/keycloak/keycloak:26.8.1`; they are
  excluded from the default surefire run (`surefire.excludedGroups=keycloak`) and meant for CI.
