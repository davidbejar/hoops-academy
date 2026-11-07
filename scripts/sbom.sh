#!/usr/bin/env bash
# CycloneDX SBOMs of the container images (WP85, ADR-0043). Used by .github/workflows/images.yml and locally; Podman.
#
#   scripts/sbom.sh maven SERVICE OUT_DIR        the service's Maven SBOM (runtime dependencies, cyclonedx-maven-plugin
#                                                 in the image's Maven stage, cached from the image build) into
#                                                 OUT_DIR/SERVICE-maven.cdx.json
#   scripts/sbom.sh generate NAME IMAGE OUT_DIR   image SBOM (OS packages + jars/files) of IMAGE with Trivy into
#                                                 OUT_DIR/NAME-image.cdx.json, then validates every OUT_DIR/*.cdx.json
#   scripts/sbom.sh validate OUT_DIR              validates every OUT_DIR/*.cdx.json against the schema of
#                                                 its specVersion (1.6 or newer, cyclonedx-cli)
#   scripts/sbom.sh attach REF OUT_DIR AUTHFILE   pushes every OUT_DIR/*.cdx.json as an OCI referrer of REF (a pushed
#                                                 image by digest, registry/name@sha256:...) with ORAS; AUTHFILE is the
#                                                 registry login (podman's auth.json, REGISTRY_AUTH_FILE)
#
# `maven` builds the Containerfile's `sbom` stage as an image and copies the file out (`podman build --output` does not
# work with a remote Podman, i.e. on macOS).
# Env: CONTAINER_ENGINE (default podman); SBOM_TRIVY_CACHE (a directory reused as Trivy's cache, optional);
#      SBOM_PLAIN_HTTP=true (attach only: a local test registry on this host's network, without TLS).
set -euo pipefail
cd "$(dirname "$0")/.."

# Pinned tools (bump tag and digest together; scripts/bump-pins.sh lists them)
TRIVY_IMAGE="docker.io/aquasec/trivy:0.76.1"
CYCLONEDX_CLI_IMAGE="docker.io/cyclonedx/cyclonedx-cli:0.33.1@sha256:252c2e26f468c25fea1e63ecde1bc3198ad6e9dbb57f5ed3236bddcb2281b3a7"
ORAS_IMAGE="ghcr.io/oras-project/oras:v1.3.6@sha256:9cfb578be975b762fd898b9d004243d8003aeb807a3e15b2ed212cdd1326c9eb"
SBOM_MEDIA_TYPE="application/vnd.cyclonedx+json"
ENGINE="${CONTAINER_ENGINE:-podman}"

die() { echo "sbom: $*" >&2; exit 1; }
abs() { (cd "$1" && pwd); }

validate() {
  local dir spec n=0; dir=$(abs "$1")
  for f in "$dir"/*.cdx.json; do
    [ -e "$f" ] || die "no *.cdx.json in $1"
    # the schema of the document's own specVersion (Maven plugin: 1.6, Trivy 0.76: 1.7); 1.6 or newer only
    spec=$(python3 -I -c 'import json, sys; b = json.load(open(sys.argv[1])); assert b["bomFormat"] == "CycloneDX"
v = b["specVersion"]; assert tuple(map(int, v.split("."))) >= (1, 6), v; print(v)' "$f") \
      || die "$(basename "$f") is not a CycloneDX 1.6+ document"
    "$ENGINE" run --rm -v "$dir:/sbom:ro" "$CYCLONEDX_CLI_IMAGE" validate --input-file "/sbom/$(basename "$f")" \
      --input-format json --input-version "v${spec/./_}" --fail-on-errors >/dev/null \
      || die "$(basename "$f") does not validate against the CycloneDX $spec schema"
    echo "sbom: valid  $(basename "$f")  CycloneDX $spec  components $(python3 -I -c \
      'import json, sys; print(len(json.load(open(sys.argv[1])).get("components", [])))' "$f")"
    n=$((n + 1))
  done
  echo "sbom: $n file(s) valid"
}

maven() {
  local service="$1" out="$2" tag ctr
  mkdir -p "$out"
  tag="localhost/hoops/$service-sbom:$$"
  # only SERVICE reaches the Maven stage, so this reuses the image build's cached layer
  "$ENGINE" build -q -f deploy/containers/service.Containerfile --ignorefile deploy/containers/service.containerignore \
    --build-arg SERVICE="$service" --target sbom -t "$tag" . >/dev/null
  ctr=$("$ENGINE" create "$tag" none)
  "$ENGINE" cp "$ctr:/$service-maven.cdx.json" "$out/$service-maven.cdx.json"
  "$ENGINE" rm "$ctr" >/dev/null
  "$ENGINE" rmi "$tag" >/dev/null
  echo "sbom: wrote $out/$service-maven.cdx.json"
}

generate() {
  local name="$1" image="$2" out="$3" work cache=()
  mkdir -p "$out"; out=$(abs "$out")
  work=$(mktemp -d); trap 'rm -rf "$work"' RETURN
  "$ENGINE" save -o "$work/image.tar" "$image"
  if [ -n "${SBOM_TRIVY_CACHE:-}" ]; then mkdir -p "$SBOM_TRIVY_CACHE"; cache=(-v "$(abs "$SBOM_TRIVY_CACHE"):/root/.cache/trivy"); fi
  "$ENGINE" run --rm ${cache[@]+"${cache[@]}"} -v "$work:/in:ro" -v "$out:/out" "$TRIVY_IMAGE" image --input /in/image.tar \
    --format cyclonedx --output "/out/$name-image.cdx.json" --no-progress --quiet
  validate "$out"
}

attach() {
  local ref="$1" dir auth plain=() net=()
  dir=$(abs "$2"); auth=$(cd "$(dirname "$3")" && pwd)/$(basename "$3")
  [ "${SBOM_PLAIN_HTTP:-}" = true ] && plain=(--plain-http) && net=(--network host)
  [[ "$ref" == *@sha256:* ]] || die "attach needs the image by digest (registry/name@sha256:...), got $ref"
  [ -f "$auth" ] || die "no registry auth file $3"
  for f in "$dir"/*.cdx.json; do
    [ -e "$f" ] || die "no *.cdx.json in $2"
    # relative file name: ORAS refuses absolute paths; the SBOM's own file name becomes its title annotation
    # No --user here: in rootless Podman (the GitHub runner) the container's root is the host user, which can read the
    # 0600 auth file; a numeric --user maps to a sub-uid that cannot (open /auth.json: permission denied).
    "$ENGINE" run --rm ${net[@]+"${net[@]}"} -v "$dir:/sbom:ro" -v "$auth:/auth.json:ro" -w /sbom \
      "$ORAS_IMAGE" attach --registry-config /auth.json ${plain[@]+"${plain[@]}"} --artifact-type "$SBOM_MEDIA_TYPE" \
      "$ref" "$(basename "$f"):$SBOM_MEDIA_TYPE"
  done
}

case "${1:-}" in
  maven) [ $# -eq 3 ] || die "usage: maven SERVICE OUT_DIR"; maven "$2" "$3" ;;
  generate) [ $# -eq 4 ] || die "usage: generate NAME IMAGE OUT_DIR"; generate "$2" "$3" "$4" ;;
  validate) [ $# -eq 2 ] || die "usage: validate OUT_DIR"; validate "$2" ;;
  attach) [ $# -eq 4 ] || die "usage: attach REF OUT_DIR AUTHFILE"; attach "$2" "$3" "$4" ;;
  *) sed -n '2,19p' "$0"; exit 2 ;;
esac
