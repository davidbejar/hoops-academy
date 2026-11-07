#!/usr/bin/env bash
# Pin bumper (WP89): --check lists outdated pins (exit 1 if any), --apply rewrites the files. Same-major unless --major.
# Inventory and resolution rules: scripts/bump_pins.py (table in its header); docs/runbooks/release.md "Pins and bumps".
# Registry lookups run skopeo in a pinned container (CONTAINER_ENGINE, default podman); GitHub releases need no token
# (set GITHUB_TOKEN to lift the anonymous rate limit). Examples:
#   scripts/bump-pins.sh --check
#   scripts/bump-pins.sh --apply --root /path/to/copy      # throwaway copy; omit --root to edit in place
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
command -v "${CONTAINER_ENGINE:-podman}" >/dev/null || { echo "bump-pins: ${CONTAINER_ENGINE:-podman} not found" >&2; exit 2; }
exec python3 -I scripts/bump_pins.py "$@"
