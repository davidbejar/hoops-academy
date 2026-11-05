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

echo "== snapshots"
for f in "$WORK"/*.yaml; do
  n=$(basename "$f")
  if [ "$UPDATE" = 1 ]; then cp "$f" "$SNAP/$n"; ok "recorded $n"
  elif [ ! -f "$SNAP/$n" ]; then bad "missing snapshot $n (run with --update)"
  elif diff -u "$SNAP/$n" "$f" > "$WORK/$n.diff"; then ok "$n"
  else bad "$n differs:"; head -60 "$WORK/$n.diff"; fi
done

echo "== schema validation"
if command -v kubeconform >/dev/null; then
  # CRDs (CNPG Cluster, Gateway API, Envoy Gateway policies) from the datree catalog; -strict rejects unknown fields.
  # The authoritative check against the pinned CRD versions is `kubectl apply --dry-run=server` on kind (kind.md).
  if kubeconform -strict -summary -kubernetes-version "${K8S_VERSION:-1.34.0}" -schema-location default \
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
! grep -q 'ingress-nginx\|nginx.ingress.kubernetes.io' "$WORK"/*.yaml && ok "no ingress-nginx namespace or annotation left" || bad "ingress-nginx reference left"
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
ratelimited() { # BackendTrafficPolicy $1 targets HTTPRoute $1 with $2 requests/minute per client IP (IPv4 + IPv6)
  local d; d=$(doc "$1" BackendTrafficPolicy)
  echo "$d" | grep -q "kind: HTTPRoute, name: $1}" && [ "$(echo "$d" | grep -c "requests: $2, unit: Minute")" = 2 ] \
    && echo "$d" | grep -q 'sourceCIDR: {type: Distinct, value: 0.0.0.0/0}' && echo "$d" | grep -q 'sourceCIDR: {type: Distinct, value: "::/0"}'; }
ratelimited keycloak-ratelimited 60 && ok "token endpoint + login form: local rate limit 60/min per client IP" || bad "keycloak rate limit"
routes_to game-service-events-batch '/api/game/matches/[^/]+/events(:|%3[Aa])batch' RegularExpression game-service \
  && ok "events:batch (and %3A) regex route, path not rewritten" || bad "events:batch route"
ratelimited game-service-events-batch 120 && ok "events:batch: local rate limit 120/min per client IP" || bad "events:batch rate limit"
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

echo "== gitleaks (rendered manifests)"
if command -v gitleaks >/dev/null; then
  if cat "$WORK"/*.yaml | gitleaks detect --pipe --no-banner --redact --config .gitleaks.toml >"$WORK/gl.txt" 2>&1; then ok "gitleaks clean"
  else bad gitleaks; cat "$WORK/gl.txt"; fi
else echo "  skip gitleaks (not installed)"; fi

[ "$fail" = 0 ] && echo "ALL CHART TESTS PASSED" || { echo "CHART TESTS FAILED"; exit 1; }
