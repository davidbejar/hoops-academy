# Runbook — Hoops Academy on kind (Podman) with Helm and Tilt

WP16. Local Kubernetes that mirrors production packaging: container images, the `hoops` umbrella chart,
CloudNativePG for PostgreSQL 17, Keycloak 26.8.1 in production mode, Envoy Gateway (Gateway API, ADR-0031). The compose stack
(`just up`, :8080) keeps working side by side; kind uses **:8090** (http) and **:8453** (https).

## Prerequisites
- Podman machine running (`podman machine list`), `source scripts/env.sh` (exports
  `KIND_EXPERIMENTAL_PROVIDER=podman`). kind ≥ 0.33, kubectl, helm 4, tilt ≥ 0.37, flutter (web image).
- `.env` at the repo root (`cp .env.example .env`, replace every `change-me-*`; `DEV_USER_PASSWORD` ≥ 12 chars).
  `up.sh`/Tilt fail if `.env` or a key is missing.
- Capacity: the full stack requests ~1.5 CPU / ~2.5 GiB inside the kind node (Keycloak 512 Mi–1 Gi, three
  services 192–448 Mi, two Postgres 192–512 Mi, Envoy Gateway controller 256 Mi + one Envoy proxy 64–256 Mi, its
  rate limit service `envoy-ratelimit` 32–128 Mi + `ratelimit-redis` 16–64 Mi, CNPG operator, control plane ~1 GiB).

### Rootless vs rootful Podman
kind's Podman provider works best on a **rootful** machine. Rootless needs cgroup v2 with the
`cpu io memory pids` controllers delegated (this machine has them). If `kind create cluster` fails on a rootless
machine (cgroup/`ip_tables`/port errors), switch the machine — this stops every container on it:
```bash
podman machine stop
podman machine set --rootful --cpus 6 --memory 12288
podman machine start
```

## Start
```bash
source scripts/env.sh
just kind-up          # cluster "hoops" (kindest/node v1.36.4) + Envoy Gateway v1.9.3 (Gateway API v1.6.1 CRDs) with its
                      # rate limit service (Redis backend ratelimit-redis.hoops:6379) + CNPG 1.30.1
                      # + ns hoops + Secrets from .env + self-signed TLS Secret hoops-gateway-tls
just tilt             # = tilt up: builds 4 images with Podman, kind-loads them, deploys the chart, port-forwards
deploy/kind/seed-users.sh   # dev users <name>@hoops-academy.com (superadmin, admin1, coach1, assistant1, parent1, player1)
```
Without Tilt: `just kind-up --deploy` (builds all images, loads them, `helm upgrade --install --wait`).
Secrets through the External Secrets Operator instead of `secrets.sh` (WP65): `deploy/kind/up.sh --eso [--deploy]`, then
`tilt up -- --eso` if you did not pass `--deploy` (section "Secrets").
CI-style: `just tilt ci` (exits 0 when every resource is Ready; `just tilt ci -- --from-host` on a fresh cluster: 5 min 55 s
with cold caches, WP42, all nine workloads healthy, no Tiltfile change needed after WP36/WP40). Then `deploy/kind/seed-users.sh`,
`deploy/kind/smoke.sh core game athlete` (4 s) and the journey (docs/runbooks/e2e.md, 21/21, mail checks included).

Tilt flags (after `--`): `--services=game-service,athlete-service` (subset; useful while a service does not
compile; combine with resource names to skip web: `tilt ci game-service athlete-service -- --services=game-service,athlete-service`), `--from-host` (package with `./mvnw` on the host and copy the fast-jar — much faster than compiling in
the container), `--skip-flutter` (reuse `apps/web/build/web`).

## What runs where
| URL (host) | Backend |
|---|---|
| `http://localhost:8090/` | `web` (nginx-unprivileged, Flutter build) |
| `http://localhost:8090/auth/` | `keycloak:8080` (issuer `http://localhost:8090/auth/realms/academy`) |
| `http://localhost:8090/api/core/`, `/platform/` | `core-service:8081` |
| `http://localhost:8090/api/game/` | `game-service:8082` |
| `http://localhost:8090/api/athlete/` | `athlete-service:8083` |
| `http://localhost:8090/api/<svc>/q/health[/live\|ready\|started]` | rewritten to `/q/health…` of the service (nothing else under `/q`) |
| `http://localhost:8090/internal/**` | **403** (routed to the web nginx `location /internal`) |
| Tilt port-forwards | Keycloak `:18080`, core `:18081`, game `:18082`, athlete `:18083` |

How the gateway is wired: the chart renders GatewayClass `envoy-gateway` (kind only, `gateway.gatewayClass.create`),
Gateway `hoops` (listeners `http` :80, `https` :443 with `hoops-gateway-tls`), one HTTPRoute per prefix, the exact
health routes, the rate-limited routes with their `BackendTrafficPolicy` (global limits, ADR-0033: 60/min and 10/s token +
login form, 120/min and 20/s `events:batch`, per client IP, one counter shared by every Envoy replica) and one
`ClientTrafficPolicy` per listener. The counters live in `ratelimit-redis` (namespace `hoops`, `rateLimit.redis.enabled`
in `values-kind.yaml`), read and written only by Envoy Gateway's `envoy-gateway-system/envoy-ratelimit` pods, which
`up.sh` enables with `config.envoyGateway.rateLimit` (Redis backend, `failClosed=false`, 100 ms timeout). Two layers
guard Redis: its NetworkPolicy and an ACL (WP46) whose only user `ratelimit` may `PING`/`INCRBY`/`EXPIRE` the keys
`hoops/hoops/*`; the `default` user is off. The password is `RATELIMIT_REDIS_PASSWORD` in `.env` (add it to an older
`.env`, see `.env.example`); `secrets.sh` renders it as `hoops/hoops-ratelimit-redis` and as
`envoy-gateway-system/envoy-ratelimit-redis-auth` (`REDIS_AUTH` of the rate limit pods), and `up.sh` applies the Secrets
before it installs Envoy Gateway. The `EnvoyProxy` `hoops` makes Envoy Gateway
create the proxy Service `envoy-gateway-system/hoops-gateway` as a NodePort (30080/30443), which `kind-config.yaml`
maps to `127.0.0.1:8090/8453`. Status: `kubectl -n hoops get gateway,httproute` (`PROGRAMMED True`, routes `Accepted`);
`kubectl -n hoops describe backendtrafficpolicy` shows whether a policy attached.

In-cluster: services reach Keycloak at `http://keycloak:8080/auth` (back-channel; `KC_HOSTNAME_BACKCHANNEL_DYNAMIC=true`
keeps the token issuer on the public URL), Postgres at `hoops-db-rw:5432/hoops`, Keycloak's DB at `keycloak-db-rw`.

HTTPS on :8453 terminates at the Gateway with the self-signed `hoops-gateway-tls` (created by `up.sh`, 365 days;
delete the Secret and re-run `up.sh` to renew); Keycloak's hostname is the http URL, so use http locally. Moving to
https = `keycloak.publicUrl` / `global.publicUrl` `https://localhost:8453`. HSTS is off on kind (`gateway.tls.hsts: ""`).

## Smoke checks
```bash
kubectl -n hoops get pods                                   # all Running/Ready
curl -s http://localhost:8090/auth/realms/academy/.well-known/openid-configuration | jq -r .issuer
curl -s http://localhost:8090/api/game/q/health/ready       # {"status":"UP",...}
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8090/internal/x   # 403
deploy/kind/smoke.sh core game athlete      # all of the above and more (pods, gateway, tokens, seeded superadmin)
deploy/kind/ratelimit-check.sh              # paced burst -> first 429 at rpm+1 per client IP, with any number of Envoy
                                            # replicas; tight burst (all at once) -> 429 from the per-second rule; Redis ACL
                                            # (waits for a fresh one-minute window per burst, ~5 min in all; limits this
                                            # client until that window ends)
deploy/kind/ratelimit-check.sh acl          # only the ACL proof: limited user, default user off, no anonymous access
deploy/kind/ratelimit-check.sh redis-down   # stops ratelimit-redis: requests pass (fail open), then the limit is back
```
Server-side validation of the chart against the installed CRDs:
`helm template hoops deploy/helm/hoops -n hoops -f deploy/helm/hoops/values-kind.yaml | kubectl --context kind-hoops -n hoops apply --dry-run=server -f -`.
With `--set externalSecrets.enabled=true` the render also holds `envoy-gateway-system/envoy-ratelimit-redis-auth`, which
`-n hoops` refuses: dry-run that document without `-n` (WP65 split the stream with awk on `namespace: envoy-gateway-system`).

## Images
`scripts/build-images.sh [--from-host] [--kind-load] [--push] [core-service|game-service|athlete-service|web]`
- Services: `deploy/containers/service.Containerfile` (build-arg `SERVICE`), stage 1 `maven:3-eclipse-temurin-21`
  with `-pl services/$SERVICE -am package -DskipTests` (Maven cache mount `hoops-m2`), stage 2
  `ubi9/openjdk-21-runtime`, uid 185, fast-jar in `/deployments`, `-XX:MaxRAMPercentage=75`.
  `--from-host` uses the `app-host` stage instead (copies `services/$SERVICE/target/quarkus-app`).
- Web: `deploy/containers/web.Containerfile`; default builds the bundle on the host (`flutter build web`, native
  arm64, seconds) and copies it into `nginx-unprivileged:1.30-alpine` (uid 101, :8080, `/healthz`).
  `--web-in-container` uses `ghcr.io/cirruslabs/flutter:stable` (hermetic, multi-GB, slow on a small machine).
- Tags: `localhost/hoops/<image>:dev` (what Podman calls `hoops/<image>:dev`). Loading into kind goes through
  `podman save` → temp archive → `kind load image-archive` (kind cannot read Podman's store).
- Scan: `trivy image localhost/hoops/<image>:dev` (CI: `.github/workflows/images.yml`).

## Charts
`deploy/helm/hoops` (umbrella) → `databases`, `keycloak`, `hoops-service` ×3 (aliases `core`, `game`, `athlete`),
`web`. Values: `values.yaml` (defaults), `values-kind.yaml`, optional git-ignored `values-local.yaml`.
- The realm JSON and the DB init SQL are **copied** into the charts (`charts/keycloak/files`,
  `charts/databases/files`) by `scripts/sync-chart-files.sh` (WP17 replaced the WP16 symlinks so `helm package`
  works). `deploy/kind/up.sh` runs the script; `deploy/helm/tests/run.sh` fails on drift. The Tiltfile does **not**
  call it yet: run `scripts/sync-chart-files.sh` before `just tilt` after editing `infra/keycloak/realm-academy.json`
  or `infra/db/init/01_roles_schemas.sql`. The realm's `http://localhost:8080` redirect URIs/web origins are rewritten to `keycloak.publicUrl` at render time.
- Tests: `deploy/helm/tests/run.sh` (lint, golden snapshots in `tests/snapshots`, kubeconform incl. the CNPG CRD,
  security assertions, gitleaks on the rendered output). After an intended change: `run.sh --update` and review
  the snapshot diff (it also changes when the realm JSON or init SQL change — on purpose).

## Secrets
See ADR-0012. `deploy/kind/secrets.sh` prints the 15 Secrets from `.env` (14 in `hoops`, the rate limit service's Redis login
`envoy-ratelimit-redis-auth` in `envoy-gateway-system`); nothing is written to disk. Rotate locally:
edit `.env`, `deploy/kind/secrets.sh | kubectl apply -f -` (or let Tilt pick up `.env`), then restart consumers
(`kubectl -n hoops rollout restart deploy`; after `RATELIMIT_REDIS_PASSWORD` also
`kubectl -n envoy-gateway-system rollout restart deploy/envoy-ratelimit`). CNPG re-applies role passwords automatically. The Keycloak admin and
client secrets only apply on the first realm import/bootstrap — for an existing DB change them in Keycloak too.

### Secrets from the External Secrets Operator (`--eso`, WP65)
`deploy/kind/up.sh --eso` replaces the `secrets.sh` step: it installs ESO (`ESO_VERSION`, v2.14.0, Helm release
`external-secrets` in namespace `external-secrets`), then applies `deploy/kind/eso-store.sh`: the stand-in for a cloud
secret manager, one Secret `hoops-secret-store/hoops` with a key per `.env` value (not `DEV_USER_PASSWORD`), a reader
ServiceAccount allowed only `get secrets` there, and the `ClusterSecretStore` `hoops` (Kubernetes provider) that only the
namespaces `hoops` and `envoy-gateway-system` may use. With `--deploy` (or `tilt up -- --eso`) the chart runs with
`externalSecrets.enabled=true`: 14 `ExternalSecret`s (13 in `hoops`, `envoy-ratelimit-redis-auth` in
`envoy-gateway-system`) and ESO writes the Secrets, with the same names and keys, refreshed every minute
(`values-kind.yaml`). Until the chart is deployed the `envoy-ratelimit` pods wait for their Secret
(`CreateContainerConfigError`), which resolves itself. Status: `kubectl get clustersecretstore hoops` (`READY True`),
`kubectl -n hoops get externalsecret` (all `SecretSynced`). Rotation: `docs/runbooks/rotate-secrets.md` section E. A
cluster stays in the mode it was created with (`just kind-down` to switch).

Measured on the 2-CPU rootless machine (warm caches): `tilt ci` for game + athlete + web ≈ 4-5 min; first ever
in-container Maven build ≈ 10 min (dependency download into the `hoops-m2` cache mount); Keycloak Ready ≈ 2 min.

## Troubleshooting
- Rootless kind on this Podman machine (cgroup v2, `cpu io memory pids` delegated) works: `kind create cluster` Ready
  after 17 s with kindest/node v1.37.0. Rootful is only needed if your machine lacks the delegated controllers.
- Envoy Gateway/CNPG rollout timeouts on the very first `kind-up`: images are pulled inside the node; on a slow link
  that takes minutes. `up.sh` waits up to 15 min and is idempotent — just re-run it.
- All three services use HTTP probes on `/q/health/live|ready|started` (WP17 added `quarkus-smallrye-health` to
  game/athlete and removed the TCP overrides). game/athlete readiness reports `core-service: reachable|unreachable` as
  data only; a core outage does not take them out of rotation.
- Tokens without `sub` (realm clients lacking the Keycloak 25+ `basic` scope) are rejected with 401. The chart renders
  the current realm; an existing `keycloak-db` keeps the old realm until it is recreated (see below).
- CNPG init SQL is passed via `postInitApplicationSQLRefs` (ConfigMap), never inline `postInitApplicationSQL`: inline
  queries reach the initdb Pod as container args, where Kubernetes `$(VAR)` expansion turns plpgsql `$$` into `$`.
- Tilt log scrubbing replaces every Secret value in logs, so the plain username `keycloak` shows as
  `[redacted secret keycloak-db-app:username]` — cosmetic.
- `Cannot connect to the Docker daemon` from kind → `KIND_EXPERIMENTAL_PROVIDER` not set; `source scripts/env.sh`.
- Pod `ErrImageNeverPull`/`ImagePullBackOff` for `localhost/hoops/*` → image not loaded: `scripts/build-images.sh <img> --kind-load`.
- Keycloak not Ready for ~2 min after start is normal (`start` re-augments; readiness `initialDelaySeconds: 60`).
- Realm changes are not applied to an existing Keycloak DB (import = IGNORE_EXISTING): delete the
  `keycloak-db` Cluster (`kubectl -n hoops delete cluster keycloak-db`) and let Helm/Tilt recreate it.
- DB init SQL runs once (`postInitApplicationSQLRefs`); to re-run, delete the `hoops-db` Cluster (data loss).
- `flutter build web` hangs at "Compiling lib/main.dart" with `font-subset` processes at 0 % CPU (seen 2026-11-06):
  stop it and build with `--no-tree-shake-icons` (`cd apps/web && flutter build web --release --pwa-strategy=offline-first
  --no-tree-shake-icons`), then `scripts/build-images.sh web --skip-web-build --kind-load`.
- A pod stuck in `Pulling image` for many minutes (kubelet pulls one image at a time, so it blocks the others): pull it on
  the host (`podman pull <image>`), `podman save -o /tmp/x.tar <image>`, `kind load image-archive /tmp/x.tar --name hoops`,
  then `podman exec hoops-control-plane systemctl restart containerd` and delete the pod.
- Tokens rejected as expired (401) by Testcontainers tests or Keycloak in Podman: the Podman VM clock drifted (seen 59 min
  after the Mac slept; chrony refused to step). Compare `date -u` with `podman machine ssh date -u`; fix with
  `podman machine ssh "sudo date -u -s @$(date +%s)"`. The hook scripts (`scripts/hooks/_common.sh`) do this by
  themselves before `just isolation-check` / `just db-role-check` and Claude's commit/push gates. Prevention for long runs:
  `caffeinate -dims -t 28800 &` keeps the host awake (the `wp-round` and `work-package` skills start it).
- `curl localhost:8090` refused or hangs: the Envoy proxy pod is not Ready yet
  (`kubectl -n envoy-gateway-system get pods`) or the Gateway is not programmed (`kubectl -n hoops describe gateway hoops`).
  A cluster created before WP36 maps 8090 to node port 80 (ingress-nginx): `just kind-down && just kind-up`.
- `up.sh: Gateway API CRDs are vX, Envoy Gateway ... needs vY`: CRDs of another version were installed before (e.g. by
  another tool). Apply the bundled CRDs as in ADR-0031 "Upgrade path", or recreate the cluster.
- Every request answers 429: this client used its counter for this minute (`deploy/kind/ratelimit-check.sh` does that on
  purpose); wait for the next full minute. The limit only covers the token endpoint, the login form and `events:batch`.
- `envoy-ratelimit` restarts once right after `just kind-up` (`creating redis connection error`): Redis only exists after
  the chart is deployed. It reconnects by itself; `kubectl -n envoy-gateway-system logs deploy/envoy-ratelimit` shows
  `redis connection re-established`.
- `envoy-ratelimit` logs `WRONGPASS` or `NOPERM`: the Redis login Secrets differ (re-run `secrets.sh` and restart both
  sides, `docs/runbooks/rotate-secrets.md`) or the ACL key pattern does not match the domain `hoops/hoops/<listener>`.
  The gateway then fails open. `secrets.sh: missing RATELIMIT_REDIS_PASSWORD`: an `.env` from before WP46; add the key.
- No 429 at all on the limited routes: the rate limit service or Redis is down and the gateway fails open (ADR-0033).
  Check `kubectl -n envoy-gateway-system get pods -l app.kubernetes.io/name=envoy-ratelimit`,
  `kubectl -n hoops get pods -l app.kubernetes.io/name=ratelimit-redis`, and that `envoy-gateway-config` has a
  `rateLimit.backend` (a cluster created before WP40 has none: `just kind-up` again upgrades the Envoy Gateway release and restarts its
  controller when the config changed).

## Verification status
WP16: game + athlete + web deployed with `tilt ci`, `smoke.sh game athlete` passed. WP18: core, game and athlete
deployed with `up.sh --deploy` + Helm, `smoke.sh core game athlete` passed (superadmin@hoops-academy.com `/api/core/me`, `/platform/tenants`).
WP36 (2026-11-06, Envoy Gateway v1.9.3, Gateway API v1.6.1, kindest/node v1.36.4, rootless 2-CPU machine): Gateway
`Programmed`, all 12 HTTPRoutes `Accepted`/`ResolvedRefs`, both BackendTrafficPolicies and ClientTrafficPolicies
`Accepted`; `kubectl apply --dry-run=server` of the rendered chart clean; `smoke.sh core game athlete` passed (incl.
encoded/dotted deny paths, `events:batch` and `%3A` forwarding, back-channel URLs on :8090); the e2e journey passed on
kind (21 tests, 0 failures, 159 s); `ratelimit-check.sh` passed (429 after one bucket, `%3A` shares it, another client IP
keeps its own); https on :8453 answers with the self-signed certificate, no HSTS.
WP40 (2026-11-06, same versions, global limits): Gateway `Programmed`, both BackendTrafficPolicies `Accepted`;
`smoke.sh core game athlete` passed; `ratelimit-check.sh` passed with 1 and with 2 Envoy replicas, identical numbers
(events:batch 250 sent, 120 passed, first 429 at #121; token 130 sent, 60 passed, first 429 at #61; both replicas served
the burst); `ratelimit-check.sh redis-down` passed (130 requests with Redis at 0 replicas: all passed, 15 s; first 429 at
#121 again once Redis was back); the Redis NetworkPolicy refused a pod in `hoops` and an unlabelled pod in
`envoy-gateway-system` and admitted a pod with the `envoy-ratelimit` label. `tilt ci` was not re-run (the Tiltfile
evaluates; gateway objects are grouped under the `gateway`, `keycloak`, service and `web` resources).
WP46 (2026-11-06, same versions, chart 0.4.0: Redis ACL + per-second caps, 1 Envoy replica): `apply --dry-run=server`
clean; Gateway `Programmed`, both policies `Accepted`; `/rlconfig` lists a MINUTE and a SECOND entry per route rule and
address family; `smoke.sh core game athlete` passed; `ratelimit-check.sh` passed: paced bursts first 429 at #121
(`events:batch`, 250 in 31 s) and #61 (token, 130 in 31 s), tight bursts 60 at once -> 20 passed / 40 x 429 and
40 at once -> 10 passed / 30 x 429, ACL probe (anonymous NOAUTH, `default` WRONGPASS, `ratelimit` PONG/INCRBY/EXPIRE on
`hoops/hoops/*`, NOPERM on other keys, GET, EVAL, FLUSHALL, KEYS, SET, ACL, INFO, SCRIPT, MULTI); `redis-down` passed
(130 requests, 0 x 429, 15 s; #121 again after Redis was back with a freshly written ACL file). The password appeared
in no log, pod spec, Envoy Gateway config or chart render. Re-running `up.sh` left the controller untouched.
WP63 (2026-11-06, chart 0.4.0 on a fresh cluster): `up.sh --deploy --from-host` 9 min 5 s cold; Gateway `Programmed`, both
BackendTrafficPolicies and both ClientTrafficPolicies `Accepted`; `smoke.sh core game athlete` passed (3 s);
`ratelimit-check.sh` and `redis-down` passed (numbers as WP46: first 429 at #121 / #61, tight bursts 20 and 10 passed,
ACL probe, 130/130 passed with Redis down, #121 again after). Two Envoy replicas (`kubectl -n hoops patch envoyproxy
hoops --type merge -p '{"spec":{"provider":{"kubernetes":{"envoyDeployment":{"replicas":2}}}}}'`): first 429 at #121,
tight burst 20 passed / 40 x 429, the burst split 97/107 and 123/123 access-log lines across the two pods. `tilt ci --
--from-host` after `up.sh` on a fresh cluster: "All workloads are healthy", `up.sh` + `tilt ci` 9 min 9 s, no Tiltfile
change. Controller-restart branch of `up.sh`: with `rateLimit.timeout` 100ms -> 150ms in `EG_VALUES` the re-run printed
`deployment.apps/envoy-gateway restarted`, the ConfigMap showed 150ms and the proxies' `envoy.filters.http.ratelimit`
filters `"timeout": "0.150s"` (admin `:19000/config_dump`); changed back, restarted again, 100ms. A re-run without a
change does not restart. e2e journey on kind (Keycloak and Mailpit port-forwards 18080 / 18025): 21/21, mail checks
included, 71 s (25 tests with `MailSinkTest`). The Podman VM (2 CPUs) was shared with other builds (load average 25-37):
see the load note under Troubleshooting.
WP65 (2026-11-06, chart 0.5.0, ESO v2.14.0, fresh cluster): `up.sh --eso` 2 min 34 s (ClusterSecretStore `hoops` Valid/Ready,
no `secrets.sh`, no Secret in `hoops` but `hoops-gateway-tls`); the WP63 `:dev` images loaded by hand and the same `helm
upgrade --install ... -f values-kind.yaml --set externalSecrets.enabled=true --wait` that `up.sh --eso --deploy` runs:
deployed in 4 min 32 s incl. the loads; 14/14 ExternalSecrets `SecretSynced` within ~25 s; all 23 Secret keys equal the
`.env` values (compared by SHA-256), types basic-auth/Opaque as with `secrets.sh`; `envoy-ratelimit` left
`CreateContainerConfigError` by itself once its Secret existed; `smoke.sh core game athlete` passed (29 checks);
`ratelimit-check.sh acl` passed. Rotation (rotate-secrets.md E): `GAME_APP_PASSWORD` changed in `hoops-secret-store/hoops`,
force-sync -> Secret updated in < 1 s, CNPG reported the new Secret version as reconciled a few minutes later, a restarted
game-service started with it, smoke passed again. An existing plain Secret was adopted by a new `ExternalSecret` (owner
reference set, value replaced) and deleted with it. `apply --dry-run=server` of the ESO render clean (63 objects).
`tilt up -- --eso` evaluated only (`tilt alpha tiltfile-result`: `secrets` holds the 14 ExternalSecrets). The Podman VM
(load average up to 118 from other agents' builds) restarted the kind control plane once mid-proof; everything recovered
without intervention.

## Stop
`just kind-down` deletes the cluster (CNPG volumes included). Recreate with `just kind-up && just tilt`.
