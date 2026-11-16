#!/usr/bin/env bash
# finance-service's roles on the compose database (ADR-0055). The init scripts run only on a new volume, so a stack
# created before finance has no finance_migrator / finance_app: re-apply infra/db/init/01_roles_schemas.sql (idempotent:
# roles, schemas, grants, RLS helpers) as the superuser inside the container, then set the two passwords from .env.
# Run by `just finance-up`; safe to repeat. Passwords travel on stdin, never on a command line.
set -euo pipefail
cd "$(dirname "$0")/../.."
[ -f .env ] || { echo "finance-db: .env not found" >&2; exit 1; }
set -a; # shellcheck disable=SC1091
. ./.env; set +a
for v in FINANCE_MIGRATOR_PASSWORD FINANCE_APP_PASSWORD; do
  [ -n "${!v:-}" ] || { echo "finance-db: set $v in .env (see .env.example)" >&2; exit 1; }
done
podman exec -i hoops-postgres psql -q -v ON_ERROR_STOP=1 -U postgres -d hoops <infra/db/init/01_roles_schemas.sql
quote() { printf "'%s'" "${1//\'/\'\'}"; }
{
  echo "alter role finance_migrator password $(quote "$FINANCE_MIGRATOR_PASSWORD");"
  echo "alter role finance_app password $(quote "$FINANCE_APP_PASSWORD");"
} | podman exec -i hoops-postgres psql -q -v ON_ERROR_STOP=1 -U postgres -d hoops
echo "finance-db: roles finance_migrator and finance_app ready"
