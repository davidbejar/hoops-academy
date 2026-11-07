#!/usr/bin/env bash
# Prints the Kubernetes Secrets for namespace hoops (incl. the event broker logins, WP66) and the rate limit service's
# Redis login for envoy-gateway-system as YAML on stdout, built from the repo .env (ADR-0012).
# Nothing is written to disk; values never appear on a command line (fed through process substitution).
#   deploy/kind/secrets.sh | kubectl apply -f -          (used by up.sh; the Tiltfile reads the same output)
set -euo pipefail
cd "$(dirname "$0")/../.."
NS="${HOOPS_NAMESPACE:-hoops}"
EG_NS=envoy-gateway-system
# shellcheck source=deploy/kind/env-keys.sh
. deploy/kind/env-keys.sh
load_env secrets.sh

LABEL=app.kubernetes.io/part-of=hoops-academy
emit() { kubectl create secret generic "$@" -n "${SECRET_NS:-$NS}" --dry-run=client -o yaml \
  | kubectl label --local -f - "$LABEL" ${EXTRA_LABEL:+"$EXTRA_LABEL"} -o yaml; echo '---'; }
# CNPG managed roles / initdb need kubernetes.io/basic-auth Secrets whose username equals the role name.
basic_auth() { # secret-name username ENV_VAR
  emit "$1" --type=kubernetes.io/basic-auth --from-literal=username="$2" --from-file=password=<(printf '%s' "${!3}")
}
# CNPG re-reads only Secrets labelled cnpg.io/reload: without it a rotated role password never reaches the database (WP86).
db_role() { EXTRA_LABEL=cnpg.io/reload=true basic_auth "$@"; }

db_role hoops-db-core-migrator   core_migrator    CORE_MIGRATOR_PASSWORD
db_role hoops-db-core-app        core_app         CORE_APP_PASSWORD
db_role hoops-db-core-platform   core_platform    CORE_PLATFORM_PASSWORD
db_role hoops-db-game-migrator   game_migrator    GAME_MIGRATOR_PASSWORD
db_role hoops-db-game-app        game_app         GAME_APP_PASSWORD
db_role hoops-db-athlete-migrator athlete_migrator ATHLETE_MIGRATOR_PASSWORD
db_role hoops-db-athlete-app     athlete_app      ATHLETE_APP_PASSWORD
db_role keycloak-db-app          keycloak         KC_DB_PASSWORD
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
# Event broker logins (WP66, ADR-0036): the Redpanda superuser and one SCRAM user per service, usernames = the chart's
# events.superuser.name / events.users[].name (the bootstrap Job sets the passwords on the broker).
basic_auth hoops-redpanda-admin           admin           REDPANDA_ADMIN_PASSWORD
basic_auth hoops-redpanda-core-service    core-service    REDPANDA_CORE_SERVICE_PASSWORD
basic_auth hoops-redpanda-game-service    game-service    REDPANDA_GAME_SERVICE_PASSWORD
basic_auth hoops-redpanda-athlete-service athlete-service REDPANDA_ATHLETE_SERVICE_PASSWORD
