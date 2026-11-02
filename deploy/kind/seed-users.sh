#!/usr/bin/env bash
# Seeds the dev users (superadmin, admin1, coach1, assistant1, parent1, player1 @hoops-academy.com; username = e-mail)
# into realm `academy` of the Keycloak running in kind. Kubernetes twin of infra/keycloak/seed-users.sh. Idempotent.
# Passwords travel over stdin of `kubectl exec`, never on a command line.
set -euo pipefail
cd "$(dirname "$0")/../.."
[ -f .env ] || { echo "seed-users: .env missing" >&2; exit 1; }
set -a; . ./.env; set +a
for v in KEYCLOAK_ADMIN KEYCLOAK_ADMIN_PASSWORD DEV_USER_PASSWORD; do
  [ -n "${!v:-}" ] || { echo "seed-users: missing env $v" >&2; exit 1; }
done
NS="${HOOPS_NAMESPACE:-hoops}"
CTX=(--context "kind-${KIND_CLUSTER:-hoops}" -n "$NS")
kubectl "${CTX[@]}" wait --for=condition=Available deployment/keycloak --timeout=600s >/dev/null

printf '%s\n%s\n%s\n' "$KEYCLOAK_ADMIN" "$KEYCLOAK_ADMIN_PASSWORD" "$DEV_USER_PASSWORD" |
kubectl "${CTX[@]}" exec -i deploy/keycloak -- bash -c '
set -euo pipefail
read -r ADMIN; read -r ADMIN_PW; read -r DEV_PW
KC=/opt/keycloak/bin/kcadm.sh; REALM=academy
export HOME=/tmp
$KC config credentials --server http://localhost:8080/auth --realm master --user "$ADMIN" --password "$ADMIN_PW" >/dev/null
ensure_user() { # name first last
  local n="$1" f="$2" l="$3" u="$1@hoops-academy.com" id legacy
  legacy=$($KC get users -r $REALM -q "username=$n" -q exact=true --fields id --format csv --noquotes | head -n1 | tr -d "\r")
  if [ -n "$legacy" ]; then
    $KC delete "users/$legacy" -r $REALM
    echo "migrated $n -> $u"
  fi
  id=$($KC get users -r $REALM -q "username=$u" -q exact=true --fields id --format csv --noquotes | head -n1 | tr -d "\r")
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
echo "seed-users: done (superadmin has super_admin)"
'
