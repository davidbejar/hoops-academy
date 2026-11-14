#!/usr/bin/env bash
# One-time developer machine setup for macOS (Apple Silicon or Intel).
set -euo pipefail

need_brew() { command -v brew >/dev/null || { echo "Homebrew is required: https://brew.sh"; exit 1; }; }
need_brew

FORMULAE=(openjdk@25 maven kind helm tilt podman podman-compose gitleaks pre-commit openapi-generator trivy just opentofu)
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

echo "==> pre-commit hooks"
( cd "$(dirname "$0")/.." && pre-commit install --install-hooks )

echo "==> Flutter"
flutter config --enable-web >/dev/null 2>&1 || true
flutter precache --web >/dev/null 2>&1 || true

echo
echo "Done. Next: 'source scripts/env.sh && scripts/doctor.sh'"
echo "For kind (WP16) a rootful machine is recommended:"
echo "  podman machine stop && podman machine set --rootful --cpus 6 --memory 12288 && podman machine start"
