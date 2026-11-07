#!/usr/bin/env bash
# Creates the Hoops Academy kind cluster (Podman provider) with Envoy Gateway (Gateway API), the CloudNativePG
# operator, namespace `hoops`, the Secrets from .env and a self-signed TLS Secret for the Gateway's HTTPS listener. Then either run `tilt up` (inner loop) or pass --deploy to build the
# images, load them into kind and `helm upgrade --install` the umbrella chart without Tilt.
# --eso (WP65, ADR-0012 amendment): no deploy/kind/secrets.sh; the External Secrets Operator (ESO_VERSION) is installed with
# a ClusterSecretStore `hoops` backed by one bootstrap Secret built from .env (deploy/kind/eso-store.sh), and the chart is
# deployed with externalSecrets.enabled=true, so ESO writes every Secret (`tilt up -- --eso` does the same with Tilt).
# Pick the mode when the cluster is created; to switch, `just kind-down` first.
# Stakater Reloader (WP87) is installed in both modes: pods roll by themselves when a Secret they read changes.
# The chart's event broker (WP66, ADR-0036: Redpanda, events.enabled in values-kind.yaml) comes with the deploy; its logins
# are Secrets from .env (REDPANDA_*_PASSWORD) like every other one, its node pulls the pinned image itself.
#
#   deploy/kind/up.sh [--deploy] [--from-host] [--eso]
set -euo pipefail
cd "$(dirname "$0")/../.."

CLUSTER="${KIND_CLUSTER:-hoops}"
NS="${HOOPS_NAMESPACE:-hoops}"
# Envoy Gateway v1.9.x bundles and needs Gateway API v1.6.1 (CRDs installed by its chart; compatibility matrix:
# https://gateway.envoyproxy.io/news/releases/matrix/). Bump both together, see docs/adr/0031-gateway-api.md.
ENVOY_GATEWAY_VERSION="v1.9.3"
GATEWAY_API_VERSION="v1.6.1"
CNPG_VERSION="1.30.1"
CNPG_BRANCH="release-${CNPG_VERSION%.*}"
# External Secrets Operator (--eso): API external-secrets.io/v1. The chart tests validate the ExternalSecrets against this
# version's CRD (deploy/helm/tests/schemas, regenerate with update-eso.sh when bumping).
ESO_VERSION="v2.14.0"
# Stakater Reloader (WP87, ADR-0012 amendment): rolls every Deployment/StatefulSet annotated with
# secret.reloader.stakater.com/auto (the chart with global.reloader.enabled, on in values-kind.yaml; envoy-ratelimit through
# EG_VALUES) when a Secret it reads changes, whether ESO refreshed it or secrets.sh re-applied it. Pinned by chart version +
# digest and image digest (v1.4.23). Least privilege: namespaced Roles in $NS and envoy-gateway-system only (no
# ClusterRole), Secrets only (ConfigMap changes already roll through the chart's checksum annotations), no Jobs/CronJobs,
# reload strategy `annotations` (a pod-template annotation, not an injected env var).
RELOADER_CHART_VERSION="2.2.19"
RELOADER_CHART_DIGEST="sha256:dfa9fd167fc7ea3a2542de23f8d23c961d79407929f38c985d5cecfa74316142"
RELOADER_IMAGE_DIGEST="sha256:82c80a15fdba22f738642553159f9fb37baf9e4d1edfeb798e8c48d87767f410"
# Global rate limiting (WP40, ADR-0033): Envoy Gateway deploys its rate limit service (Deployment envoy-ratelimit) with
# a Redis backend; values-kind.yaml deploys that Redis in namespace $NS (rateLimit.redis.enabled). failClosed=false:
# when the rate limit service or Redis does not answer within the timeout, requests pass (fail open). Other clusters
# set the same keys in the operator's Envoy Gateway install (docs/runbooks/release.md section 4).
# Redis ACL (WP46): the rate limit pods log in as user `ratelimit` with REDIS_AUTH=<user>:<password> from Secret
# envoy-ratelimit-redis-auth (deploy/kind/secrets.sh). Not in the URL: envoyproxy/ratelimit logs the URL unmasked
# ("Creating single with urls ..."), so redis.urlRef with credentials would leak the password into its log.
EG_VALUES=(
  --set config.envoyGateway.rateLimit.backend.type=Redis
  --set "config.envoyGateway.rateLimit.backend.redis.url=ratelimit-redis.${NS}.svc.cluster.local:6379"
  --set-json 'config.envoyGateway.provider.kubernetes.rateLimitDeployment.container.env=[{"name":"REDIS_AUTH","valueFrom":{"secretKeyRef":{"name":"envoy-ratelimit-redis-auth","key":"auth"}}}]'
  --set config.envoyGateway.rateLimit.failClosed=false
  --set config.envoyGateway.rateLimit.timeout=100ms
  --set config.envoyGateway.provider.kubernetes.rateLimitDeployment.container.resources.requests.cpu=10m
  --set config.envoyGateway.provider.kubernetes.rateLimitDeployment.container.resources.requests.memory=32Mi
  --set config.envoyGateway.provider.kubernetes.rateLimitDeployment.container.resources.limits.memory=128Mi
  # WP87: Reloader restarts envoy-ratelimit when envoy-ratelimit-redis-auth changes (RATELIMIT_REDIS_PASSWORD rotation)
  --set-json 'config.envoyGateway.provider.kubernetes.rateLimitDeployment.patch={"type":"StrategicMerge","value":{"metadata":{"annotations":{"secret.reloader.stakater.com/auto":"true"}}}}'
)
DEPLOY=0 ESO=0 BUILD_FLAGS=()
for a in "$@"; do
  case "$a" in
    --deploy) DEPLOY=1 ;;
    --eso) ESO=1 ;;
    --from-host) BUILD_FLAGS+=(--from-host) ;;
    *) echo "up.sh: unknown argument $a" >&2; exit 2 ;;
  esac
done

for t in podman kind kubectl helm openssl jq; do command -v "$t" >/dev/null || { echo "up.sh: $t not found" >&2; exit 1; }; done
[ -f .env ] || { echo "up.sh: .env missing (cp .env.example .env and set values)" >&2; exit 1; }
# shellcheck disable=SC1091
source scripts/env.sh >/dev/null
export KIND_EXPERIMENTAL_PROVIDER=podman

step() { printf '\n==> %s\n' "$*"; }

step "kind cluster '$CLUSTER'"
if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  echo "exists"
else
  kind create cluster --config deploy/kind/kind-config.yaml --name "$CLUSTER" --wait 180s
fi
kubectl config use-context "kind-$CLUSTER" >/dev/null
K=(kubectl --context "kind-$CLUSTER")

# Secrets first (ADR-0012): the rate limit pods of Envoy Gateway read their Redis login from envoy-gateway-system.
if [ "$ESO" = 0 ]; then
  step "namespaces $NS + envoy-gateway-system, secrets from .env"
  for n in "$NS" envoy-gateway-system; do "${K[@]}" create namespace "$n" --dry-run=client -o yaml | "${K[@]}" apply -f -; done
  HOOPS_NAMESPACE="$NS" deploy/kind/secrets.sh | "${K[@]}" apply -f -
else
  # The ExternalSecrets come with the chart, so the Secrets appear only once it is deployed; until then the envoy-ratelimit
  # pods wait for envoy-ratelimit-redis-auth (CreateContainerConfigError), which resolves itself.
  step "namespaces $NS + envoy-gateway-system + hoops-secret-store, External Secrets Operator $ESO_VERSION"
  for n in "$NS" envoy-gateway-system hoops-secret-store; do
    "${K[@]}" create namespace "$n" --dry-run=client -o yaml | "${K[@]}" apply -f -
  done
  helm --kube-context "kind-$CLUSTER" upgrade --install external-secrets oci://ghcr.io/external-secrets/charts/external-secrets \
    --version "${ESO_VERSION#v}" -n external-secrets --create-namespace --wait --timeout 15m
  HOOPS_NAMESPACE="$NS" deploy/kind/eso-store.sh | "${K[@]}" apply -f -
  "${K[@]}" wait clustersecretstore/hoops --for=condition=Ready --timeout=120s
fi

step "Stakater Reloader (chart $RELOADER_CHART_VERSION, watches $NS and envoy-gateway-system)"
helm --kube-context "kind-$CLUSTER" upgrade --install reloader \
  "oci://ghcr.io/stakater/charts/reloader:${RELOADER_CHART_VERSION}@${RELOADER_CHART_DIGEST}" \
  -n hoops-reloader --create-namespace --wait --timeout 10m \
  --set image.digest="$RELOADER_IMAGE_DIGEST" \
  --set reloader.watchGlobally=false --set-json "reloader.namespaces=[\"$NS\",\"envoy-gateway-system\"]" \
  --set reloader.ignoreConfigMaps=true --set reloader.ignoreJobs=true --set reloader.ignoreCronJobs=true \
  --set reloader.reloadStrategy=annotations --set reloader.readOnlyRootFileSystem=true \
  --set-json 'reloader.deployment.containerSecurityContext={"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}' \
  --set reloader.deployment.resources.requests.cpu=10m --set reloader.deployment.resources.requests.memory=32Mi \
  --set reloader.deployment.resources.limits.memory=128Mi

step "Envoy Gateway $ENVOY_GATEWAY_VERSION (Gateway API $GATEWAY_API_VERSION CRDs)"
# `helm upgrade` never updates CRDs: on a version bump apply them first (docs/adr/0031-gateway-api.md, upgrade path).
eg_config() { "${K[@]}" -n envoy-gateway-system get configmap envoy-gateway-config -o jsonpath='{.data}' 2>/dev/null || true; }
eg_config_before=$(eg_config)
helm --kube-context "kind-$CLUSTER" upgrade --install eg oci://docker.io/envoyproxy/gateway-helm \
  --version "$ENVOY_GATEWAY_VERSION" -n envoy-gateway-system --create-namespace "${EG_VALUES[@]}"
# The chart has no checksum annotation on the controller, so a changed config would not roll it: restart it when the
# config changed on an existing install (e.g. a cluster created before WP40 gaining the rate limit backend).
if [ -n "$eg_config_before" ] && [ "$eg_config_before" != "$(eg_config)" ]; then
  "${K[@]}" -n envoy-gateway-system rollout restart deployment/envoy-gateway
fi

step "CloudNativePG operator $CNPG_VERSION"
"${K[@]}" apply --server-side --force-conflicts \
  -f "https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/${CNPG_BRANCH}/releases/cnpg-${CNPG_VERSION}.yaml"

# Single replica on kind: no leader election (WP86). Under VM load the operator lost its lease ("leader election lost",
# CrashLoopBackOff with a 5-minute backoff) and no database came up; kube-controller-manager and kube-scheduler run without
# it too (kind-config.yaml, WP87). The apply above resets the flag on a re-run, so this patch rolls the operator once more.
cnpg_args=$("${K[@]}" -n cnpg-system get deployment cnpg-controller-manager -o json \
  | jq -c '.spec.template.spec.containers[0].args | map(if . == "--leader-elect" then "--leader-elect=false" else . end)')
"${K[@]}" -n cnpg-system patch deployment cnpg-controller-manager --type json \
  -p "[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/args\",\"value\":$cnpg_args}]"

step "waiting for Envoy Gateway and CNPG (first run pulls images; slow links take minutes)"
"${K[@]}" -n envoy-gateway-system rollout status deployment/envoy-gateway --timeout=900s
"${K[@]}" -n cnpg-system rollout status deployment/cnpg-controller-manager --timeout=900s
crd_version=$("${K[@]}" get crd gateways.gateway.networking.k8s.io \
  -o jsonpath='{.metadata.annotations.gateway\.networking\.k8s\.io/bundle-version}')
[ "$crd_version" = "$GATEWAY_API_VERSION" ] \
  || { echo "up.sh: Gateway API CRDs are $crd_version, Envoy Gateway $ENVOY_GATEWAY_VERSION needs $GATEWAY_API_VERSION" >&2; exit 1; }
echo "Gateway API CRDs $crd_version"

step "TLS secret for the Gateway"
# Self-signed certificate for https://localhost:8453 (the Gateway's HTTPS listener). Generated once per cluster in a
# temporary directory that is removed again; never committed. Keycloak's issuer stays the http URL.
if ! "${K[@]}" -n "$NS" get secret hoops-gateway-tls >/dev/null 2>&1; then
  tls_dir=$(mktemp -d); trap 'rm -rf "$tls_dir"' EXIT
  openssl req -x509 -newkey rsa:2048 -nodes -days 365 -subj "/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" -keyout "$tls_dir/tls.key" -out "$tls_dir/tls.crt" 2>/dev/null
  "${K[@]}" -n "$NS" create secret tls hoops-gateway-tls --cert="$tls_dir/tls.crt" --key="$tls_dir/tls.key"
  rm -rf "$tls_dir"
fi

if [ "$DEPLOY" = 1 ]; then
  step "images -> kind"
  KIND_CLUSTER="$CLUSTER" scripts/build-images.sh "${BUILD_FLAGS[@]}" --kind-load
  step "helm upgrade --install hoops"
  scripts/sync-chart-files.sh   # realm JSON + init SQL copies inside the charts (no symlinks; helm package works)
  VALUES=(-f deploy/helm/hoops/values-kind.yaml)
  [ ! -f deploy/helm/hoops/values-local.yaml ] || VALUES+=(-f deploy/helm/hoops/values-local.yaml)
  [ "$ESO" = 0 ] || VALUES+=(--set externalSecrets.enabled=true)
  helm --kube-context "kind-$CLUSTER" upgrade --install hoops deploy/helm/hoops -n "$NS" "${VALUES[@]}" \
    --wait --timeout 15m
  # WP71: the Job redpanda-bootstrap (a post-install hook) creates the broker users only after --wait, so on a fresh install
  # the services start before their users exist. The consumers recover by themselves; core's idempotent producer does not
  # when its very first producer-id request failed authentication (it does after later failures). Restart it once.
  # (grep without -q: with -q it stops at the first match, kubectl dies of SIGPIPE and pipefail turns the match false.)
  if "${K[@]}" -n "$NS" logs deploy/core-service 2>/dev/null | grep 'SASL authentication failed' >/dev/null; then
    step "restart core-service (it started before its broker user existed)"
    "${K[@]}" -n "$NS" rollout restart deployment/core-service
    "${K[@]}" -n "$NS" rollout status deployment/core-service --timeout=600s
  fi
fi

cat <<MSG

kind cluster '$CLUSTER' ready.  Gateway: http://localhost:8090  (https://localhost:8453 is optional, self-signed)
Next: tilt up            (or: deploy/kind/up.sh --deploy; with --eso: tilt up -- --eso)
      deploy/kind/seed-users.sh   once Keycloak is Ready
      deploy/kind/smoke.sh core game athlete   (with the event broker checks once redpanda-0 runs)
MSG
