#!/usr/bin/env bash
# Release build with the caching service worker.
#   tool/build_web.sh [extra `flutter build web` args, e.g. --dart-define=HOOPS_API_BASE=...]
# 1. flutter build web (copies web/sw.js and web/flutter_bootstrap.js into build/web)
# 2. dart run tool/sw_manifest.dart: stamps sw.js with the build id and the file list
set -euo pipefail
cd "$(dirname "$0")/.."
flutter build web --release "$@"
dart run tool/sw_manifest.dart build/web
