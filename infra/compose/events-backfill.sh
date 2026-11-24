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

# shellcheck source=scripts/lib/oidc-login.sh
. scripts/lib/oidc-login.sh
oidc_login "$BASE/auth/realms/academy" "$BASE/redirect.html" "$USERNAME" DEV_USER_PASSWORD "openid profile email" \
  || { echo "events-backfill.sh: login of $USERNAME failed (just seed-users?)" >&2; exit 1; }
tok=$OIDC_ACCESS_TOKEN
body=$(printf '{%s"force":%s}' "$tenant" "$force")
# the token goes through stdin (a header file), never on the command line
printf 'Authorization: Bearer %s\n' "$tok" |
  curl -sS --fail-with-body -X POST "$BASE/platform/events/backfill" -H @- -H 'Content-Type: application/json' \
    --data-binary "$body"
echo
