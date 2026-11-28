# Runbook: release

Status: describes the process the repository's tooling supports. **No release has been cut yet**: the Maven version is
`0.1.0-SNAPSHOT` and the Helm chart `0.9.0` (`hoops-service` 0.7.0, `keycloak` 0.5.0; 2026-11-07); the workflows in `.github/workflows` run on GitHub since
2026-11-02 and `images` pushes every commit's images to `ghcr.io/davidbejar/hoops-academy` (public). Steps marked
(design) are not implemented.

## 1. What is versioned
| Artifact | Version source | Rule |
|---|---|---|
| OpenAPI contracts | `info.version` in `libs/contracts/openapi/{core,game,athlete,common}.yaml` (now core 3.3.0, game 2.3.0, athlete 2.4.0, common 1.1.1); event JSON Schemas in `libs/contracts/events` (version per event envelope, breaking change = `<topic>.v2`, `libs/contracts/README.md`) | SemVer; policy in `libs/contracts/README.md` |
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
  `issueTenantAdminTemporaryPassword`, `.../temporary-password`); migration note in ADR-0035 (WP59). Since then
  additive minors only: core 3.1.0 events backfill (WP81), 3.2.0 / game 2.3.0 / athlete 2.4.0 season history (WP80),
  athlete 2.3.0 session plans and quick-add (WP78), core 3.3.0 academy requests (WP90).
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
just scan                      # gitleaks (full history) + OWASP dependency-check (NVD_API_KEY from .env, see .env.example)
deploy/helm/tests/run.sh       # lint, snapshots, kubeconform, policy assertions, gitleaks on rendered output
just e2e                       # journey on compose (docs/runbooks/e2e.md)
```
Also: ADR for any decision taken, handover notes in `docs/wp`, `docs/roadmap.md` updated. CI must be green on the
release commit in all five workflows (`ci`, `e2e` with the ZAP API scans, `images` with the SBOMs of section 3,
`codeql`, `semgrep`; the SAST/DAST gates and their expiring acceptances: ADR-0045, `docs/security/sast-dast.md`), and no
acceptance may be past its expiry.
Dependency bumps arrive as weekly grouped Dependabot PRs (`.github/dependabot.yml`: Maven with Quarkus in its own
group, pub for `apps/web`, GitHub Actions); `ci` and `e2e` run on each PR. Container base images, the chart's image
tags and the Envoy Gateway / kind pins are bumped by the weekly `bump-pins` PR (section 6). Ignored on purpose: semver-major updates of
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
The digest of the distroless `java25-debian13:nonroot` runtime in `deploy/containers/service.Containerfile` is bumped
by the weekly `bump-pins` PR (section 6; distroless has floating tags only, ADR-0054).

### SBOM
ADR-0043 (WP85). Every image job of `images.yml` writes CycloneDX SBOMs (Maven plugin 1.6, Trivy 1.7), validates each
against the schema of its version (`cyclonedx-cli`, the job fails on an invalid file) and keeps them as the workflow artifact `sbom-<image>` (90 days):

| Image | File | Content |
|---|---|---|
| core / game / athlete | `<svc>-maven.cdx.json` | the service's compile + runtime dependencies (`cyclonedx-maven-plugin`, profile `sbom`, run in the image's Maven stage) |
| core / game / athlete | `<svc>-image.cdx.json` | the whole image: the distroless Debian packages (ADR-0054, before it UBI), the JDK, every jar (Trivy) |
| web | `web-image.cdx.json` | the image: Alpine/nginx packages (Trivy; the Flutter bundle carries no package metadata) |
| pdf-service | `pdf-service-image.cdx.json` | the image: Debian packages of the distroless base and the crates of the `cargo auditable` binary (Trivy; WP111) |
| finance-service | `finance-service-image.cdx.json` | the image: the static Go binary's modules (Trivy; WP118) |

When the job pushes (main, `IMAGE_REGISTRY` set) it attaches each file to the pushed digest as an OCI referrer (ORAS,
artifact type `application/vnd.cyclonedx+json`; on ghcr.io via the referrers tag `sha256-<digest>`). Read them back:
```bash
img=ghcr.io/<owner>/hoops-academy/core-service@sha256:<digest>
oras=ghcr.io/oras-project/oras:v1.4.0     # scripts/sbom.sh pins the digest
podman run --rm "$oras" discover --artifact-type application/vnd.cyclonedx+json "$img"   # the SBOMs' digests
podman run --rm -v "$PWD:/w" -w /w "$oras" pull -o sbom "ghcr.io/<owner>/hoops-academy/core-service@<SBOM digest>"
```
(private packages: add `-v $REGISTRY_AUTH_FILE:/auth.json:ro --registry-config /auth.json`). Locally, the same steps
as CI (Podman; Trivy, cyclonedx-cli and ORAS run in pinned containers):
```bash
scripts/build-images.sh core-service                            # or podman build ... as images.yml does
scripts/sbom.sh maven core-service target/sbom                  # Maven SBOM from the image build's cache
scripts/sbom.sh generate core-service localhost/hoops/core-service:dev target/sbom   # image SBOM + validate all
scripts/sbom.sh generate web localhost/hoops/web:dev target/sbom
scripts/sbom.sh validate target/sbom
```
No signed attestation yet (no cosign / `actions/attest-sbom`, ADR-0043). `trivy sbom target/sbom/<file>` scans an SBOM
for vulnerabilities without the image.

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
Edge prerequisites (ADR-0031): the cluster runs Envoy Gateway (kind pins v1.10.0 with Gateway API v1.6.1 CRDs,
`deploy/kind/up.sh`) and provides a GatewayClass (default name `envoy-gateway`; `--set gateway.gatewayClass.create=true`
renders one). The chart creates the Gateway `hoops` and the HTTPRoutes; for HTTPS create a `kubernetes.io/tls` Secret
first (e.g. cert-manager) and set `gateway.tls.enabled=true`, `gateway.tls.certificateRefs[0].name=<secret>`,
`gateway.hostname=<host>`, `global.publicUrl` / `keycloak.publicUrl=https://<host>`; behind a load balancer that appends
`X-Forwarded-For` set `gateway.clientIPDetection.numTrustedHops`. The Gateway is ready when
`kubectl -n hoops get gateway hoops` shows `PROGRAMMED True`; its address is the Envoy Service in `envoy-gateway-system`.
Values renamed in chart 0.2.0: `ingress.*` -> `route.*`, `networkPolicy.ingressControllerNamespace` -> `gatewayNamespace`.

Global rate limits (chart 0.3.0, ADR-0033): the rate-limit policies are global, so Envoy Gateway must run its rate
limit service with a Redis backend. The cluster operator owns the Envoy Gateway install; these are the values kind and the cloud VM pin
in `deploy/lib/platform.sh` (`install_envoy_gateway`):
```bash
helm upgrade --install eg oci://docker.io/envoyproxy/gateway-helm --version v1.10.0 -n envoy-gateway-system --reuse-values \
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
cluster (`external-secrets.io/v1`; kind pins v2.15.0) and a store for the platform's secret manager, set
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
(new env). On a **fresh** install the bootstrap Job runs after the services are up; since core 3.1.0 (WP81) core's
publisher replaces its producer after consecutive failed sends, so it recovers by itself once its broker user exists
(no restart needed). Check: `curl -s <public url>/api/core/q/health/ready` shows `outbox-publisher` `UP` with `state` `OK`
(`DEGRADED` = no broker), and `docs/runbooks/events.md` "Kubernetes (chart, WP71)".

Rotation without manual restarts (chart 0.8.0, WP87, ADR-0012 amendment): `global.reloader.enabled=true` annotates every
Deployment/StatefulSet that reads a Secret (core, game, athlete, keycloak, ratelimit-redis, redpanda) with
`secret.reloader.stakater.com/auto: "true"`; a Stakater Reloader controller in the cluster then rolls them when one of
those Secrets changes (an ESO refresh or a re-applied Secret). The chart does not install Reloader: install it like
`deploy/lib/platform.sh` does for kind and the cloud VM (pinned chart and image digest, `reloader.watchGlobally=false` with `reloader.namespaces` = the
release namespace and `envoy-gateway-system`, `ignoreConfigMaps`, `ignoreJobs`, `ignoreCronJobs`, `reloadStrategy=annotations`),
and give Envoy Gateway's `rateLimitDeployment` the same annotation (`patch`, see `install_envoy_gateway` in `deploy/lib/platform.sh`). Without a
controller the annotation does nothing and section E of `rotate-secrets.md` lists the manual restarts. Upgrading from 0.7.0
rolls every pod once (chart labels in the ConfigMap checksums). Check: `kubectl -n hoops-reloader logs deploy/reloader-reloader`
starts with `Watching scoped namespaces: ...` and logs each workload it rolls after a rotation.

Observability (chart 0.9.0, WP86, ADR-0046): `global.observability.enabled=true` renders the OpenTelemetry collector
(`otel-collector`, OTLP gRPC 4317 / HTTP 4318, traces and logs, no metrics) and points the three services at it
(`global.observability.tracesSampleRatio`, default `0.1`; `global.observability.environment` for
`deployment.environment.name`). Since chart 0.13.0 (WP120) kind runs one Grafana LGTM pod (`observability.lgtm.enabled`,
dev only, 24 h retention, metrics through the collector) and the cloud values keep the in-memory Jaeger
(`observability.jaeger.enabled`); neither is a production backend. For a real environment send
the collector's output to the platform's backend: `observability.collector.exporters` and `pipelineExporters`
(`traces`, `logs`, and `metrics` since 0.13.0), credentials through `observability.collector.secretEnv` (Secrets created first; Reloader rolls the
collector on a rotation) and the backend's address in `observability.collector.networkPolicy.extraEgress`; or set
`observability.collector.enabled=false` and `global.observability.otlpEndpoint` to the platform's own collector. The
edge span needs the `EnvoyProxy` tracing settings of `deploy/kind/up.sh` (by the collector's DNS name, not
`backendRefs`). Check: `runbooks/observability.md`.

Switches in one place (all default off; subcharts see only `global`; `values-kind.yaml` turns on the events, Reloader and
observability, `up.sh --eso` the External Secrets):

| Value | Effect | Since |
|---|---|---|
| `events.enabled` + `global.events.enabled` (must match) | Redpanda, its bootstrap Job and the services' broker wiring | 0.6.0 / 0.7.0 |
| `game.rosterSource` / `athlete.rosterSource` | `rest` (default) or `replica` (needs the events) | 0.7.0 |
| `global.reloader.enabled` | Reloader annotation on every workload that reads a Secret (controller installed separately) | 0.8.0 |
| `global.observability.enabled` | OpenTelemetry collector and the services' OTLP export | 0.9.0 |
| `externalSecrets.enabled` | `ExternalSecret`s instead of hand-made Secrets | 0.5.0 |

Mail (core 3.3.0, WP90, ADR-0044): core sends the academy-request decision e-mails over SMTP. The chart does **not**
set core's mail keys yet (open item in `docs/wp/FOLLOW-UPS.md`); until it does, give them through the core subchart's
`env` / `secretEnv` values, else core falls back to `localhost:1025` and the mails fail (the decisions still work,
`notifiedAt` stays empty):

| Key | kind (Mailpit) | Real server |
|---|---|---|
| `SMTP_HOST` | `mailhog` (the Mailpit Service keeps the realm's name) | the relay's host |
| `SMTP_PORT` | `"1025"` | e.g. `"587"` |
| `SMTP_START_TLS` | `OPTIONAL` | `REQUIRED` |
| `MAIL_FROM` | any address | the academy platform's sender |
| `HOOPS_PUBLIC_URL` | `{{ .Values.global.publicUrl }}` | the public URL (links in the mails) |
| `SMTP_USERNAME` | — | the relay login |
| `SMTP_PASSWORD` | — | `secretEnv` from a Secret, e.g. `hoops-smtp` key `password` |

Order that matters: Secrets -> CNPG clusters -> Keycloak -> services (Flyway runs on start as `*_migrator`) -> web.
Services restart a few times on first install until `hoops-db-rw` is ready; they converge by themselves (WP18).
Database migrations are forward-only; roll back by deploying a compatible previous image or restoring (`backup-restore.md`).
Run `deploy/kind/smoke.sh core game athlete` (or the equivalent checks) after every deploy; on kind,
`deploy/kind/ratelimit-check.sh` proves the edge rate limits (it leaves this client limited for up to a minute).

## 5. Tag and record
(design) Tag the commit `vX.Y.Z` after the images for that SHA exist and the smoke test passes; record the contract
versions and the image SHAs in the release notes. Move resolved items in `docs/wp/FOLLOW-UPS.md` to "Resolved".

## 6. Pins and bumps
Dependabot covers Maven, pub and GitHub Actions. Everything else that is pinned is bumped by `scripts/bump-pins.sh`
(helper `scripts/bump_pins.py`, stdlib only; its header holds the inventory), run weekly by `.github/workflows/bump-pins.yml`
(Mondays, or manual dispatch), which opens one PR `chore/bump-pins` labelled `dependencies`. It never pushes to main.

| Pin | File | Resolved from |
|---|---|---|
| distroless java25-debian13:nonroot digest | `deploy/containers/service.Containerfile` | registry (skopeo, floating tag) |
| Maven builder image tag + digest (newest tag published for amd64 and arm64) | `deploy/containers/service.Containerfile` | registry (WP152) |
| nginx-unprivileged tag (even minors) + digest | `deploy/containers/web.Containerfile` | registry |
| cirruslabs/flutter tag + digest (its last tag is 3.44.0: the stage builds nothing today) | `deploy/containers/web.Containerfile` | registry |
| redis, mailpit tag + digest | `deploy/helm/hoops/values.yaml` | registry |
| Keycloak tag + digest; chart `appVersion` and the realm tests' image name follow it | `infra/compose/compose.yaml`, the `keycloak` sub-chart (`values.yaml`, `Chart.yaml`), `TestRealm.java` | registry |
| CNPG database image digest (for the tag of the PostgreSQL pin below) | the `databases` sub-chart's `values.yaml` | registry |
| Maven version + `distributionSha256Sum` of the wrapper | `.mvn/wrapper/maven-wrapper.properties` | Maven Central (the zip is checked against Central's SHA-512) |
| Flutter version + SHA-256 of its linux archive | `.github/actions/setup-flutter/action.yml` | `releases_linux.json` of the stable channel |
| SHA-256 of each Semgrep registry ruleset | `.semgrep/registry-rules.txt` | semgrep.dev |
| pre-commit hook repos: commit SHA + tag | `.pre-commit-config.yaml` | `git ls-remote` (the peeled tag) |
| PostgreSQL minor (one pin, a flavour per registry; WP142, WP144) | `infra/compose/compose.yaml`, the `databases` sub-chart's `values.yaml`, `PostgresRlsResource` (common-quarkus test-jar), finance's `pgtest.go`, `images.yml` | Docker Hub `library/postgres`; a minor is applied only when Docker Hub (`-trixie`) and CloudNativePG (`-minimal-trixie`) both publish it, a new major only with `--major` and the runbook [a new PostgreSQL major](postgresql-major.md) (ADR-0073) |
| redpanda tag + digest (one pin) | `values.yaml`, `infra/compose/compose.yaml`, finance-service's `consumer_test.go` | registry |
| redpanda tag of the Dev Services | common-quarkus `microprofile-config.properties` | registry |
| Trivy tag + digest | `ci.yml`, `.github/actions/image-publish/action.yml`, `scripts/sbom.sh`, `infra/tofu/check.sh` | Docker Hub |
| cyclonedx-cli, ORAS tag + digest | `scripts/sbom.sh` | registry |
| Semgrep tag + digest | `semgrep.yml` | Docker Hub |
| ZAP `stable` digest | `ci.yml`, `scripts/zap-api-scan.sh` | ghcr.io |
| Envoy Gateway; CloudNativePG version + SHA-256 of its release manifest (`CNPG_MANIFEST_SHA256`, checked by `install_cnpg` before `kubectl apply`) | `deploy/lib/platform.sh` (sourced by `deploy/kind/up.sh`, `deploy/cloud/install.sh`) | GitHub releases (the manifest's digest is the one GitHub records for the asset) |
| External Secrets | `deploy/kind/up.sh` | GitHub releases |
| Reloader chart version + digest + image digest | `deploy/lib/platform.sh` | ghcr.io (chart appVersion names the image) |

Not in the inventory, bumped by hand and each named in as few files as possible, with a test that keeps the copies equal
(`scripts/tests/test_toolchain_pins.py`, `test_jdk_pins.py`): Go (`go.mod`, `.github/actions/setup-go`,
`finance.Containerfile`), Rust (`rust-toolchain.toml`, `pdf.Containerfile` twice), the JDK (`pom.xml`, the Containerfile,
`.github/actions/setup-java`, `scripts/env.sh`), the pinned Chrome (`.github/actions/setup-pinned-chrome`), kubeconform
and gitleaks (`.github/actions/setup-chart-tools`, with the SHA-256 of their release archives).

A pin repeated in several files is one inventory entry over all of them (`scripts/tests/test_mirrored_pins.py`), so the
copies that `deploy/helm/tests/run.sh` and `just tofu-check` compare move together. What is recorded from the pins, the
chart snapshots and the ExternalSecret schema, is re-recorded by the workflow in the same PR; after a local `--apply` run
`deploy/helm/tests/schemas/update-eso.sh` and `deploy/helm/tests/run.sh --update` yourself.

By hand, hashes held by a tool and not by `bump_pins.py`: the docs site's Python dependencies (`config/docs/requirements.txt`,
every file of every version by SHA-256, installed with `pip install --require-hashes`; refresh with
`python3 -I scripts/docs_requirements.py`, Dependabot keeps the hashes of its own PRs). Not pinned by digest, on purpose
and listed in `scripts/tests/test_supply_chain_pins.py` (`BY_TAG`): the dev database and proxy of the local stack, the
test database of the finance image check, the Lighthouse images of a local run; and `apk upgrade` plus the nginx.org
package of `web.Containerfile`, which fetch signed packages at build time (the Trivy gate fails the image on a fixable
HIGH or CRITICAL; drop both once the base image has caught up). ESO and the Envoy Gateway chart are pinned by version only.

A Flutter bump (the `setup-flutter` pin) or a Dependabot pub PR resolved with another SDK can fail `flutter pub get
--enforce-lockfile` in CI: the lock file must be re-resolved with the SDK the pin names (`cd apps/web && flutter pub get`,
commit `pubspec.lock`), in the same PR.

An agent's weekly PR for a Semgrep ruleset hash is a review item: new registry rules can add findings. Until it is merged
the `semgrep` workflow stops with "changed upstream" (`scripts/semgrep-rules.sh`); that is the pin working.

Not bumped: the Gateway API version (it must match the Envoy Gateway
compatibility matrix, ADR-0031: change it by hand together with Envoy Gateway).
Same major only; `--major` allows a major and the check output says when one exists.

Locally (needs Podman; skopeo runs in a pinned container, no install):
```
scripts/bump-pins.sh --check            # lists outdated pins, exit 1 if any
scripts/bump-pins.sh --apply            # rewrites the files in place; review with git diff
```
Try `--apply` on a copy with `--root <dir>`. The scripts fail (exit 2) when a pin's format no longer matches its pattern:
keep the `NAME="value"` / `tag: x` shapes, or update the pattern in `scripts/bump_pins.py`.

Before merging a bump PR: `ci` and `e2e` green (a PR opened with GITHUB_TOKEN does not start them: close and reopen it).
Never merge it on a red `helm-chart-tests` or `tofu-check`: on 2026-11-22 PR #6 was, and main stayed red until the copies
were aligned by hand.
A bump of Envoy Gateway, CloudNativePG or External Secrets also needs the chart and kind proofs: `deploy/helm/tests/run.sh`
(for ESO regenerate the CRD schemas with `deploy/helm/tests/schemas/update-eso.sh`), then `just kind-up` and the isolation check on
the new cluster. A Reloader bump needs `deploy/helm/tests/run.sh` (it asserts the digest pins in `deploy/lib/platform.sh`) and a kind run.
One-time repository setup: Settings > Actions > "Allow GitHub Actions to create and approve pull requests", and a
`dependencies` label.
