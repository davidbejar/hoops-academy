#!/usr/bin/env bash
# Runs before Claude's `git commit` (Claude Code hook .claude/hooks/tenancy-gate.sh) and as `just isolation-check`.
# The admin of academy A logs in through a real Keycloak and tries to read academy B's data through the API and,
# under the API, through the app's own database pool. Every attempt must fail. Also checks that the pool's database
# role is bound by row-level security. Test: core CrossTenantAccessTest.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
HOOK_LABEL="tenant isolation check (academy A cannot read academy B)"
HOOK_CI_NOTE="CI does NOT run this test: it is tagged keycloak, which verify excludes"
source scripts/hooks/_common.sh

require_podman
run_maven -pl services/core-service -am test -Pkeycloak-it \
  -Dtest=CrossTenantAccessTest -Dsurefire.failIfNoSpecifiedTests=false -Djacoco.skip=true
