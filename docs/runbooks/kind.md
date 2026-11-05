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
  services 192–448 Mi, two Postgres 192–512 Mi, Envoy Gateway controller 256 Mi + one Envoy proxy 64–256 Mi, CNPG
  operator, control plane ~1 GiB).

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
just kind-up          # cluster "hoops" (kindest/node v1.36.4) + Envoy Gateway v1.9.3 (Gateway API v1.6.1 CRDs) + CNPG 1.30.1
                      # + ns hoops + Secrets from .env + self-signed TLS Secret hoops-gateway-tls
just tilt             # = tilt up: builds 4 images with Podman, kind-loads them, deploys the chart, port-forwards
deploy/kind/seed-users.sh   # dev users <name>@hoops-academy.com (superadmin, admin1, coach1, assistant1, parent1, player1)
```
Without Tilt: `just kind-up --deploy` (builds all images, loads them, `helm upgrade --install --wait`).
CI-style: `just tilt ci` (exits 0 when every resource is Ready).

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
health routes, the rate-limited routes with their `BackendTrafficPolicy` (60/min token + login form, 120/min
`events:batch`, per client IP) and one `ClientTrafficPolicy` per listener. The `EnvoyProxy` `hoops` makes Envoy Gateway
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
deploy/kind/ratelimit-check.sh              # burst -> 429 per client IP (limits this client for up to a minute)
```
Server-side validation of the chart against the installed CRDs:
`helm template hoops deploy/helm/hoops -n hoops -f deploy/helm/hoops/values-kind.yaml | kubectl --context kind-hoops -n hoops apply --dry-run=server -f -`.

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
See ADR-0012. `deploy/kind/secrets.sh` prints the 13 Secrets from `.env`; nothing is written to disk. Rotate locally:
edit `.env`, `deploy/kind/secrets.sh | kubectl apply -f -` (or let Tilt pick up `.env`), then restart consumers
(`kubectl -n hoops rollout restart deploy`). CNPG re-applies role passwords automatically. The Keycloak admin and
client secrets only apply on the first realm import/bootstrap — for an existing DB change them in Keycloak too.

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
  `podman machine ssh "sudo date -u -s @$(date +%s)"`.
- `curl localhost:8090` refused or hangs: the Envoy proxy pod is not Ready yet
  (`kubectl -n envoy-gateway-system get pods`) or the Gateway is not programmed (`kubectl -n hoops describe gateway hoops`).
  A cluster created before WP36 maps 8090 to node port 80 (ingress-nginx): `just kind-down && just kind-up`.
- `up.sh: Gateway API CRDs are vX, Envoy Gateway ... needs vY`: CRDs of another version were installed before (e.g. by
  another tool). Apply the bundled CRDs as in ADR-0031 "Upgrade path", or recreate the cluster.
- Every request answers 429: this client used its bucket (`deploy/kind/ratelimit-check.sh` does that on purpose); wait
  one minute. The limit only covers the token endpoint, the login form and `events:batch`.

## Verification status
WP16: game + athlete + web deployed with `tilt ci`, `smoke.sh game athlete` passed. WP18: core, game and athlete
deployed with `up.sh --deploy` + Helm, `smoke.sh core game athlete` passed (superadmin@hoops-academy.com `/api/core/me`, `/platform/tenants`).
WP36 (2026-11-06, Envoy Gateway v1.9.3, Gateway API v1.6.1, kindest/node v1.36.4, rootless 2-CPU machine): Gateway
`Programmed`, all 12 HTTPRoutes `Accepted`/`ResolvedRefs`, both BackendTrafficPolicies and ClientTrafficPolicies
`Accepted`; `kubectl apply --dry-run=server` of the rendered chart clean; `smoke.sh core game athlete` passed (incl.
encoded/dotted deny paths, `events:batch` and `%3A` forwarding, back-channel URLs on :8090); the e2e journey passed on
kind (21 tests, 0 failures, 159 s); `ratelimit-check.sh` passed (429 after one bucket, `%3A` shares it, another client IP
keeps its own); https on :8453 answers with the self-signed certificate, no HSTS. `tilt ci` was not re-run (the Tiltfile
evaluates; gateway objects are grouped under the `gateway`, `keycloak`, service and `web` resources).

## Stop
`just kind-down` deletes the cluster (CNPG volumes included). Recreate with `just kind-up && just tilt`.
