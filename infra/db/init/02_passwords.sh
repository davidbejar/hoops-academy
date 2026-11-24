#!/bin/bash
# Sets the password of every role 01_roles_schemas.sql lists (marked 'hoops service role') from <ROLE>_PASSWORD, the
# role's name in upper case (INF-03: the SQL's list is the only one). compose and Testcontainers run it after the SQL; infra/compose/db-roles.sh runs it again on an existing compose database. Every variable is required. Values
# travel to psql on stdin, never on a command line, and are never printed.
# In Kubernetes, CloudNativePG manages these roles declaratively from Secrets instead (deploy/helm).
set -euo pipefail

psql_hoops() { psql -v ON_ERROR_STOP=1 -q --username "${POSTGRES_USER:-postgres}" --dbname "${POSTGRES_DB:-hoops}" "$@"; }

roles=$(psql_hoops -At -c "select rolname from pg_roles where shobj_description(oid, 'pg_authid') = 'hoops service role' order by rolname")
[ -n "$roles" ] || { echo "02_passwords.sh: no role marked by 01_roles_schemas.sql" >&2; exit 1; }

missing=""
for role in $roles; do
  var="$(printf '%s' "$role" | tr '[:lower:]' '[:upper:]')_PASSWORD"
  [ -n "${!var:-}" ] || missing="$missing $var"
done
[ -z "$missing" ] || { echo "02_passwords.sh: missing env$missing" >&2; exit 1; }

quote() { printf "'%s'" "${1//\'/\'\'}"; }   # SQL string literal (standard_conforming_strings is on)
for role in $roles; do
  var="$(printf '%s' "$role" | tr '[:lower:]' '[:upper:]')_PASSWORD"
  printf 'alter role "%s" password %s;\n' "$role" "$(quote "${!var}")"
done | psql_hoops
echo "02_passwords.sh: passwords of $(printf '%s' "$roles" | wc -w | tr -d ' ') roles set"
