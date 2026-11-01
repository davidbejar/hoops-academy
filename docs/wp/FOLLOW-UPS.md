# Cross-cutting follow-ups (owned by the orchestrator)

Collected from WP handovers. Resolved items move to the bottom with the WP/commit that closed them.

## Open
- **AuthzContext enrichment** (raised by WP8, WP6): add `timezone` (tenant), `playerTeamIds` (teams of own/linked
  players) to the core `/internal/authz` response, the OpenAPI schema (core.yaml), the Java record in common-quarkus
  and the adapters in game/athlete. Until then athlete uses `hoops.athlete.default-timezone` and parent/player list
  calls require `teamId`. → consolidation pass after WP3/WP4 (call it WP2c).
- **503 `ServiceUnavailable` response** in `common.yaml` + referenced by game/athlete operations (WP6, WP8).
- **OptimisticLockException → 409 Problem** mapper: WP7 added a game-local `CONCURRENT_MODIFICATION` mapper; move to common in WP2c.
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

- **common `TenantScopedPaths`**: exempt `/api/core/me` (no X-Tenant-Id) so core can drop its reroute filter; add an
  `UnauthorizedException` → 401 Problem mapper to common (WP3).
- **Contracts**: declare 502 (identity provider failure) on createTenant/inviteMember; document the allOf request-body
  validator quirk (WP3).
- **Core onboarding crash window**: tenant row without settings/admin if the process dies mid-saga → add a repair job or
  make the platform insert last (WP3 open point); member e-mail changes not synced to Keycloak.
- **Uploads > 2 MB** return a plain 413 from the HTTP layer (no Problem body) — configure `quarkus.http.limits` + mapper.

- **Contracts (athlete)**: add operations for plan archive/unarchive and assignment progress (use cases exist, WP9);
  consider `nameKey` for template i18n.
- **common test-jar**: add a `nullableTenantTables()` hook so templates can keep a `tenant_id` column (WP9 used
  `owner_tenant_id` to satisfy the meta-test); RLS lesson learned: use separate select/insert/update/delete policies
  when USING and WITH CHECK differ (FOR ALL lets DELETE through) — fold into `app.enable_tenant_rls` docs/skill.

- **Contracts (game, WP7)**: per-event-type `type` const so request validators can discriminate MatchEvent; add
  rejection reason for "event id reused in another match" (currently CLIENT_SEQ_CONFLICT) and optionally
  `MATCH_NOT_STARTED`; `StatLine` technical/unsportsmanlike foul counts; `BoxScore.opponentFouls` has no source
  event type (drop or add OPPONENT_FOUL).
- **Ingress/nginx**: must pass `events:batch` paths through unchanged (percent-encoded colon → 404) (WP7, WP16).
- **Rate limiting** for `events:batch` and `/auth` at the proxy/ingress (WP17).

- **Contracts (athlete, WP10)**: add `GET /players/{playerId}/availability` and the `bandStatus` field
  (MATCHED|NO_NORM|MISSING_PLAYER_DATA) + nullable `ageAtMeasurement`; measurement-per-day race → map unique
  violation to 409.
- **WP10b norms research** (Sonnet + web search): replace placeholder norm blocks with cited published tables
  (FITNESSGRAM HFZ, ALPHA-Fit/Eurofit percentiles, published youth vertical-jump/T-test norms) and verify the Cooper
  1968 figures; update `R__physical_test_norms.sql` + `docs/domain/norms.md`.

## Resolved
- nginx `/platform/**` → core (WP2b handover) — fixed in commit 3418100.
- Keycloak `core-service` service account lacked realm-management `manage-users`/`view-users` — fixed in commit 85e3ca0 (requires realm re-import: `just down && podman volume rm hoops_pgdata`).
- `Problem.code` alignment between contracts and common — done in WP2a.
