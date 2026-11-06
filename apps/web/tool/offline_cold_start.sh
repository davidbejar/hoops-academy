#!/usr/bin/env bash
# Airplane-mode cold start check (WP54): builds the mock-mode release bundle (service worker stamped) into
# build/offline-check, then runs offline_cold_start.py: load online -> server stopped + offline emulation -> reload ->
# the shell renders from the cache -> sign in -> the live match opens with the offline banner.
#   tool/offline_cold_start.sh              # build + check (about 2 minutes)
#   tool/offline_cold_start.sh --no-build   # reuse build/offline-check
#   tool/offline_cold_start.sh --headed     # watch it (extra args go to the python script)
# Needs flutter, python3 and a chromedriver matching Chrome's major version (PATH or CHROMEDRIVER; CHROME = binary).
set -euo pipefail
cd "$(dirname "$0")/.."

build=1
args=()
for a in "$@"; do
  if [ "$a" = "--no-build" ]; then build=0; else args+=("$a"); fi
done
if [ "$build" = 1 ]; then
  # build_web.sh refuses HOOPS_MOCK_API on purpose (release safety), so build the throwaway mock bundle directly.
  flutter build web --release --no-web-resources-cdn --dart-define=HOOPS_MOCK_API=true --output=build/offline-check
  dart run tool/sw_manifest.dart build/offline-check
fi
exec python3 -I tool/offline_cold_start.py --dir build/offline-check ${args[@]+"${args[@]}"}
