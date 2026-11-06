#!/usr/bin/env bash
# Creates the Hoops Academy kind cluster (Podman provider) with Envoy Gateway (Gateway API), the CloudNativePG
# operator, namespace `hoops`, the Secrets from .env and a self-signed TLS Secret for the Gateway's HTTPS listener. Then either run `tilt up` (inner loop) or pass --deploy to build the
# images, load them into kind and `helm upgrade --install` the umbrella chart without Tilt.
#
#   deploy/kind/up.sh [--deploy] [--from-host]
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
# Global rate limiting (WP40, ADR-0033): Envoy Gateway deploys its rate limit service (Deployment envoy-ratelimit) with
# a Redis backend; values-kind.yaml deploys that Redis in namespace $NS (rateLimit.redis.enabled). failClosed=false:
# when the rate limit service or Redis does not answer within the timeout, requests pass (fail open). Other clusters
# set the same keys in the operator's Envoy Gateway install (docs/runbooks/deploy.md).
EG_VALUES=(
  --set config.envoyGateway.rateLimit.backend.type=Redis
  --set "config.envoyGateway.rateLimit.backend.redis.url=ratelimit-redis.${NS}.svc.cluster.local:6379"
  --set config.envoyGateway.rateLimit.failClosed=false
  --set config.envoyGateway.rateLimit.timeout=100ms
  --set config.envoyGateway.provider.kubernetes.rateLimitDeployment.container.resources.requests.cpu=10m
  --set config.envoyGateway.provider.kubernetes.rateLimitDeployment.container.resources.requests.memory=32Mi
  --set config.envoyGateway.provider.kubernetes.rateLimitDeployment.container.resources.limits.memory=128Mi
)
DEPLOY=0 BUILD_FLAGS=()
for a in "$@"; do
  case "$a" in
    --deploy) DEPLOY=1 ;;
    --from-host) BUILD_FLAGS+=(--from-host) ;;
    *) echo "up.sh: unknown argument $a" >&2; exit 2 ;;
  esac
done

for t in podman kind kubectl helm openssl; do command -v "$t" >/dev/null || { echo "up.sh: $t not found" >&2; exit 1; }; done
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

step "waiting for Envoy Gateway and CNPG (first run pulls images; slow links take minutes)"
"${K[@]}" -n envoy-gateway-system rollout status deployment/envoy-gateway --timeout=900s
"${K[@]}" -n cnpg-system rollout status deployment/cnpg-controller-manager --timeout=900s
crd_version=$("${K[@]}" get crd gateways.gateway.networking.k8s.io \
  -o jsonpath='{.metadata.annotations.gateway\.networking\.k8s\.io/bundle-version}')
[ "$crd_version" = "$GATEWAY_API_VERSION" ] \
  || { echo "up.sh: Gateway API CRDs are $crd_version, Envoy Gateway $ENVOY_GATEWAY_VERSION needs $GATEWAY_API_VERSION" >&2; exit 1; }
echo "Gateway API CRDs $crd_version"

step "namespace $NS + secrets from .env"
"${K[@]}" create namespace "$NS" --dry-run=client -o yaml | "${K[@]}" apply -f -
HOOPS_NAMESPACE="$NS" deploy/kind/secrets.sh | "${K[@]}" apply -f -
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
  helm --kube-context "kind-$CLUSTER" upgrade --install hoops deploy/helm/hoops -n "$NS" "${VALUES[@]}" \
    --wait --timeout 15m
fi

cat <<MSG

kind cluster '$CLUSTER' ready.  Gateway: http://localhost:8090  (https://localhost:8453 is optional, self-signed)
Next: tilt up            (or: deploy/kind/up.sh --deploy)
      deploy/kind/seed-users.sh   once Keycloak is Ready
MSG
