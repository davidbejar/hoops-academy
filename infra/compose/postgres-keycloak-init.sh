#!/bin/bash
# Compose-only: creates the Keycloak database and role (separate from the application database `hoops`).
set -euo pipefail
: "${KC_DB_PASSWORD:?missing KC_DB_PASSWORD}"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres -v kcpw="$KC_DB_PASSWORD" <<'EOSQL'
create role keycloak login nosuperuser nocreatedb nocreaterole nobypassrls password :'kcpw';
create database keycloak owner keycloak;
revoke all on database keycloak from public;
EOSQL
echo "keycloak db created"
