# syntax=docker/dockerfile:1
# Flutter Web PWA served by unprivileged nginx (uid 101, port 8080). Build context = repository root.
#
#   WEB_SOURCE=host (default): `flutter build web` ran on the host (scripts/build-images.sh does it);
#                              the context is only apps/web/build/web (see web.containerignore). Fast, native arm64.
#   WEB_SOURCE=flutter:        builds inside ghcr.io/cirruslabs/flutter (hermetic; no pipeline uses it, images.yml
#                              builds on the host too). Several GB image and, on Apple silicon, slow under emulation if
#                              no arm64 variant is pulled.
ARG WEB_SOURCE=host
ARG FLUTTER_IMAGE=ghcr.io/cirruslabs/flutter:stable
# The stable nginx line (even minor); scripts/bump_pins.py moves it to the next even minor.
ARG NGINX_IMAGE=docker.io/nginxinc/nginx-unprivileged:1.30-alpine

FROM ${FLUTTER_IMAGE} AS web-flutter
WORKDIR /src/apps/web
COPY apps/web/ ./
RUN flutter pub get && flutter build web --release --pwa-strategy=offline-first \
 && mkdir -p /out && cp -R build/web /out/web

FROM ${NGINX_IMAGE} AS web-host
COPY apps/web/build/web /out/web

FROM web-${WEB_SOURCE} AS web

FROM ${NGINX_IMAGE}
# SOURCE_URL: repository URL for the OCI source label (ghcr.io links the package to it). CI passes github.repository.
ARG SOURCE_URL=""
LABEL org.opencontainers.image.title="hoops-web" \
      org.opencontainers.image.source="${SOURCE_URL}" \
      org.opencontainers.image.description="Hoops Academy Flutter Web PWA on nginx-unprivileged"
# Apply Alpine security updates on top of the pinned base (the Trivy gate fails on fixable HIGH/CRITICAL CVEs).
# `apk upgrade` leaves nginx alone (the base pins it in /etc/apk/world), so a base that is older than NGINX_MIN_VERSION
# gets that nginx.org package (the base already trusts its signing key) and loses the four dynamic modules nothing loads.
# 1.30.7-r1 fixes CVE-2026-113425, -121810, -123007, -123633, -118899 and -123634; nginx-unprivileged:1.30-alpine was
# still 1.30.6 on 2026-11-22. A newer base skips the step: delete it (and this ARG) once the base has caught up.
ARG NGINX_MIN_VERSION=1.30.7-r1
USER root
RUN apk upgrade --no-cache \
 && cur=$(apk list --installed nginx 2>/dev/null | sed -n 's/^nginx-\([0-9][^ ]*\) .*/\1/p') \
 && if [ "$(apk version -t "$cur" "$NGINX_MIN_VERSION")" = "<" ]; then \
      apk del --no-cache nginx-module-geoip nginx-module-image-filter nginx-module-njs nginx-module-xslt \
      && apk add --no-cache -X "https://nginx.org/packages/alpine/v$(cut -d. -f1,2 /etc/alpine-release)/main" \
           "nginx=$NGINX_MIN_VERSION" \
      && rm -f /etc/nginx/*.apk-new; \
    fi \
 && nginx -v
COPY --chown=101:0 deploy/containers/web-nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=web --chown=101:0 /out/web /usr/share/nginx/html
USER 101
EXPOSE 8080
