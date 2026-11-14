#!/usr/bin/env bash
# Installs Hoops Academy on the k3s of the cloud VM (WP104, ADR-0050): the in-cluster half of `deploy/kind/up.sh --deploy`.
# Namespaces, the Secrets from .env (deploy/kind/secrets.sh; ENV_FILE picks another file), Stakater Reloader, Envoy Gateway
# with its rate limit backend, CloudNativePG, a self-signed certificate for the wildcard hostname, then the chart with
# values-cloud.yaml and the images of one commit from ghcr.io. Idempotent: re-run it to upgrade. OpenTofu manages none of
# this (no application secret in the state).
# NOT YET RUN: no cloud account this round (decision 77); the next round runs it (docs/runbooks/cloud.md, step 5).
#   deploy/cloud/install.sh <image tag>   (= just cloud-install <tag>; the full git sha of a main commit images.yml pushed)
set -euo pipefail
cd "$(dirname "$0")/../.."
# shellcheck source=deploy/cloud/lib.sh
. deploy/cloud/lib.sh
need tofu kubectl helm openssl jq base64

TAG="${1:-}"
[[ "$TAG" =~ ^[0-9a-f]{40}$ ]] || { echo "install.sh: give the image tag, the full git sha of a main commit whose images.yml pushed" >&2; exit 2; }
NS="${HOOPS_NAMESPACE:-hoops}"
ENV_FILE="${ENV_FILE:-.env}"
# Same pins as deploy/kind/up.sh (`just tofu-check` fails when they differ); the reasons are there.
ENVOY_GATEWAY_VERSION="v1.10.0"
GATEWAY_API_VERSION="v1.6.1"
CNPG_VERSION="1.30.1"
CNPG_BRANCH="release-${CNPG_VERSION%.*}"
RELOADER_CHART_VERSION="2.2.19"
RELOADER_CHART_DIGEST="sha256:dfa9fd167fc7ea3a2542de23f8d23c961d79407929f38c985d5cecfa74316142"
RELOADER_IMAGE_DIGEST="sha256:82c80a15fdba22f738642553159f9fb37baf9e4d1edfeb798e8c48d87767f410"
# Envoy Gateway's rate limit service with the chart's Redis (ADR-0033), as on kind.
EG_VALUES=(
  --set config.envoyGateway.rateLimit.backend.type=Redis
  --set "config.envoyGateway.rateLimit.backend.redis.url=ratelimit-redis.${NS}.svc.cluster.local:6379"
  --set-json 'config.envoyGateway.provider.kubernetes.rateLimitDeployment.container.env=[{"name":"REDIS_AUTH","valueFrom":{"secretKeyRef":{"name":"envoy-ratelimit-redis-auth","key":"auth"}}}]'
  --set config.envoyGateway.rateLimit.failClosed=false
  --set config.envoyGateway.rateLimit.timeout=100ms
  --set config.envoyGateway.provider.kubernetes.rateLimitDeployment.container.resources.requests.cpu=10m
  --set config.envoyGateway.provider.kubernetes.rateLimitDeployment.container.resources.requests.memory=32Mi
  --set config.envoyGateway.provider.kubernetes.rateLimitDeployment.container.resources.limits.memory=128Mi
  --set-json 'config.envoyGateway.provider.kubernetes.rateLimitDeployment.patch={"type":"StrategicMerge","value":{"metadata":{"annotations":{"secret.reloader.stakater.com/auto":"true"}}}}'
)
step() { printf '\n==> %s\n' "$*"; }

[ -f "$ENV_FILE" ] || { echo "install.sh: $ENV_FILE missing (cp .env.example .env, set strong values)" >&2; exit 1; }
# A public deployment never runs on the example placeholders.
! grep -q 'change-me' "$ENV_FILE" || { echo "install.sh: $ENV_FILE still holds change-me placeholders" >&2; exit 1; }
[ -s "$CLOUD_KUBECONFIG" ] || { echo "install.sh: $CLOUD_KUBECONFIG missing: just cloud-kubeconfig" >&2; exit 1; }
host=$(tofu_output hostname)
url=$(tofu_output public_url)

step "namespaces $NS + envoy-gateway-system, Secrets from $ENV_FILE"
for n in "$NS" envoy-gateway-system; do cloud_kubectl create namespace "$n" --dry-run=client -o yaml | cloud_kubectl apply -f -; done
ENV_FILE="$ENV_FILE" HOOPS_NAMESPACE="$NS" deploy/kind/secrets.sh | cloud_kubectl apply -f -

step "Stakater Reloader (chart $RELOADER_CHART_VERSION)"
cloud_helm upgrade --install reloader "oci://ghcr.io/stakater/charts/reloader:${RELOADER_CHART_VERSION}@${RELOADER_CHART_DIGEST}" \
  -n hoops-reloader --create-namespace --wait --timeout 10m \
  --set image.digest="$RELOADER_IMAGE_DIGEST" \
  --set reloader.watchGlobally=false --set-json "reloader.namespaces=[\"$NS\",\"envoy-gateway-system\"]" \
  --set reloader.ignoreConfigMaps=true --set reloader.ignoreJobs=true --set reloader.ignoreCronJobs=true \
  --set reloader.reloadStrategy=annotations --set reloader.readOnlyRootFileSystem=true \
  --set-json 'reloader.deployment.containerSecurityContext={"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}' \
  --set reloader.deployment.resources.requests.cpu=10m --set reloader.deployment.resources.requests.memory=32Mi \
  --set reloader.deployment.resources.limits.memory=128Mi

step "Envoy Gateway $ENVOY_GATEWAY_VERSION (Gateway API $GATEWAY_API_VERSION CRDs)"
cloud_helm upgrade --install eg oci://docker.io/envoyproxy/gateway-helm --version "$ENVOY_GATEWAY_VERSION" \
  -n envoy-gateway-system --create-namespace "${EG_VALUES[@]}"

step "CloudNativePG operator $CNPG_VERSION"
cloud_kubectl apply --server-side --force-conflicts \
  -f "https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/${CNPG_BRANCH}/releases/cnpg-${CNPG_VERSION}.yaml"
cloud_kubectl -n envoy-gateway-system rollout status deployment/envoy-gateway --timeout=900s
cloud_kubectl -n cnpg-system rollout status deployment/cnpg-controller-manager --timeout=900s
crd_version=$(cloud_kubectl get crd gateways.gateway.networking.k8s.io -o jsonpath='{.metadata.annotations.gateway\.networking\.k8s\.io/bundle-version}')
[ "$crd_version" = "$GATEWAY_API_VERSION" ] \
  || { echo "install.sh: Gateway API CRDs are $crd_version, Envoy Gateway $ENVOY_GATEWAY_VERSION needs $GATEWAY_API_VERSION" >&2; exit 1; }

step "TLS Secret hoops-gateway-tls for $host (self-signed until the TLS slice)"
# Generated once in a temporary directory that is removed again; the key never leaves the cluster afterwards. The public
# certificate is kept at $CLOUD_CERT so curl (the smoke scripts) can trust it.
if ! cloud_kubectl -n "$NS" get secret hoops-gateway-tls >/dev/null 2>&1; then
  tls_dir=$(mktemp -d); trap 'rm -rf "$tls_dir"' EXIT
  openssl req -x509 -newkey rsa:2048 -nodes -days 90 -subj "/CN=$host" -addext "subjectAltName=DNS:$host" \
    -keyout "$tls_dir/tls.key" -out "$tls_dir/tls.crt" 2>/dev/null
  cloud_kubectl -n "$NS" create secret tls hoops-gateway-tls --cert="$tls_dir/tls.crt" --key="$tls_dir/tls.key"
  rm -rf "$tls_dir"
fi
mkdir -p "$(dirname "$CLOUD_CERT")"
cloud_kubectl -n "$NS" get secret hoops-gateway-tls -o jsonpath='{.data.tls\.crt}' | base64 -d > "$CLOUD_CERT"

step "helm upgrade --install hoops (images ghcr.io/...:$TAG, $url)"
scripts/sync-chart-files.sh
cloud_helm upgrade --install hoops deploy/helm/hoops -n "$NS" -f deploy/helm/hoops/values-cloud.yaml \
  --set global.publicUrl="$url" --set keycloak.publicUrl="$url" --set gateway.hostname="$host" \
  --set global.imageTag="$TAG" --set web.image.tag="$TAG" \
  --wait --timeout 20m
cloud_kubectl -n "$NS" get gateway hoops

cat <<MSG

Hoops Academy installed on the cloud VM: $url (self-signed certificate: the browser warns once).
Next: just cloud-seed-users        (dev users from .env; delete them before real users arrive)
      just cloud-smoke core game athlete
MSG
