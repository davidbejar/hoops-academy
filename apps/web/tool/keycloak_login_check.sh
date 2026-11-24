#!/usr/bin/env bash
# Scripted OIDC authorization-code + PKCE login against the compose Keycloak, exactly as the app's `oidc`
# package performs it (client `web`, S256, scopes openid profile email offline_access), then a refresh.
# Proves the realm/client/seeded user work; the browser part (redirect.html, token storage) is the manual check
# in README.md because the Keycloak HTML form lives on another origin than the Flutter page.
#
#   HOOPS_E2E_USER=coach1@hoops-academy.com HOOPS_E2E_PASSWORD=... apps/web/tool/keycloak_login_check.sh
#
# HOOPS_E2E_PASSWORD defaults to DEV_USER_PASSWORD from the repo's .env (never printed).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
if [ -z "${HOOPS_E2E_PASSWORD:-}" ] && [ -f "$ROOT/.env" ]; then
  HOOPS_E2E_PASSWORD="$(grep -E '^DEV_USER_PASSWORD=' "$ROOT/.env" | head -n1 | cut -d= -f2-)"
fi
: "${HOOPS_E2E_PASSWORD:?set HOOPS_E2E_PASSWORD (or DEV_USER_PASSWORD in .env)}"
USER_NAME="${HOOPS_E2E_USER:-coach1@hoops-academy.com}"
ISSUER="${HOOPS_OIDC_ISSUER:-http://localhost:8080/auth/realms/academy}"
CLIENT="${HOOPS_OIDC_CLIENT_ID:-web}"
REDIRECT="${HOOPS_E2E_REDIRECT:-http://localhost:8080/redirect.html}" # must match the client's redirectUris
# shellcheck source=scripts/lib/oidc-login.sh
. "$ROOT/scripts/lib/oidc-login.sh"   # the same sign-in the other scripts use (client, S256, state check)
TOKEN_URL="$ISSUER/protocol/openid-connect/token"

echo "1/3 discovery"
curl -fsS "$ISSUER/.well-known/openid-configuration" | grep -q '"S256"' && echo "    S256 advertised"

echo "2/3 login form, credentials of $USER_NAME, token exchange (PKCE)"
rc=0; OIDC_CLIENT_ID="$CLIENT" oidc_login "$ISSUER" "$REDIRECT" "$USER_NAME" HOOPS_E2E_PASSWORD || rc=$?
case "$rc" in
  0) ;;
  2) echo "    rate limited (429)" >&2; exit 1 ;;
  *) echo "    no code (login form missing, wrong password, required action or unregistered redirect URI?)" >&2; exit 1 ;;
esac
ACCESS="$OIDC_ACCESS_TOKEN"; REFRESH="$OIDC_REFRESH_TOKEN"
[ -n "$ACCESS" ] && [ -n "$REFRESH" ] || { echo "    missing access/refresh token" >&2; exit 1; }

echo "3/3 claims + refresh"
field() { printf '%s' "$1" | sed -n "s/.*\"$2\":\"\([^\"]*\)\".*/\1/p"; }
PAYLOAD="$(printf '%s' "$ACCESS" | cut -d. -f2 | tr '_-' '/+' | awk '{ while (length($0) % 4) $0 = $0 "="; print }' | openssl base64 -d -A)"
for claim in preferred_username azp iss; do
  printf '    %s=%s\n' "$claim" "$(printf '%s' "$PAYLOAD" | sed -n "s/.*\"$claim\":\"\([^\"]*\)\".*/\1/p")"
done
REFRESHED="$(curl -fsS "$TOKEN_URL" -d grant_type=refresh_token -d "client_id=$CLIENT" --data-urlencode "refresh_token=$REFRESH")"
[ -n "$(field "$REFRESHED" access_token)" ] && echo "    refresh_token grant OK"
echo "OK: $USER_NAME logged in via PKCE against $ISSUER"
