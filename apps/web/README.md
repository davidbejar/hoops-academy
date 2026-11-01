# Hoops Academy web app (Flutter Web PWA)

Mobile-first (360 px) Flutter Web shell: Keycloak login (OIDC, PKCE), tenant switcher, role-aware navigation,
es / en / id, offline banner, installable PWA. Decisions: `docs/adr/0004-flutter-web-pwa.md`,
`docs/adr/0005-keycloak-authentication-only.md`. Feature screens arrive with WP12-WP14; the shell, guard,
HTTP stack and generated clients are real.

Requirements: Flutter 3.47+ (Dart 3.13), Chrome. No Node.

## Run

### Demo mode (no backend, no Keycloak)
`core-service` does not exist yet, so `/api/core/me` and the tenant profile can be served from in-memory
fixtures. "Sign in" works instantly and you get two academies (ADMIN+COACH with a logo, and PARENT):

```bash
cd apps/web
flutter pub get
flutter run -d chrome --web-port 5173 --dart-define=HOOPS_MOCK_API=true
```

The mock goes through the real Dio stack and generated clients (bearer required, `X-Tenant-Id` enforced on
tenant paths), so it exercises the same code as the real API.

### Against the local stack (Keycloak + nginx)
```bash
source scripts/env.sh && just up && just seed-users     # repo root
cd apps/web
flutter run -d chrome --web-port 5173 \
  --dart-define=HOOPS_API_BASE=http://localhost:8080      # `/api/*` goes through nginx
```
Defaults: issuer `http://localhost:8080/auth/realms/academy`, client `web`, scopes
`openid profile email offline_access`. Override with `--dart-define=HOOPS_OIDC_ISSUER=...`,
`HOOPS_OIDC_CLIENT_ID=...`, `HOOPS_OIDC_SCOPES=a,b,c`, `HOOPS_API_BASE=...`.
Seeded users (password = `DEV_USER_PASSWORD` in the repo `.env`): `superadmin`, `admin1`, `coach1`,
`assistant1`, `parent1`, `player1`.

**CORS / redirect URI.** The realm's client `web` only allows redirect URI and web origin
`http://localhost:8080` (`infra/keycloak/realm-academy.json`). Therefore:

- the real login flow works when the build is **served from `http://localhost:8080`** (nginx), or
- when serving on `:5173`, register `http://localhost:5173/*` (redirect URI, post-logout URI) and
  `http://localhost:5173` (web origin) on the client. For a throw-away local setup, in the Keycloak admin
  console (`http://localhost:8080/auth/admin/`, realm `academy`, client `web`) add them; the permanent fix is a
  WP1 follow-up (add the dev origin to the realm JSON; realm imports only run on an empty volume).

Calls to `/api/*` from `:5173` to nginx are cross-origin too, so they also need CORS on the API/nginx side
(another lane); serving the build through nginx avoids all of it.

Until `core-service` (WP3) is up, `/api/core/me` returns 502 from nginx and the shell shows a localized
error with a retry button after login; use demo mode to see the rest.

The URL strategy is the default hash strategy (`/#/matches`), so the static host needs no rewrite rules.
OIDC uses `navigationMode: samePage` (full-page redirect, no popup) and `web/redirect.html` from the `oidc`
package (re-copy it when upgrading the package).

### Release build
```bash
flutter build web --pwa-strategy=offline-first    # standard CanvasKit renderer; no COOP/COEP, no wasm
```
Output in `build/web` (service worker, manifest, deferred `main.dart.js_N.part.js` per feature module).
`--pwa-strategy` is deprecated in Flutter 3.47 (still honoured and prints a notice).

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
Goldens use the test font (blocks instead of glyphs) so they are stable across machines; they check layout.

### Login smoke (integration_test, Chrome)
Flutter cannot run `integration_test` on web with `flutter test`; it needs `flutter drive` and a
`chromedriver` matching your Chrome (https://googlechromelabs.github.io/chrome-for-testing/).
```bash
chromedriver --port=4444 &
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/login_smoke_test.dart -d chrome \
  --dart-define=HOOPS_MOCK_API=true            # full UI flow with the in-memory API
```
Without `HOOPS_MOCK_API` the test only asserts boot + login screen: the Keycloak form is a different page and
origin, which an in-page integration test cannot fill in.

**Credential check against the real Keycloak (scripted PKCE, user `coach1`):**
```bash
source scripts/env.sh && just up && just seed-users
HOOPS_E2E_PASSWORD="$DEV_USER_PASSWORD" apps/web/tool/keycloak_login_check.sh   # password env var; defaults to .env
```
It performs discovery, the login form, the code+S256 exchange (`web` client, `offline_access` scope) and a
refresh-token grant, and prints only non-secret claims.

**Manual browser check (real flow):** serve the build on `http://localhost:8080` (or register 5173, see CORS note),
open it, press *Sign in*, log in as `coach1`, expect the redirect back to the app (`redirect.html` flashes), the
tenant switcher or home (needs WP3 for `/me`; otherwise the error screen with *Retry*), reload the page and
stay signed in, *Sign out* returns to the login screen.

### PWA installability (manual Lighthouse check)
Serve `build/web` over `http://localhost` (any static server; localhost counts as secure), open DevTools ->
Lighthouse -> category *Progressive Web App* (or Application -> Manifest: no errors, "Installable"). Expected:
manifest (name "Hoops Academy", 192/512 + maskable icons), service worker registered, theme colour set.
