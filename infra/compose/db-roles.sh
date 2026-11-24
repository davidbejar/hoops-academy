#!/usr/bin/env bash
# The service roles on an existing compose database (INF-03; was finance-db.sh, ADR-0055). The init scripts run only on a
# new volume, so a stack created before a role was added lacks it: re-apply infra/db/init/01_roles_schemas.sql
# (idempotent: roles, schemas, grants, RLS helpers) as the superuser inside the container, then run
# infra/db/init/02_passwords.sh there with every <ROLE>_PASSWORD of .env. Run by `just finance-up` and
# e2e/bin/services-up.sh; safe to repeat. Passwords reach the container as environment of the exec (`-e NAME`, value
# from this process), never on a command line.
set -euo pipefail
cd "$(dirname "$0")/../.."
[ -f .env ] || { echo "db-roles: .env not found" >&2; exit 1; }
set -a; # shellcheck disable=SC1091
. ./.env; set +a
pass=()
for role in $(infra/db/roles.sh); do
  var="$(printf '%s' "$role" | tr '[:lower:]' '[:upper:]')_PASSWORD"
  [ -n "${!var:-}" ] || { echo "db-roles: set $var in .env (see .env.example)" >&2; exit 1; }
  export "${var?}"; pass+=(-e "$var")
done
podman exec -i hoops-postgres psql -q -v ON_ERROR_STOP=1 -U postgres -d hoops <infra/db/init/01_roles_schemas.sql
podman exec -i "${pass[@]}" -e POSTGRES_USER=postgres -e POSTGRES_DB=hoops hoops-postgres bash -s <infra/db/init/02_passwords.sh
echo "db-roles: $(infra/db/roles.sh | wc -l | tr -d ' ') roles ready"
