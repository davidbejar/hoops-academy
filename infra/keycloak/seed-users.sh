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

# The dev users (INF-04: infra/keycloak/dev-users.sh, shared with deploy/kind/seed-users.sh); secrets on stdin.
printf '%s\n%s\n%s\n' "$KEYCLOAK_ADMIN" "$KEYCLOAK_ADMIN_PASSWORD" "$DEV_USER_PASSWORD" |
  podman exec -i "$C" bash -c "$(cat infra/keycloak/dev-users.sh)"

# kcadm for the realm retrofit below; the admin password reaches the container as environment of this exec, never on a
# command line.
kc() { podman exec "$C" /opt/keycloak/bin/kcadm.sh "$@"; }
podman exec -e KCADM_PW="$KEYCLOAK_ADMIN_PASSWORD" "$C" bash -c \
  '/opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user "$0" --password "$KCADM_PW" >/dev/null' "$KEYCLOAK_ADMIN"
# client_id_of CLIENT_ID: Keycloak's internal id of a client of the realm (empty when there is none)
client_id_of() { kc get clients -r "$REALM" -q "clientId=$1" --fields id --format csv --noquotes | head -n1 | tr -d '\r'; }
# realm_file PART: what the retrofit needs of infra/keycloak/realm-academy.json, the source of truth (INF-07: one reader)
#   bearer-only  the bearer-only clients            audiences  client, mapper name, audience of each audience mapper
#   admin-scope  clients with scope kc-admin-api    hardening  the login hardening and security-event settings as JSON
realm_file() {
  python3 -I - infra/keycloak/realm-academy.json "$1" <<'PY'
import json, sys
realm, part = json.load(open(sys.argv[1])), sys.argv[2]
clients = realm["clients"]
if part == "bearer-only":
    print("\n".join(c["clientId"] for c in clients if c.get("bearerOnly")))
elif part == "audiences":
    for c in clients:
        for m in c.get("protocolMappers", []):
            if m["protocolMapper"] == "oidc-audience-mapper":
                print(c["clientId"], m["name"], m["config"]["included.client.audience"], sep="\t")
elif part == "admin-scope":
    print("\n".join(c["clientId"] for c in clients if "kc-admin-api" in c.get("defaultClientScopes", [])))
elif part == "hardening":
    keys = ["browserSecurityHeaders", "passwordPolicy"] + [k for k in realm if k.startswith("otpPolicy")]
    keys += ["eventsEnabled", "eventsExpiration", "eventsListeners", "enabledEventTypes", "adminEventsEnabled",
             "adminEventsDetailsEnabled", "attributes"]
    print(json.dumps({k: realm[k] for k in keys}))
else:
    sys.exit("realm_file: unknown part " + part)
PY
}

# The realm JSON is imported only into an empty volume: bring an existing realm up to date with its login theme
# (ADR-0022) and e-mail-as-username (ADR-0023: an e-mail change moves the username, which Keycloak refuses with
# error-user-attribute-read-only otherwise), without resetting the database.
kc update "realms/$REALM" -s loginTheme=hoops -s registrationEmailAsUsername=true >/dev/null
# Token settings of ADR-0034 for a realm imported before them: refresh-token rotation with reuse detection, and the
# audience mappers of each client, read from the realm file (the source of truth; existing mappers are kept).
kc update "realms/$REALM" -s revokeRefreshToken=true -s refreshTokenMaxReuse=0 >/dev/null
# Bearer-only clients added to the realm file after an import (pdf-service, ADR-0052): an audience, no flow, no secret.
realm_file bearer-only | while read -r client; do
  if [ -z "$(client_id_of "$client")" ]; then
    kc create clients -r "$REALM" -s "clientId=$client" -s bearerOnly=true -s publicClient=false \
      -s standardFlowEnabled=false -s directAccessGrantsEnabled=false -s serviceAccountsEnabled=false >/dev/null
    echo "added bearer-only client $client"
  fi
done
realm_file audiences | while IFS=$'\t' read -r client mapper audience; do
  cid=$(client_id_of "$client")
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
# Keycloak 26.8.2 and later: the Admin REST API only accepts tokens issued for it, which the built-in client scope
# kc-admin-api provides. A realm imported before the realm file had it on core-service gets it here (clients read from
# the realm file); without it every admin call of the service account returns 401.
realm_file admin-scope | while read -r client; do
  sid=$(kc get client-scopes -r "$REALM" --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "kc-admin-api" {print $1}')
  [ -n "$sid" ] || { echo "seed-users: realm has no client scope kc-admin-api (Keycloak older than 26.8.2?)" >&2; exit 1; }
  cid=$(client_id_of "$client")
  [ -n "$cid" ] || { echo "seed-users: realm has no client $client" >&2; exit 1; }
  if ! kc get "clients/$cid/default-client-scopes" -r "$REALM" --fields name --format csv --noquotes | tr -d '\r' \
      | grep -qxF kc-admin-api; then
    kc update "clients/$cid/default-client-scopes/$sid" -r "$REALM" >/dev/null
    echo "added client scope kc-admin-api to client $client"
  fi
done
# Login hardening of ADR-0038 for a realm imported before it: security headers (CSP), the password policy with its
# blocklist and the OTP policy, read from the realm file. Keycloak's built-in browser flow already asks for the OTP only
# when a login set one up, so no flow changes. Security events of ADR-0043 the same way: user events stored for 30 days
# and logged by jboss-logging, admin events without representation, their expiry (realm attribute; others are kept).
realm_file hardening |
  podman exec -i "$C" bash -c 'f=$(mktemp) && cat > "$f" && /opt/keycloak/bin/kcadm.sh update "realms/$0" -f "$f"; rc=$?; rm -f "$f"; exit $rc' "$REALM"
echo "seed-users: done (superadmin has super_admin; login theme hoops; e-mail as username; token audiences, rotation; kc-admin-api scope; CSP, password blocklist, OTP policy; security events)"
