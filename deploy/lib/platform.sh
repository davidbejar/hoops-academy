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
CNPG_VERSION="1.30.1"
CNPG_BRANCH="release-${CNPG_VERSION%.*}"
# Stakater Reloader (WP87, ADR-0012 amendment): rolls every Deployment/StatefulSet annotated with
# secret.reloader.stakater.com/auto (the chart with global.reloader.enabled, on in values-kind.yaml and values-cloud.yaml;
# envoy-ratelimit through eg_values) when a Secret it reads changes, whether ESO refreshed it or secrets.sh re-applied it.
# Pinned by chart version + digest and image digest (v1.4.24). Least privilege: namespaced Roles in $NS and
# envoy-gateway-system only (no ClusterRole), Secrets only (ConfigMap changes already roll through the chart's checksum
# annotations), no Jobs/CronJobs, reload strategy `annotations` (a pod-template annotation, not an injected env var).
RELOADER_CHART_VERSION="2.2.20"
RELOADER_CHART_DIGEST="sha256:065ab124e7e704a43465fad9b71363563157312e8ee410db30c4da83c5ac131b"
RELOADER_IMAGE_DIGEST="sha256:3ab43d3eb96c59798644bf826b0444a846c0197d22ab4b6c101c4da3e1d6ef23"

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
  "$@" apply --server-side --force-conflicts \
    -f "https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/${CNPG_BRANCH}/releases/cnpg-${CNPG_VERSION}.yaml"
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
