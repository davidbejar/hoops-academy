# Hoops Academy web app (Flutter Web PWA)

Mobile-first (360 px) Flutter Web shell: Keycloak login (OIDC, PKCE), tenant switcher, role-aware navigation,
es / en / id, offline banner, installable PWA, plus the feature screens of WP12-WP14 (admin & roster, live match
with offline queue, training, health, profile, super-admin console). Decisions: `docs/adr/0004-flutter-web-pwa.md`,
`docs/adr/0005-keycloak-authentication-only.md`, `docs/adr/0018-web-offline-shell-service-worker.md`,
`docs/adr/0019-web-session-and-sign-out.md`.

Requirements: Flutter 3.47+ (Dart 3.13), Chrome. No Node.

## Run

### Demo mode (no backend, no Keycloak)
For UI work without the backend, `/api/core/**` and `/api/game/**` can be served from in-memory fixtures (the
real services exist; see "Against the local stack"). "Sign in" works instantly and you get two academies
(ADMIN+COACH with a logo, and PARENT):

```bash
cd apps/web
flutter pub get
flutter run -d chrome --web-port 5173 --dart-define=HOOPS_MOCK_API=true
```

The mock goes through the real Dio stack and generated clients (bearer required, `X-Tenant-Id` enforced on
tenant paths), so it exercises the same code as the real API. Since WP12 it also serves the whole admin / roster
surface of core-service from memory (`lib/core/mock/mock_core_api.dart`: profile/settings/logo, members, guardian
links, seasons + rollover, age categories, teams + staff + roster + eligibility with play-up, players,
approvals, eligibility cases) and `test/core/mock_core_api_test.dart` runs the real repositories against it.
The demo user is ADMIN+COACH in "Academia Demo" (the highest role wins: admin navigation). To try the other
role variants: `--dart-define=HOOPS_MOCK_ROLES=COACH` (own team = Mini A), `ASSISTANT_COACH`, `PARENT`.

### Against the local stack (Keycloak + nginx)
```bash
source scripts/env.sh && just up && just seed-users     # repo root
cd apps/web
flutter run -d chrome --web-port 5173 \
  --dart-define=HOOPS_API_BASE=http://localhost:8080      # `/api/*` goes through nginx
```
Defaults: issuer `http://localhost:8080/auth/realms/academy`, client `web`, scopes
`openid profile email`. Override with `--dart-define=HOOPS_OIDC_ISSUER=...`,
`HOOPS_OIDC_CLIENT_ID=...`, `HOOPS_OIDC_SCOPES=a,b,c`, `HOOPS_API_BASE=...`.
Seeded users, signed in with their e-mail address (password = `DEV_USER_PASSWORD` in the repo `.env`):
`superadmin@hoops-academy.com`, `admin1@hoops-academy.com`, `coach1@hoops-academy.com`,
`assistant1@hoops-academy.com`, `parent1@hoops-academy.com`, `player1@hoops-academy.com`.

**Origins / CORS.** Since WP17 the realm's client `web` allows `http://localhost:8080/*` and
`http://localhost:5173/*` as redirect and post-logout URIs and both as web origins, and the services answer CORS
for `http://localhost:5173` (`hoops.cors.origins`, env `HOOPS_CORS_ORIGINS`; no credentials). The realm is imported
only on an empty volume: after pulling the WP17 realm run `just down && podman volume rm hoops_pgdata && just up &&
just seed-users`. Serving the build through nginx on :8080 avoids cross-origin calls altogether.

The three services must be running for the real flow (`e2e/bin/services-up.sh` or `quarkus:dev` per service);
otherwise nginx answers 502 and the shell shows a localized error with a retry button.

The URL strategy is the default hash strategy (`/#/matches`), so the static host needs no rewrite rules.
OIDC uses `navigationMode: samePage` (full-page redirect, no popup) and `web/redirect.html` from the `oidc`
package (re-copy it when upgrading the package). `redirect.html` returns the tab to the app only because `login()`
passes the current URL as `originalUri`; sign-out returns to the app's base URL, not to `redirect.html` (ADR-0022).
Keycloak's login pages use the branded `hoops` theme (`infra/keycloak/themes/hoops`).

### Release build
```bash
tool/build_web.sh [--dart-define=HOOPS_API_BASE=...]   # flutter build web --release + stamps web/sw.js (see below)
HOOPS_ALLOW_HTTP_ISSUER=1 tool/build_web.sh             # local stack only: allows the http://localhost issuer
```
The script refuses `HOOPS_MOCK_API=true` and a non-https `HOOPS_OIDC_ISSUER` (finding F-20) unless
`HOOPS_ALLOW_HTTP_ISSUER=1`, and builds with `--no-web-resources-cdn` (CanvasKit, Roboto fallback font and icons are
bundled; no request to gstatic, finding F-09). Debug `flutter run` bundles no fonts, so it still loads Roboto (and Noto
for other scripts) from Google Fonts and needs network (ADR-0018 §4). The OIDC scopes are `openid profile email` (no `offline_access`,
finding F-08); sign-out forgets the tokens locally first and wipes the offline match database (ADR-0019).
Output in `build/web` (our caching `sw.js`, manifest, deferred `main.dart.js_N.part.js` per feature module).
Standard CanvasKit renderer; no COOP/COEP, no wasm. `flutter build web` alone also works but then `build/web/sw.js`
still contains its `__BUILD_ID__` placeholder and would not cache anything useful: always release with the script.

### Offline cold start: caching service worker (WP14)
Flutter 3.47 generates a `flutter_service_worker.js` that caches nothing and unregisters itself, so reopening the
installed PWA without network failed. We ship our own worker:

| File | Role |
|---|---|
| `web/sw.js` | hand-written worker: precache of the app shell, cache-first, network-only for `/api/**`, `/auth/**`, `/platform/**` and `/internal/**` (`NETWORK_ONLY_PREFIXES`, finding F-19) |
| `web/flutter_bootstrap.js` | custom bootstrap **without** `serviceWorkerSettings`, so Flutter never registers its own worker (two workers cannot share a scope; they would replace each other on every load) |
| `web/index.html` | registers `sw.js` on `load` |
| `tool/sw_manifest.dart` | after the build, replaces `__BUILD_ID__` (hash of every shipped file) and `/*__PRECACHE_MANIFEST__*/[]` (the file list) in `build/web/sw.js`; unit tested in `test/tool/sw_manifest_test.dart` |
| `tool/build_web.sh` | guards (no mock API, https issuer or `HOOPS_ALLOW_HTTP_ISSUER=1`), `flutter build web --release --no-web-resources-cdn` then `dart run tool/sw_manifest.dart build/web` |

Precached: `index.html`, `main.dart.js` + every `main.dart.js_N.part.js`, `flutter.js`, `flutter_bootstrap.js`,
`manifest.json`, icons, `redirect.html`, `sqlite3.wasm`, `drift_worker.js`, `assets/**` and the CanvasKit files
(not `skwasm*`, `wimp*`, `webparagraph/`, `*.map`, `*.symbols`; a file that is not listed is still cached the first
time it is fetched). About 22 MB, downloaded once per build.
Rules: navigations inside the scope get the cached `index.html` (the app uses hash URLs); `redirect.html` is matched
ignoring its OIDC `?code=...` query; `/api/**`, `/auth/**`, `/platform/**`, `/internal/**`, non-GET and cross-origin
requests are never touched.
A new build installs next to the old one and activates when all tabs of the old build are closed (so lazily loaded
parts always match the running `main.dart.js`); the app shows an "update available, reload" banner
(`lib/core/pwa/update_channel*.dart`, WP14b) that posts `{type: 'SKIP_WAITING'}` and reloads once. The `flutter_service_worker.js` that Flutter still
emits is excluded from the precache and never registered; a stale page that registered it in the past replaces
our worker once and our `register('sw.js')` takes the scope back on the next load.

**Manual check (airplane mode):** `tool/build_web.sh`, serve `build/web` over `http://localhost` (any static
server), open it once online and wait for DevTools -> Application -> Service Workers to show `sw.js` *activated*
and Cache Storage -> `hoops-shell-<build id>` to hold the files. Reload once (the first page load is not
controlled). Tick *Offline* (or turn Wi-Fi off) and hard-reload: the app must start (login screen or, when signed
in, the last view with the offline banner); `/api` calls fail with the network error state, the match scorer keeps
working from IndexedDB. Rebuild and repeat to see the new cache version replace the old one after closing the tabs.

## Layout
```
lib/
  app/           router (go_router + guard), theme tokens, shell scaffold, feature_modules.dart, auth/tenant screens
  core/          auth (oidc port + mock), http (Dio, interceptors, mock adapter), errors (AppError),
                 session (guard as a pure function), navigation (role -> destinations), l10n, tenancy, ui
  features/<name>/{data,domain,application,presentation}
  l10n/          app_es.arb (template), app_en.arb, app_id.arb, gen/ (generated, committed)
packages/        GENERATED API clients hoops_{core,game,athlete}_api (do not edit; path dependencies)
```

### Adding a feature (WP12-WP14)
1. Replace the placeholder screen of your destination in `lib/features/<name>/presentation/` (keep the file
   deferred-imported in `lib/app/feature_modules.dart`); put repositories wrapping the generated client in
   `data/`, providers in `application/`.
2. New route inside a module: add a `GoRoute` in `lib/app/router.dart` under the `ShellRoute`; role access is
   decided by `destinationsFor` / `redirectFor` (`lib/core/navigation`, `lib/core/session`).
3. Get a configured client with `HoopsCoreApi(dio: ref.watch(dioProvider), interceptors: const []).getXApi()`
   (see `features/me/data/me_repository.dart`). Pass the tenant id the generated method asks for, or rely on
   the interceptor. Catch `DioException` and use `AppError.of(e)`; show `AppErrorView`.
4. Every string in all three ARBs (`flutter gen-l10n`; `test/l10n` enforces parity).
5. Tests: provider/unit, widget (loading/empty/error/populated/role), golden at 360x780 and 1024x768.

### Admin & roster module (WP12)
Routes (all under the shell; the destination decides who may enter, `Capabilities` decides which buttons show):
`/admin` (hub) -> `/admin/profile` (academy + logo), `/admin/members[/:personId]` (invite, roles, deactivate,
guardian links), `/admin/seasons[/:id/rollover]`, `/admin/age-categories`; `/teams[/:teamId]`, `/teams/cases`
(eligibility cases); `/players`, `/players/new`, `/players/requests` (approvals inbox / "my requests"),
`/players/:playerId`. Sub-pages are `ModulePage`s of a `FeatureModule` (own deferred library each).
Shared building blocks for later modules: `core/session/capabilities.dart`, `core/ui/{async_body,actions,
form_dialog,page_scaffold,labels}.dart`, `core/api/api.dart` (client + `Date`), `features/roster/presentation/
eligibility_widgets.dart` (eligibility badge / panel, play-up badge).

### Training, health, profile and platform (WP14)
Routes: `/training` (week calendar; staff create ad-hoc sessions) -> `session/:id` (detail, attendance sheet for
team staff), `schedules`, `absences`, `plans` + `plans/:planId` (library: own plans / templates, copy-on-use,
editor), `assignments[/:id]` (staff progress); `/players/:id/health` (injuries, growth, tests),
`/players/tests` (test types), `/players/norms` (norm admin); `/me` (PLAYER) and `/my-players` (PARENT,
child switcher) share `features/profile/presentation/player_hub.dart`; `/platform[/:tenantId]` (super_admin
console, also reachable from Profile when the user has memberships). Charts (`fl_chart`) follow the dataviz
tokens in `core/ui/chart_tokens.dart`. Test doubles: `test/support/fake_athlete.dart` (`FakeAthlete`),
`fake_platform.dart` (`FakePlatform`), both plugged into `Harness`/`pumpAs`. The demo mock (`HOOPS_MOCK_API`) does
not serve `/api/athlete/*` or `/platform/*` yet (those screens show the error state in demo mode).

### Live match & offline queue (WP13)
Routes (Matches module, all roles): `/matches` (list by team, status chips, "N unsynced" banner, new match for
staff), `/matches/:matchId` (live view: score / period / local game clock, court panel, action sheet, substitutions,
opponent points, timeouts, undo = VOID, event log with per-event sync state, live box score; FINISHED opens on the
box score with "copy result"), `/matches/:matchId/setup` (match roster from the team roster: players, starters,
jerseys; staff only), `/matches/stats/:playerId` (season statistics; linked from the player detail, **WP14 links Me /
My players here**). PARENT gets the restricted mode (linked players only, no clock / period / opponent / roster,
VOID of own events only); other non-staff roles are read-only.

Code: `lib/features/match/` - `domain/` (events = contract JSON, `projector/` = Dart mirror of the server projection,
`scoring_rights.dart`), `data/` (Drift store `local/`, repositories over `hoops_game_api`, `mock_game_api.dart`),
`application/` (`live_match_controller.dart`, `match_providers.dart`, `sync/` worker + backoff + status,
`game_clock.dart`), `presentation/`.

Offline: every event is written to Drift first (`pending_events`, UUIDv7 id, per-match `clientSeq` from
`client_sequences`, `device` id generated once) and synced in the background (`events:batch` in clientSeq order,
<= 500 per batch, per-event ACCEPTED / DUPLICATE / REJECTED, feed `events?after=` merged into `synced_events`).
Triggers: connectivity regained, app resumed, sign-in completed, every 15 s while a match screen is open, retry
with exponential backoff (1 s -> 60 s, jitter). A 401 (after the Dio layer's refresh failed) pauses the queue until the
next sign-in; REJECTED events stay visible with their reason until the user discards them. Matches and rosters
are cached when loaded online, so a match can be scored with the network off.

**Offline storage assets (web).** Drift runs on `web/sqlite3.wasm` + `web/drift_worker.js` (both committed).
No Node: `tool/fetch_web_db_assets.sh` downloads `sqlite3.wasm` from the sqlite3.dart GitHub release matching the
resolved `sqlite3` version and compiles `tool/drift_worker.dart` with `dart compile js`. Re-run it after upgrading
drift / sqlite3. Storage choice (`data/local/connection/web_connection.dart`): `opfsLocks` only if the page is
cross-origin isolated (it is not: no COOP/COEP, ADR-0004), otherwise IndexedDB in the page (`unsafeIndexedDb`, no
shared worker), else in-memory. Tests use the native in-memory executor (`NativeDatabase.memory()`).

Projection vectors: `tool/sync_vectors.sh` copies `libs/contracts/vectors/*.json` to `test/fixtures/vectors/`;
`test/features/match/domain/projector_vectors_test.dart` fails if the copies differ. After changing the Drift schema
run `dart run build_runner build` (generates `match_database.g.dart`, committed).

Demo: `flutter run -d chrome --web-port 5173 --dart-define=HOOPS_MOCK_API=true --dart-define=HOOPS_MOCK_ROLES=COACH`
(team Mini A: a LIVE match vs Tigres, a SCHEDULED one to set up, a FINISHED one with a box score) or
`HOOPS_MOCK_ROLES=PARENT` (linked to Ana Ruiz: family mode). Switch the browser offline in DevTools to watch the
queue grow and drain.

## Generated API clients
```bash
just gen-api            # = scripts/gen-api.sh, writes apps/web/packages/{core,game,athlete}
cd apps/web && flutter pub get
```
Requires `openapi-generator` 7.26 on PATH. The clients are not under `lib/` because a package nested inside
the app's `lib/` makes the package config invalid and the compiler fails ("language version override has to be
the same"). `packages/**` is excluded from `analysis_options.yaml`.

## Tests
```bash
flutter analyze
flutter test                                   # unit + widget + l10n parity + goldens
flutter test --update-goldens test/golden      # after an intentional UI change; review the PNGs
```
Goldens use the test font (blocks instead of glyphs) so they are stable across machines; they check layout. They are
recorded on macOS; Linux renders them a few % differently, so CI runs with `GOLDEN_DIFF_TOLERANCE=0.06`
(`test/flutter_test_config.dart`). Locally the comparison is exact.

### Login smoke (integration_test, Chrome)
Flutter cannot run `integration_test` on web with `flutter test`; it needs `flutter drive` and a
`chromedriver` matching your Chrome (https://googlechromelabs.github.io/chrome-for-testing/).
```bash
chromedriver --port=4444 &
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/login_smoke_test.dart -d web-server \
  --dart-define=HOOPS_MOCK_API=true            # full UI flow with the in-memory API
```
Without `HOOPS_MOCK_API` the test only asserts boot + login screen: the Keycloak form is a different page and
origin, which an in-page integration test cannot fill in.

**Credential check against the real Keycloak (scripted PKCE, user `coach1@hoops-academy.com`):**
```bash
source scripts/env.sh && just up && just seed-users
HOOPS_E2E_PASSWORD="$DEV_USER_PASSWORD" apps/web/tool/keycloak_login_check.sh   # password env var; defaults to .env
```
It performs discovery, the login form, the code+S256 exchange (`web` client) and a
refresh-token grant, and prints only non-secret claims.

**Browser round trip (real flow, automated):** with the stack, the services and the app on :5173 running
(`./start.sh`), and a chromedriver matching Chrome on PATH:
```bash
python3 -I apps/web/tool/browser_login_check.py --user player1@hoops-academy.com   # headless Chrome; --headed to watch it
```
It taps *Sign in*, requires the branded `hoops` Keycloak page, fills the form (password from `.env`, never printed),
requires the tab to come back to the app signed in (not stranded on `redirect.html`), then taps *Sign out* when the
landing screen has it and requires the app's sign-in screen again. `player1@hoops-academy.com` has a sign-out button on
its landing screen; `coach1@hoops-academy.com` checks the login half only.

### PWA installability (manual Lighthouse check)
Serve `build/web` over `http://localhost` (any static server; localhost counts as secure), open DevTools ->
Lighthouse -> category *Progressive Web App* (or Application -> Manifest: no errors, "Installable"). Expected:
manifest (name "Hoops Academy", 192/512 + maskable icons), service worker registered, theme colour set.
