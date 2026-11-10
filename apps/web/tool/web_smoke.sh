#!/usr/bin/env bash
# Browser smoke of the Flutter app (WP18): runs integration_test/journey_smoke_test.dart in Chrome with `flutter drive`.
#
#   tool/web_smoke.sh                 # mock mode: landing -> login -> academy -> live match -> event -> sync -> training week -> context switcher -> application admin hub -> academies (no backend needed)
#   tool/web_smoke.sh --real          # real mode: boots against http://localhost:5173 + the compose Keycloak (stack up)
#   tool/web_smoke.sh --compile-only  # no chromedriver needed: proves the test + app compile for the web
#
# The device must be `web-server`: with `-d chrome`, `flutter drive` suppresses its own Chrome launch (no-launch-chrome)
# and then waits forever for that Chrome to connect (symptom: stuck after "Waiting for connection from debug service").
# `flutter drive` needs a chromedriver whose major version matches Chrome
# (https://googlechromelabs.github.io/chrome-for-testing/). Put it on PATH or export CHROMEDRIVER=/path/to/chromedriver.
# The script starts it on :4444 and stops it afterwards.
set -euo pipefail
cd "$(dirname "$0")/.."

mode=mock
case "${1:-}" in
  --real) mode=real ;;
  --compile-only) mode=compile ;;
  "") ;;
  *) echo "usage: $0 [--real|--compile-only]" >&2; exit 2 ;;
esac

TARGET=integration_test/journey_smoke_test.dart
DEFINE=--dart-define=HOOPS_MOCK_API=true
[ "$mode" = real ] && DEFINE=--dart-define=HOOPS_E2E_REAL=true

if [ "$mode" = compile ]; then
  # Builds the test as the web entry point (same compiler path flutter drive uses). Output goes to a temp dir.
  out="$(mktemp -d)"; trap 'rm -rf "$out"' EXIT
  flutter build web --target="$TARGET" --output="$out" "$DEFINE"
  echo "OK: $TARGET compiles for the web ($mode defines: $DEFINE)"
  exit 0
fi

driver="${CHROMEDRIVER:-$(command -v chromedriver || true)}"
if [ -z "$driver" ]; then
  echo "chromedriver not found. Install one matching Chrome's major version (see header) or run: $0 --compile-only" >&2
  exit 3
fi
"$driver" --port=4444 >/dev/null 2>&1 &
cd_pid=$!
trap 'kill "$cd_pid" 2>/dev/null || true' EXIT
sleep 1

# Phone-sized window: the app is mobile first and the smoke drives the bottom NavigationBar layout.
args=(--driver=test_driver/integration_test.dart --target="$TARGET" -d web-server --browser-dimension=390x844 "$DEFINE")
[ "$mode" = real ] && args+=(--web-port 5173)
flutter drive "${args[@]}"
