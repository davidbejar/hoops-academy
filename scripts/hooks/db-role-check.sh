#!/usr/bin/env bash
# Runs before Claude's `git push` (Claude Code hook .claude/hooks/tenancy-gate.sh) and as `just db-role-check`.
# Every service connects to Postgres as a role that row-level security binds: not a superuser, not BYPASSRLS, not a
# table owner, no CREATE on any schema. Checks the users the services SHIP with (application.properties, prod
# profile) and those roles as infra/db/init creates them.
# Tests: <Service>DatabaseRoleTest (DatabaseRoleMetaTest) + the library's DatabaseRoleCheckTest/ShippedDatasourcesTest.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
HOOK_LABEL="database role check (app is not owner/superuser)"
HOOK_CI_NOTE="CI still runs these tests in the backend job's verify"
source scripts/hooks/_common.sh

require_podman
run_maven -pl services/core-service,services/game-service,services/athlete-service -am test \
  -Dtest='*DatabaseRoleTest,DatabaseRoleCheckTest,ShippedDatasourcesTest' \
  -Dsurefire.failIfNoSpecifiedTests=false -Djacoco.skip=true
