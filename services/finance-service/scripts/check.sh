#!/usr/bin/env bash
# The Go gates of finance-service (ADR-0055), run by `just test-go` (and so by `just test`) and by CI's job `go`:
#   1. gofmt -l                              formatting (no file may need a change)
#   2. go mod tidy -diff, go mod verify      go.mod / go.sum tidy and the module cache intact
#   3. golangci-lint run                     lints (.golangci.yml: complexity, duplication, unused code, errors, gosec)
#   4. go test with coverage                 unit, contract, HTTP, RLS / isolation (Postgres by Testcontainers), layering
#   5. scripts/coverage_gate.py              >= 80 % statements in the module, >= 90 % in internal/domain
#   6. go tool govulncheck                   Go vulnerability database, reachable code only
# The toolchain is the one go.mod pins (`toolchain` line; GOTOOLCHAIN=auto fetches it when the local Go is older).
# Needs golangci-lint v2 (scripts/bootstrap.sh installs it) and Podman (source scripts/env.sh: DOCKER_HOST for
# Testcontainers). --offline skips step 6 (it reads vuln.go.dev).
set -euo pipefail
cd "$(dirname "$0")/.."

command -v go >/dev/null 2>&1 || { echo "finance-service: go not found (scripts/bootstrap.sh installs it)" >&2; exit 1; }
command -v golangci-lint >/dev/null 2>&1 \
  || { echo "finance-service: golangci-lint not found (scripts/bootstrap.sh installs it)" >&2; exit 1; }
if [ -z "${DOCKER_HOST:-}" ] && [ -f ../../scripts/env.sh ]; then
  # shellcheck source=../../../scripts/env.sh
  source ../../scripts/env.sh >/dev/null
fi

offline=0
[ "${1:-}" = "--offline" ] && offline=1

step() { printf '\n== finance-service: %s\n' "$*"; }
step "gofmt"
unformatted=$(gofmt -l cmd internal db)
if [ -n "$unformatted" ]; then echo "gofmt would change:"; echo "$unformatted"; exit 1; fi
step "go.mod tidy and verified"
go mod tidy -diff
go mod verify
step "golangci-lint"
golangci-lint run ./...
step "tests with coverage"
mkdir -p target
go test -count=1 -p 2 -shuffle=on -coverpkg=./... -coverprofile=target/coverage.out ./...
step "coverage gate"
python3 -I scripts/coverage_gate.py target/coverage.out
if [ "$offline" -eq 0 ]; then
  step "vulnerability check"
  go tool govulncheck ./...
else
  step "vulnerability check skipped (--offline)"
fi
