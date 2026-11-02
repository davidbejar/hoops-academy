# ADR-0018: Web offline shell — own caching service worker, no CDN, explicit update prompt

- Status: Accepted (records decisions taken in WP13, WP14 and WP14b)
- Date: 2026-11-02
- Amends: ADR-0004 (the plan's `flutter build web --pwa-strategy=offline-first`)

## Context
The match scorer must work with the network off (SPEC: "progressive loading application"; PLAN §1.5). WP13 found that
Flutter 3.47 emits a self-unregistering `flutter_service_worker.js` that caches nothing even with
`--pwa-strategy=offline-first` (the flag is deprecated). Offline scoring therefore worked only while the tab stayed open:
reopening the installed PWA without network failed. The default build also loaded CanvasKit and fallback fonts from
Google's CDN (security finding F-09), which both broke an offline cold start and forced gstatic into the CSP.

## Decision
1. **Own worker** `apps/web/web/sw.js`, registered from `index.html`; a custom `web/flutter_bootstrap.js` without
   `serviceWorkerSettings` so Flutter never registers its own worker in the same scope.
2. **Precache per build**: `tool/sw_manifest.dart` stamps a build id (hash of the shipped files) and the file list into
   `build/web/sw.js` after `flutter build web`; `tool/build_web.sh` is the only supported release build. Cache name
   `hoops-shell-<build id>`; `activate` deletes only older `hoops-shell-*` caches.
3. **Routing rules**: navigations get the cached `index.html` (hash URLs); `redirect.html` matched ignoring its OIDC query;
   cache-first for shell assets; **network-only** for `/api/`, `/auth/`, `/platform/`, `/internal/`, non-GET and
   cross-origin requests (F-19: `/platform` GETs were cacheable before WP14b).
4. **No CDN**: `--no-web-resources-cdn`, bundled Roboto and icons, `fontFallbackBaseUrl: 'assets/fonts/'`; the CSP is
   `'self'` only (plus `wasm-unsafe-eval` and the inline-script hashes). flutter_tools bundles Roboto only in that release
   build, so `web/flutter_bootstrap.js` sets `fontFallbackBaseUrl` only when the build config has `useLocalCanvasKit` and
   is not a `dartdevc` debug build. Debug `flutter run` keeps the engine default (Google Fonts): with the override it got a
   404 for Roboto and every Noto fallback and rendered no text at all (fixed 2026-11-02, `test/web/bootstrap_fonts_test.dart`).
5. **Updates are explicit**: no `skipWaiting`/`clients.claim` on install (lazily loaded `.part.js` chunks must match
   the running `main.dart.js`); the app shows an "update available, reload" banner that posts `SKIP_WAITING` and reloads
   once on `controllerchange`.
6. Offline data itself lives in Drift on `sqlite3.wasm` over IndexedDB (no SharedWorker, no COOP/COEP, ADR-0004);
   `sqlite3.wasm` is pinned by version and sha256 (F-10).

## Consequences
- About 22 MB are downloaded once per build. Glyphs outside Roboto (CJK, emoji) render as tofu until a Noto subset is
  bundled (follow-up).
- nginx/ingress must serve `index.html`, `sw.js` and the bootstrap files with `Cache-Control: no-cache` (done in WP17).
- **Not verified in a real browser**: install/activate/airplane-mode reload, replacement of a previously registered
  Flutter worker, Lighthouse. Evidence is unit tests (`test/tool/sw_manifest_test.dart`, `test/web/service_worker_test.dart`,
  `test/web/csp_hashes_test.dart`), a mocked-globals run of `sw.js` and a headless-Chrome boot under the strict CSP.
- Production ingress prefixes must match `NETWORK_ONLY_PREFIXES` if they ever differ from the local layout.

## Alternatives considered
- Flutter's generated worker / `--pwa-strategy` — rejected: caches nothing in 3.47.
- Workbox — rejected: needs Node tooling (SPEC: no Node).
- nginx-only caching headers — rejected: cannot serve the shell without network.
