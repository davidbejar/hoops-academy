# syntax=docker/dockerfile:1
# Quarkus service image (core-service | game-service | athlete-service). Build context = repository root.
#
#   podman build -f deploy/containers/service.Containerfile --build-arg SERVICE=game-service \
#     --ignorefile deploy/containers/service.containerignore -t hoops/game-service:dev .
#
# APP_SOURCE selects where the fast-jar comes from:
#   maven (default) - stage `app-maven` compiles inside the container (reproducible, CI);
#   host            - stage `app-host` copies services/$SERVICE/target/quarkus-app built on the host by
#                     `./mvnw package` (fast inner loop for Tilt; use service-prebuilt.containerignore).
ARG APP_SOURCE=maven
ARG MAVEN_IMAGE=docker.io/library/maven:3-eclipse-temurin-21
ARG RUNTIME_IMAGE=registry.access.redhat.com/ubi9/openjdk-21-runtime:latest

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
    mvn -B -ntp -q -pl "services/${SERVICE}" -am package -DskipTests \
 && mkdir -p /out && cp -R "services/${SERVICE}/target/quarkus-app" /out/quarkus-app

# ---------- stage 1b: take the fast-jar built on the host --------------------------------------------------------
FROM ${RUNTIME_IMAGE} AS app-host
ARG SERVICE
COPY services/${SERVICE}/target/quarkus-app /out/quarkus-app

FROM app-${APP_SOURCE} AS app

# ---------- stage 2: runtime (non-root UBI9 OpenJDK 21) ----------------------------------------------------------
FROM ${RUNTIME_IMAGE}
ARG SERVICE
ARG SERVICE_PORT=8080
# SOURCE_URL: repository URL for the OCI source label (ghcr.io links the package to it). CI passes github.repository.
ARG SOURCE_URL=""
LABEL org.opencontainers.image.title="hoops-${SERVICE}" \
      org.opencontainers.image.source="${SOURCE_URL}" \
      org.opencontainers.image.description="Hoops Academy ${SERVICE} (Quarkus fast-jar)"
ENV LANGUAGE='en_US:en' \
    # container-aware heap: the JVM sizes itself from the cgroup memory limit
    JAVA_OPTS_APPEND="-XX:MaxRAMPercentage=75.0 -XX:+ExitOnOutOfMemoryError -Djava.util.logging.manager=org.jboss.logmanager.LogManager -Dquarkus.http.host=0.0.0.0" \
    JAVA_APP_JAR="/deployments/quarkus-run.jar"
# Fast-jar layout: lib/ changes least, app/ most -> better layer reuse.
COPY --from=app --chown=185:0 /out/quarkus-app/lib/ /deployments/lib/
COPY --from=app --chown=185:0 /out/quarkus-app/*.jar /deployments/
COPY --from=app --chown=185:0 /out/quarkus-app/app/ /deployments/app/
COPY --from=app --chown=185:0 /out/quarkus-app/quarkus/ /deployments/quarkus/
USER 185
EXPOSE ${SERVICE_PORT}
ENTRYPOINT ["/opt/jboss/container/java/run/run-java.sh"]
