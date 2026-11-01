# Developer entry points. Run `just` to list.
set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := true

default:
    @just --list

# Verify toolchain
doctor:
    source scripts/env.sh && scripts/doctor.sh

# Build and run all backend tests (unit + integration) with quality gates
test:
    source scripts/env.sh && ./mvnw -q -T 1C verify

# Fast compile + unit tests only
unit:
    source scripts/env.sh && ./mvnw -q -T 1C test

# Start the local stack (Postgres, Keycloak, proxy, mail)
up:
    podman compose --env-file .env -f infra/compose/compose.yaml up -d --wait

down:
    podman compose --env-file .env -f infra/compose/compose.yaml down

logs *ARGS:
    podman compose --env-file .env -f infra/compose/compose.yaml logs -f {{ARGS}}

# Seed Keycloak dev users (needs stack up)
seed-users:
    infra/keycloak/seed-users.sh

# Regenerate Dart API clients from libs/contracts
gen-api:
    scripts/gen-api.sh

# Flutter tests
web-test:
    cd apps/web && flutter test

# Security: secrets scan (full history) and dependency check
scan:
    gitleaks detect --source . --redact
    source scripts/env.sh && ./mvnw -q -Psecurity-scan org.owasp:dependency-check-maven:aggregate

# kind cluster lifecycle (WP16): cluster + ingress-nginx + CNPG + namespace/secrets. ARGS: --deploy [--from-host]
kind-up *ARGS:
    deploy/kind/up.sh {{ARGS}}

kind-down:
    deploy/kind/down.sh

# Inner loop on kind (needs `just kind-up`). ARGS go to Tilt, e.g. `just tilt ci` or `just tilt up -- --from-host`
tilt *ARGS="up":
    source scripts/env.sh && tilt {{ARGS}}

# --- WP18: end-to-end journeys (docs/runbooks/e2e.md) ---

# Build + start core/game/athlete on 8081-8083 against the running compose stack (needs `just up`, `just seed-users`)
services-up:
    e2e/bin/services-up.sh

services-down:
    e2e/bin/services-down.sh

# Whole journey suite on compose: stack up, seed users, services up, run, services down (stack stays up). BASE defaults to :8080
e2e BASE="http://localhost:8080":
    just up
    just seed-users
    e2e/bin/services-up.sh
    source scripts/env.sh && ./mvnw -pl e2e test -De2e.baseUrl={{BASE}}; rc=$?; e2e/bin/services-down.sh; exit $rc
