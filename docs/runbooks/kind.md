# Runbook — Hoops Academy on kind (Podman) with Helm and Tilt

WP16. Local Kubernetes that mirrors production packaging: container images, the `hoops` umbrella chart,
CloudNativePG for PostgreSQL 17, Keycloak 26.8.1 in production mode, Envoy Gateway (Gateway API, ADR-0031), Redpanda as the
event broker (ADR-0036). The compose stack
(`just up`, :8080) keeps working side by side; kind uses **:8090** (http) and **:8453** (https).

## Prerequisites
- Podman machine running (`podman machine list`), `source scripts/env.sh` (exports
  `KIND_EXPERIMENTAL_PROVIDER=podman`). kind ≥ 0.33, kubectl, helm 4, tilt ≥ 0.37, flutter (web image).
- `.env` at the repo root (`cp .env.example .env`, replace every `change-me-*`; `DEV_USER_PASSWORD` ≥ 12 chars).
  `up.sh`/Tilt fail if `.env` or a key is missing.
- Capacity: the full stack requests ~1.5 CPU / ~2.5 GiB inside the kind node (Keycloak 512 Mi–1 Gi, three
  services 192–448 Mi, two Postgres 192–512 Mi, Envoy Gateway controller 256 Mi + one Envoy proxy 64–256 Mi, its
  rate limit service `envoy-ratelimit` 32–128 Mi + `ratelimit-redis` 16–64 Mi, `redpanda` 512–768 Mi with a 1 Gi volume,
  CNPG operator, control plane ~1 GiB).

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
                      # + Stakater Reloader 2.2.19 (v1.4.23, namespace hoops-reloader, WP87)
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
| (not routed) `redpanda.hoops.svc.cluster.local:9092` | Redpanda `redpanda-0` (Kafka API, SASL/SCRAM; only from the services' pods) |
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

Event broker (WP66, ADR-0036, `events.enabled` in `values-kind.yaml`): StatefulSet `redpanda` (one node, developer mode,
512M Seastar memory, PVC `data-redpanda-0`), headless Service `redpanda` (Kafka 9092, admin 9644). SASL/SCRAM on Kafka,
basic auth on the admin API, ACLs enforced; the NetworkPolicy admits Kafka only from the three services and the Job
`redpanda-bootstrap`, the admin API only from that Job. The Job (a Helm post-install/upgrade hook; a plain Job for Tilt,
resource `redpanda-bootstrap`) sets the cluster properties, the users `core-service`, `game-service`, `athlete-service`
with the passwords of `hoops-redpanda-<service>`, their ACLs and the seven topics. `rpk`, consumer groups, rotation:
`docs/runbooks/events.md`. Since WP71 the services connect as those users (`global.events.enabled`, the mirror of
`events.enabled`): core publishes its outbox, game and athlete feed their roster replicas (roster source `rest`;
flip one with `--set athlete.rosterSource=replica`, `events.md` "Kubernetes (chart, WP71)").

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
deploy/kind/smoke.sh core game athlete      # all of the above and more (pods, gateway, event broker, tokens, seeded superadmin,
                                            # events: a seeded academy through core's outbox into both replicas, WP71)
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
See ADR-0012. `deploy/kind/secrets.sh` prints the 19 Secrets from `.env` (18 in `hoops`, among them the four event broker logins
`hoops-redpanda-*` from `REDPANDA_*_PASSWORD`, WP66; the rate limit service's Redis login `envoy-ratelimit-redis-auth` in
`envoy-gateway-system`); nothing is written to disk. Rotate locally:
edit `.env`, `deploy/kind/secrets.sh | kubectl apply -f -` (or let Tilt pick up `.env`). The pods that read a changed
Secret restart by themselves (WP87): `up.sh` installs Stakater Reloader (pinned chart and image digest, namespace
`hoops-reloader`, namespaced Roles for `hoops` and `envoy-gateway-system` only, Secrets only) and the chart annotates every
workload that reads a Secret (`global.reloader.enabled` in `values-kind.yaml`; `envoy-ratelimit` through Envoy Gateway's
`rateLimitDeployment.patch`). `kubectl -n hoops-reloader logs deploy/reloader-reloader` shows what it rolled. CNPG
re-applies role passwords automatically. The Keycloak admin and client secrets only apply on the first realm
import/bootstrap — for an existing DB change them in Keycloak too (`rotate-secrets.md` section E).

### Secrets from the External Secrets Operator (`--eso`, WP65)
`deploy/kind/up.sh --eso` replaces the `secrets.sh` step: it installs ESO (`ESO_VERSION`, v2.14.0, Helm release
`external-secrets` in namespace `external-secrets`), then applies `deploy/kind/eso-store.sh`: the stand-in for a cloud
secret manager, one Secret `hoops-secret-store/hoops` with a key per `.env` value (not `DEV_USER_PASSWORD`), a reader
ServiceAccount allowed only `get secrets` there, and the `ClusterSecretStore` `hoops` (Kubernetes provider) that only the
namespaces `hoops` and `envoy-gateway-system` may use. With `--deploy` (or `tilt up -- --eso`) the chart runs with
`externalSecrets.enabled=true`: 18 `ExternalSecret`s (17 in `hoops`, the four broker logins included, `envoy-ratelimit-redis-auth` in
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
- core's publisher stays `DEGRADED` after a fresh install, its log shows `SASL authentication failed` and then only
  "Expiring 1 record(s) ...": it started before the Job `redpanda-bootstrap` created its broker user and its idempotent
  producer does not recover from that first failure. `kubectl -n hoops rollout restart deploy/core-service` (`up.sh` does
  it; `events.md` "Kubernetes (chart, WP71)").
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
WP66 (2026-11-06, chart 0.6.0, Redpanda v26.2.6, fresh cluster, freshly imported realm): `up.sh --deploy --from-host`
7 min 20 s; `redpanda-0` Ready about 45 s after the pull (116 MB image), read-only root FS, developer mode, 512M; the Job
`redpanda-bootstrap` succeeded on its first run (5 cluster properties, 3 users with ACLs, 7 topics). `smoke.sh core game
athlete` passed (all checks, incl. the new event broker block and the ADR-0034 audience checks WP56 asked for). Throwaway
pods with the Redpanda image: an unlabelled pod in `hoops` could not open a TCP connection to `redpanda:9092` (timeout); a
pod labelled `core-service` with its user produced to `core.person` but not to `game.x` (`TOPIC_AUTHORIZATION_FAILED`) and
could not reach the admin API; a pod labelled `game-service` consumed that record in group `game-service.wp66`, was
refused group `athlete-service.x` (`GROUP_AUTHORIZATION_FAILED`) and producing (`CLUSTER_AUTHORIZATION_FAILED`); a wrong
password got `SASL_AUTHENTICATION_FAILED`. Rotation: a new `REDPANDA_GAME_SERVICE_PASSWORD` failed until `helm upgrade`
re-ran the Job, then worked (the first attempt found the HTTP 500 on re-creating a user, fixed in the Job); the superuser
rotation of `events.md` (PUT, Secret, restart) worked, the topics and users survived the restart on the PVC, and the next
Job logged in with the new password. ESO: the four broker `ExternalSecret`s synced against `eso-store.sh` (same values
as `.env` by SHA-256, basic-auth, username = user, owned by the ExternalSecret). `apply --dry-run=server` of the render
clean. Not run: `tilt ci` (the Tiltfile evaluates with and without `--eso`), the full `up.sh --eso --deploy` path.
Cluster deleted.
WP71 (2026-11-06, chart 0.7.0, services on the broker, compose stopped for the proof): `up.sh --deploy --from-host` on a
fresh cluster 5 min 56 s; the services started before the Job created their users (14 `SASL authentication failed` in
core's log, 10 per consumer). game and athlete reconnected by themselves; core's producer did not (every record expired,
`hoops_outbox_pending` 6) until a restart, after which the 6 events went out within 10 s. A user deleted while core runs
(broker restarted to force a reconnect) healed by itself 10 s after the Job restored it, so only the very first login
matters: `up.sh` now restarts core when its log shows the failure (re-run 2 min 56 s, `restart core-service` step), Tilt
deploys core after `redpanda-bootstrap`. `smoke.sh core game athlete` passed with `rest` (46 checks, 10 s: publisher `UP`
/`OK`, three SCRAM logins, seeded academy published 6 -> 12, game and athlete applied +6 each, group lag 0, parked 0, max
event lag 0.84 / 0.87 s). `helm upgrade ... --set athlete.rosterSource=replica`: only the athlete pod was replaced, log
`Roster source: REPLICA (replica consumer on)`; the smoke passed again (46 checks, 14 s: published 12 -> 18, both replicas
+6, parked 0, athlete answered the new player's availability from the replica). With core scaled to 0, athlete still
answered 200 for that player and 404 for an unknown one (core 503); a third smoke after core came back passed. `apply
--dry-run=server` of the render clean. Not run: a deploy with `events.enabled=false` (render assertions only), the game
flip, `tilt ci`, `--eso`. Cluster deleted.
WP87 (2026-11-07, chart 0.8.0, Reloader 2.2.19 / v1.4.23): three `up.sh --eso --deploy --from-host` attempts while four
other agents built (Podman VM load 30-68 on 2 CPUs). The first got through ESO, Reloader (namespaced Roles in `hoops`,
`envoy-gateway-system`, `hoops-reloader`, no ClusterRole; image by digest; `Watching scoped namespaces`), Envoy Gateway
(`envoy-ratelimit` carried `secret.reloader.stakater.com/auto: true` from the `rateLimitDeployment.patch`), CNPG and the
image build and load, then the chart install failed: kube-controller-manager, kube-scheduler and the CNPG operator lost
their leases and restarted, the CNPG webhook was unreachable. `kind-config.yaml` now turns leader election off on the
single control plane (applied: `--leader-elect=false` in both manifests). The next two attempts lost the API server
itself (TLS handshake timeout, `http2: client connection lost`). Not run yet, all waiting for a quiet machine: the
rotation proof (`GAME_APP_PASSWORD`, `hoops-redpanda-game-service`), `events.enabled=false`, the game replica flip,
`tilt ci`, `--eso` with the events, a complete `up.sh --eso --deploy`. Cluster deleted.

## Stop
`just kind-down` deletes the cluster (CNPG volumes included). Recreate with `just kind-up && just tilt`.
