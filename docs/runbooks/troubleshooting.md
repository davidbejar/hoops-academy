# Troubleshooting

Each entry: symptom, cause, fix. Entries come from the WP handovers and runbooks; the ones I could not trace to a run are
marked (unverified). Kind-specific problems are in `kind.md`, stack basics in `local-stack.md`, e2e in `e2e.md`.

## Podman socket and Testcontainers
- **Symptom:** `Could not find a valid Docker environment`, or `Cannot connect to Podman`, or compose fails at once.
- **Cause:** the Podman machine is stopped, the shell did not load `scripts/env.sh`, or the socket path changed after a
  machine re-init. `env.sh` exports `DOCKER_HOST` (machine socket), `TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock`
  and `TESTCONTAINERS_HOST_OVERRIDE=localhost`.
- **Fix:** `podman machine start`, then `source scripts/env.sh` in the same shell, then `just doctor`.
  If `env.sh` prints "podman machine socket not found", the machine is not running.
- `host.docker.internal` does not exist under Podman; containers reach the host as `host.containers.internal` (nginx
  upstreams use it).

## Ryuk (Testcontainers reaper)
- **Symptom:** tests hang or fail starting the `ryuk` container; leftover containers after a crash.
- **Cause:** Ryuk needs a privileged container. `env.sh` sets `TESTCONTAINERS_RYUK_DISABLED=true` on a rootless machine and
  `TESTCONTAINERS_RYUK_PRIVILEGED=true` on a rootful one.
- **Fix:** run through `source scripts/env.sh`. With Ryuk disabled, containers are removed by JVM shutdown hooks; after a
  hard kill run `podman ps -a` and remove strays. A rootful machine for kind: see `kind.md` ("Rootless vs rootful").

## Realm changes are not applied (re-import)
- **Symptom:** a change in `infra/keycloak/realm-academy.json` (clients, scopes, redirect URIs, password policy) has no
  effect; or login still fails after pulling WP17.
- **Cause:** Keycloak imports the realm only when it does not exist yet (import = ignore existing).
- **Fix (compose, destroys all local data):** `just down && podman volume rm hoops_pgdata && just up && just seed-users`.
  Same for changed DB init scripts or role passwords. **kind:** `kubectl -n hoops delete cluster keycloak-db` and let
  Helm/Tilt recreate it; run `scripts/sync-chart-files.sh` first so the chart carries the new realm.

## 401 on `/api/**`, or 404 "User is not provisioned", for a real user (token without `sub`)
- **Symptom:** every call of a signed-in user returns 401 Problem, or `GET /api/core/me` returns 404 although the person was
  invited. Decoding the access token shows no `sub`.
- **Cause:** since Keycloak 25 the `sub` mapper is in the `basic` client scope. Realms imported before WP17 lack `basic` in
  `defaultClientScopes`. Core then identified callers by `preferred_username` (bug F-21). Now `CallerSubject` rejects a JWT
  without `sub` with 401 (`hoops.security.require-sub` is false only in `%test`).
- **Fix:** re-import the realm (previous entry); the current JSON has `basic` on web and the three service clients. Check:
  `apps/web/tool/keycloak_login_check.sh` decodes the token, or decode the access token and look for `sub`.
- A 401 right after a long idle: the access token lives 5 minutes; the web app refreshes once and otherwise sends the user to
  login. Offline queued plays are kept (`pausedForAuth`).

## Keycloak issuer mismatch
- **Symptom:** services reject every token (401) or fail at startup discovering the issuer; the browser login loops.
- **Cause:** the `iss` claim must equal the configured issuer exactly. Compose: `http://localhost:8080/auth/realms/academy`
  (`OIDC_AUTH_SERVER_URL`). kind: `http://localhost:8090/auth/realms/academy` (Keycloak `KC_HOSTNAME`; pods use the
  back-channel `http://keycloak:8080/auth` with `KC_HOSTNAME_BACKCHANNEL_DYNAMIC=true` so the issuer stays public).
  Opening the app at `127.0.0.1` instead of `localhost`, or on 8090 against compose settings, changes the issuer.
- **Fix:** use `localhost` and the right port. Check: `curl -s localhost:8080/auth/realms/academy/.well-known/openid-configuration | jq -r .issuer`.
  Scripts that call the service-account token endpoint must use the same base URL.

## `events:batch` returns 404 or is rewritten
- **Symptom:** `POST /api/game/matches/{id}/events:batch` fails with 404/400 through the proxy but works against the service
  on :8082.
- **Cause:** the path contains a colon (a Google-style custom method). A proxy rule that rewrites the URI or percent-decodes
  and re-encodes it changes it. nginx (compose) and the Helm ingress forward it unchanged, both `events:batch` and
  `events%3Abatch`; the chart has an assertion for the regex Ingress without rewrite (WP2c, WP17). The same applies to
  `:copy`, `:archive`, `:unarchive` on athlete paths.
- **Fix:** do not add `rewrite-target` to the game/athlete Ingresses; keep the regex Ingress. Write test requests with the
  literal colon. Rate limits answer 429 (`events` zone: 120 r/min, burst 60), not 404.

## Flutter dev server (`flutter run`, port 5173): CORS, redirect URI
- **Symptom:** login redirect error "Invalid parameter: redirect_uri", or browser CORS errors on `/api/*` and `/auth/*`.
- **Cause:** a dev server on :5173 is a different origin from nginx on :8080. The realm client `web` must allow
  `http://localhost:5173/*` (redirect + post-logout) and web origin `http://localhost:5173`; the services allow CORS from
  `hoops.cors.origins` (`HOOPS_CORS_ORIGINS`, default `http://localhost:5173`).
- **Fix:** re-import the realm (entries above) and start with
  `flutter run -d chrome --web-port 5173 --dart-define=HOOPS_API_BASE=http://localhost:8080` (`apps/web/README.md`). Another
  port needs both a realm and a `HOOPS_CORS_ORIGINS` change. Serving the build through nginx avoids CORS entirely. Demo mode
  without any backend: `--dart-define=HOOPS_MOCK_API=true` (no athlete or platform screens).

## Other frequent problems
| Symptom | Cause / fix |
|---|---|
| nginx 502 on `/api/*` | the host service is not running on 8081/8082/8083 (`just services-up` or `quarkus:dev`) |
| nginx 502 on `/auth/*` right after `just up` changed Keycloak | the Keycloak container was recreated (new IP) and nginx still uses the old one: `podman restart hoops-nginx` |
| Keycloak shows its stock login page, not Hoops Academy's | the realm predates the `hoops` theme: `just seed-users` sets `loginTheme` (ADR-0022) |
| After login the tab says "You can now close this tab" | the app was started without `original_uri` (fixed in ADR-0022); hard-reload the app to get the current build |
| `required variable ... set in .env` | copy `.env.example` to `.env` and fill it; `DEV_USER_PASSWORD` needs 12+ characters |
| Role password changed in `.env` has no effect | init scripts run only on an empty volume; reset it or `ALTER ROLE` |
| Admin console / master realm returns 403 | by design; set `HOOPS_EXPOSE_KC_ADMIN=true` and restart (needed by the e2e suite) |
| game/athlete answer 503 `UPSTREAM_UNAVAILABLE` | core-service is down: their tenant filter calls core `/internal/authz` on every request |
| New member / admin cannot sign in | no e-mail is sent any more (ADR-0024): they sign in with the temporary password shown once at creation; lost or never received (admins created before WP24) → `POST .../temporary-password` while PENDING (`docs/runbooks/onboard-tenant.md`); an existing Keycloak account is reused and keeps its own password |
| MailHog misbehaves on Apple Silicon | it is amd64 (emulated); swap to `axllent/mailpit`, same ports (unverified on this change) |
| Cached app stays old after a deploy | by design, the service worker keeps the old build until all tabs close; `index.html`/`sw.js` are served `no-cache` |
| Chart test fails on "drift" | run `scripts/sync-chart-files.sh`, review, `deploy/helm/tests/run.sh --update` |
| `flutter drive` / web smoke cannot start | chromedriver matching Chrome is not installed (open item) |
