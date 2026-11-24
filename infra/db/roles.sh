#!/usr/bin/env bash
# Prints the service roles of the one list in infra/db/init/01_roles_schemas.sql (INF-03), one per line, in its order:
# for scripts and workflows that need the names (password variables are <ROLE>_PASSWORD, upper case).
set -euo pipefail
sql="$(dirname "$0")/init/01_roles_schemas.sql"
roles=$(sed -n "/^-- roles: begin$/,/^-- roles: end$/s/^ *('\([a-z_]*\)'.*/\1/p" "$sql")
[ -n "$roles" ] || { echo "roles.sh: no '-- roles: begin' list in $sql" >&2; exit 1; }
printf '%s\n' "$roles"
