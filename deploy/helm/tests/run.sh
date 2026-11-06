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

echo "== gitleaks (rendered manifests)"
if command -v gitleaks >/dev/null; then
  if cat "$WORK"/*.yaml | gitleaks detect --pipe --no-banner --redact --config .gitleaks.toml >"$WORK/gl.txt" 2>&1; then ok "gitleaks clean"
  else bad gitleaks; cat "$WORK/gl.txt"; fi
else echo "  skip gitleaks (not installed)"; fi

[ "$fail" = 0 ] && echo "ALL CHART TESTS PASSED" || { echo "CHART TESTS FAILED"; exit 1; }
