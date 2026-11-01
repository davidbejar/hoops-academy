#!/usr/bin/env bash
# Produces the two web assets of the offline match store (no Node needed):
#   web/sqlite3.wasm     - downloaded from the sqlite3.dart GitHub release that
#                          matches the resolved `sqlite3` package version and
#                          VERIFIED against the pinned sha256 below (F-10)
#   web/drift_worker.js  - compiled from tool/drift_worker.dart with dart2js
# Run after changing the drift / sqlite3 versions in pubspec.lock; commit both.
# Bumping sqlite3: run once, read the "expected/actual" error, check the release
# page, then update the two pins (test/web/sqlite3_wasm_test.dart guards them).
set -euo pipefail
cd "$(dirname "$0")/.."

SQLITE3_WASM_VERSION="3.8.0"
SQLITE3_WASM_SHA256="efd308be92a34f3aa15f289a37f213b0230fd80888a1364326ee29579d892d37"

version=$(awk '/^  sqlite3:/{f=1} f&&/version:/{gsub(/"/,"",$2); print $2; exit}' pubspec.lock)
if [ "$version" != "$SQLITE3_WASM_VERSION" ]; then
  echo "pubspec.lock resolves sqlite3 ${version} but the pin is for ${SQLITE3_WASM_VERSION}: update the pin" >&2
  exit 1
fi
url="https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-${version}/sqlite3.wasm"
echo "sqlite3 ${version}: ${url}"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
curl -fsSL "$url" -o "$tmp"
actual=$(shasum -a 256 "$tmp" | cut -d' ' -f1)
if [ "$actual" != "$SQLITE3_WASM_SHA256" ]; then
  echo "sqlite3.wasm checksum mismatch: expected ${SQLITE3_WASM_SHA256}, actual ${actual}" >&2
  exit 1
fi
mv "$tmp" web/sqlite3.wasm
trap - EXIT
dart compile js -O4 tool/drift_worker.dart -o web/drift_worker.js
rm -f web/drift_worker.js.deps web/drift_worker.js.map
ls -l web/sqlite3.wasm web/drift_worker.js
