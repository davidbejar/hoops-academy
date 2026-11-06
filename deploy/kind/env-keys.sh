# shellcheck shell=bash
# Sourced by deploy/kind/secrets.sh and deploy/kind/eso-store.sh: the .env keys the kind Secrets are made of (ADR-0012),
# and load_env, which reads the git-ignored .env and fails fast on a missing file or key. Values stay in this shell's
# variables; nothing is printed.
ENV_FILE="${ENV_FILE:-.env}"
SECRET_KEYS=(CORE_MIGRATOR_PASSWORD CORE_APP_PASSWORD CORE_PLATFORM_PASSWORD GAME_MIGRATOR_PASSWORD GAME_APP_PASSWORD
             ATHLETE_MIGRATOR_PASSWORD ATHLETE_APP_PASSWORD KEYCLOAK_ADMIN KEYCLOAK_ADMIN_PASSWORD KC_DB_PASSWORD
             CORE_SERVICE_CLIENT_SECRET GAME_SERVICE_CLIENT_SECRET ATHLETE_SERVICE_CLIENT_SECRET DEV_USER_PASSWORD
             RATELIMIT_REDIS_PASSWORD REDPANDA_ADMIN_PASSWORD REDPANDA_CORE_SERVICE_PASSWORD REDPANDA_GAME_SERVICE_PASSWORD
             REDPANDA_ATHLETE_SERVICE_PASSWORD)
load_env() { # $1 = caller name for messages
  [ -f "$ENV_FILE" ] || { echo "$1: $ENV_FILE not found - copy .env.example to .env and set real values" >&2; exit 1; }
  set -a; # shellcheck disable=SC1090
  . "./$ENV_FILE"; set +a
  local v missing=0
  for v in "${SECRET_KEYS[@]}"; do
    if [ -z "${!v:-}" ]; then echo "$1: missing $v in $ENV_FILE" >&2; missing=1; fi
  done
  [ "$missing" = 0 ] || exit 1
}
