# Runbook: release

Status: describes the process the repository's tooling supports. **No release has been cut yet**: the Maven version is
`0.1.0-SNAPSHOT` and the Helm chart `0.8.0` (2026-11-07); the workflows in `.github/workflows` run on GitHub since
2026-11-02 and `images` pushes every commit's images to `ghcr.io/davidbejar/hoops-academy` (public). Steps marked
(design) are not implemented.

## 1. What is versioned
| Artifact | Version source | Rule |
|---|---|---|
| OpenAPI contracts | `info.version` in `libs/contracts/openapi/{core,game,athlete,common}.yaml` (now core 3.0.0, game 2.2.0, athlete 2.2.0, common 1.1.1); event JSON Schemas in `libs/contracts/events` (version per event envelope, breaking change = `<topic>.v2`, `libs/contracts/README.md`) | SemVer; policy in `libs/contracts/README.md` |
| Maven modules and service jars | root `pom.xml` (`0.1.0-SNAPSHOT`) | one version for the repo |
| Container images | tag `dev` locally; `${{ github.sha }}` in `images.yml` | immutable, per commit |
| Helm chart | `deploy/helm/hoops/Chart.yaml` (`version`, `appVersion`) | bump with every chart change |
| Web app | built from the same commit as the services | released together |

### Contract versioning
- Minor: additive only (new operation, optional field, optional query parameter, new value of a request-only enum).
- Major: removal, rename, optional->required, type change, tightened constraint, status code change, **new value in a
  response enum**. Needs an ADR and a migration note (ADR-0016 is the template). No parallel `/v2` paths: services and web
  ship together. Latest major: core 3.0.0 removed the deprecated `resendTenantAdminInvitation` alias
  (`POST /platform/tenants/{id}/admins/{personId}/resend-invitation` now answers 404; callers use
  `issueTenantAdminTemporaryPassword`, `.../temporary-password`); migration note in ADR-0035 (WP59).
- Patch: descriptions and examples.
- Steps for a contract change:
  1. Edit the YAML and bump `info.version`.
  2. `source scripts/env.sh && ./mvnw -pl libs/contracts verify` (conventions, JSON Schema consistency, strict validation).
  3. `just gen-api` and commit the regenerated `apps/web/packages/{core,game,athlete}`; adapt `apps/web`; `just web-test`.
  4. Adapt the service and make its tests validate responses against the new spec; `just test`.
The match-event JSON Schema is mirrored in `game.yaml`; `MatchEventSchemaConsistencyTest` fails on drift.

## 2. Pre-release checklist
```bash
source scripts/env.sh
just test                      # ./mvnw verify: unit, integration, ArchUnit, RLS suites, coverage gates
just web-test                  # flutter test
just scan                      # gitleaks (full history) + OWASP dependency-check (needs an NVD API key)
deploy/helm/tests/run.sh       # lint, snapshots, kubeconform, policy assertions, gitleaks on rendered output
just e2e                       # journey on compose (docs/runbooks/e2e.md)
```
Also: ADR for any decision taken, handover notes in `docs/wp`, `docs/roadmap.md` updated.
Dependency bumps arrive as weekly grouped Dependabot PRs (`.github/dependabot.yml`: Maven with Quarkus in its own
group, pub for `apps/web`, GitHub Actions); `ci` and `e2e` run on each PR. Container base images, the chart's image
tags and the Envoy Gateway / kind pins are bumped by hand. Ignored on purpose: semver-major updates of
`com.networknt:json-schema-validator` (WP43; 3.x cannot share a classpath with the strict validator's networknt 2.x).
GitHub Actions are pinned to commit SHAs (`uses: owner/action@<40-hex> # vX.Y.Z`); Dependabot updates SHA and comment together, and a new action must be added pinned the same way.
Realm or init-SQL changes: run `scripts/sync-chart-files.sh` (copies into the charts; the chart test fails on drift) and
refresh snapshots with `deploy/helm/tests/run.sh --update` after reviewing the diff.

## 3. Build and publish images
Locally: `scripts/build-images.sh [--from-host] [--kind-load] [--push] [core-service|game-service|athlete-service|web]`.
Web: build with `apps/web/tool/build_web.sh` (stamps the service worker); a plain `flutter build web` leaves `sw.js`
unstamped. In CI `images.yml` runs on pushes to `main` that touch services, libs, web, containers or the pom:
build per service, assert non-root, Trivy gate (`HIGH,CRITICAL --ignore-unfixed`, fails the job), and push only from
`main` and only when the repository variable `IMAGE_REGISTRY` is set. Use a repo-scoped prefix so package names never
collide with another repository's: `gh variable set IMAGE_REGISTRY --body ghcr.io/<owner>/hoops-academy` (refs become
`ghcr.io/<owner>/hoops-academy/core-service:<sha>`). For ghcr.io under the repository's own owner no credential is needed:
the push jobs request `packages: write` and log in with the run's `GITHUB_TOKEN`. For any other registry (or another
owner) set BOTH secrets `REGISTRY_USERNAME`/`REGISTRY_PASSWORD`; setting only one fails the step. Images carry the
`org.opencontainers.image.source` label (build arg `SOURCE_URL`, derived from the `origin` remote by
`scripts/build-images.sh`) so ghcr.io links each package to this repository.

The first push creates each ghcr.io package **private**. The four Hoops Academy packages are **public** (verified
2026-11-05: an anonymous pull works), so a cluster needs no secret. For a private fork, either make the packages public
(package settings on github.com, fine for a public repo) or give the cluster a pull secret and reference it from the chart:
```bash
kubectl -n hoops create secret docker-registry ghcr-pull --docker-server=ghcr.io \
  --docker-username=<owner> --docker-password=<PAT with read:packages>
helm upgrade --install hoops deploy/helm/hoops -n hoops --set 'global.imagePullSecrets[0].name=ghcr-pull' ...
```
Pin the `ubi9/openjdk-21-runtime` tag in `deploy/containers/service.Containerfile` before the first release (open item).

## 4. Deploy with Helm
Umbrella chart `deploy/helm/hoops`; values `values.yaml` (defaults), `values-kind.yaml`, git-ignored `values-local.yaml`.
Image per service: `core|game|athlete.image.repository` and `.tag`.
```bash
# kind (verified in WP16): cluster + Secrets + build + helm upgrade --install --wait
just kind-up --deploy --from-host
# any cluster (design): Secrets created first (ADR-0012), then
helm upgrade --install hoops deploy/helm/hoops -n hoops -f values.prod.yaml \
  --set core.image.tag=<sha> --set game.image.tag=<sha> --set athlete.image.tag=<sha> --set web.image.tag=<sha>
```
Edge prerequisites (ADR-0031): the cluster runs Envoy Gateway (kind pins v1.9.3 with Gateway API v1.6.1 CRDs,
`deploy/kind/up.sh`) and provides a GatewayClass (default name `envoy-gateway`; `--set gateway.gatewayClass.create=true`
renders one). The chart creates the Gateway `hoops` and the HTTPRoutes; for HTTPS create a `kubernetes.io/tls` Secret
first (e.g. cert-manager) and set `gateway.tls.enabled=true`, `gateway.tls.certificateRefs[0].name=<secret>`,
`gateway.hostname=<host>`, `global.publicUrl` / `keycloak.publicUrl=https://<host>`; behind a load balancer that appends
`X-Forwarded-For` set `gateway.clientIPDetection.numTrustedHops`. The Gateway is ready when
`kubectl -n hoops get gateway hoops` shows `PROGRAMMED True`; its address is the Envoy Service in `envoy-gateway-system`.
Values renamed in chart 0.2.0: `ingress.*` -> `route.*`, `networkPolicy.ingressControllerNamespace` -> `gatewayNamespace`.

Global rate limits (chart 0.3.0, ADR-0033): the rate-limit policies are global, so Envoy Gateway must run its rate
limit service with a Redis backend. The cluster operator owns the Envoy Gateway install; these are the values kind pins
in `deploy/kind/up.sh`:
```bash
helm upgrade --install eg oci://docker.io/envoyproxy/gateway-helm --version v1.9.3 -n envoy-gateway-system --reuse-values \
  --set config.envoyGateway.rateLimit.backend.type=Redis \
  --set config.envoyGateway.rateLimit.backend.redis.url=<host:port> \
  --set config.envoyGateway.rateLimit.failClosed=false \
  --set config.envoyGateway.rateLimit.timeout=100ms \
  --set-json 'config.envoyGateway.provider.kubernetes.rateLimitDeployment.container.env=[{"name":"REDIS_AUTH","valueFrom":{"secretKeyRef":{"name":"envoy-ratelimit-redis-auth","key":"auth"}}}]'
# optional: resources of the envoy-ratelimit pods (kind: requests 10m / 32Mi, limit 128Mi)
#   --set config.envoyGateway.provider.kubernetes.rateLimitDeployment.container.resources.requests.cpu=...
```
Envoy Gateway then creates Deployment `envoy-gateway-system/envoy-ratelimit` (pods labelled
`app.kubernetes.io/name: envoy-ratelimit`). Redis: either the chart's in-memory `ratelimit-redis`
(`--set rateLimit.redis.enabled=true`, URL `ratelimit-redis.<namespace>.svc.cluster.local:6379`; its NetworkPolicy
admits only those pods, so a different Envoy Gateway namespace or pod label needs `rateLimit.redis.clientNamespace` /
`clientPodLabels`) or an external one (`rateLimit.redis.url=<host:port>`, informational: `helm install` prints the
Envoy Gateway value to set). Redis login (chart 0.4.0, ADR-0033 amendment): the chart's Redis has an ACL whose only
user `ratelimit` may run `PING`/`INCRBY`/`EXPIRE` on the keys `<namespace>/<gateway>/*`; create two Secrets from one
random password **before** the install (ADR-0012; on kind `deploy/kind/secrets.sh` does it from `.env`
`RATELIMIT_REDIS_PASSWORD`):
```bash
pw=$(openssl rand -hex 24)   # in a shell without history; never in git
kubectl -n hoops create secret generic hoops-ratelimit-redis --from-file=password=<(printf '%s' "$pw")
kubectl -n envoy-gateway-system create secret generic envoy-ratelimit-redis-auth --from-file=auth=<(printf 'ratelimit:%s' "$pw")
unset pw
```
The `REDIS_AUTH` env above hands the second one to the rate limit pods. An external Redis with a password uses the
same `REDIS_AUTH` Secret (`<user>:<password>`, or just the password for `requirepass`); TLS is
`redis.tls.certificateRef`. Do not put credentials into `redis.url` / `redis.urlRef`: the rate limit service logs the
URL unmasked. The per-second burst caps (10/s token + login form, 20/s `events:batch`) need nothing on the Envoy
Gateway side. Check: every policy
reports `Accepted=True` in `kubectl -n hoops get backendtrafficpolicy -o jsonpath='{range .items[*]}{.metadata.name}
{.status.ancestors[*].conditions[?(@.type=="Accepted")].status}{"\n"}{end}'` and
`kubectl -n envoy-gateway-system rollout status deploy/envoy-ratelimit` succeeds.

Secrets from a secret manager (chart 0.5.0, WP65, ADR-0012 amendment): with the External Secrets Operator in the
cluster (`external-secrets.io/v1`; kind pins v2.14.0) and a store for the platform's secret manager, set
`externalSecrets.enabled=true`, `externalSecrets.storeRef` (default `ClusterSecretStore/hoops`) and, if the remote
secret is not called `hoops`, `externalSecrets.remoteKey`. The remote secret holds one property per value, named like the
`.env` keys (inventory in `rotate-secrets.md`); the chart then renders one `ExternalSecret` per Secret (also
`envoy-ratelimit-redis-auth` in `envoy-gateway-system`, so the release needs `create externalsecrets` there) and none of
the Secrets above are created by hand. Limit the store to the namespaces `hoops` and `envoy-gateway-system`
(`spec.conditions`). Check: `kubectl -n hoops get externalsecret` all `SecretSynced` before the pods start.

Event broker (chart 0.6.0, WP66, ADR-0036): `--set events.enabled=true` (since 0.7.0 with `global.events.enabled=true`) renders one Redpanda node (StatefulSet `redpanda`,
pinned image, PVC `events.redpanda.storage`, default Seastar memory 1G in a 1.5 Gi limit, `developerMode` false) and the
post-install/upgrade Job `redpanda-bootstrap` (users, ACLs, topics). Create its four logins **before** the install
(kubernetes.io/basic-auth, username = broker user; on kind `deploy/kind/secrets.sh` from `.env` `REDPANDA_*_PASSWORD`, with
ESO `externalSecrets.events.properties`):
```bash
for u in admin core-service game-service athlete-service; do   # in a shell without history; never in git
  kubectl -n hoops create secret generic "hoops-redpanda-$u" --type=kubernetes.io/basic-auth \
    --from-literal=username="$u" --from-file=password=<(openssl rand -hex 24 | tr -d '\n')
done
```
The storage class needs ReadWriteOnce volumes; the NetworkPolicy needs a CNI that enforces it and DNS pods labelled
`k8s-app: kube-dns` in `kube-system` (egress of the broker). Check: `kubectl -n hoops logs job/redpanda-bootstrap` ends
with `bootstrap done`; `kubectl -n hoops exec redpanda-0 -- rpk cluster health` says `Healthy: true`
(`docs/runbooks/events.md`). Multi-node or a managed Kafka: keep `events.enabled=false` and point the services at it
(ADR-0036, decision 8).

Services on the broker (chart 0.7.0, WP71): `events.enabled=true` now also connects core (outbox publisher) and the game and
athlete replica consumers, so set **both** `events.enabled=true` and `global.events.enabled=true` (the render fails when
they differ). The four `hoops-redpanda-*` Secrets must exist **before** the upgrade: besides the bootstrap Job, every
service Deployment reads `KAFKA_SASL_PASSWORD` from its `hoops-redpanda-<service>` Secret, and a missing Secret leaves the
new pods in `CreateContainerConfigError` (the old ReplicaSet keeps serving). With `events.enabled=false` the chart switches
core's publisher and the consumers off (`CORE_OUTBOX_POLL_INTERVAL=off`, `*_ROSTER_CONSUMER_ENABLED=false`); for a managed
Kafka set `KAFKA_*` and those keys in the services' `env`/`secretEnv` instead. `game.rosterSource` / `athlete.rosterSource`
stay `rest` (ADR-0037 "When rest flips"); `replica` needs the events on. Upgrading from 0.6.0 rolls the three services
(new env). On a **fresh** install the bootstrap Job runs after the services are up, so restart core once it succeeded
(`kubectl -n hoops rollout restart deploy/core-service`): its producer does not recover from starting before its broker
user existed (`events.md` "Kubernetes (chart, WP71)"). Check: `curl -s <public url>/api/core/q/health/ready` shows `outbox-publisher` `UP` with `state` `OK`
(`DEGRADED` = no broker), and `docs/runbooks/events.md` "Kubernetes (chart, WP71)".

Rotation without manual restarts (chart 0.8.0, WP87, ADR-0012 amendment): `global.reloader.enabled=true` annotates every
Deployment/StatefulSet that reads a Secret (core, game, athlete, keycloak, ratelimit-redis, redpanda) with
`secret.reloader.stakater.com/auto: "true"`; a Stakater Reloader controller in the cluster then rolls them when one of
those Secrets changes (an ESO refresh or a re-applied Secret). The chart does not install Reloader: install it like
`deploy/kind/up.sh` does (pinned chart and image digest, `reloader.watchGlobally=false` with `reloader.namespaces` = the
release namespace and `envoy-gateway-system`, `ignoreConfigMaps`, `ignoreJobs`, `ignoreCronJobs`, `reloadStrategy=annotations`),
and give Envoy Gateway's `rateLimitDeployment` the same annotation (`patch`, see `EG_VALUES` in `up.sh`). Without a
controller the annotation does nothing and section E of `rotate-secrets.md` lists the manual restarts. Upgrading from 0.7.0
rolls every pod once (chart labels in the ConfigMap checksums). Check: `kubectl -n hoops-reloader logs deploy/reloader-reloader`
starts with `Watching scoped namespaces: ...` and logs each workload it rolls after a rotation.

Order that matters: Secrets -> CNPG clusters -> Keycloak -> services (Flyway runs on start as `*_migrator`) -> web.
Services restart a few times on first install until `hoops-db-rw` is ready; they converge by themselves (WP18).
Database migrations are forward-only; roll back by deploying a compatible previous image or restoring (`backup-restore.md`).
Run `deploy/kind/smoke.sh core game athlete` (or the equivalent checks) after every deploy; on kind,
`deploy/kind/ratelimit-check.sh` proves the edge rate limits (it leaves this client limited for up to a minute).

## 5. Tag and record
(design) Tag the commit `vX.Y.Z` after the images for that SHA exist and the smoke test passes; record the contract
versions and the image SHAs in the release notes. Move resolved items in `docs/wp/FOLLOW-UPS.md` to "Resolved".
