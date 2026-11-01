# Cross-cutting follow-ups (owned by the orchestrator)

Collected from WP handovers. Resolved items move to the bottom with the WP/commit that closed them.

## Open
- **Browser smoke tests**: chromedriver not installed (download was blocked by the environment); `flutter drive`
  smoke and the Lighthouse installability check are manual for now (apps/web/README.md).
- **Product question**: a super_admin who also holds tenant memberships gets tenant navigation only (no Platform
  entry) — decide in WP14 (suggest: Platform entry in Profile menu when realm role present).


- **WP10b norms research** (Sonnet + web search): replace placeholder norm blocks with cited published tables
  (FITNESSGRAM HFZ, ALPHA-Fit/Eurofit percentiles, published youth vertical-jump/T-test norms) and verify the Cooper
  1968 figures; update `R__physical_test_norms.sql` + `docs/domain/norms.md`.

- **PWA cold-start offline (WP13 finding)**: Flutter 3.47's generated `flutter_service_worker.js` unregisters
  itself and caches nothing (`--pwa-strategy` deprecated). Add a custom caching service worker (app shell +
  `sqlite3.wasm` + `drift_worker.js` + deferred parts precache, network-first for `/api`) in WP14 or WP17; verify
  with airplane-mode reload. Until then offline works only while the tab stays open.
- **Same-device two-tab clientSeq race** (WP13): acceptable for now (second event is CLIENT_SEQ_CONFLICT and visible).


- **Kind deploy of core-service** + `smoke.sh core game athlete` + `/api/core/me` e2e through the ingress (WP18).
- **Production ingress choice** (ingress-nginx retiring upstream) and External Secrets Operator manifests.

- **Web polish (WP14)**: add a "new version
  available, reload" prompt (SKIP_WAITING); mock mode lacks `/api/athlete/*` and `/platform/*`; calendar shows
  device timezone (use tenant timezone once AuthzContext carries it); availability badge not yet in roster/match
  setup; usage history chart once the regenerated package exposes `getTenantUsageHistory`.

- **Template i18n** (WP9): consider `nameKey`/`locale` on `TrainingPlanSummary` (the UI maps template names by id) — not
  done in WP2c.
- **Backfill REJECTED** (WP2c): players rejected before core `V8__player_rejected.sql` remain WITHDRAWN (no backfill).
- **apps/web after WP2c**: regenerate the Dart packages (`just gen-api`) and adapt: `PlayerStatus.REJECTED`,
  `BoxScore.opponentFouls` removed (also in `lib/features/match/data/mock_game_api.dart`), `StatLine.technicalFouls` /
  `unsportsmanlikeFouls`, `RejectApprovalRequest` (required note), nullable `ageAtMeasurement`, `bandStatus`,
  `EVENT_ID_REUSED` / `MATCH_NOT_STARTED`, `AuthzSummary.timezone` / `playerTeamIds`, new athlete/platform operations.

- **Member e-mail changes** are not synced to Keycloak (WP3; left open by WP17).
- **Parents via the guardian flow** get no login (WP5 note); WP17 covered players only (ADMIN add + approval).

### From the WP17 security review (`docs/security/review-2026-11.md`)
- **F-01 game event feed** (Medium): `GET /api/game/matches/{id}/events` returns every player's stat events to
  PARENT/PLAYER — filter to own/linked players + team events, or document it as intended and align the authz matrix.
- **F-03 / F-07 / F-08 web sign-out and storage** (apps/web): forget the user locally before end-session (works
  offline), wipe the drift DB on logout/subject change, scope `roster`/`matchJson`/`ownEvents` by tenant+person, drop
  `offline_access`; realm: refresh-token rotation.
- **F-09 / F-10 web supply chain** (apps/web): `flutter build web --no-web-resources-cdn` + bundled fonts (then remove
  gstatic from the CSPs in `infra/compose/nginx.conf` and `deploy/containers/web-nginx.conf`); pin the sha256 of
  `sqlite3.wasm`.
- **F-11 invite of an existing Keycloak account**: links without consent and reveals the account (ACCEPTED vs PENDING) —
  product decision (notification e-mail; uniform response).
- **F-14 token audience**: audience mapper per service + `quarkus.oidc.token.audience`.
- **F-19 / F-20 web**: derive the SW network-only prefixes from config; fail release builds with mock API / http issuer.
- **Audit read API**: `core.audit_event` has no endpoint (contract has none) — add ADMIN `GET /api/core/audit-events`
  (and/or a super_admin view) in the contract; retention job (migrator) for old rows.
- **ASVS gaps**: password blocklist (6.2.4), breached passwords (6.2.12), optional OTP for ADMIN/super_admin (6.3.3),
  Keycloak login events (16.3.1), authorization-failure logging (16.3.2), log shipping / OTel collector (16.4.3), SBOM.
- **Tiltfile**: call `scripts/sync-chart-files.sh` before `k8s_yaml(helm(...))` (chart copies of realm/init SQL).
- **e2e vs. admin console**: e2e uses the master realm + Admin API → `HOOPS_EXPOSE_KC_ADMIN=true` (compose) /
  `keycloak.exposeAdminConsole: true` (kind `values-local.yaml`).
- **Realm re-import** after WP17 (`basic` scope / `sub`, 5173 URIs, password policy): `just down && podman volume rm
  hoops_pgdata && just up`.
- **Pin `ubi9/openjdk-21-runtime`** tag in `deploy/containers/service.Containerfile` (trivy DS-0001); guava pin in the
  root pom can go once the Quarkus BOM ships ≥ 33.7.2.
- **`CoreReachabilityCheck`** is duplicated in game and athlete — move it to common-quarkus (enabled when
  `hoops.core.url` is used).

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
- WP17: onboarding crash window — `RepairOnboarding` + `OnboardingRepairJob` (core, every 10 min, 15 min grace,
  ADR-0017); orphaned Keycloak login logged for manual clean-up.
- WP17: uploads > 2 MB — `RequestBodyLimit` (common) answers 413 Problem `REQUEST_TOO_LARGE`; 2M limit for every service.
- WP17: player login — CreatePlayer (ADMIN path) and ApproveRequest (ADD_PLAYER) reuse the invitation saga for players
  with an e-mail; 502 declared on both operations (core contract 2.1.0).
- WP17: members list hides persons of PENDING_APPROVAL / REJECTED players.
- WP17: measurement-per-day race → 409 `MEASUREMENT_EXISTS_FOR_DATE` (athlete).
- WP17: `quarkus-smallrye-health` in game and athlete (DB readiness + non-blocking core indicator).
- WP17: Keycloak `web` client — `http://localhost:5173/*` redirect/post-logout URIs + web origin; services answer CORS
  for the dev origin (`hoops.cors.origins`); `basic` client scope on every client (tokens carry `sub`; sub-less JWTs → 401).
- WP17: rate limiting — nginx `limit_req` (token endpoint, `events:batch`, 429) + ingress-nginx `limit-rpm` Ingresses.
- WP17: TCP probe overrides dropped in `deploy/helm/hoops/values.yaml` (all services on `/q/health/*`).
- WP17: chart symlinks replaced by copies + `scripts/sync-chart-files.sh` (drift check in `deploy/helm/tests/run.sh`);
  `helm package` works.
- WP17: mail in kind — mailpit as Service `mailhog` (values-kind only).
- WP17: nginx/ingress serve `index.html`, `sw.js`, `flutter_service_worker.js` with `Cache-Control: no-cache`.
- WP17: ingress forwards `events:batch` unchanged (regex Ingress without rewrite; chart assertion).
