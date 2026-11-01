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
- [ ] `just kind-up && tilt up` from a clean machine script reaches all-green; `helm lint` + `helm template` snapshot tests
- [ ] `curl https://localhost:8443/api/core/q/health/ready` (or http 8080) ok through ingress; OIDC issuer consistent with ingress host
- [ ] `helm template | gitleaks detect --pipe` clean; no secret literal committed; images run as non-root (`podman inspect`)
- [ ] e2e smoke (`/api/core/me` with a real token) passes against the cluster
