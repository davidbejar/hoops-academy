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

# kind cluster lifecycle (WP16)
kind-up:
    deploy/kind/up.sh

kind-down:
    deploy/kind/down.sh
