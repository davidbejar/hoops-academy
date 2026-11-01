#!/usr/bin/env bash
# Generate the Flutter (dart-dio / built_value) API clients from libs/contracts/openapi/<svc>.yaml.
#
# Usage: scripts/gen-api.sh [service ...]        (default: core game athlete; run from anywhere, e.g. `just gen-api`)
#
# Environment:
#   API_OUT_ROOT       output root, one package per service in $API_OUT_ROOT/<svc>   (default: apps/web/lib/api;
#                      relative paths are resolved against the repository root)
#   OPENAPI_GENERATOR  generator CLI                                                  (default: openapi-generator)
#   GEN_API_BUILD      1 = run `dart pub get` + build_runner in each package so it compiles (default: 1; 0 = skip)
#
# Output is fully generated: each $API_OUT_ROOT/<svc> directory is replaced on every run. Never edit it by hand —
# change the contract and regenerate. Operations marked `x-internal` (/internal/**) are not generated.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC_DIR="$REPO_ROOT/libs/contracts/openapi"
EXPECTED_GENERATOR_VERSION="7.26.0" # keep in sync with openapi-generator.version in the root pom.xml
GENERATOR="${OPENAPI_GENERATOR:-openapi-generator}"
BUILD="${GEN_API_BUILD:-1}"

OUT_ROOT="${API_OUT_ROOT:-apps/web/lib/api}"
[[ "$OUT_ROOT" = /* ]] || OUT_ROOT="$REPO_ROOT/$OUT_ROOT"

if [[ $# -gt 0 ]]; then SERVICES=("$@"); else SERVICES=(core game athlete); fi

die() { echo "gen-api: $*" >&2; exit 1; }

command -v "$GENERATOR" >/dev/null 2>&1 || die "'$GENERATOR' not found (brew install openapi-generator)"
actual_version="$("$GENERATOR" version 2>/dev/null | tail -n 1)"
[[ "$actual_version" == "$EXPECTED_GENERATOR_VERSION" ]] ||
  echo "gen-api: warning: $GENERATOR $actual_version, contracts are validated with $EXPECTED_GENERATOR_VERSION" >&2

spec_version() { # info.version of a spec (first `version:` under `info:`)
  awk '/^info:/{in_info=1; next} in_info && /^[^ ]/{exit} in_info && $1=="version:"{print $2; exit}' "$1"
}

generate() {
  local svc="$1"
  local spec="$SPEC_DIR/$svc.yaml"
  local out="$OUT_ROOT/$svc"
  [[ -f "$spec" ]] || die "unknown service '$svc' (no $spec)"

  echo "gen-api: $svc  $spec -> $out"
  rm -rf -- "$out"
  mkdir -p -- "$out"
  "$GENERATOR" generate \
    --generator-name dart-dio \
    --input-spec "$spec" \
    --output "$out" \
    --global-property apiTests=false,modelTests=false,apiDocs=false,modelDocs=false \
    --additional-properties "pubName=hoops_${svc}_api,pubVersion=$(spec_version "$spec"),pubDescription=Generated ${svc}-service client (do not edit),serializationLibrary=built_value,dateLibrary=core,enumUnknownDefaultCase=true" \
    >/dev/null

  if [[ "$BUILD" == "1" ]]; then
    command -v dart >/dev/null 2>&1 || die "dart not found; install Flutter or set GEN_API_BUILD=0"
    (cd "$out" && dart pub get >/dev/null && dart run build_runner build --delete-conflicting-outputs >/dev/null)
  fi
}

for svc in "${SERVICES[@]}"; do
  generate "$svc"
done
echo "gen-api: done (${SERVICES[*]})"
