# syntax=docker/dockerfile:1
# Flutter Web PWA served by unprivileged nginx (uid 101, port 8080). Build context = repository root.
#
#   WEB_SOURCE=host (default): `flutter build web` ran on the host (scripts/build-images.sh does it);
#                              the context is only apps/web/build/web (see web.containerignore). Fast, native arm64.
#   WEB_SOURCE=flutter:        builds inside ghcr.io/cirruslabs/flutter (hermetic, CI). Several GB image and,
#                              on Apple silicon, slow under emulation if no arm64 variant is pulled.
ARG WEB_SOURCE=host
ARG FLUTTER_IMAGE=ghcr.io/cirruslabs/flutter:stable
# 1.30 (stable): the 1.27-alpine tag is frozen on Alpine 3.21.3 (Trivy: 58 fixable HIGH/CRITICAL on 2026-11-02;
# 1.30-alpine / Alpine 3.24.2: 3).
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
LABEL org.opencontainers.image.title="hoops-web" \
      org.opencontainers.image.description="Hoops Academy Flutter Web PWA on nginx-unprivileged"
COPY --chown=101:0 deploy/containers/web-nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=web --chown=101:0 /out/web /usr/share/nginx/html
USER 101
EXPOSE 8080
