# shellcheck shell=bash
# The dev users of realm `academy` (INF-04: one list for compose and kind). Runs INSIDE the Keycloak container, passed as
# the script of `bash -c` by infra/keycloak/seed-users.sh (podman exec) and deploy/kind/seed-users.sh (kubectl exec); it
# reads three lines on stdin: the master admin's name, its password, the dev users' password (never on a command line).
# Username = e-mail (as core-service creates users); a legacy user with the bare name is deleted first (dev data only).
# Idempotent: existing users are updated and get the password again (not temporary).
set -euo pipefail
read -r ADMIN; read -r ADMIN_PW; read -r DEV_PW
KC=/opt/keycloak/bin/kcadm.sh; REALM=academy
export HOME=/tmp   # kcadm's config file; the chart's Keycloak has a read-only root file system
$KC config credentials --server http://localhost:8080/auth --realm master --user "$ADMIN" --password "$ADMIN_PW" >/dev/null
user_id() { $KC get users -r $REALM -q "username=$1" -q exact=true --fields id --format csv --noquotes | head -n1 | tr -d '\r'; }
ensure_user() { # name first last
  local n="$1" f="$2" l="$3" u="$1@hoops-academy.com" id legacy
  legacy=$(user_id "$n")
  if [ -n "$legacy" ]; then
    $KC delete "users/$legacy" -r $REALM
    echo "migrated $n -> $u"
  fi
  id=$(user_id "$u")
  if [ -z "$id" ]; then
    $KC create users -r $REALM -s "username=$u" -s "email=$u" -s "firstName=$f" -s "lastName=$l" \
      -s enabled=true -s emailVerified=true >/dev/null
    echo "created $u"
  else
    $KC update "users/$id" -r $REALM -s "email=$u" -s enabled=true -s emailVerified=true >/dev/null
    echo "exists  $u"
  fi
  $KC set-password -r $REALM --username "$u" --new-password "$DEV_PW"
}
ensure_user superadmin Super Admin
ensure_user admin1 Alex Admin
ensure_user coach1 Casey Coach
ensure_user assistant1 Sam Assistant
ensure_user parent1 Pat Parent
ensure_user player1 Jordan Player
$KC add-roles -r $REALM --uusername superadmin@hoops-academy.com --rolename super_admin
echo "dev users: done (superadmin has super_admin)"
