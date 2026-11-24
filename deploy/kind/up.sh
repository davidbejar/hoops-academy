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
# The operator pins and installs kind shares with the cloud VM (Reloader, Envoy Gateway, CNPG).
# shellcheck source=deploy/lib/platform.sh
. deploy/lib/platform.sh
# External Secrets Operator (--eso): API external-secrets.io/v1. The chart tests validate the ExternalSecrets against this
# version's CRD (deploy/helm/tests/schemas, regenerate with update-eso.sh when bumping).
ESO_VERSION="v2.15.0"
DEPLOY=0 ESO=0 BUILD_FLAGS=()
for a in "$@"; do
  case "$a" in
    --deploy) DEPLOY=1 ;;
    --eso) ESO=1 ;;
    --from-host) BUILD_FLAGS+=(--from-host) ;;
    *) echo "up.sh: unknown argument $a" >&2; exit 2 ;;
  esac
done

# shellcheck source=deploy/lib/common.sh
. deploy/lib/common.sh
need podman kind kubectl helm openssl jq
[ -f .env ] || { echo "up.sh: .env missing (cp .env.example .env and set values)" >&2; exit 1; }
# shellcheck disable=SC1091
source scripts/env.sh >/dev/null
export KIND_EXPERIMENTAL_PROVIDER=podman


step "kind cluster '$CLUSTER'"
if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  echo "exists"
else
  kind create cluster --config deploy/kind/kind-config.yaml --name "$CLUSTER" --wait 180s
fi
kubectl config use-context "kind-$CLUSTER" >/dev/null
K=(kubectl --context "kind-$CLUSTER")
H=(helm --kube-context "kind-$CLUSTER")

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
  "${H[@]}" upgrade --install external-secrets oci://ghcr.io/external-secrets/charts/external-secrets \
    --version "${ESO_VERSION#v}" -n external-secrets --create-namespace --wait --timeout 15m
  HOOPS_NAMESPACE="$NS" deploy/kind/eso-store.sh | "${K[@]}" apply -f -
  "${K[@]}" wait clustersecretstore/hoops --for=condition=Ready --timeout=120s
fi

step "Stakater Reloader (chart $RELOADER_CHART_VERSION, watches $NS and envoy-gateway-system)"
install_reloader "${H[@]}"

step "Envoy Gateway $ENVOY_GATEWAY_VERSION (Gateway API $GATEWAY_API_VERSION CRDs)"
# `helm upgrade` never updates CRDs: on a version bump apply them first (docs/adr/0031-gateway-api.md, upgrade path).
eg_config() { "${K[@]}" -n envoy-gateway-system get configmap envoy-gateway-config -o jsonpath='{.data}' 2>/dev/null || true; }
eg_config_before=$(eg_config)
install_envoy_gateway "${H[@]}"
# The chart has no checksum annotation on the controller, so a changed config would not roll it: restart it when the
# config changed on an existing install (e.g. a cluster created before WP40 gaining the rate limit backend).
if [ -n "$eg_config_before" ] && [ "$eg_config_before" != "$(eg_config)" ]; then
  "${K[@]}" -n envoy-gateway-system rollout restart deployment/envoy-gateway
fi

step "CloudNativePG operator $CNPG_VERSION"
install_cnpg "${K[@]}"

# Single replica on kind: no leader election (WP86). Under VM load the operator lost its lease ("leader election lost",
# CrashLoopBackOff with a 5-minute backoff) and no database came up; kube-controller-manager and kube-scheduler run without
# it too (kind-config.yaml, WP87). Probes patient enough for a busy VM (WP146, see cnpg-patch.sh). The apply above resets
# both on a re-run, so this patch rolls the operator once more.
cnpg_patch=$("${K[@]}" -n cnpg-system get deployment cnpg-controller-manager -o json | deploy/kind/cnpg-patch.sh)
"${K[@]}" -n cnpg-system patch deployment cnpg-controller-manager --type json -p "$cnpg_patch"

step "waiting for Envoy Gateway and CNPG (first run pulls images; slow links take minutes)"
wait_for_platform "${K[@]}"

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
  KIND_CLUSTER="$CLUSTER" scripts/build-images.sh ${BUILD_FLAGS[@]+"${BUILD_FLAGS[@]}"} --kind-load
  step "helm upgrade --install hoops"
  scripts/sync-chart-files.sh   # realm JSON + init SQL copies inside the charts (no symlinks; helm package works)
  VALUES=(-f deploy/helm/hoops/values-kind.yaml)
  [ ! -f deploy/helm/hoops/values-local.yaml ] || VALUES+=(-f deploy/helm/hoops/values-local.yaml)
  [ "$ESO" = 0 ] || VALUES+=(--set externalSecrets.enabled=true)
  # helm's apply of the Clusters calls the CNPG webhook: the operator must serve it now, not only when wait_for_platform
  # ran before the image build (WP146: under build load it had been killed since, and the apply was refused).
  "${K[@]}" -n cnpg-system wait --for=condition=Available deployment/cnpg-controller-manager --timeout=600s
  "${H[@]}" upgrade --install hoops deploy/helm/hoops -n "$NS" "${VALUES[@]}" \
    --wait --timeout 15m
  # The Job redpanda-bootstrap (a post-install hook) creates the broker users only after --wait, so on a fresh install the
  # services start before their users exist and log `SASL authentication failed` for a while. Everyone recovers by itself:
  # the consumers reconnect, and core's publisher replaces a producer that failed hoops.outbox.producer-reset-after times
  # in a row (WP71 needed a restart of core here; WP100 removed it and proved the recovery on a fresh install).
fi

cat <<MSG

kind cluster '$CLUSTER' ready.  Gateway: http://localhost:8090  (https://localhost:8453 is optional, self-signed)
Next: tilt up            (or: deploy/kind/up.sh --deploy; with --eso: tilt up -- --eso)
      deploy/kind/seed-users.sh   once Keycloak is Ready
      deploy/kind/smoke.sh core game athlete   (with the event broker checks once redpanda-0 runs)
MSG
