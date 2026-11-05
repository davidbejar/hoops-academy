# Runbook: end-to-end journeys (WP18)

The `e2e/` Maven module drives the whole platform from the outside, through the gateway, with real Keycloak logins:
two academies, five roles, three services. It is a black box (REST Assured over HTTP, nothing internal on the
classpath); every API request and response is validated against `libs/contracts/openapi/<service>.yaml` read from
disk (`openapi-request-validator-restassured`, default strict configuration, nothing muted; ADR-0027).

`./mvnw verify` at the root does **not** run it: the module's tests are skipped unless `-De2e.baseUrl=...` or the
environment variable `E2E_BASE_URL` is set.

## Run on compose (default)
```bash
source scripts/env.sh
just e2e                      # up, seed-users, build + start the 3 services, run the suite, stop the services
# or step by step
just up && just seed-users
just services-up              # e2e/bin/services-up.sh [--no-build]; logs and pids in e2e/target/services/
./mvnw -pl e2e test -De2e.baseUrl=http://localhost:8080
just services-down
```
`services-up.sh` builds the three fast-jars once, then starts them with the secrets of `.env` (never printed) on
8081/8082/8083 and polls `/q/health/ready` of each. All three services have `quarkus-smallrye-health` since WP17
(readiness includes the database; game/athlete add an informational `core-service` check). The script waits for HTTP 200 with `"status":"UP"` from each (180 s budget).

Needs: the compose stack (Postgres, Keycloak, MailHog, nginx), `DEV_USER_PASSWORD` (the seeded `superadmin@hoops-academy.com` is the
platform super admin), `KEYCLOAK_ADMIN`/`KEYCLOAK_ADMIN_PASSWORD` and `CORE_SERVICE_CLIENT_SECRET` in `.env`.
Settings: `E2E_MAILHOG_URL` (default `http://localhost:8025`; used to check that no e-mail is sent, skipped when MailHog is unreachable),
`E2E_REDIRECT_URI` (default `<base>/redirect.html`, must match client `web`), `E2E_KEYCLOAK_ADMIN_URL` (default `<base>/auth`).

## Run on kind
```bash
source scripts/env.sh
just kind-up --deploy --from-host        # cluster, Envoy Gateway, CNPG, secrets, images, helm install (docs/runbooks/kind.md)
deploy/kind/seed-users.sh
deploy/kind/smoke.sh core game athlete   # pods, gateway, issuer, /internal 403, tokens, seeded superadmin through core
# the gateway exposes only realm `academy` (the Admin API of the master realm answers 403): port-forward Keycloak and MailHog
kubectl --context kind-hoops -n hoops port-forward svc/keycloak 18080:8080 &
kubectl --context kind-hoops -n hoops port-forward svc/mailhog 18025:8025 &
E2E_KEYCLOAK_ADMIN_URL=http://localhost:18080/auth E2E_MAILHOG_URL=http://localhost:18025 \
  ./mvnw -pl e2e test -De2e.baseUrl=http://localhost:8090
deploy/kind/ratelimit-check.sh           # optional, afterwards: burst -> 429 (limits this client for up to a minute)
just kind-down
```
On kind the services run in the cluster (`just kind-up` leaves them restarting until `hoops-db` is up); do not start
`services-up.sh`. The chart ships a MailHog pod; the no-e-mail checks are skipped when `E2E_MAILHOG_URL` is unreachable.
`http://localhost:8090` reaches the Envoy Gateway through kind's port mapping to the NodePort of Service
`envoy-gateway-system/hoops-gateway` (ADR-0031). On a cluster without that mapping, port-forward the Gateway's Envoy
Service instead: `kubectl -n envoy-gateway-system port-forward svc/hoops-gateway 8090:80` (keep `localhost:8090`, the
issuer is `http://localhost:8090/auth/realms/academy`).

## What the journey covers (ordered, `JourneyTest`)
1. super admin creates a tenant with its first admin; the response carries the admin's temporary password once
   (`no-store`), no e-mail is sent (ADR-0024);
2. the admin signs in with the temporary password and must choose their own on Keycloak's update-password page
   (`KeycloakUserTokens.firstLogin`), then logs in (scripted PKCE login of the public client `web`); season, default
   categories, team; invites a coach and a parent; the coach is made team staff;
3. admin adds a player directly (201), the coach requests one (202, PENDING), the coach cannot approve their own
   request, the admin approves; guardian link; the parent sees only the linked child;
4. coach creates a match, roster, start; coach and parent enter events (parent: linked player accepted, other player
   and `PERIOD_START` REJECTED `NOT_AUTHORIZED`); replaying the batch gives only `DUPLICATE` with the same
   `serverSeq`; box score consistent (team total = sum of player lines, parent sees only the linked line); finish;
   season stats;
5. training schedule materialises sessions; parent's planned absence shows as `expectedAbsent`; attendance;
   plan template copy-on-use (template edit 403), assignment, completion, progress;
6. injury makes the player unavailable (`availability`), body measurement, physical test result with
   `expectedBand`/`bandStatus=MATCHED`;
7. platform usage shows the counters of all three services;
8. rollover into the next season: the over-age player becomes an orphan (`CATEGORY_TOO_LOW`), the eligibility case
   is resolved (and cannot be resolved twice);
9. a second tenant: its admin gets 404 (never 403, never data) for the first tenant's team, player, match, box
   score, session, injury, also with the first tenant's id in `X-Tenant-Id`, and vice versa;
10. `/internal/**` answers 403 through the gateway, with and without a service token;
11. suspending the tenant makes every member get 404 on all services (game/athlete need up to 30 s because of
    their membership cache), `/me` drops the membership; reactivation restores it.

Steps depend on each other: after the first failure the remaining steps are skipped, so read the first failure.
All names, slugs and e-mails carry a per-run suffix, so the suite can run repeatedly on the same stack.

## How passwords are set
The first admin of tenant A and the second admin of step 31 sign in like real users: with the temporary password from
the API response, then Keycloak's update-password form (`KeycloakUserTokens.firstLogin`, ADR-0024). The other actors
use a test-only shortcut: a random permanent password set through the Keycloak Admin API (master realm `admin-cli`,
`KEYCLOAK_ADMIN`/`KEYCLOAK_ADMIN_PASSWORD` from `.env`), required actions cleared, then the scripted PKCE flow. Do not
use the shortcut outside local/CI stacks.

## Status (WP18b, 2026-11-02)
On compose the full journey is green: 20 tests, 0 failures, about 70 s, three consecutive runs on the same stack
(reproduced by the orchestrator). On kind only `deploy/kind/smoke.sh core game athlete` passed (WP18); the journey on
kind was blocked by the realm defect at that time and has not been re-run since the fix.

WP36 (2026-11-06): the journey is green **on kind through the Envoy Gateway**: 21 tests, 0 failures, 0 skipped, 159 s
(Keycloak Admin API through the port-forward as above). The MailHog checks were skipped: the chart's SMTP sink is
Mailpit, whose API is `/api/v1`, so `E2E_MAILHOG_URL` answered 404 for MailHog's `/api/v2/messages`.

## Known limits
- The realm must be the current `infra/keycloak/realm-academy.json` (every client has the Keycloak 25+ `basic` scope, so
  access tokens carry `sub`; fixed in WP17, finding F-21). The suite fails fast if a token has no `sub`, and the services
  answer 401 for a JWT without `sub`. Compose imports the realm only on an empty volume. Reset: `just down && podman volume rm hoops_pgdata && just up && just seed-users`.
- The Admin API of the master realm must be reachable: set `HOOPS_EXPOSE_KC_ADMIN=true` in `.env` (compose) and restart nginx
  (`just down && just up`); on kind use the port-forward and `E2E_KEYCLOAK_ADMIN_URL`.
- A full run takes about 70 s, of which ~60 s are the 30 s membership caches of game/athlete expiring after suspend and after reactivate; no rate limit (429) was hit.

## Browser smoke (Flutter)
`apps/web/tool/web_smoke.sh` (mock mode) / `--real` / `--compile-only`; needs a chromedriver matching Chrome for the
first two (see the script header). The Homebrew `chromedriver` cask is disabled (Gatekeeper); download the matching
`chromedriver-mac-arm64.zip` from https://googlechromelabs.github.io/chrome-for-testing/, put the binary on PATH and run
`xattr -d com.apple.quarantine` on it. The script drives the `web-server` device: with `-d chrome`, `flutter drive`
never launches a browser and hangs forever after "Waiting for connection from debug service".

## CI
`.github/workflows/e2e.yml`: Podman + podman-compose on `ubuntu-24.04`, throw-away `.env` with random secrets, the
same scripts as `just e2e`, service logs and surefire reports uploaded on failure. Not executed from a workstation.
