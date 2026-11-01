# WP16 — kind + Helm + Tilt + CloudNativePG + Keycloak-in-kind + secrets

Model: Opus. Depends on: WP1 and at least one service image (core). Lane INFRA (start early). Skills: podman-dev-env,
owasp-security (config), verification-before-completion.

## Scope
- `deploy/kind/kind-config.yaml` (one control-plane node, extraPortMappings 8080→80, 8443→443 of ingress), `up.sh`
  (`KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster`, install ingress-nginx, CNPG operator, create namespace,
  secrets from `.env` via `kubectl create secret … --dry-run=client | kubectl apply`), `down.sh`.
- CNPG: `hoops-db` Cluster (1 instance, `postInitApplicationSQL` from infra/db/init SQL, managed roles with
  passwordSecret per role), `keycloak-db` Cluster.
- Helm: `deploy/helm/hoops` umbrella with subcharts `hoops-service` (library-style: Deployment, Service, Ingress path,
  ConfigMap, probes, resources, SecurityContext runAsNonRoot/readOnlyRootFilesystem, NetworkPolicy, HPA optional,
  `existingSecret` refs), instances `core`, `game`, `athlete`, `web` (nginx-unprivileged serving Flutter build),
  `keycloak` (official image, production mode, realm import from ConfigMap, admin password Secret, readiness with
  generous initialDelay), values for kind; `values-local.yaml` ignored.
- Images: multi-stage `Containerfile` per service (or Quarkus Jib `buildTar`) — non-root UBI9 OpenJDK 21 runtime; Flutter
  nginx image; `scripts/build-images.sh` (podman) + `kind load image-archive`.
- `Tiltfile`: `custom_build` per service (Jib tar → kind load), Flutter image build, Helm release with values, port
  forwards, resource groups; live update optional.
- `docs/runbooks/kind.md`; ADR for External Secrets Operator path beyond local.

## Acceptance
- [x] `just kind-up && tilt up` from a clean machine script reaches all-green; `helm lint` + `helm template` snapshot tests — *verified live for game + athlete + web + Keycloak + both CNPG clusters (`tilt ci` → "SUCCESS. All workloads are healthy."); core-service chart/image templated identically but not built/deployed (core did not belong to this lane yet). See Handover.*
- [ ] `curl https://localhost:8443/api/core/q/health/ready` (or http 8080) ok through ingress; OIDC issuer consistent with ingress host — *partial: ports are 8090/8453 (compose owns 8080). Issuer `http://localhost:8090/auth/realms/academy` consistent (discovery + token `iss`) ✔. Health route `/api/<svc>/q/health/*` is routed and rewritten (service answers with `instance: /q/health/ready`) but game/athlete return 404 because they lack `quarkus-smallrye-health`; core not deployed.*
- [x] `helm template | gitleaks detect --pipe` clean; no secret literal committed; images run as non-root (`podman inspect`) — *gitleaks clean on rendered output and on all WP16 files; `User=185` (services) / `101` (web).*
- [ ] e2e smoke (`/api/core/me` with a real token) passes against the cluster — *not possible yet (core not deployed). Substitute verified: scripted PKCE login of `admin1` through the ingress → user token accepted by game-service, which answers 503 `UPSTREAM_UNAVAILABLE` from its RosterPort (core absent) — the designed behaviour.*

## Handover

### Built
- **Images** (`deploy/containers/`): `service.Containerfile` (build-arg `SERVICE`; stage `app-maven` =
  `maven:3-eclipse-temurin-21`, `-pl services/$SERVICE -am package -DskipTests` with a `hoops-m2` cache mount; stage
  `app-host` copies a host-built `target/quarkus-app`; runtime `ubi9/openjdk-21-runtime`, uid 185, fast-jar layered
  lib→app, `JAVA_OPTS_APPEND=-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError`, `EXPOSE` service port).
  `web.Containerfile` (default: bundle built on the host by `flutter build web`; optional `WEB_SOURCE=flutter` stage on
  `ghcr.io/cirruslabs/flutter:stable`; runtime `nginx-unprivileged:1.30-alpine`, uid 101) + `web-nginx.conf`
  (`/healthz`, `/internal` → 403, no-cache for index/service worker, security headers). Context filters
  `*.containerignore` (passed with `--ignorefile`; root `.containerignore` left alone).
- `scripts/build-images.sh` (`--from-host`, `--no-package`, `--web-in-container`, `--skip-web-build`, `--tag`,
  `--kind-load` via `podman save` → temp archive → `kind load image-archive`, `--push` with `IMAGE_REGISTRY`).
- **kind** (`deploy/kind/`): `kind-config.yaml` (cluster `hoops`, 127.0.0.1:8090→80, 8453→443, `ingress-ready`
  label), `up.sh` (cluster, ingress-nginx `controller-v1.15.1`, CNPG `1.30.1`, ns `hoops`, Secrets; `--deploy` builds,
  loads and `helm upgrade --install --wait`), `down.sh`, `secrets.sh` (13 Secrets from `.env` → YAML on stdout; values
  via process substitution, never argv/disk; fails on missing `.env`/keys), `seed-users.sh` (kcadm through
  `kubectl exec`, credentials over stdin, idempotent), `smoke.sh` (pods, issuer, `/internal` 403, health routes,
  `/q/metrics` not exposed, client-credentials token `iss`, 401 anonymous vs. accepted token).
- **Helm** (`deploy/helm/hoops`): umbrella with vendored subcharts `databases` (CNPG `hoops-db`: 1 instance, 2Gi,
  PG 17, db `hoops`, owner `app`, init SQL via `postInitApplicationSQLRefs` ConfigMap, `managed.roles` ×7 with
  `passwordSecret` and attributes mirroring the SQL — `inherit:false`, connection limits; `keycloak-db` with
  `initdb.secret`; NetworkPolicy), `keycloak` (26.8.1 `start --import-realm`, `KC_HOSTNAME=http://localhost:8090/auth`,
  `KC_HOSTNAME_BACKCHANNEL_DYNAMIC=true`, proxy headers, health on 9000 `/auth/health/*`, readiness delay 60 s, realm
  ConfigMap with redirect URIs rewritten to `publicUrl`, client secrets from Secrets, NetworkPolicy),
  `hoops-service` (×3 aliases core/game/athlete: Deployment, Service, ConfigMap env, `secretEnv`/`existingSecret`,
  Ingress path list, optional health Ingress (regex+rewrite, only `/q/health[/live|ready|started]`), probes http|tcp,
  resources, non-root/RO rootfs/drop ALL/seccomp, `/tmp` emptyDir, NetworkPolicy (ingress-nginx ns + same ns), PDB
  and HPA optional), `web` (SPA at `/`, `/internal` routed to its 403 location). `values.yaml`, `values-kind.yaml`.
  The realm JSON and init SQL are **symlinks** into the charts (single source of truth; Helm follows them).
- `deploy/helm/tests/run.sh` + 4 golden snapshots + `values/service-all-features.yaml`: lint (strict), snapshots,
  kubeconform (incl. CNPG CRD from the datree catalog), security assertions, gitleaks on rendered output.
- `Tiltfile` (custom_build per image → build-images.sh + kind load, `skips_local_docker`, no push; `flutter build web`
  local_resource; `k8s_yaml(helm(...))` with values-kind (+ optional values-local); Secrets from `secrets.sh` kept in
  memory; resource graph secrets → databases → keycloak → services | web; port-forwards 18080-18083; flags
  `--services`, `--from-host`, `--skip-flutter`; positional resource names).
- `justfile`: `kind-up *ARGS`, `kind-down`, `tilt *ARGS="up"`. `.github/workflows/images.yml` (matrix build + non-root
  check + Trivy `HIGH,CRITICAL --ignore-unfixed` gate + push only if `vars.IMAGE_REGISTRY` set; chart tests job).
- `docs/runbooks/kind.md`, `docs/adr/0012-kubernetes-secrets-strategy.md` (charts reference Secrets only; local from
  `.env`; ESO beyond local; Sealed Secrets / Helm-templated secrets / SOPS rejected).

### Verified (commands run, output read)
- `deploy/helm/tests/run.sh`: 5 charts lint OK, 4 snapshots match, kubeconform 74/74 valid (strict, k8s 1.34 schemas
  + CNPG CRD), all assertions OK, gitleaks clean → `ALL CHART TESTS PASSED`. gitleaks `--no-git` on every WP16 path:
  no leaks. `tilt alpha tiltfile-result`: evaluates without error.
- Images: `./mvnw -q -pl services/game-service,services/athlete-service package -DskipTests` OK; `build-images.sh
  --from-host --no-package` for game + athlete OK; **in-container Maven build** of game-service OK (10 min cold,
  ~1-2 min warm under Tilt); web image OK. `id -u` → 185/185/101; `podman inspect` `User=185`/`101`;
  `java -version` → 21.0.13; game image with `--read-only --tmpfs /tmp` starts until Flyway fails on the DB
  connection (no read-only FS errors); web image read-only + `--cap-drop ALL`: `/healthz` 200, `/` 200,
  `/internal/x` 403, headers present.
- Trivy (DB 2026-11-02): game/athlete — 15 HIGH in UBI9 OS packages, **0 fixable**, 0 in Java libs (CI gate with
  `--ignore-unfixed` passes); web on nginx 1.27-alpine had 58 fixable HIGH/CRITICAL → switched to 1.30-alpine: 3.
- **Live on rootless kind** (kindest/node v1.37.0, Ready after 17 s; rootful not needed): `up.sh` created ingress-nginx,
  CNPG, ns and 13 Secrets; Helm install and later `tilt ci` (twice: game+athlete subset, then game+athlete+web) →
  `SUCCESS. All workloads are healthy.`; all pods 1/1. CNPG: both clusters "healthy"; managed roles status
  `reconciled` ×7; `pg_authid`: login, NOINHERIT, NOBYPASSRLS, limits 50/50/50/10/-1, passwords set; schemas owned by
  the migrators; Flyway applied game (v2) and athlete migrations as `*_migrator`. `smoke.sh game athlete` →
  `SMOKE PASSED`: issuer `http://localhost:8090/auth/realms/academy` (also via https :8453), `/internal/x` 403,
  web 200, `/q/metrics` not exposed, client-credentials tokens `iss` = public URL and accepted by the services
  (anonymous 401, token 400 "X-Tenant-Id is required"). NetworkPolicy enforced: pod in ns `default` → game:8082
  BLOCKED, pod in ns `hoops` → CONNECTED. `seed-users.sh` twice: created ×6 then exists ×6. Scripted PKCE login of
  `admin1` (redirect URI `http://localhost:8090/`) → token → game answers 503 `UPSTREAM_UNAVAILABLE` (core absent).
- Cluster then deleted with `deploy/kind/down.sh` to free the shared machine (recreate: `just kind-up && just tilt`).

### Not verified / deviations
- **core-service**: chart values and image path are identical to game/athlete but the image was neither built nor
  deployed (another lane is building it). Its `/api/core/q/health/ready`, `/platform` route and `/api/core/me` e2e are
  untested.
- game-service and athlete-service lack `quarkus-smallrye-health` → `probes: {mode: tcp}` for them in `values.yaml`;
  their `/api/<svc>/q/health/*` ingress returns the service's 404. **Follow-up for those lanes:** add the extension,
  then delete the two `probes` overrides (the smoke check turns from WARN into ok).
- Ports 8090/8453 instead of the brief's 8080/8443 (compose owns 8080). HTTPS uses ingress-nginx's self-signed
  default cert; Keycloak's hostname stays http.
- Web base `nginx-unprivileged:1.30-alpine` instead of 1.27 (Trivy). Flutter-in-container stage written but not run.
- `.github/workflows/images.yml` not executed (no CI run from here); YAML parsed OK, download URLs checked (200).
- `apps/web/build/web` was deleted by another agent mid-run; my manual web image used a scratch copy of `apps/web`;
  Tilt's `flutter-build-web` later rebuilt `apps/web/build/web` in place (git-ignored output).
- shellcheck not installed → scripts only checked with `bash -n`.

### Decisions
- Symlinks (not copies, not `kubectl create configmap`) put the realm JSON and init SQL into the charts: one source of
  truth, `helm template` stays self-contained and snapshot-testable; the realm's compose URLs are rewritten at render.
- `/internal` blocked by routing it explicitly to the web nginx (403) — portable, no snippets (disabled by default in
  ingress-nginx); NetworkPolicies are the second layer. Health exposed by a separate regex/rewrite Ingress limited to
  `/q/health[/live|ready|started]`.
- CNPG init SQL via `postInitApplicationSQLRefs`: inline `postInitApplicationSQL` broke because Kubernetes `$(VAR)`
  expansion of container args turns `$$` into `$` (observed `syntax error at or near "$"`).
- `KC_HOSTNAME_BACKCHANNEL_DYNAMIC=true`: pods use `http://keycloak:8080/auth` for discovery/JWKS/tokens while the
  issuer stays the public URL. Keycloak keeps a writable root FS (`start` re-augments); follow-up: pre-built optimized
  image → `readOnlyRootFilesystem: true`.
- Image refs `localhost/hoops/<img>` (what Podman produces for `hoops/<img>`), matched verbatim in containerd.
- Secrets: ADR-0012.

### Open points / follow-ups
- game/athlete: add `quarkus-smallrye-health` (see above). core: build + deploy on kind and run `smoke.sh` (all
  three) + the `/api/core/me` e2e with a seeded user.
- Optimized Keycloak image; mailpit in kind if invitation e-mails must be tested (realm SMTP host `mailhog` is not
  deployed in kind); ESO manifests when a non-local cluster exists; production ingress choice (ingress-nginx is in
  retirement upstream).
- Game's problem `instance` showed `//api/game/matches` (double slash) for the 503 — worth a look in the game lane.
