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
  # CRDs (CNPG Cluster) from the datree catalog; -strict rejects unknown fields.
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
grep -q 'value: "http://localhost:8090/auth"' "$R" && ok "Keycloak hostname = ingress URL (issuer http://localhost:8090/auth/realms/academy)" || bad "KC_HOSTNAME"
grep -B2 -A6 'path: /internal' "$R" | grep -q 'name: web' && ok "/internal routed to the web 403 location" || bad "/internal route"
! grep -q 'localhost:8080' "$R" && ok "no compose URL (localhost:8080) left in the realm" || bad "realm still references localhost:8080"
grep -q 'name: hoops-db-core-app' "$R" && grep -q 'postInitApplicationSQLRefs' "$R" && ok "CNPG managed roles + postInitApplicationSQLRefs" || bad CNPG
# WP17 hardening
doc() { # print the YAML document containing "name: $1" (first match) of kind $2
  awk -v n="  name: $1" -v k="kind: $2" 'BEGIN{RS="\n---\n"} index($0,k) && index($0,n"\n") {print; exit}' "$R"; }
doc keycloak-admin-deny Ingress | grep -q 'path: /auth/admin' && doc keycloak-admin-deny Ingress | grep -q 'path: /auth/realms/master' \
  && doc keycloak-admin-deny Ingress | grep -q 'name: web' && ok "/auth/admin + master realm routed to the web 403 location" || bad "admin console deny route"
# every Ingress that routes /auth/admin or the master realm must send it to the web 403 location, never to Keycloak
[ -z "$(awk 'BEGIN{RS="\n---\n"} /kind: Ingress/ && /path: \/auth\/(admin|realms\/master)/' "$R" | grep -A2 'service:' | grep -E '^ +name:' | grep -v 'name: web$')" ] \
  && ok "no Ingress proxies /auth/admin or the master realm to Keycloak" || bad "/auth/admin exposed"
doc keycloak-ratelimited Ingress | grep -q 'limit-rpm: "60"' && doc keycloak-ratelimited Ingress | grep -q 'path: /auth/realms/academy/protocol/openid-connect/token' \
  && ok "token endpoint + login form rate-limited (limit-rpm)" || bad "keycloak rate limit"
doc game-service-events-batch Ingress | grep -q 'limit-rpm: "120"' && doc game-service-events-batch Ingress | grep -q 'path: "\?/api/game/matches/\[^/\]+/events:batch' \
  && ! doc game-service-events-batch Ingress | grep -q rewrite-target && ok "events:batch rate-limited, colon path not rewritten" || bad "events:batch rate limit"
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
