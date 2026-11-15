# ADR-0054: The Java services run on distroless Java 25, pinned by digest

- Status: Accepted
- Date: 2026-11-15
- Related: decision 87 of 2026-11-15, WP114, ADR-0045 (gates), ADR-0043 (SBOMs), WP89 (bump-pins), WP109 (Java 25),
  `deploy/containers/service.Containerfile`, `.github/workflows/images.yml`

## Context
The `images` workflow fails on fixable HIGH / CRITICAL findings (Trivy, `--ignore-unfixed`). Since 2026-11-14 every
run on `main` has been red on 14 HIGH findings, all `krb5-libs` in `ubi9/openjdk-25-runtime` (the same 14 in the
JDK 21 image): Red Hat lists a fix, but it is not in the UBI repositories, so `microdnf -y update` in the runtime stage
cannot pick it up. The JVM does not use Kerberos here; the package comes with the UBI base. Decision 87: neither wait
for Red Hat nor accept the findings, but move core, game and athlete to a distroless Java 25 base pinned by digest.

## Decision
1. **Base**: `gcr.io/distroless/java25-debian13:nonroot` (Debian 13, Temurin JRE 25.0.5+8 at the first pin, user
   `nonroot` 65532, no shell, no package manager, CA certificates, tzdata, `LANG=C.UTF-8`). It holds the JRE and the
   few libraries it needs, so Trivy has much less to report: 0 HIGH / CRITICAL on all three images on 2026-11-15
   (the UBI image of the same jars: 14 HIGH). Image size 650 MB -> 328 MB (core).
2. **Pin**: distroless publishes floating tags only (`latest`, `nonroot`, `debug`, `debug-nonroot`), so the pin is the
   digest of the multi-arch index of `nonroot` (amd64, arm64, s390x, ppc64le, riscv64). The weekly `bump-pins` PR
   moves it (`scripts/bump_pins.py`, floating-tag pin, like `zaproxy:stable`). A new JDK or Debian major changes the
   image name in the Containerfile and the pin together; `scripts/tests/test_jdk_pins.py` fails if the image's JDK is not
   `maven.compiler.release` or if the pin no longer names the Containerfile's image.
3. **Runtime stage**: no `RUN` (there is no shell), exec-form `ENTRYPOINT ["/usr/bin/java", ..., "-jar",
   "/deployments/quarkus-run.jar"]` with the flags the UBI `run-java.sh` used to get from `JAVA_OPTS_APPEND`
   (`-XX:MaxRAMPercentage=75.0`, `-XX:+ExitOnOutOfMemoryError`, JBoss log manager, `quarkus.http.host=0.0.0.0`). Extra
   flags at deploy time go in `JDK_JAVA_OPTIONS`. The fast-jar stays in `/deployments`, owned by root and readable by
   any uid (the chart's `runAsUser: 185` still starts it); `USER 65532:65532`. OS fixes come only with a new digest.
4. **Health**: HTTP only (`/q/health/{started,live,ready}`, the chart's `httpGet` probes). No `HEALTHCHECK` with a
   shell or curl in the image.
5. **CI**: the non-root check reads the image's configured user (`podman image inspect`) and starts the image's own
   `java -version` with a read-only root; `id` does not exist in the image.

## What is lost and how to debug instead
- No shell, no `curl`, `ls`, `cat`, `ps` in the container: `kubectl exec ... -- sh` and `podman exec ... sh` fail.
- Instead:
  - **Ephemeral debug container** (Kubernetes): `kubectl -n hoops debug -it deploy/core-service
    --image=busybox:1.37 --target=core-service -- sh` shares the process namespace; the app's files are under
    `/proc/1/root/deployments`.
  - **The JVM's own tools** through the image's `java`: e.g. `podman run --rm --entrypoint /usr/bin/java <image>
    --list-modules`, `-XshowSettings:all -version`. `jcmd` / `jstack` are not in the JRE: thread dumps by
    `kill -3` from a debug container (written to the container log), heap and flight recordings by
    `-XX:+HeapDumpOnOutOfMemoryError` / `-XX:StartFlightRecording` in `JDK_JAVA_OPTIONS`, written to `/tmp`.
  - **HTTP from outside**: `/q/health/*` through the gateway; `/q/metrics` with `kubectl port-forward` (it is not
    routed and the image has no curl to call it from inside).
  - **The debug variant**: `gcr.io/distroless/java25-debian13:debug-nonroot` adds busybox; build a throwaway local
    image with `--build-arg RUNTIME_IMAGE=...:debug-nonroot` (never pushed, never in the chart).
- Scripts that ran `kubectl exec <service> -- curl` must use `port-forward` instead.

## Consequences
- `images` is green again on the service jobs once merged (gate unchanged, nothing accepted).
- Debian's security fixes reach us through the weekly digest bump instead of an in-build update; a finding in the
  base between two bumps is fixed by running `scripts/bump-pins.sh --apply` early.
- One more upstream (Google distroless, Debian, Temurin builds) instead of Red Hat UBI.
- The chart can move to the image's uid (65532) or keep 185; both start (WP114 handover).
