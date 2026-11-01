#!/usr/bin/env bash
# Smoke test of the kind deployment through the ingress (http://localhost:8090 by default).
#   deploy/kind/smoke.sh [service...]        default services: core game athlete
# Checks: pods Ready, OIDC issuer, /internal -> 403, web /, each service's /q/health/ready via the ingress,
# a client-credentials token from Keycloak, and that each API rejects anonymous calls (401) but accepts the token's
# signature/issuer (anything but 401). The client secret is read from .env and sent as a form body over stdin.
set -euo pipefail
cd "$(dirname "$0")/../.."
BASE="${HOOPS_BASE_URL:-http://localhost:8090}"
SERVICES=("$@"); [ ${#SERVICES[@]} -gt 0 ] || SERVICES=(core game athlete)
CTX=(--context "kind-${KIND_CLUSTER:-hoops}" -n "${HOOPS_NAMESPACE:-hoops}")
fail=0
ok()  { printf '  ok   %s\n' "$*"; }
bad() { printf '  FAIL %s\n' "$*"; fail=1; }
warn() { printf '  WARN %s\n' "$*"; }
code() { curl -s -o /dev/null -w '%{http_code}' "$@"; }

echo "== pods"
kubectl "${CTX[@]}" get pods -o wide
not_ready=$(kubectl "${CTX[@]}" get pods --no-headers | awk '$3!="Completed" && $3!="Succeeded" {split($2,a,"/"); if (a[1]!=a[2]) print $1}')
[ -z "$not_ready" ] && ok "all pods Ready" || bad "not ready: $not_ready"

echo "== ingress"
issuer=$(curl -s "$BASE/auth/realms/academy/.well-known/openid-configuration" | sed -n 's/.*"issuer":"\([^"]*\)".*/\1/p')
[ "$issuer" = "$BASE/auth/realms/academy" ] && ok "issuer $issuer" || bad "issuer '$issuer'"
c=$(code "$BASE/internal/x"); [ "$c" = 403 ] && ok "/internal/x -> 403" || bad "/internal/x -> $c"
if [[ " ${SERVICES[*]} " == *" core "* ]]; then  # with core absent the path falls through to the SPA (200)
  c=$(code "$BASE/api/core/internal/authz/x/y"); [ "$c" != 200 ] && ok "/api/core/internal/... -> $c (not exposed)" || bad "/api/core/internal exposed"
fi
c=$(code "$BASE/"); [ "$c" = 200 ] && ok "web / -> 200" || bad "web / -> $c"

for s in "${SERVICES[@]}"; do
  body=$(curl -s "$BASE/api/$s/q/health/ready")
  if echo "$body" | grep -q '"status": *"UP"'; then ok "/api/$s/q/health/ready UP"
  elif echo "$body" | grep -q '"instance": *"/q/health/ready"'; then
    warn "/api/$s/q/health/ready routed+rewritten to the service, which has no quarkus-smallrye-health (404)"
  else bad "/api/$s/q/health/ready: $body"; fi
  c=$(code "$BASE/api/$s/q/metrics"); [ "$c" != 200 ] && ok "/api/$s/q/metrics not exposed ($c)" || bad "/api/$s/q/metrics exposed"
done

echo "== tokens (client credentials, realm role 'service')"
# A secured GET endpoint per service (anonymous -> 401; a valid token -> anything else, e.g. 400/404 without tenant).
api_path() { case "$1" in core) echo /api/core/me ;; game) echo /api/game/matches ;; athlete) echo /api/athlete/training-schedules ;; esac; }
set -a; . ./.env; set +a
for s in "${SERVICES[@]}"; do
  var="$(echo "$s" | tr '[:lower:]' '[:upper:]')_SERVICE_CLIENT_SECRET"
  token=$(printf 'grant_type=client_credentials&client_id=%s-service&client_secret=%s' "$s" "${!var}" |
    curl -s -X POST "$BASE/auth/realms/academy/protocol/openid-connect/token" \
      -H 'Content-Type: application/x-www-form-urlencoded' --data-binary @- | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
  [ -n "$token" ] || { bad "$s-service: no token"; continue; }
  iss=$(echo "$token" | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null | sed -n 's/.*"iss":"\([^"]*\)".*/\1/p' || true)
  [ "$iss" = "$BASE/auth/realms/academy" ] && ok "$s-service token iss $iss" || bad "$s-service token iss '$iss'"
  p=$(api_path "$s")
  anon=$(code "$BASE$p")
  authd=$(code -H "Authorization: Bearer $token" "$BASE$p")
  [ "$anon" = 401 ] && [ "$authd" != 401 ] && ok "$p anonymous 401, with token $authd" \
    || bad "$p anonymous $anon, with token $authd"
done

[ "$fail" = 0 ] && echo "SMOKE PASSED" || { echo "SMOKE FAILED"; exit 1; }
