#!/usr/bin/env bash
# Scripted OIDC authorization-code + PKCE login against the compose Keycloak, exactly as the app's `oidc`
# package performs it (client `web`, S256, scopes openid profile email offline_access), then a refresh.
# Proves the realm/client/seeded user work; the browser part (redirect.html, token storage) is the manual check
# in README.md because the Keycloak HTML form lives on another origin than the Flutter page.
#
#   HOOPS_E2E_USER=coach1 HOOPS_E2E_PASSWORD=... apps/web/tool/keycloak_login_check.sh
#
# HOOPS_E2E_PASSWORD defaults to DEV_USER_PASSWORD from the repo's .env (never printed).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
if [ -z "${HOOPS_E2E_PASSWORD:-}" ] && [ -f "$ROOT/.env" ]; then
  HOOPS_E2E_PASSWORD="$(grep -E '^DEV_USER_PASSWORD=' "$ROOT/.env" | head -n1 | cut -d= -f2-)"
fi
: "${HOOPS_E2E_PASSWORD:?set HOOPS_E2E_PASSWORD (or DEV_USER_PASSWORD in .env)}"
USER_NAME="${HOOPS_E2E_USER:-coach1}"
ISSUER="${HOOPS_OIDC_ISSUER:-http://localhost:8080/auth/realms/academy}"
CLIENT="${HOOPS_OIDC_CLIENT_ID:-web}"
REDIRECT="${HOOPS_E2E_REDIRECT:-http://localhost:8080/redirect.html}" # must match the client's redirectUris
SCOPE="openid profile email offline_access"
JAR="$(mktemp)"; trap 'rm -f "$JAR"' EXIT

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
VERIFIER="$(openssl rand 48 | b64url)"
CHALLENGE="$(printf '%s' "$VERIFIER" | openssl dgst -sha256 -binary | b64url)"
STATE="$(openssl rand -hex 8)"

AUTH_URL="$ISSUER/protocol/openid-connect/auth"
TOKEN_URL="$ISSUER/protocol/openid-connect/token"

echo "1/4 discovery"
curl -fsS "$ISSUER/.well-known/openid-configuration" | grep -q '"S256"' && echo "    S256 advertised"

echo "2/4 login form"
FORM="$(curl -fsS -c "$JAR" -b "$JAR" -G "$AUTH_URL" \
  --data-urlencode "client_id=$CLIENT" --data-urlencode "response_type=code" \
  --data-urlencode "redirect_uri=$REDIRECT" --data-urlencode "scope=$SCOPE" \
  --data-urlencode "state=$STATE" --data-urlencode "code_challenge=$CHALLENGE" \
  --data-urlencode "code_challenge_method=S256")"
ACTION="$(printf '%s' "$FORM" | tr '\n' ' ' | sed -n 's/.*id="kc-form-login"[^>]*action="\([^"]*\)".*/\1/p' | sed 's/&amp;/\&/g')"
[ -n "$ACTION" ] || { echo "    login form not found (is the client's redirect URI registered?)" >&2; exit 1; }

echo "3/4 submit credentials for $USER_NAME"
LOCATION="$(curl -sS -o /dev/null -D - -c "$JAR" -b "$JAR" "$ACTION" \
  --data-urlencode "username=$USER_NAME" --data-urlencode "password=$HOOPS_E2E_PASSWORD" \
  | tr -d '\r' | sed -n 's/^[Ll]ocation: //p')"
case "$LOCATION" in "$REDIRECT"*) ;; *) echo "    no redirect with code (wrong password / required action?)" >&2; exit 1 ;; esac
CODE="$(printf '%s' "$LOCATION" | sed -n 's/.*[?&]code=\([^&#]*\).*/\1/p')"
[ "$(printf '%s' "$LOCATION" | sed -n 's/.*[?&]state=\([^&#]*\).*/\1/p')" = "$STATE" ] || { echo "    state mismatch" >&2; exit 1; }

echo "4/4 token exchange (PKCE) + refresh"
TOKENS="$(curl -fsS "$TOKEN_URL" -d grant_type=authorization_code -d "client_id=$CLIENT" \
  --data-urlencode "code=$CODE" --data-urlencode "redirect_uri=$REDIRECT" --data-urlencode "code_verifier=$VERIFIER")"
field() { printf '%s' "$1" | sed -n "s/.*\"$2\":\"\([^\"]*\)\".*/\1/p"; }
ACCESS="$(field "$TOKENS" access_token)"; REFRESH="$(field "$TOKENS" refresh_token)"
[ -n "$ACCESS" ] && [ -n "$REFRESH" ] || { echo "    missing access/refresh token" >&2; exit 1; }
PAYLOAD="$(printf '%s' "$ACCESS" | cut -d. -f2 | tr '_-' '/+' | awk '{ while (length($0) % 4) $0 = $0 "="; print }' | openssl base64 -d -A)"
for claim in preferred_username azp iss; do
  printf '    %s=%s\n' "$claim" "$(printf '%s' "$PAYLOAD" | sed -n "s/.*\"$claim\":\"\([^\"]*\)\".*/\1/p")"
done
echo "    scope=$(field "$TOKENS" scope)"
REFRESHED="$(curl -fsS "$TOKEN_URL" -d grant_type=refresh_token -d "client_id=$CLIENT" --data-urlencode "refresh_token=$REFRESH")"
[ -n "$(field "$REFRESHED" access_token)" ] && echo "    refresh_token grant OK"
echo "OK: $USER_NAME logged in via PKCE against $ISSUER"
