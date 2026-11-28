# shellcheck shell=bash
# The platform operators that kind (deploy/kind/up.sh) and the cloud VM (deploy/cloud/install.sh) both install, pinned
# once (DEP-02, ADR-0068): Stakater Reloader, Envoy Gateway with its rate limit backend, CloudNativePG. Sourced from the
# repository root; NS (the application namespace) must be set. Each function takes the caller's helm or kubectl command
# as its arguments (kind: helm --kube-context kind-hoops; cloud: cloud_helm), so it reaches the right cluster.
# scripts/bump_pins.py bumps the pins below; infra/tofu/check.sh fails when up.sh or install.sh pin one again.

# Envoy Gateway v1.10.x bundles and needs Gateway API v1.6.1, Kubernetes 1.34 to 1.37 (CRDs installed by its chart;
# compatibility matrix: https://gateway.envoyproxy.io/news/releases/matrix/). Bump both together, see
# docs/adr/0031-gateway-api.md (amendment WP100).
ENVOY_GATEWAY_VERSION="v1.10.0"
GATEWAY_API_VERSION="v1.6.1"
# CloudNativePG: the operator manifest of the release (a release asset, not a branch file), applied only when its SHA-256
# is the one pinned here (TM-04). scripts/bump_pins.py moves both: the digest GitHub records for the asset.
CNPG_VERSION="1.30.2"
CNPG_MANIFEST_SHA256="ea4cc355b394e10661d30c6b409cefb19029dd973bccb76b1ed8c789985bc68c"
# Stakater Reloader (WP87, ADR-0012 amendment): rolls every Deployment/StatefulSet annotated with
# secret.reloader.stakater.com/auto (the chart with global.reloader.enabled, on in values-kind.yaml and values-cloud.yaml;
# envoy-ratelimit through eg_values) when a Secret it reads changes, whether ESO refreshed it or secrets.sh re-applied it.
# Pinned by chart version + digest and image digest (v1.4.25). Least privilege: namespaced Roles in $NS and
# envoy-gateway-system only (no ClusterRole), Secrets only (ConfigMap changes already roll through the chart's checksum
# annotations), no Jobs/CronJobs, reload strategy `annotations` (a pod-template annotation, not an injected env var).
RELOADER_CHART_VERSION="2.2.21"
RELOADER_CHART_DIGEST="sha256:d8daf25bbedcc180fa4bb35297709f9539c0e231f1d7815080541810deadaa98"
RELOADER_IMAGE_DIGEST="sha256:db8b1818f5da373ab85c05b30220fcae80a9ac0532052e6d68a6a5999111f18f"

install_reloader() { # helm-command...
  "$@" upgrade --install reloader "oci://ghcr.io/stakater/charts/reloader:${RELOADER_CHART_VERSION}@${RELOADER_CHART_DIGEST}" \
    -n hoops-reloader --create-namespace --wait --timeout 10m \
    --set image.digest="$RELOADER_IMAGE_DIGEST" \
    --set reloader.watchGlobally=false --set-json "reloader.namespaces=[\"$NS\",\"envoy-gateway-system\"]" \
    --set reloader.ignoreConfigMaps=true --set reloader.ignoreJobs=true --set reloader.ignoreCronJobs=true \
    --set reloader.reloadStrategy=annotations --set reloader.readOnlyRootFileSystem=true \
    --set-json 'reloader.deployment.containerSecurityContext={"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}' \
    --set reloader.deployment.resources.requests.cpu=10m --set reloader.deployment.resources.requests.memory=32Mi \
    --set reloader.deployment.resources.limits.memory=128Mi
}

# Global rate limiting (WP40, ADR-0033): Envoy Gateway deploys its rate limit service (Deployment envoy-ratelimit) with
# a Redis backend; the chart deploys that Redis in namespace $NS (rateLimit.redis.enabled). failClosed=false: when the
# rate limit service or Redis does not answer within the timeout, requests pass (fail open). Other clusters set the same
# keys in the operator's Envoy Gateway install (docs/runbooks/release.md section 4).
# Redis ACL (WP46): the rate limit pods log in as user `ratelimit` with REDIS_AUTH=<user>:<password> from Secret
# envoy-ratelimit-redis-auth (deploy/kind/secrets.sh). Not in the URL: envoyproxy/ratelimit logs the URL unmasked
# ("Creating single with urls ..."), so redis.urlRef with credentials would leak the password into its log.
# WP87: the patch annotates envoy-ratelimit, so Reloader restarts it when envoy-ratelimit-redis-auth changes.
install_envoy_gateway() { # helm-command...
  "$@" upgrade --install eg oci://docker.io/envoyproxy/gateway-helm --version "$ENVOY_GATEWAY_VERSION" \
    -n envoy-gateway-system --create-namespace \
    --set config.envoyGateway.rateLimit.backend.type=Redis \
    --set "config.envoyGateway.rateLimit.backend.redis.url=ratelimit-redis.${NS}.svc.cluster.local:6379" \
    --set-json 'config.envoyGateway.provider.kubernetes.rateLimitDeployment.container.env=[{"name":"REDIS_AUTH","valueFrom":{"secretKeyRef":{"name":"envoy-ratelimit-redis-auth","key":"auth"}}}]' \
    --set config.envoyGateway.rateLimit.failClosed=false \
    --set config.envoyGateway.rateLimit.timeout=100ms \
    --set config.envoyGateway.provider.kubernetes.rateLimitDeployment.container.resources.requests.cpu=10m \
    --set config.envoyGateway.provider.kubernetes.rateLimitDeployment.container.resources.requests.memory=32Mi \
    --set config.envoyGateway.provider.kubernetes.rateLimitDeployment.container.resources.limits.memory=128Mi \
    --set-json 'config.envoyGateway.provider.kubernetes.rateLimitDeployment.patch={"type":"StrategicMerge","value":{"metadata":{"annotations":{"secret.reloader.stakater.com/auto":"true"}}}}'
}

install_cnpg() { # kubectl-command...
  local dir manifest sum
  dir=$(mktemp -d) && manifest="$dir/cnpg-${CNPG_VERSION}.yaml"
  curl -sSfL -o "$manifest" \
    "https://github.com/cloudnative-pg/cloudnative-pg/releases/download/v${CNPG_VERSION}/cnpg-${CNPG_VERSION}.yaml" \
    || { rm -rf "$dir"; echo "install_cnpg: cannot fetch the v${CNPG_VERSION} manifest" >&2; return 1; }
  sum=$(if command -v sha256sum >/dev/null; then sha256sum "$manifest"; else shasum -a 256 "$manifest"; fi)
  if [ "${sum%% *}" != "$CNPG_MANIFEST_SHA256" ]; then
    rm -rf "$dir"
    echo "install_cnpg: the v${CNPG_VERSION} manifest is not the pinned one (SHA-256 ${sum%% *}, pinned $CNPG_MANIFEST_SHA256)" >&2
    return 1
  fi
  "$@" apply --server-side --force-conflicts -f "$manifest"
  rm -rf "$dir"
}

wait_for_platform() { # kubectl-command...: both operators rolled out, and the Gateway API CRDs Envoy Gateway needs
  local crd_version
  "$@" -n envoy-gateway-system rollout status deployment/envoy-gateway --timeout=900s
  "$@" -n cnpg-system rollout status deployment/cnpg-controller-manager --timeout=900s
  crd_version=$("$@" get crd gateways.gateway.networking.k8s.io \
    -o jsonpath='{.metadata.annotations.gateway\.networking\.k8s\.io/bundle-version}')
  [ "$crd_version" = "$GATEWAY_API_VERSION" ] || {
    echo "$(basename "$0"): Gateway API CRDs are $crd_version, Envoy Gateway $ENVOY_GATEWAY_VERSION needs $GATEWAY_API_VERSION" >&2
    exit 1; }
  echo "Gateway API CRDs $crd_version"
}
