# WP114 — Images: Java services on a distroless Java 25 base

Model: Opus · effort medium. Wave 1 (2026-11-15, eighth round): runs alongside WP111 (pdf-service: chart, kind,
compose, CI), WP112, WP113 (poms) and WP115. You own `deploy/containers/service.Containerfile`,
`deploy/containers/service*.containerignore`, the pin scripts (`scripts/bump_pins.py`, `scripts/bump-pins.sh`, their
tests) and `docs/adr/0054-*.md`. Shared with WP111, change only the Java runtime image lines:
`.github/workflows/images.yml`, `scripts/build-images.sh`. You do not touch the chart or kind (WP111 has them this
wave): if the chart needs a change for the new image, write it in your handover. Depends on: ADR-0045, the `images`
runs listed in `docs/HANDOVER.md`. Skills: owasp-security, podman-dev-env, systematic-debugging,
verification-before-completion. Worktree: `~/code/hoops-wt/wp114-distroless`, branch `wp114-distroless`.

Decision 87 of 2026-11-15 (owner): the `images` gate is red on 14 HIGH `krb5-libs` findings of
`ubi9/openjdk` runtime; do not wait, do not accept them: move core, game and athlete to a distroless Java 25 base,
pinned by digest. ADR-0054 is reserved.

## Scope
1. **Choose the image**: a Debian-based distroless Java 25 runtime (check that the tag exists and which JDK build it
   carries; if no Java 25 distroless image is published, stop and report the alternatives with their Trivy counts
   instead of picking one yourself). Pin by digest; the weekly bump-pins run must follow it (script test first).
2. **Containerfile**: runtime stage on the new base, non-root user, no shell assumed (no `RUN` in the runtime stage,
   exec-form entrypoint, health checks that need no shell), the Quarkus fast-jar layout kept, the SBOM stage working.
3. **Proof without kind**: build the three images; Trivy with the workflow's settings: 0 HIGH / CRITICAL; each image
   started with `podman run --read-only` and the chart's security context flags against the compose database and
   Keycloak, health endpoints up, one authenticated request per service; time zone and locale data present (the
   services format dates in academy time zones); container start time and image size before and after.
4. **Docs**: ADR-0054 (why distroless, what is lost: no shell for debugging, how to debug instead), the image lines
   of the runbooks you find by grep.

## Acceptance
- [ ] Trivy 0 HIGH / CRITICAL on the three images locally with the workflow's flags (output in the handover)
- [ ] `just test-hooks` green (pin script tests); `actionlint` clean
- [ ] The three services answer health and one authenticated call from the new image, read-only root FS
- [ ] Handover appended: the image and digest, what the chart or kind needs (if anything), debugging without a shell

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first (JDK 25). Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then a plain `git commit` with explicit paths (never `git add -A`, never
  `--no-verify`: the session refuses it). The pre-commit hooks run and may trim whitespace in generated files: re-add
  and commit again. Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit
  (it resyncs the Podman VM clock itself); under load it can time out: retry when a build has finished, never bypass
  it. End every commit message with a `Co-Authored-By:` line that names the model you are.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Gate rules: constant SQL with bound parameters (CodeQL), no nil-tenant bind without a dated acceptance (Semgrep), no
  environment-derived program names in scripts and tests (Semgrep taint). Since WP113 the PMD / CPD gate runs in
  `verify`: stay inside its thresholds, add no exclusion without a reason.
- An OpenAPI generator run can leave whitespace-only diffs in the Dart packages: discard them. Regenerate only your
  package (`scripts/gen-api.sh <svc>`). `apps/web/pubspec.lock`: commit it only with a generated package's version
  bump; revert other drift. `apps/web/lib/l10n/*.arb`: keys next to the feature's existing keys, never at the end.
- Shared index files (`docs/adr/README.md`, `docs/domain/authz-matrix.md`): append at the end, one entry per line.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
- Built:
  - Runtime base `gcr.io/distroless/java25-debian13:nonroot@sha256:1c4ced761d17961c900cba60c33c8c3c46edbdadaa9d5ef9806eb5a6824fd406`
    (multi-arch index: amd64, arm64, s390x, ppc64le, riscv64; Debian 13.7, Temurin 25.0.5+8; resolved 2026-11-15).
  - `service.Containerfile` runtime stage: no `RUN`, exec-form `/usr/bin/java` entrypoint with the old
    `JAVA_OPTS_APPEND` flags, fast-jar in `/deployments` owned by root (readable by any uid), `USER 65532:65532`;
    `microdnf update` gone. Maven, host and SBOM stages unchanged.
  - `scripts/bump_pins.py`: the UBI tag+digest pin replaced by a floating-tag digest pin on `nonroot`;
    `test_jdk_pins.py`: the runtime image must be distroless `java<release>` and the bump pin must name exactly the
    Containerfile's image (test committed red first, ce62e615).
  - `images.yml` service job: the non-root step reads `Config.User` and runs the image's `java -version` read-only
    (`id` is not in the image). Nothing else in the workflow touched.
  - ADR-0054 (+ README row); runbooks: `kind.md` image line, `release.md` pin lines, `events.md` metrics recipe
    (port-forward instead of `exec curl`).
- Verified (2026-11-15, VM load 4-14 from other agents):
  - Trivy 0.76.1 with the workflow flags (`--severity HIGH,CRITICAL --ignore-unfixed --exit-code 1`, plus a local DB
    cache and `--timeout 30m` because the first Java DB download timed out): core, game, athlete exit 0, 0 findings in the
    debian 13.7 layer and in all 288 jars of each image. Same jars on the old UBI base: exit 1, `Total: 14 (HIGH: 14)`, all
    `krb5-libs`.
  - Each image run with `--read-only --tmpfs /tmp --cap-drop=ALL --security-opt=no-new-privileges --memory=768m`
    against the compose Postgres and Keycloak (VM host network, `.env`): core and athlete as 65532, game as the chart's
    `185:0`. All `/q/health/ready` and `/live` 200; no ERROR log line, no read-only FS error. Authenticated: core
    `/api/core/me` as superadmin (PKCE) 200 `superAdmin:true`, `/platform/tenants` 200; game and athlete
    `/internal/usage/<nil>` with core-service's client token 200; anonymous 401 on all three.
  - Time zones and locales: a class run by the image's java prints tzdb 2026e (604 zones) and full es / en / id
    date-times for Europe/Madrid, Asia/Jakarta, America/Mexico_City; `jdk.localedata` present.
  - Size: core 650 MB (UBI, same jars) -> 328 MB; game 325 MB, athlete 326 MB. Start (core, "started in", two rounds
    each, same flags): UBI 3.9 s / 7.8 s, distroless 5.5 s / 3.9 s: the same within the VM's noise.
  - `just test-hooks` exit 0 (35 tests, 1 skipped); `BUMP_PINS_ONLINE=1` multi-arch test OK; the new pin resolves to
    the pinned digest; `actionlint` clean.
  - CI path for core: Maven-stage build (`APP_SOURCE=maven`, 6 min 39 s under load), then `scripts/sbom.sh maven`
    and `generate`: both SBOMs valid (Maven CycloneDX 1.6, 287 components; image CycloneDX 1.7, 319 components).
- Decisions/ADRs: ADR-0054.
- What the chart / kind needs (WP111 owns them; not changed here):
  - `deploy/kind/smoke.sh` line 168 `metrics()` runs `kubectl exec ... -- curl`: fails on distroless (no curl). Use
    `kubectl port-forward` (as the `events.md` recipe now does) or read the metrics through a debug container.
  - Chart `hoops-service` securityContext `runAsUser: 185`, `runAsGroup: 0`, `fsGroup: 0` works unchanged (proven
    with game as 185:0); recommended to switch to 65532/65532 to match the image (snapshots change). `/tmp` emptyDir,
    read-only root and the httpGet probes are already what the image needs. Nothing sets `JAVA_OPTS_APPEND` for the
    services; any future JVM flag goes in `JDK_JAVA_OPTIONS`.
- Open points / not verified:
  - Not run on kind (WP111 holds it) nor on amd64 (CI will be the first amd64 run).
  - `just test` not run: no Java, pom or test-suite change in this WP.
  - Debugging without a shell: ADR-0054 "What is lost" (ephemeral `kubectl debug`, port-forward, `debug-nonroot`).
