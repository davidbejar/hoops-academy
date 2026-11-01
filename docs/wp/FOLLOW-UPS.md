# Cross-cutting follow-ups (owned by the orchestrator)

Collected from WP handovers. Resolved items move to the bottom with the WP/commit that closed them.

## Open
- **Keycloak client `web`**: add `http://localhost:5173/*` redirect/post-logout URIs and web origin for the Flutter dev
  server; API CORS for the dev origin in nginx (WP11). Realm import runs once → needs volume reset.
- **Browser smoke tests**: chromedriver not installed (download was blocked by the environment); `flutter drive`
  smoke and the Lighthouse installability check are manual for now (apps/web/README.md).
- **Product question**: a super_admin who also holds tenant memberships gets tenant navigation only (no Platform
  entry) — decide in WP14 (suggest: Platform entry in Profile menu when realm role present).

- **Core onboarding crash window**: tenant row without settings/admin if the process dies mid-saga → add a repair job or
  make the platform insert last (WP3 open point); member e-mail changes not synced to Keycloak.
- **Uploads > 2 MB** return a plain 413 from the HTTP layer (no Problem body) — configure `quarkus.http.limits` + mapper.

- **Rate limiting** for `events:batch` and `/auth` at the proxy/ingress (WP17).

- **WP10b norms research** (Sonnet + web search): replace placeholder norm blocks with cited published tables
  (FITNESSGRAM HFZ, ALPHA-Fit/Eurofit percentiles, published youth vertical-jump/T-test norms) and verify the Cooper
  1968 figures; update `R__physical_test_norms.sql` + `docs/domain/norms.md`.

- **PWA cold-start offline (WP13 finding)**: Flutter 3.47's generated `flutter_service_worker.js` unregisters
  itself and caches nothing (`--pwa-strategy` deprecated). Add a custom caching service worker (app shell +
  `sqlite3.wasm` + `drift_worker.js` + deferred parts precache, network-first for `/api`) in WP14 or WP17; verify
  with airplane-mode reload. Until then offline works only while the tab stays open.
- **Same-device two-tab clientSeq race** (WP13): acceptable for now (second event is CLIENT_SEQ_CONFLICT and visible).

- **Player login/invitation** (WP5): CreatePlayer stores email but creates no Keycloak user; reuse the InviteMember
  saga for players with an email (and for parents created via guardian flow).
- **Members list** shows pending/rejected players' persons (WP5) — filter by status.

- **Health extension** (WP16): add `quarkus-smallrye-health` to game- and athlete-service and drop the TCP probe
  overrides in `deploy/helm/hoops/values.yaml`.
- **Kind deploy of core-service** + `smoke.sh core game athlete` + `/api/core/me` e2e through the ingress (WP18).
- **Helm chart symlinks** (realm JSON, init SQL) break `helm package`; replace with a copy step in `up.sh`/CI before
  publishing charts.
- **Mail in kind**: realm SMTP host `mailhog` is not deployed in the cluster (add mailpit chart or disable e-mail).
- **Production ingress choice** (ingress-nginx retiring upstream) and External Secrets Operator manifests.

- **Web polish (WP14)**: nginx/ingress must serve `sw.js` with `Cache-Control: no-cache`; add a "new version
  available, reload" prompt (SKIP_WAITING); mock mode lacks `/api/athlete/*` and `/platform/*`; calendar shows
  device timezone (use tenant timezone once AuthzContext carries it); availability badge not yet in roster/match
  setup; usage history chart once the regenerated package exposes `getTenantUsageHistory`.

- **Template i18n** (WP9): consider `nameKey`/`locale` on `TrainingPlanSummary` (the UI maps template names by id) — not
  done in WP2c.
- **Measurement-per-day race** (WP10): two simultaneous inserts hit the unique constraint as a 500; map the unique
  violation to 409 `MEASUREMENT_EXISTS_FOR_DATE` — not done in WP2c.
- **Ingress (WP16)**: the compose nginx forwards `events:batch` / `:copy` unchanged (verified in WP2c); the k8s ingress
  must do the same (no rewrite / URI normalisation) — check when WP16 lands.
- **Backfill REJECTED** (WP2c): players rejected before core `V8__player_rejected.sql` remain WITHDRAWN (no backfill).
- **apps/web after WP2c**: regenerate the Dart packages (`just gen-api`) and adapt: `PlayerStatus.REJECTED`,
  `BoxScore.opponentFouls` removed (also in `lib/features/match/data/mock_game_api.dart`), `StatLine.technicalFouls` /
  `unsportsmanlikeFouls`, `RejectApprovalRequest` (required note), nullable `ageAtMeasurement`, `bandStatus`,
  `EVENT_ID_REUSED` / `MATCH_NOT_STARTED`, `AuthzSummary.timezone` / `playerTeamIds`, new athlete/platform operations.

## Resolved
- nginx `/platform/**` → core (WP2b handover) — fixed in commit 3418100.
- Keycloak `core-service` service account lacked realm-management `manage-users`/`view-users` — fixed in commit 85e3ca0 (requires realm re-import: `just down && podman volume rm hoops_pgdata`).
- `Problem.code` alignment between contracts and common — done in WP2a.
- WP2c: AuthzContext enrichment — core `/internal/authz` and `/me` (`AuthzSummary`) carry `timezone` and
  `playerTeamIds` (open, valid assignments of own + linked players); `ownPlayerId` already was the own player id (/me
  item of WP13); Java record + shared client + athlete (tenant registry zone, team-less PARENT/PLAYER lists).
- WP2c: 503 `ServiceUnavailable` in `common.yaml`, declared on every `/api/game/**` and `/api/athlete/**` operation;
  502 `UpstreamIdentityProvider` on `createTenant` / `inviteMember`.
- WP2c: optimistic-lock → 409 `CONCURRENT_MODIFICATION`, `UnauthorizedException` → 401 and `UpstreamUnavailableException`
  → 503 mappers in common; game's local mappers deleted.
- WP2c: `openapi-request-validator-restassured` 3.0.0 (relocated name) in the root pom and the three services.
- WP2c: RosterPort REST code moved to `com.hoopsacademy.common.client` (`CoreInternalClient`, `CoreRosterClient`,
  `RosterAuthzResolver` default bean); game/athlete keep thin `RosterPort` adapters.
- WP2c: `TenantScope.runExclusive` (advisory xact lock, lock tx suspended while the work runs) for core's eligibility
  sweep and usage snapshot and athlete's materialisation.
- WP2c: `/internal/usage/{tenantId}` → 200 with zero counters for an unknown tenant in every service (contract + core).
- WP2c: allOf / additionalProperties validator quirk, combinator-resolution side effects and colon paths documented
  in `libs/contracts/README.md`.
- WP2c: `hoops.tenancy.exempt-paths` (default `/api/core/me`) replaces core's `MePathRewriteFilter`.
- WP2c: athlete plan `:archive` / `:unarchive` and `GET /plan-assignments/{id}/progress` in the contract and wired.
- WP2c: `RlsSchemaMetaTest.nullableTenantTables()` / `GenericRlsIsolationTest.nullableTenantTables()` hook with the
  one-policy-per-command check; athlete's four shared tables use it; skill updated.
- WP2c: game contract — fixed `type` per MatchEvent variant (batch and feed bodies contract-validated again),
  `EVENT_ID_REUSED`, `MATCH_NOT_STARTED` (reserved), `StatLine` technical/unsportsmanlike fouls, `BoxScore.opponentFouls`
  removed (ADR-0016).
- WP2c: nginx passes `events:batch` (and `%3A`) through unchanged — verified from the nginx upstream URI, no config change.
- WP2c: athlete availability operation + `bandStatus` + nullable `ageAtMeasurement` in the contract.
- WP2c: core `PlayerStatus.REJECTED` (reject sets it), `GET /platform/tenants/{id}/usage/history`, required reject note
  (`RejectApprovalRequest`), core counter keys documented in `UsageReport` (+ `playersRejected`).
- WP2c: Problem `instance` double slash in game 503 responses — game's local 503 mapper (`"/" + uri.getPath()`) was
  deleted; common's mapper uses the raw request path.
