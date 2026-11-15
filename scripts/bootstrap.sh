#!/usr/bin/env bash
# One-time developer machine setup for macOS (Apple Silicon or Intel).
set -euo pipefail

need_brew() { command -v brew >/dev/null || { echo "Homebrew is required: https://brew.sh"; exit 1; }; }
need_brew

# rustup, cargo-llvm-cov and cargo-deny: pdf-service (ADR-0052); go and golangci-lint: finance-service (ADR-0055);
# no Node anywhere
FORMULAE=(openjdk@25 maven kind helm tilt podman podman-compose gitleaks pre-commit openapi-generator trivy just opentofu
          rustup cargo-llvm-cov cargo-deny go golangci-lint)
CASKS=(flutter)   # openjdk@25 formula needs no sudo (temurin cask does)

echo "==> Installing formulae: ${FORMULAE[*]}"
brew install "${FORMULAE[@]}"
echo "==> Installing casks: ${CASKS[*]}"
brew install --cask "${CASKS[@]}"

echo "==> Podman machine"
if ! podman machine inspect >/dev/null 2>&1; then
  podman machine init --cpus 6 --memory 12288 --disk-size 100
fi
podman machine start 2>/dev/null || true

echo "==> Testcontainers properties"
TC=~/.testcontainers.properties
touch "$TC"
grep -q '^ryuk.container.privileged' "$TC" || echo 'ryuk.container.privileged=true' >> "$TC"

echo "==> Rust toolchain of pdf-service (services/pdf-service/rust-toolchain.toml)"
# Homebrew's rustup is keg-only; `rustup toolchain install` without a name installs the pinned toolchain file's
( cd "$(dirname "$0")/../services/pdf-service" && PATH="$(brew --prefix rustup)/bin:$PATH" rustup toolchain install )
echo "    add $(brew --prefix rustup)/bin to PATH (or let scripts/check.sh find it)"

echo "==> Go toolchain of finance-service (services/finance-service/go.mod)"
# The `toolchain` line of go.mod pins the version; GOTOOLCHAIN=auto (Go's default) fetches it when Homebrew's go is
# older. govulncheck is a tool dependency of the module (`go tool govulncheck`), pinned by go.sum.
( cd "$(dirname "$0")/../services/finance-service" && go mod download && go version )

echo "==> pre-commit hooks"
( cd "$(dirname "$0")/.." && pre-commit install --install-hooks )

echo "==> Flutter"
flutter config --enable-web >/dev/null 2>&1 || true
flutter precache --web >/dev/null 2>&1 || true

echo
echo "Done. Next: 'source scripts/env.sh && scripts/doctor.sh'"
echo "For kind (WP16) a rootful machine is recommended:"
echo "  podman machine stop && podman machine set --rootful --cpus 6 --memory 12288 && podman machine start"
