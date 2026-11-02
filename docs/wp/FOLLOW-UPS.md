# Cross-cutting follow-ups (owned by the orchestrator)

Collected from the WP handovers and the WP20 review (2026-11-02). Grouped by area; **[v2]** marks items that are out of
v1 by decision (PLAN §8, roadmap). Resolved items are listed at the bottom with the WP that closed them. The
statement-by-statement status of the spec is in [`../conformance.md`](../conformance.md).

## Open

### Product / contract decisions
- **F-01 event feed** (Medium): `GET /api/game/matches/{id}/events` returns every player's events to PARENT/PLAYER members;
  the box score hides them. Filter the feed to team-level events + own/linked players, or declare the full feed intended
  (live scoring by parents) and align `docs/domain/authz-matrix.md` and the guides.
- **F-11 invite of an existing Keycloak account**: links without consent and reveals the account (ACCEPTED vs PENDING);
  decide on a notification e-mail and a uniform response.
- **Audit read API**: `core.audit_event` has no endpoint; add ADMIN `GET /api/core/audit-events` (and/or a super_admin
  view) to the contract, plus a retention job (migrator) for old rows.
- **Contract `allOf` + `additionalProperties: false`** (WP18b): e.g. `AgeCategory = allOf[AgeCategoryInput, {id}]` cannot
  validate any real response; tests and e2e mute those errors. Drop `additionalProperties:false` from composed members
  (or move to `unevaluatedProperties` with OpenAPI 3.1).
- **`MatchEvent` oneOf/discriminator** is not resolvable by the atlassian validator for feed responses (WP18b); e2e reads
  the feed unvalidated.
- **Template i18n** (WP9): `nameKey`/`locale` on `TrainingPlanSummary`; the 10 templates are English-only in the DB.
- **Withdrawn tenant logins**: memberships vanish (404) but Keycloak accounts stay enabled; game/athlete need up to
  30 s (membership cache) — decide whether suspend/withdraw should also invalidate peers' caches or disable logins.

### Security (from `docs/security/review-2026-11.md`)
- **F-07 residual (apps/web)**: cached reads (`roster`, `matchJson`, `ownEvents`) are keyed by matchId only; add
  tenant + person columns (drift migration) and wipe when a *different* `sub` signs in after an expired session.
- **F-08 residual (realm)**: refresh-token rotation / reuse detection in `infra/keycloak/realm-academy.json`; the realm
  still lists `offline_access` as an optional scope.
- **F-14 token audience**: audience mapper per service + `quarkus.oidc.token.audience`.
- **ASVS gaps**: password blocklist (6.2.4), breached passwords (6.2.12), optional OTP for ADMIN/super_admin (6.3.3),
  Keycloak login events (16.3.1), authorization-failure logging (16.3.2), log shipping / OTel collector (16.4.3), SBOM.
- **Offline end-session** is skipped, not queued (SSO session lives until its 4 h idle timeout) — accepted, ADR-0019.

### Web app (`apps/web`)
- **Browser-level tests**: `apps/web/tool/web_smoke.sh` ran green in mock mode on 2026-11-02 (chromedriver 156 installed
  by hand from Chrome for Testing; the Homebrew cask is disabled). Still open: the Lighthouse installability check and the
  airplane-mode cold-start check (README "Offline cold start"); add chromedriver to CI.
- **PLAYER's own line in the live box score**: `scoring_rights.dart` `canSeeLine` ignores `ownPlayerId` (server returns
  the line).
- **REJECTED player label**: `lib/core/ui/labels.dart` maps `PlayerStatus.REJECTED` to "withdrawn"; add a label in es/en/id.
- **Training plan on a session**: no plan picker on ad-hoc sessions and no session edit screen (`SessionDetailNotifier.edit`
  exists); also no UI to edit/delete measurements and test results, update test types or edit absences.
- **Availability badge** in team roster rows and match setup (needs the athlete fake in those tests).
- **Calendar timezone**: times are shown in the device zone; `/me` now carries the tenant `timezone`, use it.
- **Usage trend chart** on the platform console (`getTenantUsageHistory` is in the regenerated package, unused).
- **Demo mock** lacks `/api/athlete/*` and `/platform/*`.
- **Fonts**: glyphs outside Roboto (CJK, emoji) render as tofu; bundle a Noto subset if a language needs it.
- **Same-device two-tab clientSeq race** (WP13): accepted for now (second event is `CLIENT_SEQ_CONFLICT`, visible).
- **Production ingress prefixes** must match `NETWORK_ONLY_PREFIXES` in `web/sw.js` if they ever differ.

### Backend
- **Member e-mail changes** are not synced to Keycloak (WP3).
- **Parents via the guardian flow** get no login (WP5 note); WP17 covered players only (ADMIN add + approval).
- **Entitlement seam** has no test of a denial path (the noop implementation always allows).
- **Usage snapshots** are never pruned; the snapshot job aggregates tenants sequentially (fine for tens of tenants).
- **`staffTeamIds` / `playerTeamIds`** include teams of ended seasons while a staff row / assignment is open.
- **Unassigning an invalidated assignment** leaves its OPEN eligibility case open (resolve via the case API).
- **Backfill REJECTED** (WP2c): players rejected before core `V8` stay WITHDRAWN (pre-release data; accepted).
- **Fitness norms** (WP10b): replace placeholders with cited five-band tables (Tomkinson 2017 for the beep test,
  ALPHA-Fit/HELENA for sit-and-reach, sprint / T-test / vertical jump sources) and obtain a primary Cooper table.
- **Dependency hygiene**: `dependency:analyze` lists Quarkus extensions as "unused" (false positives, runtime-only) and
  many transitive APIs as "used undeclared"; only `caffeine` in game/athlete was really unused (removed in WP20).

### Infra, CI, e2e
- **e2e journey on kind**: never green (blocked by the realm defect at the time, not re-run). Run per
  `docs/runbooks/e2e.md` (port-forwards for the Keycloak Admin API and MailHog).
- **`tilt ci` with core-service** has not been run (WP16 deployed game/athlete/web; WP18 used `up.sh --deploy`).
- **Tiltfile**: call `scripts/sync-chart-files.sh` before `k8s_yaml(helm(...))` (chart copies of realm/init SQL).
- **`e2e/bin/services-up.sh`** treats any HTTP answer as ready and its comment says game/athlete have no health
  extension; switch to `status == UP` on `/q/health/ready` now that all three have it.
- **CI workflows** (`ci.yml`, `images.yml`, `e2e.yml`) have never run; the e2e workflow's throw-away `.env` must set
  `HOOPS_EXPOSE_KC_ADMIN=true`; dependency-check needs `secrets.NVD_API_KEY`.
- **Pin `ubi9/openjdk-21-runtime`** in `deploy/containers/service.Containerfile` (trivy DS-0001); drop the guava pin in the
  root pom once the Quarkus BOM ships ≥ 33.7.2.
- **Optimised Keycloak image** (read-only root FS; KSV-0014 accepted until 2027-03-31).
- **Production ingress choice** (ingress-nginx is retiring upstream) and External Secrets Operator manifests.
- **PIT** (mutation testing) is configured in the root pom but no run is recorded.

### v2 (by decision)
- **[v2] Events**: outbox publisher + Redpanda + `*_ref` replicas behind `RosterPort` (WP19 brief; `core.outbox` is
  already written and never read).
- **[v2] Billing module** on the existing seams (`billing.*`, `EntitlementService`, outbox events).
- **[v2] Purge job** for withdrawn tenants after the retention period.
- **[v2]** Push notifications, native images, Pact broker.

## Resolved
- nginx `/platform/**` → core (WP2b handover) — fixed in commit 3418100.
- Keycloak `core-service` service account lacked realm-management `manage-users`/`view-users` — fixed in commit 85e3ca0.
- `Problem.code` alignment between contracts and common — done in WP2a.
- WP2c: AuthzContext enrichment — core `/internal/authz` and `/me` carry `timezone` and `playerTeamIds`; `ownPlayerId`
  is the own player id.
- WP2c: 503 `ServiceUnavailable` on every game/athlete operation; 502 `UpstreamIdentityProvider` on `createTenant` /
  `inviteMember`.
- WP2c: optimistic-lock → 409, `UnauthorizedException` → 401, `UpstreamUnavailableException` → 503 mappers in common.
- WP2c: `openapi-request-validator-restassured` 3.0.0 (relocated name) in the root pom and the three services.
- WP2c: RosterPort REST code moved to `com.hoopsacademy.common.client`; game/athlete keep thin adapters.
- WP2c: `TenantScope.runExclusive` for core's sweep and snapshot and athlete's materialisation.
- WP2c: `/internal/usage/{tenantId}` → 200 with zero counters for an unknown tenant in every service.
- WP2c: allOf / additionalProperties validator quirk, combinator side effects and colon paths documented in
  `libs/contracts/README.md`.
- WP2c: `hoops.tenancy.exempt-paths` replaces core's `MePathRewriteFilter`.
- WP2c: plan `:archive` / `:unarchive` and assignment progress in the contract and wired.
- WP2c: `nullableTenantTables()` RLS hook for shared global+tenant tables.
- WP2c: game contract — fixed `type` per variant, `EVENT_ID_REUSED`, `MATCH_NOT_STARTED` (reserved), `StatLine` foul
  counters, `BoxScore.opponentFouls` removed (ADR-0016).
- WP2c: nginx passes `events:batch` (and `%3A`) through unchanged.
- WP2c: athlete availability operation + `bandStatus` + nullable `ageAtMeasurement` in the contract.
- WP2c: core `PlayerStatus.REJECTED`, usage history endpoint, required reject note, counter keys documented.
- WP2c: Problem `instance` double slash in game 503 responses.
- WP10b: norms research — beep test 9–17 sourced (Zhang 2020), sit-and-reach anchored on FITNESSGRAM HFZ; remaining
  placeholders tracked above.
- WP14: super_admin with memberships reaches the Platform console from Profile.
- WP14: caching service worker `web/sw.js` for the offline cold start (ADR-0018; browser check tracked above).
- WP14b: "new version available, reload" prompt (SKIP_WAITING).
- WP14b: F-03 sign-out, F-08 `offline_access` dropped, F-09 no CDN, F-10 sqlite3.wasm sha256, F-19 network-only prefixes,
  F-20 release-build guards; security review statuses updated in WP20.
- WP17: onboarding crash window — `RepairOnboarding` + `OnboardingRepairJob` (ADR-0017).
- WP17: uploads > 2 MB → 413 Problem `REQUEST_TOO_LARGE` for every service.
- WP17: player login for ADMIN add + approval (core contract 2.1.0).
- WP17: members list hides persons of PENDING_APPROVAL / REJECTED players.
- WP17: measurement-per-day race → 409 `MEASUREMENT_EXISTS_FOR_DATE`.
- WP17: `quarkus-smallrye-health` in game and athlete; TCP probe overrides dropped.
- WP17: Keycloak `web` client 5173 URIs + web origin; CORS allow-list; `basic` scope on every client (tokens carry
  `sub`; sub-less JWTs → 401).
- WP17: rate limiting (nginx `limit_req`, ingress-nginx `limit-rpm`).
- WP17: chart symlinks replaced by copies + `scripts/sync-chart-files.sh` (drift check in the chart tests).
- WP17: mail in kind (mailpit as Service `mailhog`); `no-cache` for the app shell files; ingress forwards `events:batch`.
- WP18: kind deploy of core-service + `smoke.sh core game athlete` + superadmin `/api/core/me` through the ingress.
- WP18b: realm re-imported on compose; `HOOPS_EXPOSE_KC_ADMIN=true` for the e2e Admin API; **journey 20/20 green on
  compose** (three consecutive runs).
- apps/web after WP2c: Dart packages regenerated (core 2.1.0, game/athlete 2.0.0) and the app adapted.
- WP20: `CoreReachabilityCheck` moved to common-quarkus (core disables it with `hoops.core.reachability-check.enabled=false`).
- WP20: flaky job-lock tests (`NightlyEligibilityJobTest`, `UsageSnapshotJobTest`, `NightlyMaterialisationTest`) release
  the other replica's session lock explicitly instead of relying on connection close.
- WP20: runbooks, apps/web README, PLAN implementation notes, security review statuses reconciled; ADR-0018…0021.
