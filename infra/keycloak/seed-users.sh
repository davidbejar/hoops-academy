#!/usr/bin/env bash
# Seeds local dev users into realm `academy` using kcadm.sh inside the Keycloak container. Idempotent.
# Needs: stack up (`just up`), KEYCLOAK_ADMIN, KEYCLOAK_ADMIN_PASSWORD, DEV_USER_PASSWORD in env (.env).
set -euo pipefail
cd "$(dirname "$0")/../.."
if [ -f .env ]; then set -a; . ./.env; set +a; fi
for v in KEYCLOAK_ADMIN KEYCLOAK_ADMIN_PASSWORD DEV_USER_PASSWORD; do
  [ -n "${!v:-}" ] || { echo "seed-users: missing env $v" >&2; exit 1; }
done
[ "${#DEV_USER_PASSWORD}" -ge 12 ] || { echo "seed-users: DEV_USER_PASSWORD must be >= 12 chars (realm password policy)" >&2; exit 1; }

C="${KEYCLOAK_CONTAINER:-hoops-keycloak}"
REALM=academy
# Secrets are passed via the container environment of this exec, never on a command line.
kc() { podman exec -e KCADM_PW="$KEYCLOAK_ADMIN_PASSWORD" -e DEV_PW="$DEV_USER_PASSWORD" "$C" /opt/keycloak/bin/kcadm.sh "$@"; }

podman exec -e KCADM_PW="$KEYCLOAK_ADMIN_PASSWORD" "$C" bash -c \
  '/opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user "$0" --password "$KCADM_PW" >/dev/null' "$KEYCLOAK_ADMIN"

ensure_user() { # username first last
  local u="$1" f="$2" l="$3" id
  id=$(kc get users -r "$REALM" -q "username=$u" -q exact=true --fields id --format csv --noquotes | head -n1 | tr -d '\r')
  if [ -z "$id" ]; then
    kc create users -r "$REALM" -s "username=$u" -s "email=$u@hoops.local" -s "firstName=$f" -s "lastName=$l" \
       -s enabled=true -s emailVerified=true >/dev/null
    echo "created $u"
  else
    kc update "users/$id" -r "$REALM" -s "email=$u@hoops.local" -s enabled=true -s emailVerified=true >/dev/null
    echo "exists  $u"
  fi
  # Always (re)set the password from the environment; temporary=false.
  podman exec -e KCADM_PW="$KEYCLOAK_ADMIN_PASSWORD" -e DEV_PW="$DEV_USER_PASSWORD" "$C" bash -c \
    '/opt/keycloak/bin/kcadm.sh set-password -r "$0" --username "$1" --new-password "$DEV_PW"' "$REALM" "$u"
}

ensure_user superadmin Super Admin
ensure_user admin1 Alex Admin
ensure_user coach1 Casey Coach
ensure_user assistant1 Sam Assistant
ensure_user parent1 Pat Parent
ensure_user player1 Jordan Player

kc add-roles -r "$REALM" --uusername superadmin --rolename super_admin
echo "seed-users: done (superadmin has super_admin)"
