# Cross-cutting follow-ups (owned by the orchestrator)

Collected from WP handovers. Resolved items move to the bottom with the WP/commit that closed them.

## Open
- **AuthzContext enrichment** (raised by WP8, WP6): add `timezone` (tenant), `playerTeamIds` (teams of own/linked
  players) to the core `/internal/authz` response, the OpenAPI schema (core.yaml), the Java record in common-quarkus
  and the adapters in game/athlete. Until then athlete uses `hoops.athlete.default-timezone` and parent/player list
  calls require `teamId`. → consolidation pass after WP3/WP4 (call it WP2c).
- **503 `ServiceUnavailable` response** in `common.yaml` + referenced by game/athlete operations (WP6, WP8).
- **OptimisticLockException → 409 Problem** mapper in common-quarkus (WP6 reports 500 today). WP7 may add a local one.
- **`swagger-request-validator-restassured` relocated** to `openapi-request-validator-restassured` — rename in root pom.
- **RosterPort adapter duplication** (game, athlete): move to `libs/common-quarkus` (`client` package) in WP2c; keep
  service-specific resolvers thin.
- **Nightly jobs on multiple replicas** (athlete materialisation, core eligibility): add a Postgres advisory lock
  helper in common (`TenantScope.runExclusive`) before WP16 scales replicas.
- **`/internal/usage` for unknown tenant** returns zeros in game/athlete (contract says 404) — align contract.
- **Keycloak web origins** for Flutter dev server port (5173) — WP1 realm follow-up once WP11 lands.
- **allOf + swagger-request-validator additionalProperties** quirk — document in contracts README (WP8).

## Resolved
- nginx `/platform/**` → core (WP2b handover) — fixed in commit 3418100.
- `Problem.code` alignment between contracts and common — done in WP2a.
