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

# Username = e-mail (as core-service creates users). A legacy user with the bare name is deleted first: dev data only.
ensure_user() { # name first last
  local n="$1" f="$2" l="$3" u="$1@hoops-academy.com" id legacy
  legacy=$(kc get users -r "$REALM" -q "username=$n" -q exact=true --fields id --format csv --noquotes | head -n1 | tr -d '\r')
  if [ -n "$legacy" ]; then
    kc delete "users/$legacy" -r "$REALM"
    echo "migrated $n -> $u"
  fi
  id=$(kc get users -r "$REALM" -q "username=$u" -q exact=true --fields id --format csv --noquotes | head -n1 | tr -d '\r')
  if [ -z "$id" ]; then
    kc create users -r "$REALM" -s "username=$u" -s "email=$u" -s "firstName=$f" -s "lastName=$l" \
       -s enabled=true -s emailVerified=true >/dev/null
    echo "created $u"
  else
    kc update "users/$id" -r "$REALM" -s "email=$u" -s enabled=true -s emailVerified=true >/dev/null
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

kc add-roles -r "$REALM" --uusername superadmin@hoops-academy.com --rolename super_admin

# The realm JSON is imported only into an empty volume: bring an existing realm up to date with its login theme
# (ADR-0022) and e-mail-as-username (ADR-0023: an e-mail change moves the username, which Keycloak refuses with
# error-user-attribute-read-only otherwise), without resetting the database.
kc update "realms/$REALM" -s loginTheme=hoops -s registrationEmailAsUsername=true >/dev/null
# Token settings of ADR-0034 for a realm imported before them: refresh-token rotation with reuse detection, and the
# audience mappers of each client, read from the realm file (the source of truth; existing mappers are kept).
kc update "realms/$REALM" -s revokeRefreshToken=true -s refreshTokenMaxReuse=0 >/dev/null
python3 -I - infra/keycloak/realm-academy.json <<'PY' |
import json, sys
for client in json.load(open(sys.argv[1]))["clients"]:
    for m in client.get("protocolMappers", []):
        if m["protocolMapper"] == "oidc-audience-mapper":
            print(client["clientId"], m["name"], m["config"]["included.client.audience"], sep="\t")
PY
while IFS=$'\t' read -r client mapper audience; do
  cid=$(kc get clients -r "$REALM" -q "clientId=$client" --fields id --format csv --noquotes | head -n1 | tr -d '\r')
  [ -n "$cid" ] || { echo "seed-users: realm has no client $client" >&2; exit 1; }
  if ! kc get "clients/$cid/protocol-mappers/models" -r "$REALM" --fields name --format csv --noquotes | tr -d '\r' \
      | grep -qxF "$mapper"; then
    kc create "clients/$cid/protocol-mappers/models" -r "$REALM" -s "name=$mapper" -s protocol=openid-connect \
      -s protocolMapper=oidc-audience-mapper -s "config.\"included.client.audience\"=$audience" \
      -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false' \
      -s 'config."introspection.token.claim"=true' >/dev/null
    echo "added $mapper to client $client"
  fi
done
# Login hardening of ADR-0038 for a realm imported before it: security headers (CSP), the password policy with its
# blocklist and the OTP policy, read from the realm file. Keycloak's built-in browser flow already asks for the OTP only
# when a login set one up, so no flow changes. Security events of ADR-0043 the same way: user events stored for 30 days
# and logged by jboss-logging, admin events without representation, their expiry (realm attribute; others are kept).
python3 -I - infra/keycloak/realm-academy.json <<'PY' |
import json, sys
realm = json.load(open(sys.argv[1]))
keys = ["browserSecurityHeaders", "passwordPolicy"] + [k for k in realm if k.startswith("otpPolicy")]
keys += ["eventsEnabled", "eventsExpiration", "eventsListeners", "enabledEventTypes", "adminEventsEnabled",
         "adminEventsDetailsEnabled", "attributes"]
print(json.dumps({k: realm[k] for k in keys}))
PY
  podman exec -i "$C" bash -c 'f=$(mktemp) && cat > "$f" && /opt/keycloak/bin/kcadm.sh update "realms/$0" -f "$f"; rc=$?; rm -f "$f"; exit $rc' "$REALM"
echo "seed-users: done (superadmin has super_admin; login theme hoops; e-mail as username; token audiences, rotation; CSP, password blocklist, OTP policy; security events)"
