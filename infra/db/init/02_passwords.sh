#!/bin/bash
# Sets role passwords from environment variables (compose + Testcontainers). Runs after 01_roles_schemas.sql.
# In Kubernetes, CloudNativePG manages these roles declaratively from Secrets instead (deploy/helm).
set -euo pipefail

require() { [ -n "${!1:-}" ] || { echo "02_passwords.sh: missing env $1" >&2; exit 1; }; }
for v in CORE_MIGRATOR_PASSWORD CORE_APP_PASSWORD CORE_PLATFORM_PASSWORD GAME_MIGRATOR_PASSWORD GAME_APP_PASSWORD ATHLETE_MIGRATOR_PASSWORD ATHLETE_APP_PASSWORD; do require "$v"; done

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  -v core_migrator="$CORE_MIGRATOR_PASSWORD" -v core_app="$CORE_APP_PASSWORD" -v core_platform="$CORE_PLATFORM_PASSWORD" \
  -v game_migrator="$GAME_MIGRATOR_PASSWORD" -v game_app="$GAME_APP_PASSWORD" \
  -v athlete_migrator="$ATHLETE_MIGRATOR_PASSWORD" -v athlete_app="$ATHLETE_APP_PASSWORD" <<'EOSQL'
alter role core_migrator    password :'core_migrator';
alter role core_app         password :'core_app';
alter role core_platform    password :'core_platform';
alter role game_migrator    password :'game_migrator';
alter role game_app         password :'game_app';
alter role athlete_migrator password :'athlete_migrator';
alter role athlete_app      password :'athlete_app';
EOSQL
echo "02_passwords.sh: role passwords set"
