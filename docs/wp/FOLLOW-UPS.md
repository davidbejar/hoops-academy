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
- **Keycloak client `web`**: add `http://localhost:5173/*` redirect/post-logout URIs and web origin for the Flutter dev
  server; API CORS for the dev origin in nginx (WP11). Realm import runs once → needs volume reset.
- **Browser smoke tests**: chromedriver not installed (download was blocked by the environment); `flutter drive`
  smoke and the Lighthouse installability check are manual for now (apps/web/README.md).
- **Product question**: a super_admin who also holds tenant memberships gets tenant navigation only (no Platform
  entry) — decide in WP14 (suggest: Platform entry in Profile menu when realm role present).
- **allOf + swagger-request-validator additionalProperties** quirk — document in contracts README (WP8).

## Resolved
- nginx `/platform/**` → core (WP2b handover) — fixed in commit 3418100.
- `Problem.code` alignment between contracts and common — done in WP2a.
