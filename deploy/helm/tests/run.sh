#!/usr/bin/env bash
# Helm chart tests (WP16): lint, golden snapshots, schema validation, policy assertions, secret scan.
#   deploy/helm/tests/run.sh            verify
#   deploy/helm/tests/run.sh --update   re-record snapshots after an intended change (review the diff!)
# Snapshots include infra/keycloak/realm-academy.json and infra/db/init/01_roles_schemas.sql (symlinked into the
# charts), so a change there shows up here on purpose.
set -euo pipefail
cd "$(dirname "$0")/../../.."
CHART=deploy/helm/hoops
SNAP=deploy/helm/tests/snapshots
UPDATE=0; [ "${1:-}" = "--update" ] && UPDATE=1
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
fail=0
ok()  { printf '  ok   %s\n' "$*"; }
bad() { printf '  FAIL %s\n' "$*"; fail=1; }
quiet_helm() { helm "$@" 2> >(grep -v 'found symbolic link' >&2); }

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

echo "== gitleaks (rendered manifests)"
if command -v gitleaks >/dev/null; then
  if cat "$WORK"/*.yaml | gitleaks detect --pipe --no-banner --redact --config .gitleaks.toml >"$WORK/gl.txt" 2>&1; then ok "gitleaks clean"
  else bad gitleaks; cat "$WORK/gl.txt"; fi
else echo "  skip gitleaks (not installed)"; fi

[ "$fail" = 0 ] && echo "ALL CHART TESTS PASSED" || { echo "CHART TESTS FAILED"; exit 1; }
