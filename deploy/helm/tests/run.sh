#!/usr/bin/env bash
# Helm chart tests (WP16): lint, golden snapshots, schema validation, policy assertions, secret scan.
#   deploy/helm/tests/run.sh            verify
#   deploy/helm/tests/run.sh --update   re-record snapshots after an intended change (review the diff!)
# Snapshots include infra/keycloak/realm-academy.json and infra/db/init/01_roles_schemas.sql (copied into the charts
# by scripts/sync-chart-files.sh; a stale copy fails the drift check), so a change there shows up here on purpose.
set -euo pipefail
cd "$(dirname "$0")/../../.."
CHART=deploy/helm/hoops
SNAP=deploy/helm/tests/snapshots
UPDATE=0; [ "${1:-}" = "--update" ] && UPDATE=1
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
fail=0
ok()  { printf '  ok   %s\n' "$*"; }
bad() { printf '  FAIL %s\n' "$*"; fail=1; }
quiet_helm() { helm "$@"; }

echo "== chart file copies (no symlinks, identical to their sources)"
if scripts/sync-chart-files.sh --check; then ok "realm JSON, init SQL and login theme copies in sync"
else bad "chart copies drifted: run scripts/sync-chart-files.sh"; fi

echo "== helm lint"
for c in "$CHART" "$CHART"/charts/*/; do
  if quiet_helm lint --strict "$c" -f "$CHART/values-kind.yaml" >"$WORK/lint.txt" 2>&1 || quiet_helm lint --strict "$c" >"$WORK/lint.txt" 2>&1; then
    ok "lint $c"
  else bad "lint $c"; cat "$WORK/lint.txt"; fi
done

echo "== render"
render() { # name args...
  local name="$1"; shift
  quiet_helm template "$@" > "$WORK/$name.yaml"
}
render umbrella-default   hoops "$CHART" -n hoops
render umbrella-kind      hoops "$CHART" -n hoops -f "$CHART/values-kind.yaml"
render service-defaults   svc "$CHART/charts/hoops-service" -n hoops
render service-all        svc "$CHART/charts/hoops-service" -n hoops -f deploy/helm/tests/values/service-all-features.yaml
render umbrella-tls       hoops "$CHART" -n hoops -f deploy/helm/tests/values/umbrella-tls.yaml
render umbrella-eso       hoops "$CHART" -n hoops -f "$CHART/values-kind.yaml" -f deploy/helm/tests/values/umbrella-eso.yaml

echo "== snapshots"
for f in "$WORK"/*.yaml; do
  n=$(basename "$f")
  if [ "$UPDATE" = 1 ]; then cp "$f" "$SNAP/$n"; ok "recorded $n"
  elif [ ! -f "$SNAP/$n" ]; then bad "missing snapshot $n (run with --update)"
  elif diff -u "$SNAP/$n" "$f" > "$WORK/$n.diff"; then ok "$n"
  else bad "$n differs:"; head -60 "$WORK/$n.diff"; fi
done

echo "== schema validation"
# WP65: the ExternalSecret schema comes from the CRD of the ESO version kind pins (tests/schemas, update-eso.sh).
eso_pin=$(sed -n 's/^ESO_VERSION="\(v[0-9.]*\)"$/\1/p' deploy/kind/up.sh)
[ -n "$eso_pin" ] && [ "$(cat deploy/helm/tests/schemas/external-secrets.io/VERSION)" = "$eso_pin" ] \
  && ok "ExternalSecret schema generated from ESO $eso_pin (the version deploy/kind/up.sh installs)" \
  || bad "ExternalSecret schema is not ESO ${eso_pin:-?}: run deploy/helm/tests/schemas/update-eso.sh"
if command -v kubeconform >/dev/null; then
  # CRDs (CNPG Cluster, Gateway API, Envoy Gateway policies) from the datree catalog; -strict rejects unknown fields.
  # The authoritative check against the pinned CRD versions is `kubectl apply --dry-run=server` on kind (kind.md).
  if kubeconform -strict -summary -kubernetes-version "${K8S_VERSION:-1.34.0}" -schema-location default \
      -schema-location 'deploy/helm/tests/schemas/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
      -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
      "$WORK"/*.yaml; then ok kubeconform; else bad kubeconform; fi
else echo "  skip kubeconform (not installed: brew install kubeconform)"; fi

echo "== policy assertions (umbrella-kind)"
R="$WORK/umbrella-kind.yaml"
deployments=$(grep -c '^kind: Deployment' "$R")
[ "$(grep -c 'runAsNonRoot: true' "$R")" -ge "$deployments" ] && ok "runAsNonRoot on all $deployments Deployments" || bad runAsNonRoot
[ "$(grep -c 'allowPrivilegeEscalation: false' "$R")" -ge "$deployments" ] && ok "no privilege escalation" || bad allowPrivilegeEscalation
[ "$(grep -A2 'capabilities:' "$R" | grep -c 'drop: \[ALL\]\|- ALL')" -ge "$deployments" ] && ok "capabilities drop ALL" || bad "capabilities drop"
[ "$(grep -c 'readOnlyRootFilesystem: true' "$R")" -ge $((deployments - 1)) ] && ok "readOnlyRootFilesystem (all but keycloak)" || bad readOnlyRootFilesystem
[ "$(grep -c '^kind: NetworkPolicy' "$R")" -ge 6 ] && ok "NetworkPolicies present" || bad NetworkPolicy
! grep -q '^kind: Secret' "$R" && ok "chart renders no Secret objects" || bad "chart renders a Secret"
grep -q 'value: "http://localhost:8090/auth"' "$R" && ok "Keycloak hostname = gateway URL (issuer http://localhost:8090/auth/realms/academy)" || bad "KC_HOSTNAME"
! grep -q 'localhost:8080' "$R" && ok "no compose URL (localhost:8080) left in the realm" || bad "realm still references localhost:8080"
grep -q 'name: hoops-db-core-app' "$R" && grep -q 'postInitApplicationSQLRefs' "$R" && ok "CNPG managed roles + postInitApplicationSQLRefs" || bad CNPG
doc() { # print the YAML document containing "name: $1" (first match) of kind $2 (of file $3, default umbrella-kind)
  awk -v n="  name: $1" -v k="kind: $2" 'BEGIN{RS="\n---\n"} index($0,"\n"k"\n") && index($0,n"\n") {print; exit}' "${3:-$R}"; }
rule() { # print the rule of HTTPRoute $1 whose match has path value $2 (of file $3)
  doc "$1" HTTPRoute "${3:-$R}" | awk -v p="value: \"$2\"}" 'BEGIN{RS="\n    - matches:"} index($0,p) {print; exit}'; }
routes_to() { # HTTPRoute $1 sends path $2 (match type $3) to Service $4 without rewriting it
  local r; r=$(rule "$1" "$2"); echo "$r" | grep -q "type: $3, value:" && echo "$r" | grep -q -- "- {name: $4, port:" && ! echo "$r" | grep -q URLRewrite; }

echo "== gateway (WP36: Gateway API + Envoy Gateway, no Ingress)"
! grep -q '^kind: Ingress' "$WORK"/*.yaml && ok "no Ingress objects in any render" || bad "an Ingress is still rendered"
! grep -hv '^ *#' "$WORK"/*.yaml | grep -q 'ingress-nginx\|nginx.ingress.kubernetes.io' && ok "no ingress-nginx namespace or annotation left" || bad "ingress-nginx reference left"
doc hoops Gateway | grep -q 'gatewayClassName: envoy-gateway' && doc hoops Gateway | grep -q 'name: http, protocol: HTTP, port: 80' \
  && ok "Gateway hoops: class envoy-gateway, HTTP listener :80" || bad "Gateway hoops"
doc envoy-gateway GatewayClass | grep -q 'controllerName: gateway.envoyproxy.io/gatewayclass-controller' && ok "kind: GatewayClass created by the chart (switch on)" || bad "kind GatewayClass"
! grep -q '^kind: GatewayClass' "$WORK/umbrella-default.yaml" && ok "default: GatewayClass provided by the cluster (not rendered)" || bad "GatewayClass rendered by default"
[ -z "$(awk 'BEGIN{RS="\n---\n"} /\nkind: HTTPRoute\n/ && !/parentRefs:\n    - name: hoops\n/' "$R")" ] && ok "every HTTPRoute attaches to Gateway hoops" || bad "HTTPRoute without parentRef hoops"
[ "$(grep -c -- '^    - matches:' "$R")" = "$(grep -c 'timeouts: {request: 60s}' "$R")" ] && ok "every route rule has the 60 s request timeout (ingress-nginx proxy timeouts)" || bad "route timeouts"
for spec in core-service-api-core:/api/core:core-service core-service-platform:/platform:core-service \
    game-service-api-game:/api/game:game-service athlete-service-api-athlete:/api/athlete:athlete-service \
    keycloak:/auth:keycloak web:/:web web:/internal:web; do
  IFS=: read -r route path svc <<<"$spec"
  routes_to "$route" "$path" PathPrefix "$svc" && ok "HTTPRoute $route: $path -> $svc" || bad "HTTPRoute $route: $path -> $svc"
done
for p in /auth/admin /auth/realms/master; do
  routes_to keycloak-admin-deny "$p" PathPrefix web && ok "$p routed to the web 403 location" || bad "admin deny route $p"
done
# every HTTPRoute rule that matches /auth/admin or the master realm must go to the web 403 location, never to Keycloak
[ -z "$(awk 'BEGIN{RS="\n    - matches:"} /value: "\/auth\/(admin|realms\/master)/' "$R" | grep -- '- {name:' | grep -v -- '- {name: web, ')" ] \
  && ok "no HTTPRoute proxies /auth/admin or the master realm to Keycloak" || bad "/auth/admin exposed"
for p in /auth/realms/academy/protocol/openid-connect/token /auth/realms/academy/login-actions/authenticate; do
  routes_to keycloak-ratelimited "$p" PathPrefix keycloak && ok "rate-limited route $p -> keycloak" || bad "rate-limited route $p"
done
ratelimited() { # BackendTrafficPolicy $1 (of file $4, default umbrella-kind) targets HTTPRoute $1 with global rules per
  # client IP (IPv4 + IPv6): $2 requests/minute and, WP46, $3 requests/second (burst cap; 0 = no per-second rule), the
  # latter with an always-true path selector so its descriptor differs from the per-minute rule's (Envoy Gateway v1.9)
  local d; d=$(doc "$1" BackendTrafficPolicy "${4:-$R}")
  echo "$d" | grep -q "kind: HTTPRoute, name: $1}" && [ "$(echo "$d" | grep -c "requests: $2, unit: Minute")" = 2 ] \
    && [ "$(echo "$d" | grep -c "unit: Second")" = $((${3:-0} > 0 ? 2 : 0)) ] \
    && { [ "${3:-0}" = 0 ] || [ "$(echo "$d" | grep -c "requests: $3, unit: Second")" = 2 ]; } \
    && [ "$(echo "$d" | grep -c -- '- path: {type: PathPrefix, value: /}')" = $((${3:-0} > 0 ? 2 : 0)) ] \
    && [ "$(echo "$d" | grep -c -- '- clientSelectors:')" = $((${3:-0} > 0 ? 4 : 2)) ] \
    && echo "$d" | grep -q '^    global:$' && ! echo "$d" | grep -q '^    local:$' \
    && echo "$d" | grep -q 'sourceCIDR: {type: Distinct, value: "0.0.0.0/0"}' && echo "$d" | grep -q 'sourceCIDR: {type: Distinct, value: "::/0"}'; }
for spec in keycloak:/auth keycloak-ratelimited:/auth/realms/academy/protocol/openid-connect/token; do
  IFS=: read -r route path <<<"$spec"
  rule "$route" "$path" | grep -q 'set: \[{name: X-Forwarded-Host, value: "localhost:8090"}\]' \
    && ok "$route: X-Forwarded-Host = public host (Keycloak back-channel URLs keep :8090)" || bad "$route X-Forwarded-Host"
done
rule keycloak /auth "$WORK/umbrella-tls.yaml" | grep -q 'value: "hoops.example.test"}' && ok "TLS: X-Forwarded-Host = hoops.example.test" || bad "TLS X-Forwarded-Host"
ratelimited keycloak-ratelimited 60 10 && ok "token endpoint + login form: global rate limit 60/min and 10/s per client IP" || bad "keycloak rate limit"
routes_to game-service-events-batch '/api/game/matches/[^/]+/events(:|%3[Aa])batch' RegularExpression game-service \
  && ok "events:batch (and %3A) regex route, path not rewritten" || bad "events:batch route"
ratelimited game-service-events-batch 120 20 && ok "events:batch: global rate limit 120/min and 20/s per client IP" || bad "events:batch rate limit"
ratelimited demo-service-batch 120 20 "$WORK/service-all.yaml" && ratelimited demo-service-plain 10 0 "$WORK/service-all.yaml" \
  && ok "service chart: per-second rule only where rateLimits[].rps is set" || bad "service chart rps"
# WP40 (ADR-0033): every Envoy replica shares the counters; no per-replica local limit is left in any render.
! grep -hv '^ *#' "$WORK"/*.yaml | grep -q '^ *local:$' && ok "no local rate limit rendered (global only)" || bad "a local rate limit is still rendered"
for s in core game athlete; do
  for h in "" /live /ready /started; do
    rule "$s-service-health" "/api/$s/q/health$h" | grep -q "type: Exact, value:" \
      && rule "$s-service-health" "/api/$s/q/health$h" | grep -q "replaceFullPath: \"/q/health$h\"" || { bad "$s health route $h"; continue 2; }
  done
  ok "$s-service: only /api/$s/q/health[/live|ready|started] rewritten to /q/health (Exact)"
  doc "$s-service" NetworkPolicy | grep -q 'kubernetes.io/metadata.name: envoy-gateway-system' && ok "$s-service NetworkPolicy admits the Envoy proxies" || bad "$s-service NetworkPolicy"
done
! grep -q 'value: "/api/[a-z]*/q/metrics' "$R" && ok "/q/metrics never routed" || bad "/q/metrics routed"
for n in keycloak web; do
  doc "$n" NetworkPolicy | grep -q 'kubernetes.io/metadata.name: envoy-gateway-system' && ok "$n NetworkPolicy admits the Envoy proxies" || bad "$n NetworkPolicy"
done
e=$(doc hoops EnvoyProxy)
echo "$e" | grep -q 'type: NodePort' && echo "$e" | grep -q 'nodePort: 30080' && echo "$e" | grep -q 'nodePort: 30443' \
  && doc hoops Gateway | grep -q 'parametersRef: {group: gateway.envoyproxy.io, kind: EnvoyProxy, name: hoops}' \
  && ok "kind: Envoy Service NodePort 30080/30443 (kind-config maps 8090/8453)" || bad "kind EnvoyProxy"
doc hoops Gateway | grep -q 'name: https, protocol: HTTPS, port: 443' && doc hoops Gateway | grep -q 'name: hoops-gateway-tls' \
  && ok "kind: HTTPS listener :443 with Secret hoops-gateway-tls" || bad "kind HTTPS listener"
doc hoops-http ClientTrafficPolicy | grep -q 'remove: \[X-Forwarded-Host, X-Forwarded-Port\]' && ok "client-supplied X-Forwarded-Host/Port dropped" || bad "X-Forwarded-Host not dropped"
! grep -q Strict-Transport-Security "$R" && ok "kind: no HSTS on localhost" || bad "HSTS on kind"
! grep -q '^kind: EnvoyProxy' "$WORK/umbrella-default.yaml" && ! grep -q 'name: https, protocol' "$WORK/umbrella-default.yaml" \
  && ok "default: no EnvoyProxy override, no HTTPS listener without a certificate" || bad "default gateway"
T="$WORK/umbrella-tls.yaml"
doc hoops Gateway "$T" | grep -q 'name: https, protocol: HTTPS, port: 443' && doc hoops Gateway "$T" | grep -q 'hostname: "hoops.example.test"' \
  && doc hoops-https ClientTrafficPolicy "$T" | grep -q 'sectionName: https}' \
  && doc hoops-https ClientTrafficPolicy "$T" | grep -q 'name: Strict-Transport-Security, value: "max-age=31536000; includeSubDomains"' \
  && ! doc hoops-http ClientTrafficPolicy "$T" | grep -q Strict-Transport-Security \
  && ok "TLS: HTTPS listener, HSTS on the HTTPS listener only" || bad "TLS/HSTS"
doc hoops-http ClientTrafficPolicy "$T" | grep -q 'numTrustedHops: 1' && doc hoops-https ClientTrafficPolicy "$T" | grep -q 'numTrustedHops: 1' \
  && ok "behind a load balancer: client IP from X-Forwarded-For (1 trusted hop) on both listeners" || bad "clientIPDetection"

echo "== workloads (umbrella-kind)"
for s in core game athlete; do
  d=$(doc "$s-service" Deployment)
  echo "$d" | grep -q 'path: /q/health/ready' && ! echo "$d" | grep -q tcpSocket && echo "$d" | grep -q 'prometheus.io/scrape: "true"' \
    && ok "$s-service: http health probes, metrics annotations" || bad "$s-service probes/metrics"
  doc "$s-service-env" ConfigMap | grep -q 'HOOPS_CORS_ORIGINS: "http://localhost:8090"' && ok "$s-service CORS allow-list = public URL" || bad "$s-service CORS env"
done
! grep -q 'localhost:5173' "$R" && ok "Flutter dev-server origin rewritten out of the cluster realm" || bad "realm still allows localhost:5173"
grep -q '"passwordPolicy": "length(12)' "$R" && grep -q '"bruteForceProtected": true' "$R" && ok "realm: password policy + brute-force protection" || bad "realm hardening"
# ADR-0022: the realm's login theme must be mounted, or Keycloak falls back to its own pages.
grep -q '"loginTheme": "hoops"' "$R" && doc keycloak Deployment | grep -q 'mountPath: /opt/keycloak/themes/hoops/login' \
  && doc keycloak-theme ConfigMap | grep -q 'parent=keycloak.v2' \
  && ok "realm login theme hoops mounted from keycloak-theme ConfigMap" || bad "login theme not mounted"
doc mailhog Service | grep -q 'port: 1025' && ok "kind: SMTP sink Service mailhog:1025 (realm smtpServer)" || bad "mailhog in kind"
! grep -q 'name: mailhog' "$WORK/umbrella-default.yaml" && ok "SMTP sink disabled outside kind" || bad "mailpit enabled by default"

echo "== rate limit store (WP40, ADR-0033)"
d=$(doc ratelimit-redis Deployment)
echo "$d" | grep -q 'image: "docker.io/library/redis:[0-9][0-9.]*-alpine' && echo "$d" | grep -q 'runAsNonRoot: true' \
  && echo "$d" | grep -q 'readOnlyRootFilesystem: true' && echo "$d" | grep -q 'automountServiceAccountToken: false' \
  && echo "$d" | grep -A1 'limits:' | grep -q 'memory:' && ok "kind: ratelimit-redis pinned tag, non-root, read-only root FS, memory limit" || bad "ratelimit-redis Deployment"
echo "$d" | grep -A1 -- '- --save' | grep -q -- '- ""' && echo "$d" | grep -A1 -- '- --appendonly' | grep -q -- '- "no"' \
  && echo "$d" | grep -A1 -- '- --rename-command' | grep -q -- '- CONFIG' && ok "ratelimit-redis: in memory only, CONFIG disabled" || bad "ratelimit-redis args"
n=$(doc ratelimit-redis NetworkPolicy)
echo "$n" | grep -q 'policyTypes: \[Ingress, Egress\]' && echo "$n" | grep -q 'egress: \[\]' \
  && [ "$(echo "$n" | grep -c -- '- namespaceSelector:')" = 1 ] && ! echo "$n" | grep -q -- '- podSelector:' \
  && echo "$n" | grep -A5 -- '- namespaceSelector:' | grep -q 'kubernetes.io/metadata.name: envoy-gateway-system' \
  && echo "$n" | grep -A5 -- '- namespaceSelector:' | grep -q '^          podSelector:' \
  && echo "$n" | grep -q 'app.kubernetes.io/name: envoy-ratelimit' \
  && ok "ratelimit-redis NetworkPolicy: only envoy-ratelimit pods of envoy-gateway-system, no egress" || bad "ratelimit-redis NetworkPolicy"
! grep -q 'name: ratelimit-redis' "$WORK/umbrella-default.yaml" && ok "default: no in-chart Redis (external, rateLimit.redis.url)" || bad "ratelimit-redis rendered by default"
# WP46: Redis ACL. The default user is off; the one user gets only the commands envoyproxy/ratelimit issues (PING, INCRBY,
# EXPIRE; no GET/EVAL/admin) on the keys of this release's rate limit domains; its password comes from a Secret only.
echo "$d" | grep -A1 -- '- --aclfile' | grep -q -- '- /acl/users.acl' && ok "ratelimit-redis: users from an ACL file" || bad "ratelimit-redis --aclfile"
init=$(echo "$d" | awk '/^      initContainers:$/,/^      containers:$/')
echo "$init" | grep -q 'user default off resetpass resetkeys resetchannels -@all' \
  && echo "$init" | grep -q 'resetkeys ~%s resetchannels -@all +ping +incrby +expire\\n' \
  && [ "$(echo "$init" | grep -o '+[@a-z|]*' | sort -u | tr '\n' ' ')" = "+expire +incrby +ping " ] \
  && ok "ACL: default user off, ratelimit user only +ping +incrby +expire" || bad "ACL rules"
echo "$init" | grep -A1 'name: ACL_USER$' | grep -q 'value: "ratelimit"' && echo "$init" | grep -A1 'name: ACL_KEYS$' | grep -q 'value: "hoops/hoops/\*"' \
  && ok "ACL: user ratelimit on keys hoops/hoops/* (rate limit domain = Envoy listener <namespace>/<gateway>/<listener>)" || bad "ACL user/keys"
echo "$init" | grep -A3 'name: ACL_PASSWORD$' | grep -q 'secretKeyRef: {name: hoops-ratelimit-redis, key: password}' \
  && ! echo "$d" | grep -q 'requirepass' && ok "ACL password only from Secret hoops-ratelimit-redis (hashed into the file)" || bad "ACL password source"
echo "$d" | grep -q 'name: acl, emptyDir: {medium: Memory, sizeLimit: 1Mi}' && echo "$d" | grep -q 'name: acl, mountPath: /acl, readOnly: true' \
  && ok "ACL file in memory, read-only for redis-server" || bad "ACL volume"

echo "== event broker (WP66, ADR-0036)"
# One Redpanda pin for compose, the chart and the Quarkus Dev Services; one topic list and topic config for compose and chart.
V=deploy/helm/hoops/values.yaml
chart_img=$(awk '/^events:/ {e=1} e && /^      repository: / {r=$2} e && /^      tag: / {t=$2} e && /^      digest: / {print r ":" t "@" $2; exit}' "$V")
compose_img=$(sed -n 's/^    image: \(docker.io\/redpandadata\/redpanda:.*\)$/\1/p' infra/compose/compose.yaml)
devsvc_img=$(sed -n 's/^\(# *\)\{0,1\}quarkus.kafka.devservices.image-name=\(.*\)$/\2/p' libs/common-quarkus/src/main/resources/META-INF/microprofile-config.properties)
[ -n "$chart_img" ] && [ "$chart_img" = "$compose_img" ] && [ "${chart_img%@*}" = "$devsvc_img" ] \
  && ok "Redpanda pin ${chart_img%@*} (digest pinned) in chart, compose and Dev Services" \
  || bad "Redpanda pins differ: chart '$chart_img', compose '$compose_img', Dev Services '$devsvc_img'"
compose_topics=$(sed -n 's/^TOPICS=(\(.*\))$/\1/p' infra/compose/redpanda-topics.sh | tr ' ' '\n')
chart_topics=$(sed -n 's/^    names: \[\(.*\)\]$/\1/p' "$V" | tr -d ' ' | tr ',' '\n')
compose_cfg=$(sed -n 's/^CONFIG=(\(.*\))$/\1/p' infra/compose/redpanda-topics.sh | tr ' ' '\n' | sort)
chart_cfg=$(doc redpanda-bootstrap ConfigMap | awk '/^  topic-config: \|$/ {c=1; next} c && /^    / {print $1; next} c {exit}' | sort)
[ "$(echo "$compose_topics" | wc -l | tr -d ' ')" = 7 ] && [ "$compose_topics" = "$chart_topics" ] \
  && [ "$(doc redpanda-bootstrap ConfigMap | awk '/^  topics: \|$/ {c=1; next} c && /^    / {print $1; next} c {exit}')" = "$chart_topics" ] \
  && ok "seven topics, same list in compose and chart: $(echo "$chart_topics" | tr '\n' ' ')" || bad "topic lists differ (compose vs chart)"
[ -n "$compose_cfg" ] && [ "$compose_cfg" = "$chart_cfg" ] && echo "$chart_cfg" | grep -qx 'cleanup.policy=compact' \
  && [ "$(sed -n 's/^PARTITIONS=//p' infra/compose/redpanda-topics.sh)" = 1 ] && doc redpanda-bootstrap Job | grep -q '{name: PARTITIONS, value: "1"}' \
  && ok "topic config identical in compose and chart (compacted, 1 partition): $(echo "$chart_cfg" | tr '\n' ' ')" || bad "topic config differs"
s=$(doc redpanda StatefulSet)
echo "$s" | grep -q "image: \"$chart_img\"" && echo "$s" | grep -q 'runAsNonRoot: true' && echo "$s" | grep -q 'readOnlyRootFilesystem: true' \
  && echo "$s" | grep -q 'allowPrivilegeEscalation: false' && echo "$s" | grep -A2 'capabilities:' | grep -q -- '- ALL' \
  && echo "$s" | grep -q 'automountServiceAccountToken: false' && echo "$s" | grep -A1 'limits:' | grep -q 'memory:' \
  && echo "$s" | grep -q 'volumeClaimTemplates:' && echo "$s" | grep -q 'name: config, mountPath: /etc/redpanda, readOnly: true' \
  && ok "kind: redpanda StatefulSet pinned by digest, non-root, read-only root FS (config read-only), memory limit, volume" \
  || bad "redpanda StatefulSet"
c=$(doc redpanda-config ConfigMap)
echo "$c" | grep -q '{name: internal, address: 0.0.0.0, port: 9092, authentication_method: sasl}' \
  && [ "$(echo "$c" | grep -c 'port: 9092')" = 2 ] && ! echo "$c" | grep -q 'pandaproxy\|schema_registry' \
  && ok "one Kafka listener, SASL; no HTTP proxy or schema registry" || bad "redpanda listeners"
for kv in 'superusers: \[admin\]' 'kafka_enable_authorization: true' 'admin_api_require_auth: true' \
    'auto_create_topics_enabled: false' 'enable_metrics_reporter: false'; do
  echo "$c" | grep -q "^    $kv$" || { bad "bootstrap property $kv"; continue; }
  ok "bootstrap property ${kv//\\/}"
done
echo "$s" | grep -A2 'name: RP_ADMIN_PASSWORD$' | grep -q 'secretKeyRef: {name: hoops-redpanda-admin, key: password}' \
  && echo "$s" | grep -q 'value: "admin:$(RP_ADMIN_PASSWORD):SCRAM-SHA-256"' \
  && ok "superuser admin created at bootstrap from Secret hoops-redpanda-admin (no value in the spec)" || bad "superuser bootstrap"
n=$(doc redpanda NetworkPolicy)
admitted=$(echo "$n" | awk '/operator: In/ {i=1; next} i && /^ *values:$/ {next} i && /^ *- [a-z-]+$/ {print $2; next} i {exit}' | sort | tr '\n' ' ')
[ "$admitted" = "athlete-service core-service game-service redpanda-bootstrap " ] \
  && echo "$n" | grep -q 'policyTypes: \[Ingress, Egress\]' && [ "$(echo "$n" | grep -c -- '- from:')" = 2 ] \
  && echo "$n" | awk '/- from:/ {f++} f==1 && /port: kafka/ {k=1} f==1 && /port: admin/ {a=1} END {exit !(k && !a)}' \
  && echo "$n" | awk '/- from:/ {f++} f==2 && /redpanda-bootstrap/ {b=1} f==2 && /port: admin/ {a=1} f==2 && /port: kafka/ {k=1} END {exit !(b && a && !k)}' \
  && ! echo "$n" | grep -q 'namespaceSelector: {}' && echo "$n" | grep -q 'k8s-app: kube-dns' && [ "$(echo "$n" | grep -c -- '- to:')" = 1 ] \
  && ok "redpanda NetworkPolicy: Kafka from the three services + bootstrap Job, admin API from the Job only, egress DNS only" \
  || bad "redpanda NetworkPolicy (admitted: $admitted)"
for u in core-service game-service athlete-service; do
  doc "$u" Deployment | grep -q "app.kubernetes.io/name: $u" || bad "events user $u has no Deployment with that name label"
done
j=$(doc redpanda-bootstrap Job)
echo "$j" | grep -q 'helm.sh/hook: post-install,post-upgrade' && echo "$j" | grep -q 'helm.sh/hook-delete-policy: before-hook-creation' \
  && echo "$j" | grep -q 'readOnlyRootFilesystem: true' && echo "$j" | grep -q 'automountServiceAccountToken: false' \
  && all_of() { local x; for x in admin core-service game-service athlete-service; do "$@" "$x" || return 1; done; } \
  && job_reads() { echo "$j" | grep -q "secretKeyRef: {name: hoops-redpanda-$1, key: password}"; } && all_of job_reads \
  && ok "bootstrap Job: post-install/upgrade hook, passwords from the four Secrets, read-only root FS" || bad "bootstrap Job"
script=deploy/helm/hoops/files/redpanda-bootstrap.sh
! grep -v '^ *#' "$script" | grep -q -- '--password\|--new-password\|-X pass\|-u "\|--user ' && grep -q 'kafka_enable_authorization\|cluster-config' "$script" \
  && ok "bootstrap script puts no password on a command line (RPK_PASS env, curl netrc fd + stdin)" || bad "bootstrap script command lines"
users=$(doc redpanda-bootstrap ConfigMap | awk '/^  users: \|$/ {c=1; next} c && /^    / {sub(/^    /, ""); print; next} c {exit}')
[ "$users" = "$(printf '0 core-service core. - -\n1 game-service - core. game-service.\n2 athlete-service - core. athlete-service.')" ] \
  && ok "ACLs: core-service writes core.*, game/athlete-service read core.* with groups <service>.*" || bad "events users/ACLs: $users"
! grep -q 'redpanda' "$WORK/umbrella-default.yaml" && ok "default: no event broker (events.enabled off)" || bad "redpanda rendered by default"
e=$(awk 'BEGIN{RS="\n---\n"} /\nkind: ExternalSecret\n/ && /name: hoops-redpanda-/' "$WORK/umbrella-eso.yaml")
[ "$(echo "$e" | grep -c '^kind: ExternalSecret')" = 4 ] && [ "$(echo "$e" | grep -c 'type: kubernetes.io/basic-auth')" = 4 ] \
  && es_login() { local d; d=$(doc "hoops-redpanda-$1" ExternalSecret "$WORK/umbrella-eso.yaml")
       echo "$d" | grep -qx "        username: $1" && echo "$d" | grep -q "property: REDPANDA_$(echo "${1%-service}" | tr '[:lower:]' '[:upper:]')$([ "$1" = admin ] || echo _SERVICE)_PASSWORD}"; } \
  && all_of es_login \
  && ok "ESO: four broker logins (basic-auth, username = user, REDPANDA_*_PASSWORD)" || bad "ESO broker logins"

echo "== services on the event broker (WP71, ADR-0036/0037)"
# events.enabled (umbrella) is mirrored in global.events.enabled, the only value the service subcharts see; the subchart
# derives the Kafka client from it, the umbrella refuses a render where the two differ or the wiring is half done.
D="$WORK/umbrella-default.yaml"
mkdir -p "$WORK/extra"
upper() { echo "$1" | tr '[:lower:]' '[:upper:]'; }
for s in core game athlete; do
  u="$s-service"; c=$(doc "$u-env" ConfigMap); d=$(doc "$u" Deployment)
  echo "$c" | grep -qx '  KAFKA_BOOTSTRAP_SERVERS: "redpanda.hoops.svc.cluster.local:9092"' \
    && echo "$c" | grep -qx '  KAFKA_SECURITY_PROTOCOL: "SASL_PLAINTEXT"' && echo "$c" | grep -qx "  KAFKA_SASL_USERNAME: \"$u\"" \
    && echo "$d" | grep -A5 -- '- name: KAFKA_SASL_PASSWORD$' | grep -q "name: hoops-redpanda-$u$" \
    && echo "$d" | grep -A5 -- '- name: KAFKA_SASL_PASSWORD$' | grep -q 'key: password$' \
    && ! echo "$c" | grep -q 'KAFKA_SASL_PASSWORD' \
    && ok "events on: $u gets redpanda.hoops...:9092, SASL_PLAINTEXT, user $u, password from Secret hoops-redpanda-$u" \
    || bad "events on: $u Kafka client"
  ! echo "$c" | grep -q '_OUTBOX_POLL_INTERVAL: "off"\|_ROSTER_CONSUMER_ENABLED: "false"' \
    && ok "events on: $u publisher/consumer not switched off" || bad "events on: $u switched off"
  # the Secret the Deployment reads is the one secrets.sh and the ESO render create and the bootstrap Job gives the user
  grep -Eq "^basic_auth hoops-redpanda-$u +$u +REDPANDA_$(upper "$s")_SERVICE_PASSWORD$" deploy/kind/secrets.sh \
    && doc "hoops-redpanda-$u" ExternalSecret "$WORK/umbrella-eso.yaml" | grep -qx "        username: $u" \
    && doc redpanda-bootstrap Job | grep -q "secretKeyRef: {name: hoops-redpanda-$u, key: password}" \
    && doc redpanda-bootstrap ConfigMap | grep -Eq "^    [0-9]+ $u " \
    && ok "Secret hoops-redpanda-$u: same name in secrets.sh, ESO and the bootstrap Job (broker user $u)" \
    || bad "Secret hoops-redpanda-$u differs between the Deployment, secrets.sh, ESO and the bootstrap Job"
done
! grep -q 'KAFKA_' "$D" && ok "events off: no KAFKA_* in any workload" || bad "events off: KAFKA_* rendered"
doc core-service-env ConfigMap "$D" | grep -qx '  CORE_OUTBOX_POLL_INTERVAL: "off"' \
  && ok "events off: core publisher off (CORE_OUTBOX_POLL_INTERVAL=off)" || bad "events off: core publisher"
for s in game athlete; do
  doc "$s-service-env" ConfigMap "$D" | grep -qx "  $(upper "$s")_ROSTER_CONSUMER_ENABLED: \"false\"" \
    && ok "events off: $s consumer off ($(upper "$s")_ROSTER_CONSUMER_ENABLED=false)" || bad "events off: $s consumer"
  for f in "$R" "$D"; do
    doc "$s-service-env" ConfigMap "$f" | grep -qx "  $(upper "$s")_ROSTER_SOURCE: \"rest\"" || { bad "$s roster source in $(basename "$f")"; continue 2; }
  done
  ok "$s roster source rest by default and on kind"
done
! grep -q 'ROSTER_SOURCE\|ROSTER_CONSUMER\|OUTBOX_POLL' "$WORK/service-defaults.yaml" && ! grep -q 'KAFKA_' "$WORK/service-defaults.yaml" \
  && ok "service chart alone: no broker client, no switches" || bad "service chart defaults carry event settings"
a=$(doc demo-service-env ConfigMap "$WORK/service-all.yaml")
echo "$a" | grep -qx '  KAFKA_SASL_USERNAME: "demo-service"' && echo "$a" | grep -qx '  KAFKA_BOOTSTRAP_SERVERS: "redpanda.hoops.svc.cluster.local:9092"' \
  && ! echo "$a" | grep -q 'DEMO_EVENTS' && doc demo-service Deployment "$WORK/service-all.yaml" | grep -A5 -- '- name: KAFKA_SASL_PASSWORD$' | grep -q 'name: hoops-redpanda-demo-service$' \
  && ok "service chart with global.events.enabled: client named after the service, events.offEnv not applied" || bad "service chart events on"
# Cutover of one service (ADR-0037): only athlete's ConfigMap (and so its checksum) changes.
helm template hoops "$CHART" -n hoops -f "$CHART/values-kind.yaml" --set athlete.rosterSource=replica > "$WORK/extra/replica.yaml"
doc athlete-service-env ConfigMap "$WORK/extra/replica.yaml" | grep -qx '  ATHLETE_ROSTER_SOURCE: "replica"' \
  && [ "$(diff "$R" "$WORK/extra/replica.yaml" | grep -c '^[<>]')" = 4 ] \
  && [ "$(diff "$R" "$WORK/extra/replica.yaml" | grep '^[<>]' | grep -vc 'ATHLETE_ROSTER_SOURCE\|checksum/env')" = 0 ] \
  && ok "--set athlete.rosterSource=replica changes ATHLETE_ROSTER_SOURCE (and the pod checksum) only" || bad "athlete replica flip"
refused() { # message helm-args...: the render fails and names the message
  local m="$1"; shift
  ! helm template hoops "$CHART" -n hoops "$@" >/dev/null 2>"$WORK/extra/refused.txt" && grep -q -- "$m" "$WORK/extra/refused.txt"; }
K=(-f "$CHART/values-kind.yaml")
refused 'global.events.enabled' --set events.enabled=true && refused 'global.events.enabled' "${K[@]}" --set global.events.enabled=false \
  && ok "events.enabled and global.events.enabled must agree (broker and clients switch together)" || bad "events switch mismatch rendered"
refused 'rosterSource' --set athlete.rosterSource=replica && refused 'rosterSource' "${K[@]}" --set game.rosterSource=cache \
  && ok "rosterSource: rest|replica only, replica only with events" || bad "rosterSource guard"
refused 'KAFKA_BOOTSTRAP_SERVERS' "${K[@]}" --set core.env.KAFKA_BOOTSTRAP_SERVERS=elsewhere:9092 \
  && refused 'KAFKA_SASL_PASSWORD' "${K[@]}" --set-json 'game.secretEnv=[{"name":"KAFKA_SASL_PASSWORD","secretName":"x","key":"password"}]' \
  && ok "events on: KAFKA_* in env/secretEnv refused (the chart sets the client)" || bad "KAFKA_* override rendered"
refused 'hoops-redpanda-core-service' "${K[@]}" --set-json 'events.users=[{"name":"core-service","passwordSecret":"other","produce":["core."]},{"name":"game-service","passwordSecret":"hoops-redpanda-game-service","consume":["core."],"groups":["game-service."]},{"name":"athlete-service","passwordSecret":"hoops-redpanda-athlete-service","consume":["core."],"groups":["athlete-service."]}]' \
  && ok "events on: every service needs events user <service> with Secret hoops-redpanda-<service>" || bad "events.users guard"

echo "== external secrets (WP65, ADR-0012 amendment; umbrella-eso)"
E="$WORK/umbrella-eso.yaml"
for f in umbrella-default umbrella-kind umbrella-tls service-defaults service-all; do
  grep -q '^kind: ExternalSecret' "$WORK/$f.yaml" && { bad "$f renders an ExternalSecret (externalSecrets.enabled is off)"; continue; }
done; ok "externalSecrets off by default: no ExternalSecret in the other renders"
without_es() { awk 'BEGIN{RS="\n---\n"; ORS="\n---\n"} !/\nkind: ExternalSecret\n/' "$1"; }
diff -u <(without_es "$R") <(without_es "$E") >"$WORK/eso-workloads.diff" \
  && ok "every other object identical to umbrella-kind (the workloads do not change)" \
  || { bad "umbrella-eso changes more than ExternalSecrets"; head -40 "$WORK/eso-workloads.diff"; }
! grep -q '^kind: Secret' "$E" && ! grep -q '^kind: \(Cluster\)\{0,1\}SecretStore' "$E" \
  && ok "ESO render: no Secret, no SecretStore (the store belongs to the cluster)" || bad "ESO render creates a Secret or store"
secret_refs() { # "<secret> <key>" for every Secret key the workloads of render $1 read (env, CNPG roles and initdb)
  awk '
    /secretKeyRef: \{name: / { n=$0; sub(/.*secretKeyRef: \{name: /, "", n); k=n; sub(/,.*/, "", n); sub(/.*key: /, "", k); sub(/\}.*/, "", k); print n, k; next }
    /^ *secretKeyRef:$/ { ref=1; next }
    ref && /^ *name: / { n=$2; next }
    ref && /^ *key: / { print n, $2; ref=0; next }
    /^ *(passwordSecret|secret):$/ { basic=1; next }
    basic && /^ *name: / { print $2, "username"; print $2, "password"; basic=0 }' "$1" | sort -u; }
es_keys() { # the keys ExternalSecret $1 (of render $E) writes: its data secretKeys and the template data keys
  doc "$1" ExternalSecret "$E" | awk '/^    - secretKey: / {print $3} /^      data:$/ {t=1; next} t && /^        [A-Za-z0-9._-]+:/ {k=$1; sub(/:$/, "", k); print k; next} t {t=0}' | sort -u; }
missing=""
while read -r name key; do
  es_keys "$name" | grep -qx -- "$key" || missing="$missing $name/$key"
done < <(secret_refs "$R"; echo "envoy-ratelimit-redis-auth auth")
[ -z "$missing" ] && ok "every Secret key the workloads read (plus envoy-ratelimit-redis-auth/auth) comes from an ExternalSecret" \
  || bad "Secret keys without an ExternalSecret:$missing"
roles_ok=1
while read -r role secret; do
  d=$(doc "$secret" ExternalSecret "$E")
  echo "$d" | grep -q 'type: kubernetes.io/basic-auth' && echo "$d" | grep -qx "        username: $role" || { roles_ok=0; bad "ExternalSecret $secret: basic-auth, username $role"; }
done < <(awk '/^      - name: / {r=$3} /^ *passwordSecret:$/ {p=1; next} p && /^ *name: / {print r, $2; p=0}
              /^ +owner: / {o=$2} /^      secret:$/ {s=1; next} s && /^ *name: / {print o, $2; s=0}' "$R")
[ "$roles_ok" = 1 ] && ok "CNPG role and initdb Secrets: kubernetes.io/basic-auth, username = role name (ADR-0012)"
n_es=$(grep -c '^kind: ExternalSecret' "$E")
[ "$(grep -c 'secretStoreRef: {kind: ClusterSecretStore, name: hoops}' "$E")" = "$n_es" ] \
  && [ "$(grep -c '^  refreshInterval: "1m"$' "$E")" = "$n_es" ] && [ "$(grep -c 'creationPolicy: Owner' "$E")" = "$n_es" ] \
  && [ "$(grep -c 'deletionPolicy: Retain' "$E")" = "$n_es" ] && [ "$(grep -c '^apiVersion: external-secrets.io/v1$' "$E")" = "$n_es" ] \
  && ok "all $n_es ExternalSecrets: external-secrets.io/v1, store hoops, refresh 1m, owned Secret, kept when the source value goes" \
  || bad "ExternalSecret store/refresh/policies"
a=$(doc envoy-ratelimit-redis-auth ExternalSecret "$E")
echo "$a" | grep -q '^  namespace: envoy-gateway-system$' && echo "$a" | grep -q 'mergePolicy: Replace' \
  && echo "$a" | grep -qx '        auth: "ratelimit:{{ .password }}"' \
  && echo "$a" | grep -q 'remoteRef: {key: hoops, property: RATELIMIT_REDIS_PASSWORD}' \
  && doc hoops-ratelimit-redis ExternalSecret "$E" | grep -q 'remoteRef: {key: hoops, property: RATELIMIT_REDIS_PASSWORD}' \
  && ok "Redis login: one source property, REDIS_AUTH = ratelimit:<password> in envoy-gateway-system" || bad "Redis login ExternalSecrets"
! grep -q 'name: hoops-dev-users' "$E" && ok "no hoops-dev-users ExternalSecret (no workload reads it)" || bad "hoops-dev-users ExternalSecret"

echo "== secret rotation (WP87, ADR-0012 amendment: Stakater Reloader)"
# global.reloader.enabled (on in values-kind.yaml): every Deployment/StatefulSet that reads a Secret (env secretKeyRef,
# envFrom secretRef, a secret volume) carries secret.reloader.stakater.com/auto on its own metadata, so Reloader rolls it
# when one of those Secrets changes (ESO refresh, secrets.sh); a workload that reads none carries nothing. Derived from
# the render, so a new workload or a new Secret reference is covered without touching this test.
workloads() { # "<kind>/<name> <reads a Secret 0|1> <annotated 0|1>" for every Deployment/StatefulSet of render $1
  awk 'BEGIN{RS="\n---\n"} /\nkind: (Deployment|StatefulSet)\n/ {
    n=split($0, L, "\n"); k=""; name=""; a=0; meta=0
    for (i = 1; i <= n; i++) {
      if (L[i] ~ /^kind: /) k=substr(L[i], 7)
      if (L[i] == "metadata:") { meta=1; continue }
      if (meta && L[i] ~ /^[^ ]/) meta=0
      if (meta && name == "" && L[i] ~ /^  name: /) name=substr(L[i], 9)
      if (meta && L[i] == "    secret.reloader.stakater.com/auto: \"true\"") a=1
    }
    print k "/" name, ($0 ~ /secretKeyRef:|secretRef:|secretName:/) ? 1 : 0, a }' "$1"; }
for f in umbrella-kind umbrella-eso service-all; do
  w=$(workloads "$WORK/$f.yaml")
  readers=$(echo "$w" | awk '$2 == 1 {print $1}' | tr '\n' ' ')
  wrong=$(echo "$w" | awk '$2 != $3 {print $1 "(reads " $2 ", annotated " $3 ")"}' | tr '\n' ' ')
  [ -n "$readers" ] && [ -z "$wrong" ] \
    && ok "$f: exactly the workloads that read a Secret roll on rotation: $readers" || bad "$f: Reloader annotation mismatch: $wrong"
done
[ "$(workloads "$R" | awk '$2 == 1 && $3 == 1' | wc -l | tr -d ' ')" -ge 6 ] \
  && workloads "$R" | grep -q '^Deployment/web 0 0$' \
  && ok "kind: core, game, athlete, keycloak, ratelimit-redis and redpanda annotated; web (no Secret) not" \
  || bad "kind: expected at least the six Secret readers annotated and web not"
! grep -h -A30 '^kind: Job$' "$R" | grep -q 'reloader.stakater.com' && ok "the redpanda-bootstrap Job is not annotated (helm upgrade re-runs it)" \
  || bad "a Job carries a Reloader annotation"
for f in umbrella-default umbrella-tls service-defaults; do
  grep -q 'reloader.stakater.com' "$WORK/$f.yaml" && { bad "$f: Reloader annotation rendered while global.reloader.enabled is off"; continue; }
  ok "$f: no Reloader annotation (global.reloader.enabled off)"
done
grep -qx '  reloader: {enabled: true}.*' "$CHART/values-kind.yaml" && ok "values-kind.yaml: global.reloader.enabled on" \
  || bad "values-kind.yaml does not switch global.reloader.enabled on"
# The controller is installed by deploy/kind/up.sh, pinned by chart version + digest and image digest (like ESO).
sha='sha256:[0-9a-f]\{64\}'
grep -q "^RELOADER_CHART_VERSION=\"[0-9][0-9.]*\"$" deploy/kind/up.sh && grep -q "^RELOADER_CHART_DIGEST=\"$sha\"$" deploy/kind/up.sh \
  && grep -q "^RELOADER_IMAGE_DIGEST=\"$sha\"$" deploy/kind/up.sh \
  && ok "Reloader pinned in deploy/kind/up.sh (chart version + digest, image digest)" || bad "Reloader not pinned in deploy/kind/up.sh"

echo "== observability (WP86, ADR-0046: OpenTelemetry collector)"
# global.observability.enabled (on in values-kind.yaml): an OTLP collector `otel-collector` (traces + logs, debug exporter,
# traces on to an in-memory Jaeger on kind), the services export to it (SDK on, logs on, parent-based ratio sampling,
# resource attributes without a tenant), the Envoy proxy traces the edge. Off: nothing rendered, the SDK stays off.
img_pinned() { # image line of document $1 matches repository $2 with tag and sha256 digest
  echo "$1" | grep -Eq "image: \"$2:[0-9][0-9.]*@sha256:[0-9a-f]{64}\""; }
hardened() { # document $1: non-root, read-only root FS, no privilege escalation, drop ALL, no token, memory limit
  echo "$1" | grep -q 'runAsNonRoot: true' && echo "$1" | grep -q 'readOnlyRootFilesystem: true' \
    && echo "$1" | grep -q 'allowPrivilegeEscalation: false' && echo "$1" | grep -A2 'capabilities:' | grep -q -- '- ALL\|drop: \[ALL\]' \
    && echo "$1" | grep -q 'automountServiceAccountToken: false' && echo "$1" | grep -A1 'limits:' | grep -q 'memory:'; }
oc=$(doc otel-collector Deployment)
img_pinned "$oc" docker.io/otel/opentelemetry-collector && hardened "$oc" \
  && echo "$oc" | grep -q 'name: config, mountPath: /etc/otelcol, readOnly: true' && echo "$oc" | grep -q 'checksum/config:' \
  && echo "$oc" | grep -q 'path: /, port: health' \
  && ok "kind: otel-collector pinned by digest, non-root, read-only root FS, config read-only (checksum rolls it), health probes" \
  || bad "otel-collector Deployment"
doc otel-collector Service | grep -q '{name: otlp-grpc, port: 4317, targetPort: otlp-grpc' \
  && doc otel-collector Service | grep -q '{name: otlp-http, port: 4318, targetPort: otlp-http' \
  && ok "otel-collector Service: OTLP gRPC 4317, OTLP/HTTP 4318" || bad "otel-collector Service"
cfg=$(doc otel-collector-config ConfigMap | awk '/^  config.yaml: \|$/ {c=1; next} c && /^    / {sub(/^    /, ""); print; next} c {exit}')
pipeline() { echo "$cfg" | awk -v p="    $1:" '$0 == p {f=1; next} f && /^      / {print; next} f {exit}'; }
echo "$cfg" | grep -q '^  otlp:$' && pipeline traces | grep -q 'receivers: \[otlp\]' && pipeline logs | grep -q 'receivers: \[otlp\]' \
  && pipeline traces | grep -q 'processors: \[memory_limiter, attributes/strip-ids, batch\]' && pipeline logs | grep -q 'processors: \[memory_limiter, batch\]' \
  && pipeline traces | grep -q 'exporters: \[debug, otlp_grpc/jaeger\]' && pipeline logs | grep -q 'exporters: \[debug\]' \
  && ! echo "$cfg" | grep -q '^    metrics:$' \
  && ok "collector pipelines: traces (debug + Jaeger) and logs (debug) from OTLP, memory_limiter first, ids stripped from spans, no metrics" \
  || bad "collector config: $(echo "$cfg" | tr '\n' ' ' | head -c 400)"
# Span attributes that carry concrete paths or message keys (tenant and other ids: /internal/usage/<tenant>, /platform/
# tenants/<id>, Kafka keys <tenant>:<id>) are deleted before any exporter; http.route (the template) and span names stay.
strip=$(echo "$cfg" | awk '/^  attributes\/strip-ids:$/ {s=1; next} s && /^    / {print; next} s {exit}' | { grep -o 'key: [a-z._]*' || true; } | sort | tr '\n' ' ')
[ "$strip" = "key: http.target key: http.url key: messaging.kafka.message.key key: url.full key: url.path key: url.query " ] \
  && [ "$(echo "$cfg" | awk '/^  attributes\/strip-ids:$/ {s=1; next} s && /^    / {print; next} s {exit}' | grep -c 'action: delete')" = 6 ] \
  && ok "spans: url.full, url.path, url.query, http.url, http.target and Kafka message keys deleted (no tenant id leaves)" || bad "strip-ids processor: $strip"
echo "$cfg" | grep -q 'endpoint: jaeger.hoops.svc.cluster.local:4317' && echo "$cfg" | grep -q 'insecure: true' \
  && echo "$cfg" | grep -q 'level: none' && ok "collector: traces to jaeger.hoops:4317, own metrics off" || bad "collector exporters/telemetry"
n=$(doc otel-collector NetworkPolicy)
admitted=$(echo "$n" | awk '/operator: In/ {i=1; next} i && /^ *values:$/ {next} i && /^ *- [a-z-]+$/ {print $2; next} i {exit}' | sort | tr '\n' ' ')
[ "$admitted" = "athlete-service core-service game-service " ] && echo "$n" | grep -q 'policyTypes: \[Ingress, Egress\]' \
  && [ "$(echo "$n" | grep -c -- '- from:')" = 2 ] && ! echo "$n" | grep -q 'namespaceSelector: {}' \
  && echo "$n" | awk '/- from:/ {f++} f==1 && /port: otlp-grpc/ {g=1} f==1 && /port: otlp-http/ {h=1} END {exit !(g && h)}' \
  && echo "$n" | awk '/- from:/ {f++} f==2 && /kubernetes.io\/metadata.name: envoy-gateway-system/ {e=1} f==2 && /app.kubernetes.io\/component: proxy/ {p=1} f==2 && /port: otlp-grpc/ {g=1} f==2 && /port: otlp-http/ {h=1} END {exit !(e && p && g && !h)}' \
  && echo "$n" | grep -q 'k8s-app: kube-dns' && [ "$(echo "$n" | grep -c -- '- to:')" = 2 ] \
  && echo "$n" | awk '/- to:/ {t++} t==2 && /app.kubernetes.io\/name: jaeger/ {j=1} t==2 && /port: 4317/ {p=1} END {exit !(j && p)}' \
  && ok "otel-collector NetworkPolicy: OTLP from the three services + Envoy proxies (gRPC), egress DNS + Jaeger only" \
  || bad "otel-collector NetworkPolicy (admitted: $admitted)"
for u in core-service game-service athlete-service; do
  doc "$u" Deployment | grep -q "app.kubernetes.io/name: $u" || bad "collector client $u has no Deployment with that name label"
done
j=$(doc jaeger Deployment)
img_pinned "$j" docker.io/jaegertracing/jaeger && hardened "$j" \
  && ok "kind: jaeger pinned by digest, non-root, read-only root FS, memory limit" || bad "jaeger Deployment"
doc jaeger-config ConfigMap | grep -q 'max_traces: 5000' && ! doc jaeger-config ConfigMap | grep -q '4318\|9411\|14250\|14268' \
  && ok "jaeger: in-memory store capped (5000 traces), OTLP gRPC receiver only" || bad "jaeger config"
n=$(doc jaeger NetworkPolicy)
echo "$n" | grep -q 'policyTypes: \[Ingress, Egress\]' && echo "$n" | grep -q 'egress: \[\]' \
  && [ "$(echo "$n" | grep -c -- '- from:')" = 1 ] && echo "$n" | grep -A6 -- '- from:' | grep -q 'app.kubernetes.io/name: otel-collector' \
  && echo "$n" | grep -q 'port: otlp-grpc' && ! echo "$n" | grep -q 'port: ui\|16686' \
  && ok "jaeger NetworkPolicy: OTLP from the collector only, UI by port-forward only, no egress" || bad "jaeger NetworkPolicy"
for s in core game athlete; do
  c=$(doc "$s-service-env" ConfigMap)
  echo "$c" | grep -qx '  QUARKUS_OTEL_SDK_DISABLED: "false"' \
    && echo "$c" | grep -qx '  QUARKUS_OTEL_EXPORTER_OTLP_ENDPOINT: "http://otel-collector.hoops.svc.cluster.local:4317"' \
    && echo "$c" | grep -qx '  QUARKUS_OTEL_TRACES_SAMPLER_ARG: "1.0"' \
    && echo "$c" | grep -qx '  QUARKUS_OTEL_RESOURCE_ATTRIBUTES: "service.namespace=hoops-academy,deployment.environment.name=kind,k8s.namespace.name=hoops"' \
    && ok "kind: $s-service exports to otel-collector:4317, all traces sampled, resource attributes without a tenant" \
    || bad "kind: $s-service OTel env"
  p=services/$s-service/src/main/resources/application.properties
  grep -qx 'quarkus.otel.logs.enabled=true' "$p" && grep -qx 'quarkus.otel.traces.sampler=parentbased_traceidratio' "$p" \
    && ok "$s-service build: logs exporter and parent-based ratio sampler compiled in (build-time keys)" || bad "$s-service OTel build keys"
  doc "$s-service-env" ConfigMap "$D" | grep -qx '  QUARKUS_OTEL_SDK_DISABLED: "true"' && ! doc "$s-service-env" ConfigMap "$D" | grep -q 'OTLP_ENDPOINT' \
    && ok "default: $s-service OTel SDK off, no endpoint" || bad "default: $s-service OTel env"
done
! grep -qi 'tenant' <(grep -h 'QUARKUS_OTEL_RESOURCE_ATTRIBUTES' "$WORK"/*.yaml) && ok "no tenant in any resource attribute" || bad "tenant in resource attributes"
e=$(doc hoops EnvoyProxy)
echo "$e" | grep -A8 '^    tracing:$' | grep -q 'type: OpenTelemetry' \
  && echo "$e" | grep -A8 '^    tracing:$' | grep -q 'backendRefs: \[{name: otel-collector, port: 4317}\]' \
  && echo "$e" | grep -A8 '^    tracing:$' | grep -q 'samplingFraction: {numerator: 10000, denominator: 10000}' \
  && ok "kind: Envoy proxy traces the edge to otel-collector:4317 (W3C traceparent, same ratio)" || bad "EnvoyProxy tracing"
for f in umbrella-default umbrella-tls service-defaults; do
  grep -q 'otel-collector\|jaeger\|tracing:' "$WORK/$f.yaml" && { bad "$f: observability rendered while global.observability.enabled is off"; continue; }
  ok "$f: no collector, no Jaeger, no edge tracing (global.observability.enabled off)"
done
grep -qx '  QUARKUS_OTEL_SDK_DISABLED: "true"' "$WORK/service-defaults.yaml" && ok "service chart alone: OTel SDK off" || bad "service chart default OTel"
a=$(doc demo-service-env ConfigMap "$WORK/service-all.yaml")
echo "$a" | grep -qx '  QUARKUS_OTEL_EXPORTER_OTLP_ENDPOINT: "http://otel-collector.hoops.svc.cluster.local:4317"' \
  && echo "$a" | grep -qx '  QUARKUS_OTEL_TRACES_SAMPLER_ARG: "0.25"' \
  && echo "$a" | grep -qx '  QUARKUS_OTEL_RESOURCE_ATTRIBUTES: "service.namespace=hoops-academy,deployment.environment.name=hoops,k8s.namespace.name=hoops"' \
  && ok "service chart with global.observability: endpoint, ratio from global, environment = namespace by default" || bad "service chart OTel on"
grep -q '^  observability: {enabled: true' "$CHART/values-kind.yaml" && ok "values-kind.yaml: global.observability.enabled on" \
  || bad "values-kind.yaml does not switch global.observability.enabled on"
# Another environment: the platform's own collector/agent (no chart collector), or the chart's collector forwarding to a
# backend (extra exporter, its credential from a Secret, an egress rule for it).
helm template hoops "$CHART" -n hoops -f "$CHART/values-kind.yaml" --set observability.collector.enabled=false \
  --set observability.jaeger.enabled=false --set global.observability.otlpEndpoint=http://otel-agent.monitoring:4317 > "$WORK/extra/agent.yaml"
! grep -q 'name: otel-collector\|name: jaeger' "$WORK/extra/agent.yaml" \
  && [ "$(grep -c 'QUARKUS_OTEL_EXPORTER_OTLP_ENDPOINT: "http://otel-agent.monitoring:4317"' "$WORK/extra/agent.yaml")" = 3 ] \
  && ! grep -q 'tracing:' "$WORK/extra/agent.yaml" \
  && ok "external collector: no chart collector, services and nothing else point at global.observability.otlpEndpoint" || bad "external collector"
refused 'otlpEndpoint' "${K[@]}" --set observability.collector.enabled=false \
  && refused 'jaeger' "${K[@]}" --set observability.collector.enabled=false --set global.observability.otlpEndpoint=http://x:4317 \
  && ok "collector off needs global.observability.otlpEndpoint; Jaeger needs the chart collector" || bad "collector-off guards"
helm template hoops "$CHART" -n hoops -f "$CHART/values-kind.yaml" --set observability.jaeger.enabled=false \
  --set-json 'observability.collector.exporters={"otlp_http/backend":{"endpoint":"https://otlp.example.test","headers":{"authorization":"Bearer ${env:BACKEND_TOKEN}"}}}' \
  --set-json 'observability.collector.pipelineExporters={"traces":["otlp_http/backend"],"logs":["otlp_http/backend"]}' \
  --set-json 'observability.collector.secretEnv=[{"name":"BACKEND_TOKEN","secretName":"otel-backend","key":"token"}]' \
  --set-json 'observability.collector.networkPolicy.extraEgress=[{"ports":[{"port":443,"protocol":"TCP"}]}]' > "$WORK/extra/backend.yaml"
bcfg=$(doc otel-collector-config ConfigMap "$WORK/extra/backend.yaml")
bd=$(doc otel-collector Deployment "$WORK/extra/backend.yaml")
echo "$bcfg" | grep -q 'exporters: \[debug, otlp_http/backend\]' && [ "$(echo "$bcfg" | grep -c 'exporters: \[debug, otlp_http/backend\]')" = 2 ] \
  && echo "$bcfg" | grep -q 'Bearer ${env:BACKEND_TOKEN}' && ! grep -q 'name: jaeger' "$WORK/extra/backend.yaml" \
  && echo "$bd" | grep -q 'secretKeyRef: {name: otel-backend, key: token}' && echo "$bd" | grep -q 'secret.reloader.stakater.com/auto: "true"' \
  && doc otel-collector NetworkPolicy "$WORK/extra/backend.yaml" | grep -q 'port: 443' \
  && ok "backend: extra exporter in both pipelines, its token from a Secret (Reloader rolls it), egress rule added" || bad "collector backend wiring"

echo "== gitleaks (rendered manifests)"
if command -v gitleaks >/dev/null; then
  if cat "$WORK"/*.yaml | gitleaks detect --pipe --no-banner --redact --config .gitleaks.toml >"$WORK/gl.txt" 2>&1; then ok "gitleaks clean"
  else bad gitleaks; cat "$WORK/gl.txt"; fi
else echo "  skip gitleaks (not installed)"; fi

[ "$fail" = 0 ] && echo "ALL CHART TESTS PASSED" || { echo "CHART TESTS FAILED"; exit 1; }
