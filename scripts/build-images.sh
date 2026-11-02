#!/usr/bin/env bash
# Builds the Hoops Academy container images with Podman (WP16).
#
#   scripts/build-images.sh [options] [image...]      image = core-service | game-service | athlete-service | web
#
# Options:
#   --tag REF         full image ref for a single image (Tilt passes $EXPECTED_REF); default localhost/hoops/<img>:dev
#   --from-host       services: package on the host (./mvnw) and copy target/quarkus-app (fast, uses ~/.m2)
#                     default: compile inside the container (maven stage, reproducible)
#   --no-package      with --from-host: reuse the existing target/quarkus-app (no ./mvnw run)
#   --web-in-container  web: run `flutter build web` inside ghcr.io/cirruslabs/flutter instead of on the host
#   --skip-web-build  web: reuse an existing apps/web/build/web
#   --kind-load       load the built image(s) into the kind cluster ($KIND_CLUSTER, default hoops)
#   --push            push to $IMAGE_REGISTRY (refs become $IMAGE_REGISTRY/<img>:$IMAGE_TAG)
set -euo pipefail
cd "$(dirname "$0")/.."

ALL=(core-service game-service athlete-service web)
TAG_OVERRIDE="" FROM_HOST=0 NO_PACKAGE=0 WEB_IN_CONTAINER=0 SKIP_WEB_BUILD=0 KIND_LOAD=0 PUSH=0
IMAGES=()
while [ $# -gt 0 ]; do
  case "$1" in
    --tag) TAG_OVERRIDE="$2"; shift 2 ;;
    --from-host) FROM_HOST=1; shift ;;
    --no-package) NO_PACKAGE=1; shift ;;
    --web-in-container) WEB_IN_CONTAINER=1; shift ;;
    --skip-web-build) SKIP_WEB_BUILD=1; shift ;;
    --kind-load) KIND_LOAD=1; shift ;;
    --push) PUSH=1; shift ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    core-service|game-service|athlete-service|web) IMAGES+=("$1"); shift ;;
    *) echo "build-images: unknown argument $1" >&2; exit 2 ;;
  esac
done
[ ${#IMAGES[@]} -gt 0 ] || IMAGES=("${ALL[@]}")
if [ -n "$TAG_OVERRIDE" ] && [ ${#IMAGES[@]} -ne 1 ]; then echo "build-images: --tag needs exactly one image" >&2; exit 2; fi

REGISTRY="${IMAGE_REGISTRY:-localhost/hoops}"
REGISTRY="${REGISTRY%/}"
TAG="${IMAGE_TAG:-dev}"
# OCI source label: SOURCE_URL env, else the origin remote as an https URL, else empty.
SOURCE_URL="${SOURCE_URL:-$(git remote get-url origin 2>/dev/null | sed -E 's#^git@github.com:#https://github.com/#; s#\.git$##')}"
KIND_CLUSTER="${KIND_CLUSTER:-hoops}"
ref_for() { if [ -n "$TAG_OVERRIDE" ]; then echo "$TAG_OVERRIDE"; else echo "$REGISTRY/$1:$TAG"; fi; }
port_for() { case "$1" in core-service) echo 8081 ;; game-service) echo 8082 ;; athlete-service) echo 8083 ;; esac; }

build_service() {
  local svc="$1" ref; ref=$(ref_for "$svc")
  local src=maven ignore=deploy/containers/service.containerignore
  if [ "$FROM_HOST" = 1 ]; then
    src=host ignore=deploy/containers/service-prebuilt.containerignore
    if [ "$NO_PACKAGE" = 0 ]; then
      # shellcheck disable=SC1091
      source scripts/env.sh >/dev/null
      ./mvnw -q -B -pl "services/$svc" -am package -DskipTests
    fi
    [ -f "services/$svc/target/quarkus-app/quarkus-run.jar" ] || { echo "build-images: services/$svc/target/quarkus-app missing" >&2; exit 1; }
  fi
  echo "==> $ref (APP_SOURCE=$src)"
  podman build -f deploy/containers/service.Containerfile --ignorefile "$ignore" \
    --build-arg SERVICE="$svc" --build-arg SERVICE_PORT="$(port_for "$svc")" --build-arg APP_SOURCE="$src" \
    --build-arg SOURCE_URL="$SOURCE_URL" -t "$ref" .
}

build_web() {
  local ref; ref=$(ref_for web)
  local src=host ignore=deploy/containers/web.containerignore
  if [ "$WEB_IN_CONTAINER" = 1 ]; then
    src=flutter ignore=deploy/containers/web-flutter.containerignore
  elif [ "$SKIP_WEB_BUILD" = 0 ]; then
    (cd apps/web && flutter pub get >/dev/null && flutter build web --release --pwa-strategy=offline-first)
  fi
  [ "$src" = flutter ] || [ -f apps/web/build/web/index.html ] || { echo "build-images: apps/web/build/web missing" >&2; exit 1; }
  echo "==> $ref (WEB_SOURCE=$src)"
  podman build -f deploy/containers/web.Containerfile --ignorefile "$ignore" --build-arg WEB_SOURCE="$src" \
    --build-arg SOURCE_URL="$SOURCE_URL" -t "$ref" .
}

kind_load() { # podman save | kind load image-archive (kind cannot read Podman's image store directly)
  local ref="$1" archive
  archive=$(mktemp "${TMPDIR:-/tmp}/hoops-image.XXXXXX")
  trap 'rm -f "$archive"' RETURN
  podman save --format docker-archive -o "$archive" "$ref" >/dev/null
  KIND_EXPERIMENTAL_PROVIDER="${KIND_EXPERIMENTAL_PROVIDER:-podman}" kind load image-archive "$archive" --name "$KIND_CLUSTER"
  echo "==> loaded $ref into kind/$KIND_CLUSTER"
}

for img in "${IMAGES[@]}"; do
  if [ "$img" = web ]; then build_web; else build_service "$img"; fi
  [ "$KIND_LOAD" = 0 ] || kind_load "$(ref_for "$img")"
  [ "$PUSH" = 0 ] || podman push "$(ref_for "$img")"
done
