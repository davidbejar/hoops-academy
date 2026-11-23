#!/usr/bin/env bash
# Helm chart tests (WP16): lint, golden snapshots, schema validation, policy assertions, secret scan.
#   deploy/helm/tests/run.sh            verify
#   deploy/helm/tests/run.sh --update   re-record snapshots after an intended change (review the diff!)
# Snapshots: umbrella-kind and the service-* renders whole; the other umbrella renders as their difference to a base
# render (see "== snapshots"); every check below runs on the whole renders.
# Snapshots include infra/keycloak/realm-academy.json and infra/db/init/01_roles_schemas.sql (copied into the charts
# by scripts/sync-chart-files.sh; a stale copy fails the drift check), so a change there shows up here on purpose.
set -euo pipefail
cd "$(dirname "$0")/../../.."
CHART=deploy/helm/hoops
SNAP=deploy/helm/tests/snapshots
UPDATE=0; [ "${1:-}" = "--update" ] && UPDATE=1
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
fail=0
# shellcheck source=deploy/lib/common.sh
. deploy/lib/common.sh

echo "== chart file copies (no symlinks, identical to their sources)"
if scripts/sync-chart-files.sh --check; then ok "realm JSON, init SQL and login theme copies in sync"
else bad "chart copies drifted: run scripts/sync-chart-files.sh"; fi

echo "== library chart (ADR-0068: one copy of what the service sub-charts share)"
LIB="$CHART/charts/hoops-lib"
SERVICE_CHARTS=(hoops-service pdf-service finance-service)
grep -qx 'type: library' "$LIB/Chart.yaml" 2>/dev/null && grep -A1 -- '- name: hoops-lib$' "$CHART/Chart.yaml" | grep -q 'version:' \
  && ok "hoops-lib is a library chart and a dependency of the umbrella" || bad "hoops-lib library chart missing from the umbrella"
for c in "${SERVICE_CHARTS[@]}"; do
  grep -A2 -- '- name: hoops-lib$' "$CHART/charts/$c/Chart.yaml" | grep -q 'repository: file://../hoops-lib' \
    || bad "$c does not declare hoops-lib (repository file://../hoops-lib)"
done
own=$(for c in "${SERVICE_CHARTS[@]}"; do
  grep -lE 'define "[a-z-]+\.(fullname|selectorLabels|labels|image|parentRefs|ruleTimeouts|hostnames|eventsEnabled)"' \
    "$CHART/charts/$c"/templates/*; done | tr "\n" " " || true)
[ -z "$own" ] && ok "no service sub-chart defines its own fullname/labels/image/route helpers" || bad "helpers still copied in: $own"
for f in "${SERVICE_CHARTS[@]/%//templates/service.yaml}" hoops-service/templates/httproute.yaml finance-service/templates/httproute.yaml; do
  [ "$(grep -cv '^ *$' "$CHART/charts/$f")" = 1 ] && grep -q 'include "hoops-lib\.' "$CHART/charts/$f" || bad "$f is not one include of hoops-lib"
done
ok "service.yaml and httproute.yaml of the service sub-charts are one include of hoops-lib each (unless a FAIL above)"
standalone() { # a service sub-chart rendered alone: a copy with hoops-lib resolved (nothing written into the repository)
  local d="$WORK/standalone"
  [ -d "$d/hoops-lib" ] || { mkdir -p "$d"; cp -R "$LIB" "$d/"; }
  [ -d "$d/$1" ] || { cp -R "$CHART/charts/$1" "$d/"; helm dependency update --skip-refresh "$d/$1" >/dev/null; }
  echo "$d/$1"; }

echo "== helm lint"
for c in "$CHART" "$CHART"/charts/*/; do
  case " ${SERVICE_CHARTS[*]} " in *" $(basename "$c") "*) c=$(standalone "$(basename "$c")") ;; esac
  if helm lint --strict "$c" -f "$CHART/values-kind.yaml" >"$WORK/lint.txt" 2>&1 || helm lint --strict "$c" >"$WORK/lint.txt" 2>&1; then
    ok "lint $c"
  else bad "lint $c"; cat "$WORK/lint.txt"; fi
done

echo "== render"
render() { # name args...
  local name="$1"; shift
  helm template "$@" > "$WORK/$name.yaml"
}
render umbrella-default   hoops "$CHART" -n hoops
render umbrella-kind      hoops "$CHART" -n hoops -f "$CHART/values-kind.yaml"
render service-defaults   svc "$(standalone hoops-service)" -n hoops
render service-all        svc "$(standalone hoops-service)" -n hoops -f deploy/helm/tests/values/service-all-features.yaml
render umbrella-tls       hoops "$CHART" -n hoops -f deploy/helm/tests/values/umbrella-tls.yaml
render umbrella-eso       hoops "$CHART" -n hoops -f "$CHART/values-kind.yaml" -f deploy/helm/tests/values/umbrella-eso.yaml
render umbrella-cloud     hoops "$CHART" -n hoops -f "$CHART/values-cloud.yaml" -f deploy/helm/tests/values/umbrella-cloud.yaml

echo "== snapshots"
# DEP-03: the five umbrella renders share most of their documents. umbrella-kind is stored whole; each other umbrella
# render stores only what differs from its base (base_of): its documents whose text differs from the base's document of the
# same source, kind, namespace and name, its new documents, and a "# removed:" line per base document it lacks. The
# password blocklist (10,000 lines, a verbatim chart file) is stored as a pointer; the check below compares it whole.
BLOCKLIST="$CHART/charts/keycloak/files/hoops-password-blocklist.txt"
BLOCKLIST_KEY='  hoops-password-blocklist.txt: |'
base_of() { case "$1" in umbrella-default|umbrella-eso|umbrella-cloud) echo umbrella-kind ;; umbrella-tls) echo umbrella-default ;; esac; }
compact() { # render $1 with the blocklist body replaced by a pointer to its file
  awk -v key="$BLOCKLIST_KEY" -v file="$BLOCKLIST" '
    skip && /^    / { next } { skip=0 }
    $0 == key { print; print "    # = " file " (not stored; deploy/helm/tests/run.sh compares it whole)"; skip=1; next }
    { print }' "$1"; }
delta() { # documents of render $2 that differ from render $1 (both compacted), as described above
  awk 'function id(d,   s, k, ns, n) {
         s = match(d, /# Source: [^\n]*/) ? substr(d, RSTART + 10, RLENGTH - 10) : ""
         k = match(d, /\nkind: [^\n]*/) ? substr(d, RSTART + 7, RLENGTH - 7) : ""
         ns = match(d, /\n  namespace: [^\n]*/) ? substr(d, RSTART + 13, RLENGTH - 13) : ""
         n = match(d, /\nmetadata:\n  name: [^\n]*/) ? substr(d, RSTART + 18, RLENGTH - 18) : ""
         return s " " k " " ns "/" n }
       BEGIN { RS = "\n---\n" }
       { sub(/^---\n/, ""); sub(/\n+$/, ""); i = id($0) }
       FNR == NR { if (i in base) { print "duplicate document " i > "/dev/stderr"; exit 2 } base[i] = $0; order[++nb] = i; next }
       { seen[i] = 1; if (base[i] != $0) printf "---\n%s\n", $0 }
       END { for (j = 1; j <= nb; j++) if (!(order[j] in seen)) print "# removed: " order[j] }' \
    <(compact "$1") <(compact "$2"); }
mkdir -p "$WORK/snap"
for f in "$WORK"/*.yaml; do
  n=$(basename "$f" .yaml); b=$(base_of "$n")
  if [ -n "$b" ]; then
    { echo "# $n: the documents that differ from $b (deploy/helm/tests/run.sh, DEP-03)"; delta "$WORK/$b.yaml" "$f"; } > "$WORK/snap/$n.yaml"
  else compact "$f" > "$WORK/snap/$n.yaml"; fi
done
for f in "$WORK"/snap/*.yaml; do
  n=$(basename "$f")
  if [ "$UPDATE" = 1 ]; then cp "$f" "$SNAP/$n"; ok "recorded $n"
  elif [ ! -f "$SNAP/$n" ]; then bad "missing snapshot $n (run with --update)"
  elif diff -u "$SNAP/$n" "$f" > "$WORK/$n.diff"; then ok "$n"
  else bad "$n differs:"; head -60 "$WORK/$n.diff"; fi
done
blocklist_ok=1
for n in umbrella-default umbrella-kind umbrella-tls umbrella-eso umbrella-cloud; do
  # (nindent leaves one whitespace-only line after the file's last newline)
  awk -v key="$BLOCKLIST_KEY" 'on && /^    / { print substr($0, 5); next } { on=0 } $0 == key { on=1 }' "$WORK/$n.yaml" \
    | sed '$ { /^$/d; }' | cmp -s - "$BLOCKLIST" || { blocklist_ok=0; bad "$n: the password blocklist ConfigMap is not $BLOCKLIST verbatim"; }
done
[ "$blocklist_ok" = 1 ] && ok "every umbrella render carries $BLOCKLIST verbatim (the snapshots store a pointer)"

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
  # latter with an always-true path selector so its descriptor differs from the per-minute rule's (Envoy Gateway v1.9 and v1.10, WP100)
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
routes_to core-service-academy-requests '/platform/academy-requests' RegularExpression core-service \
  && ratelimited core-service-academy-requests 10 2 \
  && ok "academy requests (public, WP90): exact-path route, global rate limit 10/min and 2/s per client IP" || bad "academy-requests rate limit"
# WP96/WP100: the CSV exports (one page-by-page read of up to 10,000 rows each) get the same brake, the colon or %3A form.
for spec in 'roster-export:/api/core/teams/[^/]+/roster(:|%3[Aa])export' 'audit-export:/api/core/audit-events(:|%3[Aa])export' \
    'platform-audit-export:/platform/audit-events(:|%3[Aa])export'; do
  n=${spec%%:*}; p=${spec#*:}
  routes_to "core-service-$n" "$p" RegularExpression core-service && ratelimited "core-service-$n" 10 2 \
    && ok "$n (WP96): regex route incl. %3A, path not rewritten, global rate limit 10/min and 2/s per client IP" || bad "$n rate limit"
done
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
# ADR-0022 amendment: the script that applies the look chosen in the app must sit where theme.properties names it.
doc keycloak-theme ConfigMap | grep -q '^  hoops-theme.js: |' && doc keycloak-theme ConfigMap | grep -q 'scripts=js/hoops-theme.js' \
  && doc keycloak Deployment | grep -q 'key: hoops-theme.js, path: resources/js/hoops-theme.js' \
  && ok "login theme script mounted at resources/js/hoops-theme.js" || bad "login theme script not mounted"
doc mailhog Service | grep -q 'port: 1025' && ok "kind: SMTP sink Service mailhog:1025 (realm smtpServer)" || bad "mailhog in kind"
! grep -q 'name: mailhog' "$WORK/umbrella-default.yaml" && ok "SMTP sink disabled outside kind" || bad "mailpit enabled by default"
# WP100: core's decision e-mails (WP90) go to the same SMTP host as Keycloak's; the login link uses the public URL; the
# password of a real server comes from the optional Secret hoops-smtp (absent on kind: the pod starts without it).
c=$(doc core-service-env ConfigMap)
echo "$c" | grep -qx '  SMTP_HOST: "mailhog"' && echo "$c" | grep -qx '  SMTP_PORT: "1025"' && echo "$c" | grep -qx '  SMTP_START_TLS: "OPTIONAL"' \
  && echo "$c" | grep -qx '  MAIL_FROM: "Hoops Academy <no-reply@hoops.localhost>"' && echo "$c" | grep -qx '  HOOPS_PUBLIC_URL: "http://localhost:8090"' \
  && ! echo "$c" | grep -q 'SMTP_PASSWORD' \
  && doc core-service Deployment | grep -A6 -- '- name: SMTP_PASSWORD$' | grep -q 'name: hoops-smtp$' \
  && doc core-service Deployment | grep -A6 -- '- name: SMTP_PASSWORD$' | grep -q 'optional: true$' \
  && ok "core SMTP: mailhog:1025, STARTTLS optional, MAIL_FROM, HOOPS_PUBLIC_URL = global.publicUrl, SMTP_PASSWORD from optional Secret hoops-smtp" \
  || bad "core SMTP env"
doc core-service-env ConfigMap "$WORK/umbrella-tls.yaml" | grep -qx '  HOOPS_PUBLIC_URL: "https://hoops.example.test"' \
  && ok "TLS: HOOPS_PUBLIC_URL follows global.publicUrl" || bad "TLS HOOPS_PUBLIC_URL"
! grep -q 'optional: true' "$WORK/service-defaults.yaml" && doc demo-service Deployment "$WORK/service-all.yaml" | grep -A6 -- '- name: DEMO_OPTIONAL$' | grep -q 'optional: true$' \
  && [ "$(grep -c 'optional: true' "$R")" = 1 ] \
  && ok "service chart: secretEnv[].optional renders optional: true only where set" || bad "secretEnv optional"

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
[ "$admitted" = "athlete-service core-service finance-service game-service redpanda-bootstrap " ] \
  && echo "$n" | grep -q 'policyTypes: \[Ingress, Egress\]' && [ "$(echo "$n" | grep -c -- '- from:')" = 2 ] \
  && echo "$n" | awk '/- from:/ {f++} f==1 && /port: kafka/ {k=1} f==1 && /port: admin/ {a=1} END {exit !(k && !a)}' \
  && echo "$n" | awk '/- from:/ {f++} f==2 && /redpanda-bootstrap/ {b=1} f==2 && /port: admin/ {a=1} f==2 && /port: kafka/ {k=1} END {exit !(b && a && !k)}' \
  && ! echo "$n" | grep -q 'namespaceSelector: {}' && echo "$n" | grep -q 'k8s-app: kube-dns' && [ "$(echo "$n" | grep -c -- '- to:')" = 1 ] \
  && ok "redpanda NetworkPolicy: Kafka from the four consuming/producing services + bootstrap Job, admin API from the Job only, egress DNS only" \
  || bad "redpanda NetworkPolicy (admitted: $admitted)"
for u in core-service game-service athlete-service finance-service; do
  doc "$u" Deployment | grep -q "app.kubernetes.io/name: $u" || bad "events user $u has no Deployment with that name label"
done
j=$(doc redpanda-bootstrap Job)
echo "$j" | grep -q 'helm.sh/hook: post-install,post-upgrade' && echo "$j" | grep -q 'helm.sh/hook-delete-policy: before-hook-creation' \
  && echo "$j" | grep -q 'readOnlyRootFilesystem: true' && echo "$j" | grep -q 'automountServiceAccountToken: false' \
  && all_of() { local x; for x in admin core-service game-service athlete-service finance-service; do "$@" "$x" || return 1; done; } \
  && job_reads() { echo "$j" | grep -q "secretKeyRef: {name: hoops-redpanda-$1, key: password}"; } && all_of job_reads \
  && ok "bootstrap Job: post-install/upgrade hook, passwords from the five Secrets, read-only root FS" || bad "bootstrap Job"
script=deploy/helm/hoops/files/redpanda-bootstrap.sh
! grep -v '^ *#' "$script" | grep -q -- '--password\|--new-password\|-X pass\|-u "\|--user ' && grep -q 'kafka_enable_authorization\|cluster-config' "$script" \
  && ok "bootstrap script puts no password on a command line (RPK_PASS env, curl netrc fd + stdin)" || bad "bootstrap script command lines"
users=$(doc redpanda-bootstrap ConfigMap | awk '/^  users: \|$/ {c=1; next} c && /^    / {sub(/^    /, ""); print; next} c {exit}')
[ "$users" = "$(printf '0 core-service core. - -\n1 game-service - core. game-service.\n2 athlete-service - core. athlete-service.\n3 finance-service - core. finance-service.')" ] \
  && ok "ACLs: core-service writes core.*, game/athlete/finance-service read core.* with groups <service>.*" || bad "events users/ACLs: $users"
! grep -q 'redpanda' "$WORK/umbrella-default.yaml" && ok "default: no event broker (events.enabled off)" || bad "redpanda rendered by default"
e=$(awk 'BEGIN{RS="\n---\n"} /\nkind: ExternalSecret\n/ && /name: hoops-redpanda-/' "$WORK/umbrella-eso.yaml")
[ "$(echo "$e" | grep -c '^kind: ExternalSecret')" = 5 ] && [ "$(echo "$e" | grep -c 'type: kubernetes.io/basic-auth')" = 5 ] \
  && es_login() { local d; d=$(doc "hoops-redpanda-$1" ExternalSecret "$WORK/umbrella-eso.yaml")
       echo "$d" | grep -qx "        username: $1" && echo "$d" | grep -q "property: REDPANDA_$(echo "${1%-service}" | tr '[:lower:]' '[:upper:]')$([ "$1" = admin ] || echo _SERVICE)_PASSWORD}"; } \
  && all_of es_login \
  && ok "ESO: five broker logins (basic-auth, username = user, REDPANDA_*_PASSWORD)" || bad "ESO broker logins"

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
  ! echo "$c" | grep -q '_OUTBOX_POLL_INTERVAL: "off"\|_OUTBOX_ENABLED: "false"\|_ROSTER_CONSUMER_ENABLED: "false"' \
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
# WP91/WP100: hoops.outbox.enabled=false keeps core quiet without a broker (no KafkaProducer, so no NetworkClient warnings
# about localhost:19092); the poll interval switch alone stopped the publisher job but not the producer's connection attempts.
doc core-service-env ConfigMap "$D" | grep -qx '  CORE_OUTBOX_ENABLED: "false"' \
  && doc core-service-env ConfigMap "$D" | grep -qx '  CORE_OUTBOX_POLL_INTERVAL: "off"' \
  && ok "events off: core publisher and producer off (CORE_OUTBOX_ENABLED=false, CORE_OUTBOX_POLL_INTERVAL=off)" || bad "events off: core publisher"
# Decision 66 (ADR-0037 flip, WP98/WP100): rosterSource empty = replica with events, rest without; always rendered
# explicitly, so the services' own default (replica) never applies to a release without a broker.
for s in game athlete; do
  doc "$s-service-env" ConfigMap "$D" | grep -qx "  $(upper "$s")_ROSTER_CONSUMER_ENABLED: \"false\"" \
    && ok "events off: $s consumer off ($(upper "$s")_ROSTER_CONSUMER_ENABLED=false)" || bad "events off: $s consumer"
  doc "$s-service-env" ConfigMap "$R" | grep -qx "  $(upper "$s")_ROSTER_SOURCE: \"replica\"" \
    && doc "$s-service-env" ConfigMap "$D" | grep -qx "  $(upper "$s")_ROSTER_SOURCE: \"rest\"" \
    && ok "$s roster source replica with events (kind), rest without (default render)" || bad "$s roster source default"
done
! grep -q 'ROSTER_SOURCE\|ROSTER_CONSUMER\|OUTBOX_POLL' "$WORK/service-defaults.yaml" && ! grep -q 'KAFKA_' "$WORK/service-defaults.yaml" \
  && ok "service chart alone: no broker client, no switches" || bad "service chart defaults carry event settings"
a=$(doc demo-service-env ConfigMap "$WORK/service-all.yaml")
echo "$a" | grep -qx '  KAFKA_SASL_USERNAME: "demo-service"' && echo "$a" | grep -qx '  KAFKA_BOOTSTRAP_SERVERS: "redpanda.hoops.svc.cluster.local:9092"' \
  && ! echo "$a" | grep -q 'DEMO_EVENTS' && doc demo-service Deployment "$WORK/service-all.yaml" | grep -A5 -- '- name: KAFKA_SASL_PASSWORD$' | grep -q 'name: hoops-redpanda-demo-service$' \
  && ok "service chart with global.events.enabled: client named after the service, events.offEnv not applied" || bad "service chart events on"
# Rollback of one service to rest (ADR-0037 "Rollback to rest"): only athlete's ConfigMap (and so its checksum) changes;
# an explicit replica with events renders the same as the default.
helm template hoops "$CHART" -n hoops -f "$CHART/values-kind.yaml" --set athlete.rosterSource=rest > "$WORK/extra/rest.yaml"
helm template hoops "$CHART" -n hoops -f "$CHART/values-kind.yaml" --set athlete.rosterSource=replica --set game.rosterSource=replica > "$WORK/extra/replica.yaml"
doc athlete-service-env ConfigMap "$WORK/extra/rest.yaml" | grep -qx '  ATHLETE_ROSTER_SOURCE: "rest"' \
  && [ "$(diff "$R" "$WORK/extra/rest.yaml" | grep -c '^[<>]')" = 4 ] \
  && [ "$(diff "$R" "$WORK/extra/rest.yaml" | grep '^[<>]' | grep -vc 'ATHLETE_ROSTER_SOURCE\|checksum/env')" = 0 ] \
  && diff -q "$R" "$WORK/extra/replica.yaml" >/dev/null \
  && ok "--set athlete.rosterSource=rest changes ATHLETE_ROSTER_SOURCE (and the pod checksum) only; explicit replica = default" || bad "athlete rollback to rest"
refused() { # message helm-args...: the render fails and names the message
  local m="$1"; shift
  ! helm template hoops "$CHART" -n hoops "$@" >/dev/null 2>"$WORK/extra/refused.txt" && grep -q -- "$m" "$WORK/extra/refused.txt"; }
K=(-f "$CHART/values-kind.yaml")
refused 'global.events.enabled' --set events.enabled=true && refused 'global.events.enabled' "${K[@]}" --set global.events.enabled=false \
  && ok "events.enabled and global.events.enabled must agree (broker and clients switch together)" || bad "events switch mismatch rendered"
refused 'rosterSource' --set athlete.rosterSource=replica && refused 'rosterSource' --set game.rosterSource=replica \
  && refused 'rosterSource' "${K[@]}" --set game.rosterSource=cache \
  && ok "rosterSource: empty|rest|replica only, replica only with events" || bad "rosterSource guard"
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
secret_refs() { # "<secret> <key>" for every Secret key the workloads of render $1 read (env, CNPG roles and initdb); an
  # optional reference (secretEnv[].optional, WP100: hoops-smtp for a real SMTP server) may have no source and is skipped
  awk '
    ref == 2 && !/^ *optional: true$/ { print pk }
    ref == 2 { ref=0 }
    /secretKeyRef: \{name: / { n=$0; sub(/.*secretKeyRef: \{name: /, "", n); k=n; sub(/,.*/, "", n); sub(/.*key: /, "", k); sub(/\}.*/, "", k); print n, k; next }
    /^ *secretKeyRef:$/ { ref=1; next }
    ref && /^ *name: / { n=$2; next }
    ref && /^ *key: / { pk=n " " $2; ref=2; next }
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
# WP86 (WP87's rotation proof on kind): CNPG watches only Secrets labelled cnpg.io/reload; without the label a rotated role
# password reached the Secret (and Reloader restarted the service) but not the database role, so the new pod never got Ready.
unlabelled=""
while read -r _ secret; do
  doc "$secret" ExternalSecret "$E" | awk '/^      metadata:$/ {m=1; next} m && /^      [a-z]/ {exit} m' | grep -q 'cnpg.io/reload: "true"' \
    || unlabelled="$unlabelled $secret(ESO)"
  grep -Eq "^db_role $secret " deploy/kind/secrets.sh || unlabelled="$unlabelled $secret(secrets.sh)"
done < <(awk '/^      - name: / {r=$3} /^ *passwordSecret:$/ {p=1; next} p && /^ *name: / {print r, $2; p=0}
              /^ +owner: / {o=$2} /^      secret:$/ {s=1; next} s && /^ *name: / {print o, $2; s=0}' "$R")
[ -z "$unlabelled" ] && ok "every CNPG role/initdb Secret carries cnpg.io/reload (ESO template and secrets.sh): CNPG applies a rotated password" \
  || bad "CNPG Secrets without cnpg.io/reload:$unlabelled"
! grep -q 'cnpg.io/reload' <(awk 'BEGIN{RS="\n---\n"} /\nkind: ExternalSecret\n/ && !/name: (hoops-db-|keycloak-db-app)/' "$E") \
  && ok "no other Secret carries cnpg.io/reload" || bad "cnpg.io/reload on a non-CNPG Secret"
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
# The controller is installed by deploy/kind/up.sh and deploy/cloud/install.sh from deploy/lib/platform.sh, pinned by
# chart version + digest and image digest (like ESO).
sha='sha256:[0-9a-f]\{64\}'; P=deploy/lib/platform.sh
grep -q "^RELOADER_CHART_VERSION=\"[0-9][0-9.]*\"$" "$P" && grep -q "^RELOADER_CHART_DIGEST=\"$sha\"$" "$P" \
  && grep -q "^RELOADER_IMAGE_DIGEST=\"$sha\"$" "$P" \
  && ok "Reloader pinned in $P (chart version + digest, image digest)" || bad "Reloader not pinned in $P"

echo "== observability (WP86 / WP120, ADR-0046: OpenTelemetry collector, Grafana LGTM on kind)"
# global.observability.enabled (on in values-kind.yaml): an OTLP collector `otel-collector` (traces + logs over OTLP, the
# services' /q/metrics scraped; debug exporter, on kind everything on to one Grafana LGTM pod `lgtm`; the cloud keeps the
# in-memory Jaeger), the services export to it (SDK on, logs on, parent-based ratio sampling, resource attributes without a
# tenant), the Envoy proxy traces the edge. Off: nothing rendered, the SDK stays off.
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
  && pipeline traces | grep -q 'exporters: \[debug, otlp_grpc/lgtm\]' && pipeline logs | grep -q 'exporters: \[debug, otlp_grpc/lgtm\]' \
  && pipeline metrics | grep -q 'receivers: \[otlp, prometheus\]' && pipeline metrics | grep -q 'processors: \[memory_limiter, batch\]' \
  && pipeline metrics | grep -q 'exporters: \[debug, otlp_grpc/lgtm\]' \
  && ok "kind collector pipelines: traces, logs (OTLP) and metrics (OTLP + scraped) to debug and LGTM, memory_limiter first, ids stripped from spans" \
  || bad "collector config: $(echo "$cfg" | tr '\n' ' ' | head -c 400)"
# The services' Prometheus endpoints (hoops_authz_denied_total, Micrometer's http_server_requests) reach the backend through
# the collector: one scrape job per enabled service, named after it (= service.name of the metric), its Service and port.
jobs=$(echo "$cfg" | { grep -o 'job_name: [a-z-]*' || true; } | awk '{print $2}' | sort | tr '\n' ' ')
scrape_ok=1
for t in core-service:8081 game-service:8082 athlete-service:8083 pdf-service:8084 finance-service:8085; do
  echo "$cfg" | grep -A3 -- "- job_name: ${t%:*}$" | grep -q "static_configs: \[{targets: \[\"${t%:*}.hoops.svc.cluster.local:${t#*:}\"\]}\]" || scrape_ok=0
done
[ "$jobs" = "athlete-service core-service finance-service game-service pdf-service " ] && [ "$scrape_ok" = 1 ] \
  && [ "$(echo "$cfg" | grep -c 'metrics_path: /q/metrics')" = 5 ] && [ "$(echo "$cfg" | grep -c 'scrape_interval: 30s')" = 5 ] \
  && ok "collector scrapes /q/metrics of the five services every 30 s (job = service name, target = its Service and port)" \
  || bad "collector scrape jobs: $jobs"
! echo "$cfg" | grep -q 'verbosity: normal' \
  && ok "kind collector debug exporter at basic (counts only: no log body or span in the collector's own log, P-07)" || bad "kind debugVerbosity"
# Span attributes that carry concrete paths or message keys (tenant and other ids: /internal/usage/<tenant>, /platform/
# tenants/<id>, Kafka keys <tenant>:<id>) are deleted before any exporter; http.route (the template) and span names stay.
strip=$(echo "$cfg" | awk '/^  attributes\/strip-ids:$/ {s=1; next} s && /^    / {print; next} s {exit}' | { grep -o 'key: [a-z._]*' || true; } | sort | tr '\n' ' ')
[ "$strip" = "key: http.target key: http.url key: messaging.kafka.message.key key: url.full key: url.path key: url.query " ] \
  && [ "$(echo "$cfg" | awk '/^  attributes\/strip-ids:$/ {s=1; next} s && /^    / {print; next} s {exit}' | grep -c 'action: delete')" = 6 ] \
  && ok "spans: url.full, url.path, url.query, http.url, http.target and Kafka message keys deleted (no tenant id leaves)" || bad "strip-ids processor: $strip"
echo "$cfg" | grep -q 'endpoint: lgtm.hoops.svc.cluster.local:4317' && echo "$cfg" | grep -q 'insecure: true' \
  && ! echo "$cfg" | grep -q 'jaeger' \
  && echo "$cfg" | grep -q 'level: none' && ok "kind collector: everything to lgtm.hoops:4317, no Jaeger, own metrics off" || bad "collector exporters/telemetry"
n=$(doc otel-collector NetworkPolicy)
admitted=$(echo "$n" | awk '/operator: In/ {i=1; next} i && /^ *values:$/ {next} i && /^ *- [a-z-]+$/ {print $2; next} i {exit}' | sort | tr '\n' ' ')
# egress rules by the pod name they select and their port, e.g. "lgtm:4317 core-service:8081"
egress=$(echo "$n" | awk '/^  egress:/ {e=1} e && /- to:/ {name=""} e && match($0, /app\.kubernetes\.io\/name: [a-z-]+/) {name=substr($0, RSTART+24, RLENGTH-24)}
  e && name != "" && match($0, /port: [0-9]+/) {print name ":" substr($0, RSTART+6, RLENGTH-6)}' | sort | tr '\n' ' ')
[ "$admitted" = "athlete-service core-service finance-service game-service pdf-service " ] && echo "$n" | grep -q 'policyTypes: \[Ingress, Egress\]' \
  && [ "$(echo "$n" | grep -c -- '- from:')" = 2 ] && ! echo "$n" | grep -q 'namespaceSelector: {}' \
  && echo "$n" | awk '/- from:/ {f++} f==1 && /port: otlp-grpc/ {g=1} f==1 && /port: otlp-http/ {h=1} END {exit !(g && h)}' \
  && echo "$n" | awk '/- from:/ {f++} f==2 && /kubernetes.io\/metadata.name: envoy-gateway-system/ {e=1} f==2 && /app.kubernetes.io\/component: proxy/ {p=1} f==2 && /owning-gateway-name: hoops$/ {o=1} f==2 && /managed-by/ {m=1} f==2 && /port: otlp-grpc/ {g=1} f==2 && /port: otlp-http/ {h=1} END {exit !(e && p && o && !m && g && !h)}' \
  && echo "$n" | grep -q 'k8s-app: kube-dns' && [ "$(echo "$n" | grep -c -- '- to:')" = 7 ] \
  && [ "$egress" = "athlete-service:8083 core-service:8081 finance-service:8085 game-service:8082 lgtm:4317 pdf-service:8084 " ] \
  && ok "otel-collector NetworkPolicy: OTLP from the five services + the Gateway's Envoy proxies (gRPC; no managed-by selector, Tilt rewrites it); egress DNS, lgtm:4317 and each service's port (scrape) only" \
  || bad "otel-collector NetworkPolicy (admitted: $admitted; egress: $egress)"
for u in core-service game-service athlete-service pdf-service finance-service; do
  doc "$u" Deployment | grep -q "app.kubernetes.io/name: $u" || bad "collector client $u has no Deployment with that name label"
done
# Grafana LGTM (WP120, decision 91): one dev-only pod with Grafana, Loki, Tempo and Prometheus behind the collector. No
# persistence (emptyDir, capped), an explicit 24 h retention for logs, traces and metrics (P-07), Grafana only through
# kubectl port-forward as an anonymous Viewer (Explore allowed; no login, no admin), nothing fetched from the internet.
l=$(doc lgtm Deployment)
img_pinned "$l" docker.io/grafana/otel-lgtm && hardened "$l" && echo "$l" | grep -q 'type: Recreate' \
  && echo "$l" | grep -q '{name: data, emptyDir: {sizeLimit: 2Gi}}' && ! echo "$l" | grep -q 'persistentVolumeClaim\|hostPath' \
  && echo "$l" | grep -q '{name: data, mountPath: /data}' && echo "$l" | grep -q '{name: tmp, mountPath: /tmp}' \
  && echo "$l" | grep -q '{name: tempo, mountPath: /var/tempo}' \
  && echo "$l" | grep -q '{name: dashboards, mountPath: /otel-lgtm/hoops-dashboards, readOnly: true}' \
  && echo "$l" | grep -q '{name: dashboard-provider, mountPath: /otel-lgtm/grafana/conf/provisioning/dashboards, readOnly: true}' \
  && echo "$l" | grep -q 'exec: {command: \[/otel-lgtm/docker/healthcheck.sh\]}' \
  && ok "kind: lgtm pinned by digest, non-root, read-only root FS, memory limit, Recreate, no persistence (emptyDir /data capped at 2Gi), health script probes" \
  || bad "lgtm Deployment"
lgtm_env() { echo "$1" | sed -n 's/^ *- {name: \([A-Z_]*\), value: \(".*"\)}$/\1=\2/p' | sort; }
le=$(lgtm_env "$l")
echo "$le" | grep -qx 'LOKI_EXTRA_ARGS="-compactor.retention-enabled=true -compactor.delete-request-store=filesystem -store.retention=24h"' \
  && echo "$le" | grep -qx 'TEMPO_EXTRA_ARGS="-backend-worker.compaction.block-retention=24h -backend-scheduler.provider.work.compaction.block-retention=24h"' \
  && echo "$le" | grep -qx 'PROMETHEUS_EXTRA_ARGS="--storage.tsdb.retention.time=24h"' \
  && ok "lgtm retention 24 h: Loki (compactor retention), Tempo (block retention, scheduler and worker), Prometheus (TSDB)" \
  || bad "lgtm retention: $le"
echo "$le" | grep -qx 'GF_AUTH_ANONYMOUS_ENABLED="true"' && echo "$le" | grep -qx 'GF_AUTH_ANONYMOUS_ORG_ROLE="Viewer"' \
  && echo "$le" | grep -qx 'GF_USERS_VIEWERS_CAN_EDIT="true"' && echo "$le" | grep -qx 'GF_AUTH_DISABLE_LOGIN_FORM="true"' \
  && echo "$le" | grep -qx 'GF_AUTH_BASIC_ENABLED="false"' && echo "$le" | grep -qx 'GF_PLUGINS_PREINSTALL_DISABLED="true"' \
  && echo "$le" | grep -qx 'GF_ANALYTICS_REPORTING_ENABLED="false"' && echo "$le" | grep -qx 'GF_ANALYTICS_CHECK_FOR_UPDATES="false"' \
  && ! echo "$le" | grep -q 'Admin\|ADMIN_PASSWORD\|ADMIN_USER' \
  && ok "Grafana: anonymous Viewer (Explore allowed), no login form, no basic auth (admin/admin unusable), no plugin download, no phoning home" \
  || bad "lgtm Grafana settings: $le"
s=$(doc lgtm Service)
echo "$s" | grep -q '{name: otlp-grpc, port: 4317, targetPort: otlp-grpc, appProtocol: grpc}' && echo "$s" | grep -q '{name: grafana, port: 3000, targetPort: grafana}' \
  && ! echo "$s" | grep -q 'type: \(NodePort\|LoadBalancer\)' && ! grep -h -- '- {name: lgtm' "$WORK"/*.yaml | grep -q . \
  && ok "lgtm Service: ClusterIP, OTLP gRPC 4317 and Grafana 3000; no HTTPRoute to it in any render (port-forward only)" || bad "lgtm Service"
n=$(doc lgtm NetworkPolicy)
echo "$n" | grep -q 'policyTypes: \[Ingress, Egress\]' && echo "$n" | grep -q 'egress: \[\]' \
  && [ "$(echo "$n" | grep -c -- '- from:')" = 1 ] && echo "$n" | grep -A3 -- '- from:' | grep -q 'app.kubernetes.io/name: otel-collector' \
  && echo "$n" | grep -q 'port: otlp-grpc' && ! echo "$n" | grep -q 'port: grafana\|3000' \
  && ok "lgtm NetworkPolicy: OTLP from the collector only, Grafana by port-forward only, no egress (no plugin, update or phone-home traffic)" \
  || bad "lgtm NetworkPolicy"
# Dashboards: provisioned from the chart's files (compose mounts the same directory), read-only, in folder "Hoops Academy".
dash_dir="$CHART/files/grafana/dashboards"
dk=$(doc lgtm-dashboards ConfigMap | sed -n 's/^  \([a-z0-9-]*\.json\): .*/\1/p' | sort | tr '\n' ' ')
[ "$dk" = "$(cd "$dash_dir" && ls -- *.json | sort | tr '\n' ' ')" ] && [ "$dk" = "hoops-authz-denials.json hoops-requests.json hoops-security-events.json " ] \
  && doc lgtm-dashboard-provider ConfigMap | grep -q 'path: /otel-lgtm/hoops-dashboards' \
  && doc lgtm-dashboard-provider ConfigMap | grep -q 'allowUiUpdates: false' \
  && ok "lgtm dashboards: requests and errors, authorisation denials, security events (from the chart's files), provider read-only" \
  || bad "lgtm dashboards: $dk"
# No personal data or request content in what the dashboards query (P-07, privacy threat model): no subject, roles, tenant,
# e-mail, user, address, concrete path or message key; log panels keep only the listed fields and print their own line.
exprs=$(jq -r '.. | objects | .expr? // empty' "$dash_dir"/*.json)
dsuids=$(jq -r '.. | objects | .datasource? | objects | .uid' "$dash_dir"/*.json | sort -u | tr '\n' ' ')
logs_ok=1
while IFS= read -r q; do
  kept=$(echo "$q" | sed -n 's/.*| keep \([a-z_, ]*\)|.*/\1/p' | tr -d ' ' | tr ',' '\n' | sort | tr '\n' ' ')
  [ "$kept" = "security_kind security_outcome security_reason security_resource service_name trace_id " ] && echo "$q" | grep -q '| line_format "' || logs_ok=0
done < <(jq -r '.panels[] | select(.type == "logs") | .targets[].expr' "$dash_dir"/*.json)
[ -n "$exprs" ] && ! echo "$exprs" | grep -Eiq 'subject|roles|tenant|e_?mail|user|client_address|peer|url_|http_target|message_key|body|password|token' \
  && [ "$logs_ok" = 1 ] && [ "$(jq -r '.panels[] | select(.type == "logs") | .id' "$dash_dir"/*.json | wc -l | tr -d ' ')" -ge 1 ] \
  && [ "$dsuids" = "loki prometheus " ] && jq -e . "$dash_dir"/*.json >/dev/null \
  && ok "dashboards query no subject, roles, tenant, e-mail, user, address, path, message key or body; log panels keep six fields and the trace id" \
  || bad "dashboard queries (datasources: $dsuids)"
# Cloud keeps the in-memory Jaeger (values-cloud.yaml); LGTM is dev-only and off there.
CR="$WORK/umbrella-cloud.yaml"
ccfg=$(doc otel-collector-config ConfigMap "$CR" | awk '/^  config.yaml: \|$/ {c=1; next} c && /^    / {sub(/^    /, ""); print; next} c {exit}')
! grep -q 'name: lgtm' "$CR" && echo "$ccfg" | grep -q 'exporters: \[debug, otlp_grpc/jaeger\]' \
  && [ "$(echo "$ccfg" | grep -c 'exporters: \[debug\]')" = 2 ] && grep -A4 '^observability:' "$CHART/values-cloud.yaml" | grep -q '^  lgtm: {enabled: false}' \
  && ok "cloud: no lgtm (off in values-cloud.yaml); traces to Jaeger, logs and metrics to debug only" || bad "cloud observability backend"
j=$(doc jaeger Deployment "$CR")
img_pinned "$j" docker.io/jaegertracing/jaeger && hardened "$j" \
  && ok "cloud: jaeger pinned by digest, non-root, read-only root FS, memory limit" || bad "jaeger Deployment"
doc jaeger-config ConfigMap "$CR" | grep -q 'max_traces: 5000' && ! doc jaeger-config ConfigMap "$CR" | grep -q '4318\|9411\|14250\|14268' \
  && ok "jaeger: in-memory store capped (5000 traces), OTLP gRPC receiver only" || bad "jaeger config"
! grep -q 'name: jaeger' "$R" && ok "kind: no Jaeger (replaced by lgtm)" || bad "kind still renders Jaeger"
n=$(doc jaeger NetworkPolicy "$CR")
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
e=$(doc hoops EnvoyProxy | grep -v '^ *#')
t=$(echo "$e" | grep -A8 '^    tracing:$' || true)   # (a captured block: grep -q in a pipe under pipefail can SIGPIPE its source)
echo "$t" | grep -q 'type: OpenTelemetry' && echo "$t" | grep -q 'host: otel-collector.hoops.svc.cluster.local' \
  && echo "$t" | grep -q 'port: 4317' && ! echo "$e" | grep -q 'backendRefs' \
  && echo "$t" | grep -q 'samplingFraction: {numerator: 10000, denominator: 10000}' \
  && ok "kind: Envoy proxy traces the edge to otel-collector:4317 by DNS name (W3C traceparent, same ratio; no backendRefs: with those a collector outage un-accepts the Gateway)" || bad "EnvoyProxy tracing"
for f in umbrella-default umbrella-tls service-defaults; do
  grep -q 'otel-collector\|jaeger\|lgtm\|tracing:' "$WORK/$f.yaml" && { bad "$f: observability rendered while global.observability.enabled is off"; continue; }
  ok "$f: no collector, no Jaeger, no LGTM, no edge tracing (global.observability.enabled off)"
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
  --set observability.lgtm.enabled=false --set global.observability.otlpEndpoint=http://otel-agent.monitoring:4317 > "$WORK/extra/agent.yaml"
! grep -q 'name: otel-collector\|name: jaeger\|name: lgtm' "$WORK/extra/agent.yaml" \
  && [ "$(grep -c 'QUARKUS_OTEL_EXPORTER_OTLP_ENDPOINT: "http://otel-agent.monitoring:4317"' "$WORK/extra/agent.yaml")" = 3 ] \
  && ! grep -q 'tracing:' "$WORK/extra/agent.yaml" \
  && ok "external collector: no chart collector, services and nothing else point at global.observability.otlpEndpoint" || bad "external collector"
refused 'otlpEndpoint' "${K[@]}" --set observability.collector.enabled=false \
  && refused 'jaeger' "${K[@]}" --set observability.collector.enabled=false --set observability.lgtm.enabled=false \
       --set observability.jaeger.enabled=true --set global.observability.otlpEndpoint=http://x:4317 \
  && refused 'lgtm' "${K[@]}" --set observability.collector.enabled=false --set global.observability.otlpEndpoint=http://x:4317 \
  && ok "collector off needs global.observability.otlpEndpoint; Jaeger and LGTM need the chart collector" || bad "collector-off guards"
helm template hoops "$CHART" -n hoops -f "$CHART/values-kind.yaml" --set observability.lgtm.enabled=false \
  --set-json 'observability.collector.exporters={"otlp_http/backend":{"endpoint":"https://otlp.example.test","headers":{"authorization":"Bearer ${env:BACKEND_TOKEN}"}}}' \
  --set-json 'observability.collector.pipelineExporters={"traces":["otlp_http/backend"],"logs":["otlp_http/backend"],"metrics":["otlp_http/backend"]}' \
  --set-json 'observability.collector.secretEnv=[{"name":"BACKEND_TOKEN","secretName":"otel-backend","key":"token"}]' \
  --set-json 'observability.collector.networkPolicy.extraEgress=[{"ports":[{"port":443,"protocol":"TCP"}]}]' > "$WORK/extra/backend.yaml"
bcfg=$(doc otel-collector-config ConfigMap "$WORK/extra/backend.yaml")
bd=$(doc otel-collector Deployment "$WORK/extra/backend.yaml")
echo "$bcfg" | grep -q 'exporters: \[debug, otlp_http/backend\]' && [ "$(echo "$bcfg" | grep -c 'exporters: \[debug, otlp_http/backend\]')" = 3 ] \
  && echo "$bcfg" | grep -q 'Bearer ${env:BACKEND_TOKEN}' && ! grep -q 'name: jaeger\|name: lgtm' "$WORK/extra/backend.yaml" \
  && echo "$bd" | grep -q 'secretKeyRef: {name: otel-backend, key: token}' && echo "$bd" | grep -q 'secret.reloader.stakater.com/auto: "true"' \
  && doc otel-collector NetworkPolicy "$WORK/extra/backend.yaml" | grep -q 'port: 443' \
  && ok "backend: extra exporter in the three pipelines, its token from a Secret (Reloader rolls it), egress rule added" || bad "collector backend wiring"

echo "== compose profile observability (WP120): the chart's collector wiring, backend and dashboards"
CF=infra/compose/compose.yaml; CC=infra/compose/otel-collector.yaml
svc_block() { awk -v s="  $1:" '$0 == s {f=1; print; next} f && /^  [a-z]/ {exit} f && /^[a-z]/ {exit} f {print}' "$CF"; }
section() { awk -v s="$1:" '$0 == s {f=1; print; next} f && /^[a-z]/ {exit} f {print}'; }
cl=$(svc_block lgtm); co=$(svc_block otel-collector)
li=$(echo "$l" | sed -n 's/^ *image: "\(.*\)"$/\1/p'); oi=$(echo "$oc" | sed -n 's/^ *image: "\(.*\)"$/\1/p')
[ -n "$li" ] && echo "$cl" | grep -qx "    image: $li" && [ -n "$oi" ] && echo "$co" | grep -qx "    image: $oi" \
  && echo "$cl" | grep -qx '    profiles: \[observability\]' && echo "$co" | grep -qx '    profiles: \[observability\]' \
  && ok "compose lgtm and otel-collector: profile observability (off by default), the chart's image pins" || bad "compose observability images/profile"
ce=$(echo "$cl" | sed -n 's/^      \([A-Z_]*\): \(".*"\)$/\1=\2/p' | sort)
[ -n "$ce" ] && [ "$ce" = "$le" ] && ok "compose lgtm: the chart's environment (24 h retention, anonymous Viewer, no login, no downloads)" \
  || bad "compose lgtm environment differs from the chart: $(diff <(echo "$ce") <(echo "$le") | tr '\n' ' ')"
echo "$cl" | grep -qx '    read_only: true' && echo "$cl" | grep -qx '    cap_drop: \[ALL\]' && echo "$cl" | grep -qx '    user: "10001:10001"' \
  && [ "$(echo "$cl" | grep -c '^      - "')" = 1 ] && echo "$cl" | grep -qx '      - "127.0.0.1:3000:3000"' \
  && echo "$cl" | grep -qx '      - /data:size=512m' && echo "$cl" | grep -qx '      - /tmp' && echo "$cl" | grep -qx '      - /var/tempo' \
  && echo "$cl" | grep -qx '      - ../../deploy/helm/hoops/files/grafana/dashboards:/otel-lgtm/hoops-dashboards:ro' \
  && echo "$cl" | grep -qx '      - ../../deploy/helm/hoops/files/grafana/provisioning/dashboards:/otel-lgtm/grafana/conf/provisioning/dashboards:ro' \
  && ok "compose lgtm: read-only, non-root, no capabilities, tmpfs data (512m, counted in its memory limit), Grafana on 127.0.0.1:3000 only, the chart's dashboard files" \
  || bad "compose lgtm hardening/mounts"
echo "$co" | grep -qx '    read_only: true' && echo "$co" | grep -qx '    cap_drop: \[ALL\]' \
  && echo "$co" | grep -qx '      - ./otel-collector.yaml:/etc/otelcol/config.yaml:ro' \
  && [ "$(echo "$co" | grep -c '^      - "127.0.0.1:43')" = 2 ] && ! echo "$co" | grep -q '"0.0.0.0\|- "43' \
  && ok "compose otel-collector: read-only, no capabilities, OTLP on 127.0.0.1:4317/4318 for the services on the host" \
  || bad "compose otel-collector"
diff <(echo "$cfg" | section processors) <(section processors < "$CC") >/dev/null \
  && diff <(echo "$cfg" | section service) <(section service < "$CC") >/dev/null \
  && grep -q 'endpoint: lgtm:4317' "$CC" && grep -q 'verbosity: basic' "$CC" \
  && [ "$(grep -c 'metrics_path: /q/metrics' "$CC")" = 5 ] \
  && [ "$(grep -o 'host.containers.internal:808[1-5]' "$CC" | sort -u | wc -l | tr -d ' ')" = 5 ] \
  && ok "compose collector config: the chart's processors (ids stripped) and pipelines, to lgtm:4317, scrapes the five host ports" \
  || bad "compose collector config differs from the chart's"
grep -q '^observability-up:' justfile && grep -q -- '--profile observability' justfile \
  && grep -q 'observability' infra/compose/README.md && ok "just observability-up / down, README line" || bad "just entry or README line"

echo "== pdf-service (WP111, ADR-0052: Rust renderer, internal only)"
D="$WORK/umbrella-default.yaml"
pd=$(doc pdf-service Deployment)
echo "$pd" | grep -q 'image: "localhost/hoops/pdf-service:dev"' && echo "$pd" | grep -q 'runAsUser: 65532' \
  && echo "$pd" | grep -q 'readOnlyRootFilesystem: true' && echo "$pd" | grep -q 'automountServiceAccountToken: false' \
  && ! echo "$pd" | grep -q 'secretKeyRef\|secretRef' && echo "$pd" | grep -q 'httpGet: {path: /q/health/ready, port: http}' \
  && ok "kind: pdf-service as nonroot 65532, read-only root FS, no Secret, no service account token, HTTP probes" || bad "pdf-service Deployment"
! grep -h -- '- {name: pdf-service' "$WORK"/*.yaml | grep -q . && ! grep -q 'kind: HTTPRoute' <(doc pdf-service HTTPRoute) \
  && ok "no HTTPRoute sends anything to pdf-service in any render (decision 89: the browser never calls it)" || bad "pdf-service routed"
pn=$(doc pdf-service NetworkPolicy)
padmitted=$(echo "$pn" | awk '/operator: In/ {i=1; next} i && /^ *values:$/ {next} i && /^ *- [a-z-]+$/ {print $2; next} i {exit}' | sort | tr '\n' ' ')
[ "$padmitted" = "core-service game-service " ] && echo "$pn" | grep -q 'policyTypes: \[Ingress, Egress\]' \
  && [ "$(echo "$pn" | grep -c -- '- from:')" = 2 ] && ! echo "$pn" | grep -q 'namespaceSelector: {}\|envoy-gateway-system' \
  && echo "$pn" | awk '/- from:/ {f++} f==2 && /app.kubernetes.io\/name: otel-collector/ {c=1} f==2 && /port: http,/ {p=1} END {exit !(c && p)}' \
  && [ "$(echo "$pn" | grep -c -- '- to:')" = 3 ] && echo "$pn" | grep -q 'k8s-app: kube-dns' \
  && echo "$pn" | awk '/- to:/ {t++} t==2 && /app.kubernetes.io\/name: keycloak/ {k=1} t==2 && /port: 8080/ {p=1} END {exit !(k && p)}' \
  && echo "$pn" | awk '/- to:/ {t++} t==3 && /app.kubernetes.io\/name: otel-collector/ {c=1} t==3 && /port: 4318/ {p=1} END {exit !(c && p)}' \
  && ok "pdf-service NetworkPolicy: only core-service and game-service in (and the collector, /q/metrics); out only DNS, Keycloak :8080, collector :4318" \
  || bad "pdf-service NetworkPolicy (admitted: $padmitted)"
pc=$(doc pdf-service-env ConfigMap)
echo "$pc" | grep -qx '  OIDC_AUTH_SERVER_URL: "http://keycloak:8080/auth/realms/academy"' && echo "$pc" | grep -qx '  OIDC_AUDIENCE: "pdf-service"' \
  && ! echo "$pc" | grep -q 'OIDC_ISSUER' && echo "$pc" | grep -qx '  PDF_HTTP_PORT: "8084"' \
  && echo "$pc" | grep -qx '  OTEL_SDK_DISABLED: "false"' \
  && echo "$pc" | grep -qx '  OTEL_EXPORTER_OTLP_ENDPOINT: "http://otel-collector.hoops.svc.cluster.local:4318"' \
  && echo "$pc" | grep -qx '  OTEL_RESOURCE_ATTRIBUTES: "deployment.environment.name=kind,k8s.namespace.name=hoops"' \
  && ok "kind: pdf-service verifies against Keycloak (issuer by discovery), OTLP/HTTP to the collector, no tenant attribute" \
  || bad "pdf-service env"
for s in core game; do
  for f in "$R" "$D"; do
    doc "$s-service-env" ConfigMap "$f" | grep -qx '  PDF_SERVICE_URL: "http://pdf-service:8084"' || bad "$s-service PDF_SERVICE_URL in $(basename "$f")"
  done
done
! doc athlete-service-env ConfigMap | grep -q PDF_SERVICE_URL \
  && ok "core and game get PDF_SERVICE_URL=http://pdf-service:8084 (default and kind), athlete not" || bad "athlete has PDF_SERVICE_URL"
! grep -q 'name: pdf-service' "$D" && ok "default: pdf-service off (pdf.enabled false), nothing rendered" || bad "default renders pdf-service"
pa=$(doc pdf-service-env ConfigMap "$WORK/extra/agent.yaml")
echo "$pa" | grep -qx '  OTEL_EXPORTER_OTLP_ENDPOINT: "http://otel-agent.monitoring:4318"' \
  && [ "$(doc pdf-service NetworkPolicy "$WORK/extra/agent.yaml" | grep -c -- '- to:')" = 2 ] \
  && ok "external collector: pdf-service exports OTLP/HTTP to the agent's :4318; no collector egress rule (networkPolicy.egress.extra)" \
  || bad "pdf-service with an external collector"
echo "== finance-service (WP118, ADR-0055: Go, /api/finance behind the gateway)"
fd=$(doc finance-service Deployment)
echo "$fd" | grep -q 'image: "localhost/hoops/finance-service:dev"' && echo "$fd" | grep -q 'runAsUser: 65532' \
  && echo "$fd" | grep -q 'readOnlyRootFilesystem: true' && echo "$fd" | grep -q 'automountServiceAccountToken: false' \
  && echo "$fd" | grep -q 'secretKeyRef: {name: hoops-db-finance-app, key: password}' \
  && echo "$fd" | grep -q 'secretKeyRef: {name: hoops-db-finance-migrator, key: password}' \
  && echo "$fd" | grep -q 'secretKeyRef: {name: hoops-redpanda-finance-service, key: password}' \
  && echo "$fd" | grep -q 'httpGet: {path: /q/health/ready, port: http}' && echo "$fd" | grep -q 'secret.reloader.stakater.com/auto' \
  && ok "kind: finance-service as nonroot 65532, read-only root FS, database and broker passwords from Secrets, HTTP probes" \
  || bad "finance-service Deployment"
fc=$(doc finance-service-env ConfigMap)
echo "$fc" | grep -qx '  OIDC_AUDIENCE: "finance-service"' && echo "$fc" | grep -qx '  FINANCE_HTTP_PORT: "8085"' \
  && echo "$fc" | grep -qx '  FINANCE_DB_URL: "postgres://hoops-db-rw:5432/hoops"' \
  && echo "$fc" | grep -qx '  KAFKA_SASL_USERNAME: "finance-service"' && echo "$fc" | grep -qx '  KAFKA_SECURITY_PROTOCOL: "SASL_PLAINTEXT"' \
  && echo "$fc" | grep -qx '  OTEL_EXPORTER_OTLP_ENDPOINT: "http://otel-collector.hoops.svc.cluster.local:4318"' \
  && ! echo "$fc" | grep -q 'PASSWORD\|FINANCE_ROSTER_CONSUMER_ENABLED' \
  && ok "kind: finance-service env (audience, database URL, broker user, OTLP/HTTP), no secret in the ConfigMap" || bad "finance-service env"
doc finance-service-api-finance HTTPRoute | grep -q 'value: "/api/finance"' && doc finance-service-dues-export BackendTrafficPolicy | grep -q 'requests: 10, unit: Minute' \
  && doc finance-service-expenses-export HTTPRoute | grep -q 'expenses(:|%3\[Aa\])export' \
  && doc finance-service-health HTTPRoute | grep -q 'value: "/api/finance/q/health/ready"' \
  && ok "finance-service routes: /api/finance, health, the CSV exports rate-limited 10/min (P-12)" || bad "finance-service routes"
fn=$(doc finance-service NetworkPolicy)
echo "$fn" | grep -q 'policyTypes: \[Ingress, Egress\]' && [ "$(echo "$fn" | grep -c -- '- from:')" = 2 ] \
  && echo "$fn" | awk '/- from:/ {f++} f==2 && /app.kubernetes.io\/name: otel-collector/ {c=1} f==2 && /port: http,/ {p=1} END {exit !(c && p)}' \
  && echo "$fn" | grep -q 'kubernetes.io/metadata.name: envoy-gateway-system' && ! echo "$fn" | grep -q 'podSelector: {}' \
  && [ "$(echo "$fn" | grep -c -- '- to:')" = 5 ] && echo "$fn" | grep -q 'cnpg.io/cluster: hoops-db' \
  && echo "$fn" | awk '/app.kubernetes.io\/name: redpanda/ {r=1} r && /port: 9092/ {p=1} END {exit !p}' \
  && ok "finance-service NetworkPolicy: in only from the gateway (and the collector, /q/metrics); out DNS, Postgres, Keycloak, Redpanda, collector" \
  || bad "finance-service NetworkPolicy"
doc hoops-db Cluster | grep -q 'name: finance_app' && doc hoops-db Cluster | grep -q 'name: finance_migrator' \
  && ok "CNPG manages finance_migrator and finance_app" || bad "finance roles in hoops-db"
! grep -q 'name: finance-service' "$D" && ok "default: finance-service off (finance.enabled false), nothing rendered" || bad "default renders finance-service"
fo=$(doc finance-service-env ConfigMap "$WORK/umbrella-default.yaml" 2>/dev/null || true)
[ -z "$fo" ] || bad "finance-service rendered without finance.enabled"
noev=$(helm template hoops "$CHART" -n hoops --set finance.enabled=true 2>&1)
grep -qx '  FINANCE_ROSTER_CONSUMER_ENABLED: "false"' <<<"$noev" && ! grep -q 'hoops-redpanda-finance-service' <<<"$noev" \
  && ok "without events: the roster consumer off, no broker Secret read" || bad "finance-service without events"

nonroot=0
for s in core game athlete; do
  doc "$s-service" Deployment | grep -A6 '^      securityContext:' | grep -q 'runAsUser: 65532' && nonroot=$((nonroot + 1))
done
[ "$nonroot" = 3 ] && ok "core, game and athlete run as the distroless nonroot user 65532:65532 (ADR-0054)" || bad "services runAsUser"

echo "== cloud: one k3s VM on Alibaba Cloud (WP104, ADR-0050; umbrella-cloud)"
# values-cloud.yaml plus what deploy/cloud/install.sh sets from the OpenTofu outputs (tests/values/umbrella-cloud.yaml:
# the mocked EIP 203.0.113.10 of infra/tofu/tests, a fixed image tag).
C="$WORK/umbrella-cloud.yaml"; CH=203-0-113-10.sslip.io; CT=0123456789abcdef0123456789abcdef01234567
if helm lint --strict "$CHART" -f "$CHART/values-cloud.yaml" >"$WORK/lint-cloud.txt" 2>&1 \
    && helm lint --strict "$CHART" -f "$CHART/values-cloud.yaml" -f deploy/helm/tests/values/umbrella-cloud.yaml >>"$WORK/lint-cloud.txt" 2>&1; then
  ok "helm lint --strict with values-cloud.yaml (alone and with the install values)"
else bad "helm lint values-cloud.yaml"; cat "$WORK/lint-cloud.txt"; fi
objects() { awk 'BEGIN{RS="\n---\n"} {k=""; n=""; if (match($0, /\nkind: [A-Za-z]+\n/)) k=substr($0, RSTART+7, RLENGTH-8)
  if (match($0, /\nmetadata:\n  name: [^\n]+/)) n=substr($0, RSTART+18, RLENGTH-18); if (k != "") print k "/" n}' "$1" | sort; }
# The observability backend differs on purpose (kind: the dev-only lgtm pod; cloud: the in-memory Jaeger), the rest is equal.
diff <(objects "$R" | grep -v '/ *lgtm') <(objects "$C" | grep -v '/ *jaeger') >"$WORK/cloud-objects.diff" \
  && [ "$(objects "$R" | grep -c '/ *lgtm')" = 5 ] && [ "$(objects "$C" | grep -c '/ *jaeger')" = 4 ] \
  && ok "same objects as umbrella-kind but the trace backend ($(objects "$C" | wc -l | tr -d ' ')): the kind policy assertions above cover the cloud workloads too" \
  || { bad "umbrella-cloud renders other objects than umbrella-kind"; cat "$WORK/cloud-objects.diff"; }
for img in core-service game-service athlete-service web; do
  grep -q "image: \"ghcr.io/davidbejar/hoops-academy/$img:$CT\"" "$C" || bad "image $img not from ghcr.io with tag $CT"
done
! grep -q 'image: "localhost/' "$C" && ! grep -q 'image: "[^"]*:dev"' "$C" \
  && ok "images core, game, athlete, web from ghcr.io/davidbejar/hoops-academy at the commit tag; no localhost/ image, no :dev" \
  || bad "a localhost/ or :dev image in the cloud render"
g=$(doc hoops Gateway "$C")
echo "$g" | grep -q "name: http, protocol: HTTP, port: 80, hostname: \"$CH\"" \
  && echo "$g" | grep -q "name: https, protocol: HTTPS, port: 443, hostname: \"$CH\", tls: {mode: Terminate, certificateRefs: \[{name: hoops-gateway-tls}\]}" \
  && ok "Gateway: listeners :80 and :443 for $CH, TLS from Secret hoops-gateway-tls (install.sh, self-signed)" || bad "cloud Gateway listeners"
! grep -q Strict-Transport-Security "$C" && ok "no HSTS (a self-signed host would lock browsers out)" || bad "HSTS in the cloud render"
e=$(doc hoops EnvoyProxy "$C")
echo "$e" | grep -q 'type: LoadBalancer' && ! echo "$e" | grep -q 'nodePort' && echo "$e" | grep -q 'name: hoops-gateway' \
  && ok "Envoy Service hoops-gateway is a LoadBalancer (k3s ServiceLB binds it to the node's 80/443), no fixed NodePort" || bad "cloud EnvoyProxy"
! doc hoops-http ClientTrafficPolicy "$C" | grep -q numTrustedHops && ok "client IP from the connection (no proxy in front, no trusted X-Forwarded-For hop)" \
  || bad "cloud trusts X-Forwarded-For"
doc keycloak Deployment "$C" | grep -A1 -- '- name: KC_HOSTNAME$' | grep -q "value: \"https://$CH/auth\"" \
  && [ "$(grep -c "HOOPS_CORS_ORIGINS: \"https://$CH\"" "$C")" = 4 ] && doc core-service-env ConfigMap "$C" | grep -qx "  HOOPS_PUBLIC_URL: \"https://$CH\"" \
  && ! grep -q 'localhost:8090' "$C" \
  && ok "issuer https://$CH/auth/realms/academy, CORS and mail links on the https URL, nothing left on localhost:8090" || bad "cloud public URL"
[ "$(doc hoops-db Cluster "$C" | grep -c 'storageClass: local-path')" = 1 ] && [ "$(doc keycloak-db Cluster "$C" | grep -c 'storageClass: local-path')" = 1 ] \
  && doc redpanda StatefulSet "$C" | grep -q 'storageClassName: local-path' \
  && ok "volumes on k3s's local-path storage class (hoops-db, keycloak-db, redpanda)" || bad "cloud storage class"
! grep -q '^kind: Secret' "$C" && ! grep -q '^kind: ExternalSecret' "$C" \
  && ok "no Secret, no ExternalSecret (Secrets from .env through deploy/kind/secrets.sh, ADR-0012)" || bad "cloud render holds Secrets"
[ "$(grep -c 'deployment.environment.name=cloud' "$C")" = 5 ] && [ "$(grep -c 'secret.reloader.stakater.com/auto' "$C")" -ge 6 ] \
  && ok "observability environment cloud (three services, pdf-service and finance-service); Reloader annotations on (install.sh installs Reloader)" || bad "cloud observability/reloader"
V="$CHART/values-cloud.yaml"
! grep -v '^ *#' "$V" | grep -Eq '[0-9]{1,3}(\.[0-9]{1,3}){3}|[0-9]{1,3}(-[0-9]{1,3}){3}\.(sslip|nip)\.io' \
  && [ "$(grep -c 'hoops.invalid' "$V")" = 3 ] \
  && ok "values-cloud.yaml holds no address: publicUrl, keycloak.publicUrl and the hostname are .invalid placeholders" || bad "address in values-cloud.yaml"
for s in 'global.publicUrl="$url"' 'keycloak.publicUrl="$url"' 'gateway.hostname="$host"' 'global.imageTag="$TAG"' 'web.image.tag="$TAG"'; do
  grep -qF -- "--set $s" deploy/cloud/install.sh || bad "deploy/cloud/install.sh does not set $s"
done
grep -qF -- '-f deploy/helm/hoops/values-cloud.yaml' deploy/cloud/install.sh \
  && ok "deploy/cloud/install.sh installs with values-cloud.yaml and sets every placeholder from the OpenTofu outputs" || bad "install.sh values"

echo "== gitleaks (rendered manifests)"
if command -v gitleaks >/dev/null; then
  if cat "$WORK"/*.yaml | gitleaks detect --pipe --no-banner --redact --config .gitleaks.toml >"$WORK/gl.txt" 2>&1; then ok "gitleaks clean"
  else bad gitleaks; cat "$WORK/gl.txt"; fi
else echo "  skip gitleaks (not installed)"; fi

[ "$fail" = 0 ] && echo "ALL CHART TESTS PASSED" || { echo "CHART TESTS FAILED"; exit 1; }
