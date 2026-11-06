#!/usr/bin/env bash
# Prints the Kubernetes Secrets for namespace hoops (and the rate limit service's Redis login for envoy-gateway-system)
# as YAML on stdout, built from the repo .env (ADR-0012).
# Nothing is written to disk; values never appear on a command line (fed through process substitution).
#   deploy/kind/secrets.sh | kubectl apply -f -          (used by up.sh; the Tiltfile reads the same output)
set -euo pipefail
cd "$(dirname "$0")/../.."
ENV_FILE="${ENV_FILE:-.env}"
NS="${HOOPS_NAMESPACE:-hoops}"
EG_NS=envoy-gateway-system
[ -f "$ENV_FILE" ] || { echo "secrets.sh: $ENV_FILE not found - copy .env.example to .env and set real values" >&2; exit 1; }
set -a; # shellcheck disable=SC1090
. "./$ENV_FILE"; set +a

REQUIRED=(CORE_MIGRATOR_PASSWORD CORE_APP_PASSWORD CORE_PLATFORM_PASSWORD GAME_MIGRATOR_PASSWORD GAME_APP_PASSWORD
          ATHLETE_MIGRATOR_PASSWORD ATHLETE_APP_PASSWORD KEYCLOAK_ADMIN KEYCLOAK_ADMIN_PASSWORD KC_DB_PASSWORD
          CORE_SERVICE_CLIENT_SECRET GAME_SERVICE_CLIENT_SECRET ATHLETE_SERVICE_CLIENT_SECRET DEV_USER_PASSWORD
          RATELIMIT_REDIS_PASSWORD)
missing=0
for v in "${REQUIRED[@]}"; do
  if [ -z "${!v:-}" ]; then echo "secrets.sh: missing $v in $ENV_FILE" >&2; missing=1; fi
done
[ "$missing" = 0 ] || exit 1

LABEL=app.kubernetes.io/part-of=hoops-academy
emit() { kubectl create secret generic "$@" -n "${SECRET_NS:-$NS}" --dry-run=client -o yaml \
  | kubectl label --local -f - "$LABEL" -o yaml; echo '---'; }
# CNPG managed roles / initdb need kubernetes.io/basic-auth Secrets whose username equals the role name.
basic_auth() { # secret-name username ENV_VAR
  emit "$1" --type=kubernetes.io/basic-auth --from-literal=username="$2" --from-file=password=<(printf '%s' "${!3}")
}

basic_auth hoops-db-core-migrator    core_migrator    CORE_MIGRATOR_PASSWORD
basic_auth hoops-db-core-app         core_app         CORE_APP_PASSWORD
basic_auth hoops-db-core-platform    core_platform    CORE_PLATFORM_PASSWORD
basic_auth hoops-db-game-migrator    game_migrator    GAME_MIGRATOR_PASSWORD
basic_auth hoops-db-game-app         game_app         GAME_APP_PASSWORD
basic_auth hoops-db-athlete-migrator athlete_migrator ATHLETE_MIGRATOR_PASSWORD
basic_auth hoops-db-athlete-app      athlete_app      ATHLETE_APP_PASSWORD
basic_auth keycloak-db-app           keycloak         KC_DB_PASSWORD
emit keycloak-admin --from-file=username=<(printf '%s' "$KEYCLOAK_ADMIN") --from-file=password=<(printf '%s' "$KEYCLOAK_ADMIN_PASSWORD")
emit hoops-oidc-core-service    --from-file=client-secret=<(printf '%s' "$CORE_SERVICE_CLIENT_SECRET")
emit hoops-oidc-game-service    --from-file=client-secret=<(printf '%s' "$GAME_SERVICE_CLIENT_SECRET")
emit hoops-oidc-athlete-service --from-file=client-secret=<(printf '%s' "$ATHLETE_SERVICE_CLIENT_SECRET")
emit hoops-dev-users --from-file=password=<(printf '%s' "$DEV_USER_PASSWORD")
# Redis ACL of ratelimit-redis (WP46, ADR-0033): the password of its only user (hashed into the ACL file by the chart),
# and the same login as REDIS_AUTH=<user>:<password> for Envoy Gateway's rate limit pods, which can only read Secrets of
# their own namespace. The user name is the chart's rateLimit.redis.acl.user.
emit hoops-ratelimit-redis --from-file=password=<(printf '%s' "$RATELIMIT_REDIS_PASSWORD")
SECRET_NS="$EG_NS" emit envoy-ratelimit-redis-auth --from-file=auth=<(printf 'ratelimit:%s' "$RATELIMIT_REDIS_PASSWORD")
