// Hoops Academy caching service worker (hand written, no Node).
//
// Why: Flutter 3.47's generated flutter_service_worker.js caches nothing and
// unregisters itself, so a cold start without network would fail. This worker
// precaches the app shell and serves it cache-first.
//
// `tool/build_web.sh` runs `flutter build web` and then `tool/sw_manifest.dart`,
// which replaces the two placeholders below (build id = hash of the shipped
// files, manifest = every file of the build except this worker).
//
// Rules
//  - /api/**, /platform/**, /auth/**, /internal/**: never touched (network only, tokens and data stay fresh).
//  - navigations inside the scope: the cached index.html (single page app,
//    hash URLs); redirect.html is matched ignoring its OIDC query string.
//  - everything else under the scope: cache first, then network; successful
//    responses are added to the cache (covers files missing from the manifest).
//  - a new build installs next to the old one but only activates once every tab
//    of the old build is closed (or the page posts {type: 'SKIP_WAITING'}), so
//    lazily loaded `main.dart.js_N.part.js` chunks always match the running app.
'use strict';

const BUILD_ID = '__BUILD_ID__';
const PRECACHE = /*__PRECACHE_MANIFEST__*/[];

const CACHE_PREFIX = 'hoops-shell-';
const CACHE = CACHE_PREFIX + BUILD_ID;
const SCOPE = new URL(self.registration.scope);

const absolute = (path) => new URL(path, SCOPE).href;

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE).then((cache) =>
      // `reload` bypasses the HTTP cache so a fresh build never precaches stale files.
      Promise.all(
        PRECACHE.map((path) =>
          fetch(new Request(absolute(path), { cache: 'reload' })).then((response) => {
            if (!response.ok) throw new Error(`precache ${path}: HTTP ${response.status}`);
            return cache.put(absolute(path), response);
          }),
        ),
      ),
    ),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(keys.filter((k) => k.startsWith(CACHE_PREFIX) && k !== CACHE).map((k) => caches.delete(k))),
      ),
  );
});

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') self.skipWaiting();
});

// Same-origin paths that must never be served from or written to the cache:
// the REST APIs (/api, /platform), Keycloak behind the proxy (/auth) and the
// internal routes. Keep in step with infra/compose/nginx.conf and the ingress.
const NETWORK_ONLY_PREFIXES = ['/api/', '/auth/', '/platform/', '/internal/'];

function isNetworkOnly(url) {
  return NETWORK_ONLY_PREFIXES.some((prefix) => url.pathname.startsWith(prefix));
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin !== SCOPE.origin || isNetworkOnly(url) || !url.href.startsWith(SCOPE.href)) return;
  event.respondWith(respond(request, url));
});

async function respond(request, url) {
  const cache = await caches.open(CACHE);
  if (request.mode === 'navigate') {
    const isRedirectPage = url.pathname.endsWith('/redirect.html');
    const cached = isRedirectPage
      ? await cache.match(absolute('redirect.html'), { ignoreSearch: true })
      : await cache.match(absolute('index.html'));
    if (cached) return cached;
    try {
      return await fetch(request);
    } catch (e) {
      return (await cache.match(absolute('index.html'))) || Response.error();
    }
  }
  const hit = await cache.match(request);
  if (hit) return hit;
  const response = await fetch(request);
  if (response.ok && response.type === 'basic') cache.put(request, response.clone());
  return response;
}
