#!/usr/bin/env bash
# Release build with the caching service worker.
#   tool/build_web.sh [extra `flutter build web` args, e.g. --dart-define=HOOPS_API_BASE=...]
# 0. guards (F-20): no mock API; the OIDC issuer must be https unless
#    HOOPS_ALLOW_HTTP_ISSUER=1 (local stack: http://localhost:8080/auth/...)
# 1. flutter build web --no-web-resources-cdn: CanvasKit and the Roboto fallback font are
#    bundled into build/web (no gstatic.com requests, works offline, strict CSP; F-09)
# 2. dart run tool/sw_manifest.dart: stamps sw.js with the build id and the file list
# HOOPS_BUILD_GUARD_ONLY=1 stops after the guards (used by test/web/build_guard_test.dart).
set -euo pipefail
cd "$(dirname "$0")/.."

issuer="http://localhost:8080/auth/realms/academy"  # AppConfig default
for arg in "$@"; do
  case "$arg" in
    --dart-define=HOOPS_MOCK_API=true|--dart-define=HOOPS_MOCK_API=1)
      echo "build_web.sh: refusing a release build with HOOPS_MOCK_API (MockAuthService signs anyone in)" >&2
      exit 1 ;;
    --dart-define=HOOPS_OIDC_ISSUER=*) issuer="${arg#--dart-define=HOOPS_OIDC_ISSUER=}" ;;
  esac
done
case "$issuer" in
  https://*) ;;
  *)
    if [ "${HOOPS_ALLOW_HTTP_ISSUER:-0}" != "1" ]; then
      echo "build_web.sh: OIDC issuer '$issuer' is not https; pass --dart-define=HOOPS_OIDC_ISSUER=https://... or set HOOPS_ALLOW_HTTP_ISSUER=1 for a local build" >&2
      exit 1
    fi ;;
esac
[ "${HOOPS_BUILD_GUARD_ONLY:-0}" = "1" ] && exit 0

flutter build web --release --no-web-resources-cdn "$@"
dart run tool/sw_manifest.dart build/web
