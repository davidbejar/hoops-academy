# WP14b - Web security follow-ups

## Brief
Flutter web follow-ups from the security review (`docs/security/review-2026-11.md`: F-03, F-07, F-08, F-09, F-10, F-19,
F-20) and the apps/web actions of the WP17 handover. Owner: `apps/web/**`; only the CSP lines of the nginx configs.
Deliverables, tests first:
1. Offline-safe sign-out (F-03): clear OIDC session, selected tenant, request context and the Drift DB (pending events
   included, with a localized es/en/id confirmation when events are unsynced) before the Keycloak end-session redirect;
   offline the local sign-out still completes and the end-session is skipped.
2. Drop `offline_access`; refresh must keep working within the Keycloak SSO idle timeout (4 h); document the trade-off.
3. No CDN: `--no-web-resources-cdn`, bundled fonts, canvaskit local, gstatic removed from both CSPs, inline-script hashes
   re-checked, Dart test that ties `web/index.html` / `redirect.html` hashes to the nginx configs.
4. Pin the `sqlite3.wasm` sha256 (fetch script verifies; test checks the committed binary).
5. Service worker: "new version available - reload" prompt through the existing `SKIP_WAITING` path, behind an interface.
6. Cheap remaining Low/Info findings.

## Handover

### Built
- **Sign-out (F-03, F-07)**: `lib/app/sign_out.dart` (`signOut`, `confirmAndSignOut`). Order: selected tenant cleared
  (pref + notifier), `RequestContext.tenantId = null`, `MatchStore.wipe()` (every table + device id; new
  `unsyncedTotal()` counts all users), then `AuthService.logout(endSession: online)`. `OidcAuthService.logout` forgets the
  user locally first (after a best-effort refresh-token revocation with a 3 s timeout, only when `endSession`), then
  navigates to the end-session URL it builds itself (`id_token_hint`, `client_id`, `post_logout_redirect_uri`) through
  `end_session_redirect*.dart`. So a dead Keycloak or no network cannot leave tokens in localStorage. If unsynced events
  exist, an `AlertDialog` (`signout-warning`, es/en/id strings `signOutUnsyncedTitle/Body/Anyway`) asks first; Cancel changes
  nothing. Used by the profile, splash-error and no-access screens.
- **Scopes (F-08)**: default `openid,profile,email` (`offline_access` removed from `AppConfig` and README).
- **No CDN (F-09)**: `tool/build_web.sh` runs `flutter build web --release --no-web-resources-cdn`; the generated build
  config has `useLocalCanvasKit:true`, Roboto is `assets/fonts/fallback/Roboto-Regular.ttf`, Material/Cupertino icons are
  bundled. `web/flutter_bootstrap.js` passes `fontFallbackBaseUrl: 'assets/fonts/'`. gstatic removed from
  `infra/compose/nginx/web-headers.conf` and `deploy/containers/web-nginx.conf` (3 CSPs: server, index location); CSP is now
  `script-src 'self' 'wasm-unsafe-eval' 'sha256-xv+z...'`, `font-src 'self' data:`, `connect-src 'self'`. The Helm web
  chart has no CSP of its own (it runs the web-nginx image), nothing to change there. `scripts/csp-hashes.py --check`
  reports all 3 inline hashes present (hashes unchanged: index.html / redirect.html were not edited).
- **sqlite3.wasm (F-10)**: `tool/fetch_web_db_assets.sh` pins `SQLITE3_WASM_VERSION=3.8.0` and `SQLITE3_WASM_SHA256`
  (efd308be...), downloads to a temp file, compares, then moves it in. A fresh download of the release matched the committed
  file.
- **Update prompt**: `lib/core/pwa/update_channel*.dart` (`UpdateChannel` interface; web implementation over
  `navigator.serviceWorker`: waiting worker / `updatefound`+`installed` while a controller exists, hourly `reg.update()`;
  `activate()` posts `{type:'SKIP_WAITING'}`, `controllerchange` reloads once), `update_providers.dart`, banner in
  `AppShell` (`update-banner`, `update-reload`, strings `updateAvailable/updateReload`).
- **Cheap findings**: F-19 `sw.js` network-only prefixes are now `['/api/','/auth/','/platform/','/internal/']`
  (`/platform/**` GETs were previously cacheable cache-first - a real leak of super_admin data into the cache);
  F-20 `build_web.sh` refuses `HOOPS_MOCK_API=true` and a non-https issuer (override for the local stack:
  `HOOPS_ALLOW_HTTP_ISSUER=1`); `sw_manifest.dart` build id was printed negative (signed 64-bit), fixed with `BigInt`.
- New dependencies: `web` (direct, was transitive), `crypto` (dev).

### Tests (written first, red confirmed)
`test/app/sign_out_test.dart` (7: wipe order, offline skip, warn/cancel, confirm, es/en/id), `test/app/update_prompt_test.dart`
(2), `test/features/match/data/match_store_wipe_test.dart` (1), `test/core/app_config_test.dart` (1),
`test/web/csp_hashes_test.dart` (7: hashes for 2 SPA + 2 redirect CSPs, no third-party host, no CDN in web/),
`test/web/sqlite3_wasm_test.dart` (4), `test/web/service_worker_test.dart` (3), `test/web/build_guard_test.dart` (5).

### Verified
- `flutter analyze`: no issues. `flutter test`: **477 passed, 0 failed**.
- `HOOPS_ALLOW_HTTP_ISSUER=1 tool/build_web.sh`: `Built build/web`, `sw.js: build 7b88a07dacd5359a, 193 files precached`.
- grep of `build/web` for `gstatic`: only the engine's *dead default constants* remain (`https://www.gstatic.com/flutter-canvaskit`
  in `flutter.js` / `flutter_bootstrap.js` behind `useLocalCanvasKit`, `https://fonts.gstatic.com/s/` in `main.dart.js`
  as default of `fontFallbackBaseUrl`, overridden in our bootstrap). No HTML, manifest or sw reference.
- Temporary `nginxinc/nginx-unprivileged` container (port 18080) with the real `infra/compose/nginx/web-headers.conf` /
  `redirect-headers.conf` and `build/web`, headless Chrome `--dump-dom` + `--enable-logging --v=1`: the DOM shows
  `flt-renderer="canvaskit"` and the Flutter viewport, i.e. the app boots under the strict CSP. Server log: canvaskit.js/wasm
  (`/canvaskit/chromium/`), `Roboto-Regular.ttf`, `MaterialIcons-Regular.otf`, CupertinoIcons, all `main.dart.js_N.part.js`
  were served by nginx with 200; no request to fonts.gstatic.com / www.gstatic.com from the page (the only gstatic line in
  Chrome's verbose log is Chrome's own OHTTP key fetch). The only CSP violation: `connect-src 'self'` blocked the OIDC
  discovery fetch to `http://localhost:8080/auth/...` - expected because the test origin was :18080 and not the compose
  origin :8080 (same-origin there). Container stopped afterwards.
- Not run: real Keycloak end-session round trip and the airplane-mode manual check (no chromedriver/Node here).

### Decisions / trade-offs
- **No `offline_access`**: the refresh token is now a normal SSO-session one. The Keycloak SSO idle timeout is 4 h, so a
  match is safe as long as the app refreshes within it (access tokens refresh every ~5 min, `refreshBefore` 60 s, plus the
  401 interceptor); a device that stays offline > 4 h loses its session and must sign in again once online, but the unsynced
  events stay in the DB (expiry does not wipe) and sync afterwards. Long matches only need the app open or any request in
  the 4 h window; offline scoring itself needs no token until the batch is sent.
- Offline sign-out skips the end-session call rather than queueing it (a queued redirect would need the id token, which
  is exactly what must not stay on the device). The SSO cookie at Keycloak expires by itself.
- Sign-out discards unsynced events after an explicit warning (shared-device privacy over data retention).
- The nginx CSP files outside apps/web were edited only on the CSP lines/comments.

### Open points
See `docs/wp/FOLLOW-UPS.md` (F-07 per-tenant/person scoping + wipe on `sub` change, realm refresh-token rotation, Noto
subset, security review statuses to update). Note the review document still lists F-03, F-09, F-10, F-19, F-20 as Open.
