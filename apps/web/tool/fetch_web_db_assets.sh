#!/usr/bin/env bash
# Produces the two web assets of the offline match store (no Node needed):
#   web/sqlite3.wasm     - downloaded from the sqlite3.dart GitHub release that
#                          matches the resolved `sqlite3` package version
#   web/drift_worker.js  - compiled from tool/drift_worker.dart with dart2js
# Run after changing the drift / sqlite3 versions in pubspec.lock; commit both.
set -euo pipefail
cd "$(dirname "$0")/.."
version=$(awk '/^  sqlite3:/{f=1} f&&/version:/{gsub(/"/,"",$2); print $2; exit}' pubspec.lock)
url="https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-${version}/sqlite3.wasm"
echo "sqlite3 ${version}: ${url}"
curl -fsSL "$url" -o web/sqlite3.wasm
dart compile js -O4 tool/drift_worker.dart -o web/drift_worker.js
rm -f web/drift_worker.js.deps web/drift_worker.js.map
ls -l web/sqlite3.wasm web/drift_worker.js
