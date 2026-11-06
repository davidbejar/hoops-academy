#!/usr/bin/env bash
# CI (e2e.yml) / local: first-sign-in round trip in a real headless browser against the compose stack (WP55).
#   1. creates a Keycloak user with a TEMPORARY password (kcadm in the Keycloak container, secrets via container env),
#   2. builds the release web app against the local issuer and serves build/web on :5173 (the origin the realm allows),
#   3. runs browser_login_check.py --set-new-password.
# Needs: stack up (`just up`), .env (KEYCLOAK_ADMIN, KEYCLOAK_ADMIN_PASSWORD), flutter, python3, chromedriver
# matching Chrome on PATH (or CHROMEDRIVER). Optional: HOOPS_E2E_ARTIFACT_DIR for the failure screenshot.
set -euo pipefail
cd "$(dirname "$0")/../../.."
if [ -f .env ]; then set -a; . ./.env; set +a; fi
for v in KEYCLOAK_ADMIN KEYCLOAK_ADMIN_PASSWORD; do
  [ -n "${!v:-}" ] || { echo "ci_login_check: missing env $v" >&2; exit 1; }
done
C="${KEYCLOAK_CONTAINER:-hoops-keycloak}"
USER_EMAIL="${HOOPS_E2E_USER:-firstlogin@hoops-academy.com}"
export HOOPS_E2E_PASSWORD="${HOOPS_E2E_PASSWORD:-$(openssl rand -hex 12)Aa1}"
export HOOPS_E2E_NEW_PASSWORD="${HOOPS_E2E_NEW_PASSWORD:-$(openssl rand -hex 12)Bb2}"
[ -z "${GITHUB_ACTIONS:-}" ] || { echo "::add-mask::$HOOPS_E2E_PASSWORD"; echo "::add-mask::$HOOPS_E2E_NEW_PASSWORD"; }

kc() { podman exec -e KCADM_PW="$KEYCLOAK_ADMIN_PASSWORD" -e TMP_PW="$HOOPS_E2E_PASSWORD" "$C" bash -c "$@"; }
kc '/opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user "$0" --password "$KCADM_PW" >/dev/null' "$KEYCLOAK_ADMIN"
old=$(kc '/opt/keycloak/bin/kcadm.sh get users -r academy -q "username=$0" -q exact=true --fields id --format csv --noquotes' "$USER_EMAIL" | head -n1 | tr -d '\r')
[ -z "$old" ] || kc '/opt/keycloak/bin/kcadm.sh delete "users/$0" -r academy' "$old"
kc '/opt/keycloak/bin/kcadm.sh create users -r academy -s "username=$0" -s "email=$0" -s firstName=First -s lastName=Login -s enabled=true -s emailVerified=true >/dev/null' "$USER_EMAIL"
kc '/opt/keycloak/bin/kcadm.sh set-password -r academy --username "$0" --new-password "$TMP_PW" --temporary' "$USER_EMAIL"
echo "temporary-password user $USER_EMAIL ready"

cd apps/web
HOOPS_ALLOW_HTTP_ISSUER=1 tool/build_web.sh
python3 -I -m http.server 5173 --bind 127.0.0.1 --directory build/web >/dev/null 2>&1 &
http_pid=$!
trap 'kill "$http_pid" 2>/dev/null || true' EXIT
sleep 1

python3 -I tool/browser_login_check.py --app http://localhost:5173/ --user "$USER_EMAIL" --set-new-password
