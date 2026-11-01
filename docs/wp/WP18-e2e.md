# WP18 — End-to-end journey suite (compose and kind) + Flutter integration tests

Model: Sonnet. Depends on: WP12–WP14, WP16. Skills: test-driven-development, verification-before-completion.

## Scope
- `e2e/` Maven module (REST Assured + Keycloak token helper + Awaitility) run against `BASE_URL` (compose `http://localhost:8080`
  or kind ingress). Journey: super admin creates tenant → first admin invite (read MailHog) → admin invites coach/parent
  → coach requests player → admin approves → assignment → match created, scored by coach + parent (parent restricted
  checks) → box score → training session + attendance → injury → physical test with band → season rollover produces
  orphan → resolved → cross-tenant 404s throughout → tenant suspended → 404s.
- Flutter `integration_test` smoke on Chrome: login, tenant switch, open match, enter one event offline, sync.
- `just e2e` recipe; CI job (compose on GitHub runner).

## Acceptance
- [ ] journey passes against compose and against kind; Flutter smoke passes; CI job green

## Handover

**Status: PARTIAL. Everything is built and compiles; the journey is verified only up to its first real-user login,
which is blocked by a realm defect in another lane (bug 1). Acceptance boxes are NOT ticked.**

### Built
- `e2e/` Maven module (Java 21, JUnit 5, REST Assured, Awaitility, Jackson, AssertJ, `openapi-request-validator-restassured`
  3.0.0 from the root pom; nothing internal depended upon), added as `<module>e2e</module>` in the root pom (only root-pom
  change). Tests are skipped (`skipTests`) unless `-De2e.baseUrl=...` or env `E2E_BASE_URL` is set (two activation
  profiles), so `./mvnw verify` is unaffected.
  - `support/KeycloakUserTokens` (browser-less PKCE login of client `web`: cookie jar done by hand because the JDK
    `CookieManager` drops the `Secure` cookies Keycloak sets over http; service tokens via client credentials),
    `KeycloakAdmin` (sets a random permanent password + clears required actions via master-realm `admin-cli`),
    `MailHog` (API v2), `Actor` (bearer + `X-Tenant-Id`, every response validated against
    `libs/contracts/openapi/<svc>.yaml` read from disk), `E2eEnv` (env / `.env`, values never logged), `Check`.
  - `JourneyTest`: 20 ordered steps (tenant + first admin + setup mail, login, season/team, coach + parent invites, direct
    player + coach request/approval, guardian link, match/roster/start, coach + parent events incl. NOT_AUTHORIZED and
    replay = all DUPLICATE, box score, finish, season stats, schedule/sessions/planned absence/attendance, plan
    copy-on-use/assignment/completion, injury/availability/measurement/physical test band, platform usage, rollover orphan
    + eligibility case, second-tenant isolation 404s, `/internal` 403 with/without service token, suspend/404/reactivate).
    After the first failing step the rest is skipped.
  - `e2e/bin/services-up.sh [--no-build]` / `services-down.sh` (bash 3.2 safe; env from `.env`; logs/pids in
    `e2e/target/services/`).
- `justfile`: `services-up`, `services-down`, `e2e BASE=...` (only these three recipes added).
- `.github/workflows/e2e.yml` (Podman + podman-compose on ubuntu-24.04, random throw-away `.env`, same scripts). Not run.
- `docs/runbooks/e2e.md` (compose, kind, journey list, password shortcut, blockers).
- `deploy/kind/smoke.sh`: with `core` in the list it now logs the seeded `superadmin` in (PKCE, curl) and checks
  `GET /api/core/me` (superAdmin=true), `GET /platform/tenants` 200 and `/internal/*` with a user token 403.
- Flutter: `apps/web/integration_test/journey_smoke_test.dart` (mock: login -> academy -> Partidos -> live match -> 3PT by
  the starter -> score +3 -> sync banner gone, no "Pendiente"; real: boots against the real origin, login screen, no mock
  banner; both skipped without their `--dart-define`), `apps/web/tool/web_smoke.sh` (`--compile-only`, default mock,
  `--real`; starts/stops chromedriver on :4444).

### Verified (what actually ran)
- `./mvnw -pl e2e test-compile` OK; `bash -n` on every script.
- Compose (reset once: `just down`, `podman volume rm hoops_pgdata`, `just up`, `just seed-users`; jars built with
  `./mvnw -q -pl core,game,athlete -am package -DskipTests`; `e2e/bin/services-up.sh --no-build` -> all three ready):
  `./mvnw -pl e2e test -De2e.baseUrl=http://localhost:8080` -> **20 tests: 2 passed, 1 error, 17 skipped, ~3-4 s.**
  Passed: super admin creates tenant (201, ACTIVE) and the setup e-mail is found in MailHog. Error at step 3 (admin
  logs in): `GET /api/core/me` -> 404 "User is not provisioned" (bug 1). Steps 4-20 therefore NOT executed against a real
  stack: their request bodies/assertions were written from the contracts and handovers and are unverified (expect some
  first-run adjustments, e.g. exact band/gamesPlayed/session-count assertions).
- kind (rootless, 2 CPU / 8 GiB machine): `deploy/kind/up.sh --deploy --from-host` created cluster, ingress, CNPG,
  secrets; its Maven step failed on `services/core-service` (bug 3, other lane mid-edit), so images were built from the
  existing jars (`build-images.sh --from-host --no-package --skip-web-build --kind-load`, built 02:40, before the
  hardening edits), then `helm upgrade --install` (`--wait`, OK) and `deploy/kind/seed-users.sh`.
  **`deploy/kind/smoke.sh core game athlete` -> `SMOKE PASSED`**, all three services Ready and `/api/<svc>/q/health/ready`
  UP, core included: issuer, `/internal` 403, tokens, superadmin `/api/core/me`, `/platform/tenants` 200.
  `E2E journey on kind`: steps 1-2 reached, then the same blocker; additionally the Admin API is not reachable through the
  ingress (master realm answers 403): the suite now takes `E2E_KEYCLOAK_ADMIN_URL` (port-forward svc/keycloak) and
  `E2E_MAILHOG_URL`. Cluster deleted with `down.sh` afterwards. Core/game/athlete pods restarted 3x at install
  (Flyway could not reach `hoops-db-rw` before CNPG was ready); they converge by themselves.
- Flutter: `flutter analyze integration_test` clean; `tool/web_smoke.sh --compile-only` (`flutter build web --target=integration_test/journey_smoke_test.dart --dart-define=HOOPS_MOCK_API=true`) OK
  (60 s). **`flutter drive` did NOT run**: no chromedriver on the machine and the download of Google's
  chrome-for-testing chromedriver was denied by the sandbox. Chrome is 156.0.8078.74; install chromedriver 156.x and run
  `apps/web/tool/web_smoke.sh`. The widget interactions (keys `match-<id>`, `player-p-ana`, `action-3pt-made`,
  `score-team`, `sync-banner`, `tab-log`) were taken from the existing widget tests/mock but never executed in a browser.

### Bugs found in other lanes (not fixed, per scope)
1. **Realm: client `web` has no `sub` in its access tokens (blocker for every browser/real user).** `infra/keycloak/realm-academy.json`
   lists `defaultClientScopes: web-origins, acr, profile, roles, email` for `web` (and the same for the other clients);
   since Keycloak 25 the `sub` mapper lives in the `basic` scope. Repro: `just down && podman volume rm hoops_pgdata && just up
   && just seed-users`; log in with `apps/web/tool/keycloak_login_check.sh` (or any PKCE login), decode the access token:
   no `sub`; `GET /api/core/me` for a provisioned user (any invited admin/coach/parent) -> 404 `User is not provisioned`,
   because `CallerIdentity` falls back to `preferred_username` while `core.app_user.keycloak_sub` /
   `user_membership_index` hold the Keycloak user id. `superadmin` still works only because super admins are
   auto-registered under whatever subject arrives (its `/me` shows `"sub":"superadmin"`). Fix: add `"basic"` to
   `defaultClientScopes` of every client (at least `web`) and reset the realm; the kind chart carries the same realm via
   `scripts/sync-chart-files.sh`. A defensive fix in core is also worth considering: reject tokens without `sub` with 401
   instead of looking up `preferred_username`. The suite fails fast with this explanation, or with `E2E_FIX_REALM=1` adds
   `basic` to `web` in the running realm through the Admin API (the sandbox refused me to do that on the shared compose
   Keycloak, so it was never run).
2. **kind ingress:** `/auth/realms/master/...` is blocked (403), so the Admin API needs a port-forward; fine for
   production, documented for the suite.
3. **core-service did not compile at 02:5x** (other lane in progress, not necessarily a bug):
   `adapters/out/audit/AuditActor.java:[21,37] invalid accessor method in record AuditActor (accessor method must be public)`,
   `AuditWriter.java:[25,45]/[33,40] subject() has private access`. It broke `up.sh --deploy`'s Maven step.
4. game-service/athlete-service now expose `/q/health/ready` (smoke shows UP), so the WP16 `probes: tcp` overrides can go.

### Open points / how to finish
- Fix bug 1 (or approve `E2E_FIX_REALM=1`), reset the realm, then run `just e2e` and fix first-run assertion drift in
  steps 4-20 (iterate: the suite stops at the first failing step). Then repeat on kind (`docs/runbooks/e2e.md`) and tick
  the acceptance boxes.
- Install chromedriver and run `apps/web/tool/web_smoke.sh` (mock) once.
- CI workflow is unproven (podman-compose on the runner, nginx `host.containers.internal`).
- Unique data per run is left in the stack (tenants `e2e-*`, Keycloak users `e2e-*@hoops.local`); `just down` + volume
  removal cleans it.
- The compose stack was left running; the three service jars were stopped.
