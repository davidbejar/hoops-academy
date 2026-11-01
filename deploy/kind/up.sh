#!/usr/bin/env bash
# Creates the Hoops Academy kind cluster (Podman provider) with ingress-nginx, the CloudNativePG operator,
# namespace `hoops` and the Secrets from .env. Then either run `tilt up` (inner loop) or pass --deploy to build the
# images, load them into kind and `helm upgrade --install` the umbrella chart without Tilt.
#
#   deploy/kind/up.sh [--deploy] [--from-host]
set -euo pipefail
cd "$(dirname "$0")/../.."

CLUSTER="${KIND_CLUSTER:-hoops}"
NS="${HOOPS_NAMESPACE:-hoops}"
INGRESS_NGINX_VERSION="controller-v1.15.1"
CNPG_VERSION="1.30.1"
CNPG_BRANCH="release-${CNPG_VERSION%.*}"
DEPLOY=0 BUILD_FLAGS=()
for a in "$@"; do
  case "$a" in
    --deploy) DEPLOY=1 ;;
    --from-host) BUILD_FLAGS+=(--from-host) ;;
    *) echo "up.sh: unknown argument $a" >&2; exit 2 ;;
  esac
done

for t in podman kind kubectl helm; do command -v "$t" >/dev/null || { echo "up.sh: $t not found" >&2; exit 1; }; done
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

step "ingress-nginx $INGRESS_NGINX_VERSION"
"${K[@]}" apply -f "https://raw.githubusercontent.com/kubernetes/ingress-nginx/${INGRESS_NGINX_VERSION}/deploy/static/provider/kind/deploy.yaml"

step "CloudNativePG operator $CNPG_VERSION"
"${K[@]}" apply --server-side --force-conflicts \
  -f "https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/${CNPG_BRANCH}/releases/cnpg-${CNPG_VERSION}.yaml"

step "waiting for ingress-nginx and CNPG (first run pulls images; slow links take minutes)"
"${K[@]}" -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=900s
# rate-limited Ingresses (WP17) answer 429 instead of ingress-nginx' default 503
"${K[@]}" -n ingress-nginx patch configmap ingress-nginx-controller --type merge \
  -p '{"data":{"limit-req-status-code":"429","limit-conn-status-code":"429"}}'
"${K[@]}" -n cnpg-system rollout status deployment/cnpg-controller-manager --timeout=900s

step "namespace $NS + secrets from .env"
"${K[@]}" create namespace "$NS" --dry-run=client -o yaml | "${K[@]}" apply -f -
HOOPS_NAMESPACE="$NS" deploy/kind/secrets.sh | "${K[@]}" apply -f -

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

kind cluster '$CLUSTER' ready.  Ingress: http://localhost:8090  (https://localhost:8453 is optional, self-signed)
Next: tilt up            (or: deploy/kind/up.sh --deploy)
      deploy/kind/seed-users.sh   once Keycloak is Ready
MSG
