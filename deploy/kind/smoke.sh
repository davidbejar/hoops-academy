#!/usr/bin/env bash
# Smoke test of the kind deployment through the Envoy Gateway (http://localhost:8090 by default).
#   deploy/kind/smoke.sh [service...]        default services: core game athlete
# core is deployed since WP18: with `core` in the list the script also logs the seeded `superadmin` in (PKCE, no browser)
# and checks GET /api/core/me (200, superAdmin=true) and GET /platform/tenants (200).
# Checks: pods Ready, Gateway programmed, OIDC issuer, /internal -> 403, web /, each service's /q/health/ready via the gateway,
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

echo "== gateway"
prog=$(kubectl "${CTX[@]}" get gateway hoops -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}' 2>/dev/null || true)
[ "$prog" = True ] && ok "Gateway hoops programmed" || bad "Gateway hoops Programmed='$prog'"
disco=$(curl -s "$BASE/auth/realms/academy/.well-known/openid-configuration")
issuer=$(echo "$disco" | sed -n 's/.*"issuer":"\([^"]*\)".*/\1/p')
[ "$issuer" = "$BASE/auth/realms/academy" ] && ok "issuer $issuer" || bad "issuer '$issuer'"
# back-channel URLs come from X-Forwarded-Host, which the Keycloak routes set to the public host (a spoofed one is ignored)
tep=$(curl -s -H 'X-Forwarded-Host: evil.example' "$BASE/auth/realms/academy/.well-known/openid-configuration" |
  sed -n 's/.*"token_endpoint":"\([^"]*\)".*/\1/p')
[ "$tep" = "$BASE/auth/realms/academy/protocol/openid-connect/token" ] && ok "token_endpoint $tep (spoofed X-Forwarded-Host ignored)" \
  || bad "token_endpoint '$tep'"
c=$(code "$BASE/internal/x"); [ "$c" = 403 ] && ok "/internal/x -> 403" || bad "/internal/x -> $c"
# Envoy normalises the path (RFC 3986, merged slashes) before routing: encoded or dotted variants hit the deny routes too
for p in //internal/x /%69nternal/x /auth/admin/ /auth/realms/academy/../master/ /auth/realms/%6Daster/; do
  c=$(code --path-as-is "$BASE$p"); [ "$c" = 403 ] && ok "$p -> 403" || bad "$p -> $c"
done
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

if [[ " ${SERVICES[*]} " == *" game "* ]]; then
  # The rate-limited regex route forwards the colon path byte-for-byte (anonymous -> the service's 401); the
  # percent-encoded form also reaches the service unchanged (its Problem echoes the path; Quarkus answers 404 for it).
  m=00000000-0000-0000-0000-000000000001
  body=$(curl -s -X POST -H 'Content-Type: application/json' --data '[]' "$BASE/api/game/matches/$m/events:batch")
  echo "$body" | grep -q '"status":401' && echo "$body" | grep -q "events:batch" && ok "events:batch reaches game-service unchanged (401)" \
    || bad "events:batch: $body"
  body=$(curl -s --path-as-is -X POST -H 'Content-Type: application/json' --data '[]' "$BASE/api/game/matches/$m/events%3Abatch")
  echo "$body" | grep -q 'events%3Abatch' && ok "events%3Abatch forwarded undecoded" || bad "events%3Abatch: $body"
fi

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

if [[ " ${SERVICES[*]} " == *" core "* ]]; then
  echo "== seeded user through core (/api/core/me, /platform)"
  # Browser-less authorization-code + PKCE login of client `web` (as apps/web/tool/keycloak_login_check.sh).
  user_token() {  # $1 = username; password = DEV_USER_PASSWORD from .env (never printed)
    local iss="$BASE/auth/realms/academy" redir="$BASE/redirect.html" jar v c form action loc code
    jar=$(mktemp); trap 'rm -f "$jar"' RETURN
    b64() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
    v=$(openssl rand 48 | b64); c=$(printf '%s' "$v" | openssl dgst -sha256 -binary | b64)
    form=$(curl -fsS -c "$jar" -b "$jar" -G "$iss/protocol/openid-connect/auth" --data-urlencode client_id=web \
      --data-urlencode response_type=code --data-urlencode "redirect_uri=$redir" --data-urlencode "scope=openid profile email" \
      --data-urlencode state=smoke --data-urlencode "code_challenge=$c" --data-urlencode code_challenge_method=S256) || return 1
    action=$(printf '%s' "$form" | tr '\n' ' ' | sed -n 's/.*id="kc-form-login"[^>]*action="\([^"]*\)".*/\1/p' | sed 's/&amp;/\&/g')
    [ -n "$action" ] || return 1
    loc=$(printf 'username=%s&password=%s' "$1" "$DEV_USER_PASSWORD" |
      curl -sS -o /dev/null -D - -c "$jar" -b "$jar" "$action" --data-binary @- | tr -d '\r' | sed -n 's/^[Ll]ocation: //p')
    code=$(printf '%s' "$loc" | sed -n 's/.*[?&]code=\([^&#]*\).*/\1/p'); [ -n "$code" ] || return 1
    curl -fsS "$iss/protocol/openid-connect/token" -d grant_type=authorization_code -d client_id=web \
      --data-urlencode "code=$code" --data-urlencode "redirect_uri=$redir" --data-urlencode "code_verifier=$v" |
      sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'
  }
  utok=$(user_token superadmin@hoops-academy.com || true)
  if [ -z "$utok" ]; then bad "superadmin PKCE login failed (run deploy/kind/seed-users.sh first?)"
  else
    me=$(curl -s -H "Authorization: Bearer $utok" "$BASE/api/core/me")
    echo "$me" | grep -q '"superAdmin":true' && ok "/api/core/me -> superadmin" || bad "/api/core/me: $me"
    c=$(code -H "Authorization: Bearer $utok" "$BASE/platform/tenants")
    [ "$c" = 200 ] && ok "/platform/tenants -> 200" || bad "/platform/tenants -> $c"
    c=$(code -H "Authorization: Bearer $utok" "$BASE/internal/usage/00000000-0000-0000-0000-000000000000")
    [ "$c" = 403 ] && ok "/internal with a user token -> 403" || bad "/internal with a user token -> $c"
  fi
fi

[ "$fail" = 0 ] && echo "SMOKE PASSED" || { echo "SMOKE FAILED"; exit 1; }
