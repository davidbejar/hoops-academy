#!/usr/bin/env bash
# Seeds the dev users (superadmin, admin1, coach1, assistant1, parent1, player1 @hoops-academy.com; username = e-mail)
# into realm `academy` of the Keycloak running in kind: infra/keycloak/dev-users.sh through kubectl exec. Idempotent.
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

# the users and their creation live in infra/keycloak/dev-users.sh (INF-04), shared with compose's seed-users.sh
printf '%s\n%s\n%s\n' "$KEYCLOAK_ADMIN" "$KEYCLOAK_ADMIN_PASSWORD" "$DEV_USER_PASSWORD" |
  kubectl "${CTX[@]}" exec -i deploy/keycloak -- bash -c "$(cat infra/keycloak/dev-users.sh)"
