#!/usr/bin/env bash
# Publishes core's roster aggregates that have no event yet (WP81, ADR-0037 "When rest flips") on the compose stack:
# signs in as the seeded super admin (authorization code + PKCE of client `web`, password DEV_USER_PASSWORD from .env,
# never printed) and calls POST /platform/events/backfill. Idempotent; `force` republishes every aggregate.
#   infra/compose/events-backfill.sh            (`just events-backfill`)
#   infra/compose/events-backfill.sh force      (`just events-backfill force`)
#   infra/compose/events-backfill.sh <tenant-id> [force]
set -euo pipefail
cd "$(dirname "$0")/../.."
if [ -f .env ]; then set -a; . ./.env; set +a; fi
[ -n "${DEV_USER_PASSWORD:-}" ] || { echo "events-backfill.sh: DEV_USER_PASSWORD missing (.env)" >&2; exit 1; }
BASE="${HOOPS_BASE_URL:-http://localhost:8080}"
USERNAME="${HOOPS_SUPER_ADMIN:-superadmin@hoops-academy.com}"

tenant="" force=false
for arg in "$@"; do
  case "$arg" in
    force) force=true ;;
    *-*-*-*-*) tenant="\"tenantId\":\"$arg\"," ;;
    *) echo "usage: events-backfill.sh [<tenant-id>] [force]" >&2; exit 2 ;;
  esac
done

token() {
  local iss="$BASE/auth/realms/academy" redir="$BASE/redirect.html" jar v c form action loc code
  jar=$(mktemp); trap 'rm -f "$jar"' RETURN
  b64() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
  v=$(openssl rand 48 | b64); c=$(printf '%s' "$v" | openssl dgst -sha256 -binary | b64)
  form=$(curl -fsS -c "$jar" -b "$jar" -G "$iss/protocol/openid-connect/auth" --data-urlencode client_id=web \
    --data-urlencode response_type=code --data-urlencode "redirect_uri=$redir" --data-urlencode "scope=openid profile email" \
    --data-urlencode state=backfill --data-urlencode "code_challenge=$c" --data-urlencode code_challenge_method=S256) || return 1
  action=$(printf '%s' "$form" | tr '\n' ' ' | sed -n 's/.*id="kc-form-login"[^>]*action="\([^"]*\)".*/\1/p' | sed 's/&amp;/\&/g')
  [ -n "$action" ] || return 1
  loc=$(printf 'username=%s&password=%s' "$USERNAME" "$DEV_USER_PASSWORD" |
    curl -sS -o /dev/null -D - -c "$jar" -b "$jar" "$action" --data-binary @- | tr -d '\r' | sed -n 's/^[Ll]ocation: //p')
  code=$(printf '%s' "$loc" | sed -n 's/.*[?&]code=\([^&#]*\).*/\1/p'); [ -n "$code" ] || return 1
  curl -fsS "$iss/protocol/openid-connect/token" -d grant_type=authorization_code -d client_id=web \
    --data-urlencode "code=$code" --data-urlencode "redirect_uri=$redir" --data-urlencode "code_verifier=$v" |
    sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'
}

tok=$(token) && [ -n "$tok" ] || { echo "events-backfill.sh: login of $USERNAME failed (just seed-users?)" >&2; exit 1; }
body=$(printf '{%s"force":%s}' "$tenant" "$force")
# the token goes through stdin (a header file), never on the command line
printf 'Authorization: Bearer %s\n' "$tok" |
  curl -sS --fail-with-body -X POST "$BASE/platform/events/backfill" -H @- -H 'Content-Type: application/json' \
    --data-binary "$body"
echo
