# syntax=docker/dockerfile:1
# Quarkus service image (core-service | game-service | athlete-service). Build context = repository root.
#
#   podman build -f deploy/containers/service.Containerfile --build-arg SERVICE=game-service \
#     --ignorefile deploy/containers/service.containerignore -t hoops/game-service:dev .
#
# The maven stage also writes the service's CycloneDX SBOM (`-Psbom`); stage `sbom` holds only that file:
#   scripts/sbom.sh maven <service> <dir>      (images.yml; builds `--target sbom` from cache and copies it out)
#
# APP_SOURCE selects where the fast-jar comes from:
#   maven (default) - stage `app-maven` compiles inside the container (reproducible, CI);
#   host            - stage `app-host` copies services/$SERVICE/target/quarkus-app built on the host by
#                     `./mvnw package` (fast inner loop for Tilt; use service-prebuilt.containerignore).
ARG APP_SOURCE=maven
ARG MAVEN_IMAGE=docker.io/library/maven:3-eclipse-temurin-25
# Distroless Java 25 (ADR-0054): Debian 13, Temurin JRE, user nonroot (65532), no shell, no package manager. Distroless
# publishes floating tags only, so the pin is the digest (trivy DS-0001) of the multi-arch index (amd64, arm64, s390x,
# ppc64le, riscv64) of `java25-debian13:nonroot`, resolved 2026-11-21 (Temurin 25.0.5.1+2, the first build with the fix of CVE-2026-114938 "Java4Shell"). The weekly
# scripts/bump-pins.sh moves the digest; a new JDK or Debian major changes the name here and in scripts/bump_pins.py.
ARG RUNTIME_IMAGE=gcr.io/distroless/java25-debian13:nonroot@sha256:59bbb349c9752fc57b75744b41b1614c9dabe8bb4869523aabd5a4288f6c09a0

# ---------- stage 1a: build with Maven ---------------------------------------------------------------------------
FROM ${MAVEN_IMAGE} AS app-maven
ARG SERVICE
WORKDIR /src
# The reactor needs every module's POM; sources come with them (target/ dirs are excluded by the ignore file).
COPY pom.xml ./
COPY .mvn .mvn
COPY libs libs
COPY services services
COPY e2e/pom.xml e2e/pom.xml
RUN --mount=type=cache,target=/root/.m2,id=hoops-m2 \
    test -n "${SERVICE}" || { echo "build-arg SERVICE is required" >&2; exit 1; }; \
    mvn -B -ntp -q -pl "services/${SERVICE}" -am package -DskipTests -Psbom \
 && mkdir -p /out/sbom && cp -R "services/${SERVICE}/target/quarkus-app" /out/quarkus-app \
 && cp "services/${SERVICE}/target/bom.json" "/out/sbom/${SERVICE}-maven.cdx.json"

# ---------- stage 1b: take the fast-jar built on the host --------------------------------------------------------
FROM ${RUNTIME_IMAGE} AS app-host
ARG SERVICE
COPY services/${SERVICE}/target/quarkus-app /out/quarkus-app

FROM app-${APP_SOURCE} AS app

# ---------- SBOM export (WP85): only the CycloneDX of the Maven build above (scripts/sbom.sh maven)
FROM scratch AS sbom
COPY --from=app-maven /out/sbom/ /

# ---------- stage 2: runtime (distroless Java 25, non-root, no shell) -----------------------------------------------
# No shell here: no RUN, an exec-form entrypoint, HTTP probes only (the chart's httpGet on /q/health/*). OS fixes come
# with a new base digest (bump-pins), never from a package manager in this stage. Debugging: ADR-0054.
FROM ${RUNTIME_IMAGE}
ARG SERVICE
ARG SERVICE_PORT=8080
# SOURCE_URL: repository URL for the OCI source label (ghcr.io links the package to it). CI passes github.repository.
ARG SOURCE_URL=""
LABEL org.opencontainers.image.title="hoops-${SERVICE}" \
      org.opencontainers.image.source="${SOURCE_URL}" \
      org.opencontainers.image.description="Hoops Academy ${SERVICE} (Quarkus fast-jar)"
# Fast-jar layout: lib/ changes least, app/ most -> better layer reuse. Owned by root and read-only for the app user
# (any uid can read them, so a runAsUser other than 65532 still starts).
COPY --from=app /out/quarkus-app/lib/ /deployments/lib/
COPY --from=app /out/quarkus-app/*.jar /deployments/
COPY --from=app /out/quarkus-app/app/ /deployments/app/
COPY --from=app /out/quarkus-app/quarkus/ /deployments/quarkus/
WORKDIR /deployments
USER 65532:65532
EXPOSE ${SERVICE_PORT}
# Container-aware heap: the JVM sizes itself from the cgroup memory limit. Extra JVM flags at deploy time go in
# JDK_JAVA_OPTIONS (read by the java launcher); run-java.sh and JAVA_OPTS_APPEND of the old UBI image are gone.
ENTRYPOINT ["/usr/bin/java", "-XX:MaxRAMPercentage=75.0", "-XX:+ExitOnOutOfMemoryError", \
            "-Djava.util.logging.manager=org.jboss.logmanager.LogManager", "-Dquarkus.http.host=0.0.0.0", \
            "-jar", "/deployments/quarkus-run.jar"]
