# WP109 — JDK 25 on the branch `jdk-25` (draft pull request, not merged)

Model: Opus · effort high. Wave 2 (2026-11-14, seventh round): starts after wave 1 is merged, so the branch is cut
from a `main` that has WP104–WP107; runs alongside WP108 (web only). On your branch you may change whatever the
upgrade needs; nothing of it reaches `main` this round. Depends on: decision 81, ADR-0003 (Quarkus 3.x on Java 21),
ADR-0045 (SAST gates), `docs/quality/mutation.md`, the backlog entry "Upgrade to JDK 25" in
`docs/wp/FOLLOW-UPS.md` (the places that pin 21). Skills: systematic-debugging, owasp-security,
verification-before-completion. Worktree: `~/code/hoops-wt/jdk-25`, branch `jdk-25`.

Decision 81 of 2026-11-14 (owner): the upgrade to JDK 25 is done this round **on a dedicated branch**, pushed as a
**draft pull request** so CI proves it, and **not merged** into `main` until the owner says so. The orchestrator
pushes the branch and opens the pull request; you do neither.

## Scope
1. **Find out first, from current documentation and release notes, not from memory**: whether the Quarkus platform
   in the root `pom.xml` supports Java 25; which versions of the bytecode-reading tools do (JaCoCo, PIT and its
   JUnit 5 plugin, SpotBugs and find-sec-bugs, ArchUnit, the compiler and surefire plugins, CodeQL's Java
   extractor); which runtime and build images exist for 25 (the runtime is pinned by digest today). Write the
   findings in the handover before changing anything.
2. **The pins**: `maven.compiler.release`; `scripts/env.sh` (it accepts only a JDK whose major version is exactly 21)
   and `scripts/bootstrap.sh`; `actions/setup-java` in `ci.yml`, `e2e.yml`, `mutation.yml`, `codeql.yml`;
   `deploy/containers/service.Containerfile` (build image, runtime image by tag and digest, multi-arch index);
   `start.sh`; the wording in `CLAUDE.md`, `README.md`, `docs/architecture.md`, `docs/PLAN.md`; a dated amendment
   to ADR-0003. Tool versions only as far as 25 needs them.
3. **No gate is weakened to get green**: coverage thresholds, SpotBugs, ArchUnit, the RLS suites and the mutation
   baselines stay. If a tool cannot run on 25 yet, stop there, record it and say what is blocked and until when;
   a branch that is honestly red with the reason is a valid result.
4. **Proof**: the full verify on JDK 25; one service image built with Podman and started (health UP); `just mutation`
   for one module at its baseline; `actionlint` on the workflows. The local JDK 25 is installed with Homebrew.

## Acceptance
- [x] Findings of scope 1 recorded with their sources
- [x] `./mvnw -B -ntp -T 1C clean verify -Dquarkus.http.test-port=0` green on JDK 25 (fresh; totals), or the
      blocker named with evidence
- [x] One service image built on the 25 images and healthy; the digest pin explained
- [x] No quality gate lowered, no exclusion added without a justification
- [x] **The handover is your last commit and touches only this file**, so the orchestrator can bring it to `main`
      without the rest of the branch
- [x] Handover: what changed, what the owner should look at before merging, the conflicts to expect when the
      branch is rebased later (`ci.yml` gained a job in WP104)

## Working rules
- Work only in your worktree on the branch `jdk-25`; do not touch `main`, do not push, do not open the pull request.
- The project's `scripts/env.sh` selects JDK 21 until you change it on your branch: make sure the builds you report
  really ran on 25 (`java -version` in the handover).
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with a
  `Co-Authored-By:` line that names the model you are.
- Another agent runs web tests at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port
  clash, re-run that module alone with `-Dquarkus.http.test-port=0`.
- The owner may have the services running on 8081–8083: never stop them; use other ports for the image you start.
- Do not edit docs/HANDOVER.md or docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->

### Findings before any change (scope 1, looked up 2026-11-14)
| Piece | In use on `main` | Java 25 support | Source |
|---|---|---|---|
| Quarkus platform | 3.40.1.2 | Full Java 25 support since **3.31** (28 Jan 2026): "Java 25 runtime images and native image builds with Mandrel"; JVM mode supports JDK 17–25 | [Quarkus 3.31 released](https://quarkus.io/blog/quarkus-3-31-released/), [Mandrel 25 minimum](https://quarkus.io/blog/mandrel-25-minimum-version/) |
| maven-compiler-plugin | 3.16.0 | 3.14.1 fixed "Unsupported class file major version 69" (ASM 9.8); 3.15.0 runs CI on Java 25 and ships ASM 9.9.1 | [issue #961](https://github.com/apache/maven-compiler-plugin/issues/961), [releases](https://github.com/apache/maven-compiler-plugin/releases) |
| maven-surefire-plugin | 3.6.1 | No Java-25-specific note; it reads no bytecode (forks a JVM), so proven by running | [releases](https://github.com/apache/maven-surefire/releases) |
| JaCoCo | 0.8.16 | Official Java 25 since 0.8.14 (2025-10-11); 0.8.16 (2026-10-24) is official up to Java 27 | [change history](https://www.jacoco.org/jacoco/trunk/doc/changes.html) |
| PIT | 1.30.1 | ASM 9.8 (adds `V25`) since 1.19.6; 1.25.8 fixes the BigDecimal/BigInteger mutators "for java 25"; 1.30.1 bumps ASM to 9.11 | [PIT release notes](https://github.com/hcoles/pitest/blob/master/README.md), [ASM versions](https://asm.ow2.io/versions.html) |
| pitest-junit5-plugin | 1.2.3 | Reads no bytecode (drives the JUnit Platform launcher); proven by running | [releases](https://github.com/pitest/pitest-junit5-plugin/releases) |
| SpotBugs | 4.10.5 (2026-10-11) | No explicit "Java 25" changelog entry; 4.9.7 builds on JDK 25, 4.10.0 fixes an init failure "on Java 25". Its POM pulls ASM 9.11 (up to `V28`) and BCEL 6.13.0 (`Const.MAJOR_25`…`MAJOR_28` present, checked in the jar) | [CHANGELOG](https://github.com/spotbugs/spotbugs/blob/master/CHANGELOG.md), `spotbugs-4.10.5.pom` |
| find-sec-bugs | 1.14.0 | No JDK note after "Java 21 Support" (1.13.0); it is a SpotBugs detector plugin that reads classes through SpotBugs' BCEL/ASM above, so proven by running | [releases](https://github.com/find-sec-bugs/find-sec-bugs/releases) |
| ArchUnit | 1.5.1 | "Support Java 25 / class file major version 69" since 1.4.1 (2025-05-07); 1.5.0 up to Java 27. Note: JDK 25 javac adds a synthetic `Objects.requireNonNull` call in inner-class constructors | [releases](https://github.com/TNG/ArchUnit/releases) |
| CodeQL Java extractor | action v4.39.3 → bundle **2.27.4** (`src/defaults.json` at the pinned SHA) | Java 25 since CLI 2.23.1; current docs: builds on Java 7–26 analysed, preview/incubator features not | [CodeQL 2.23.1 changelog](https://github.blog/changelog/2025-09-26-codeql-2-23-1-adds-support-for-java-25-typescript-5-9-and-swift-6-1-3/), [supported languages](https://codeql.github.com/docs/codeql-overview/supported-languages-and-frameworks/) |
| Build image | `maven:3-eclipse-temurin-21` | `maven:3-eclipse-temurin-25` exists (index `sha256:a4734fd7…ca2a3` on 2026-11-14, Docker Hub registry API) | Docker Hub |
| Runtime image | `ubi9/openjdk-21-runtime:1.24@sha256:9a074c2f…` | `ubi9/openjdk-25-runtime` exists, tag `1.24` = `latest` = `1.24-3.1794341158`, multi-arch index `sha256:7f2eaba33484d04e5331135e8d3e621c5a4740b6b03bc99d25e4d4dc043f6b8c` (amd64, arm64, ppc64le, s390x; registry API, 2026-11-14) | [Red Hat catalog](https://catalog.redhat.com/software/containers/ubi9/openjdk-25-runtime/69204990c46419100ce30a5b) |
| actions/setup-java | v6.2.0, Temurin | Temurin 25 is a GA LTS release; proven by CI on the draft pull request | — |

Conclusion: no tool version bump is needed for 25; every tool in use is at or beyond its first Java 25 release.

### Built (branch `jdk-25`; nothing of it is on `main` except this handover)
- `42891d8a` test (red first): `scripts/tests/env-jdk.test.sh` (env.sh keeps a JAVA_HOME that is a 25, replaces a 21 or a
  26; stub JDKs, in `just test-hooks`) and `scripts/tests/test_jdk_pins.py` (the Containerfile's build and runtime
  images, `actions/setup-java` in ci/e2e/mutation/codeql and env.sh's `_JDK_MAJOR` all equal `maven.compiler.release`;
  every `bump_pins.PINS` pattern is still found in its files).
- `025b9f90` build: `maven.compiler.release` 25; `scripts/env.sh` picks exactly `_JDK_MAJOR=25` (Homebrew
  `openjdk@25`, then `java_home -v 25`); `bootstrap.sh` installs `openjdk@25`; `doctor.sh` checks "JDK 25"; `start.sh`
  wording; `java-version: '25'` in ci.yml (4), e2e.yml, mutation.yml, codeql.yml; Containerfile
  `MAVEN_IMAGE=maven:3-eclipse-temurin-25` and `RUNTIME_IMAGE=ubi9/openjdk-25-runtime:1.24@sha256:7f2eaba3…6b8c`;
  `bump_pins.py` follows `openjdk-25-runtime`. **No tool version, threshold, exclusion or baseline changed.**
- `0a6a7051` docs: CLAUDE.md, README.md, architecture.md, PLAN.md, conformance S-01, runbooks (kind, release),
  sast-dast.md (CodeQL container), ADR-0003 amendment + ADR index row.
- Digest pin: the runtime is pinned by the **multi-arch index** digest of tag `1.24` (= `latest` =
  `1.24-3.1794341158` on 2026-11-14; amd64, arm64, ppc64le, s390x), read from the registry API, so `bump-pins` keeps
  resolving it as before. The build image stays a floating tag as on `main`.

### Verified (all on JDK 25, 2026-11-14)
- `source scripts/env.sh && java -version` → `openjdk version "25.0.5.0.2" 2026-10-22` (Homebrew); Maven 3.10.0 reports
  "Java version: 25.0.5.0.2"; compiled classes are `major version: 69` (javap).
- `./mvnw -B -ntp -T 1C clean verify -Dquarkus.http.test-port=0` at `0a6a7051`: **BUILD SUCCESS**, 6:34 min; **3388
  tests, 0 failures, 0 errors, 26 skipped**; JaCoCo "All coverage checks have been met" ×4; SpotBugs + find-sec-bugs
  "BugInstance size is 0" ×4; ArchUnit suites (5 classes) and RLS/isolation/database-role suites (24 classes) green.
  (A first run before the docs commit: same totals.)
- `just mutation` (all four modules): common-quarkus 337/338 (99), core-service 925/926 (99), game-service 525/527 (99),
  athlete-service 690/690 (100) — mutant counts identical to `docs/quality/mutation.md`, every module at its baseline.
- `just test-hooks`: env-jdk 3/3, Python script tests 34 (1 skipped: the online pin check); `actionlint`: clean.
- Image: `podman build … --build-arg SERVICE=game-service` (2:20 min) on the 25 images; started on 127.0.0.1:18092
  against a throwaway Postgres 17 (project init scripts, generated passwords, own network; no Keycloak, no broker,
  consumer off): Flyway applied v1–v6, "started in 2.450s", `/q/health` **UP** (database UP; core "unreachable" is
  informational), `java -version` in the container 25.0.5 (Red Hat), uid 185. Containers, network, volume and the
  local image tag removed afterwards; the owner's stack was not touched.
- `trivy image --severity HIGH,CRITICAL --ignore-unfixed` (0.76.1) on the built image: **14 HIGH, 0 CRITICAL, all
  `krb5-libs` 1.21.1-10.el9_8.1** (Trivy names 1.21.1-10.el9_9.2 as fixed; `microdnf -y update` does not find it in the
  UBI repositories yet), 0 in the Java libraries. The bare 25 runtime base has 27 (expat 3, krb5-libs 14, libxml2 2,
  python3/-libs 4, util-linux libs 4): the same picture as the 21 image on `main`. No acceptance added; the `images`
  workflow's Trivy gate will fail on the branch exactly as it does on `main` until Red Hat ships krb5.

### Decisions/ADRs
- ADR-0003 amended (Java 25 LTS, decision 81). No other decision.

### Open points / for the owner before merging
- **Not run locally**: the e2e workflow, CodeQL (bundle 2.27.4 per the action's `defaults.json`, Java 25 since 2.23.1)
  and the `images` workflow: the draft pull request's CI is their proof.
- After the merge every machine and worktree needs `openjdk@25` (`scripts/bootstrap.sh`); env.sh then refuses a 21.
  Branches cut before the merge keep selecting 21 through their own env.sh.
- Tests print the JDK's "A Java agent has been loaded dynamically" warning (Mockito's byte-buddy); it appears on 21 too
  (JEP 451) and is only a warning on 25.
- `docs/HANDOVER.md` and `docs/wp/FOLLOW-UPS.md` were not edited (rule): the "Upgrade to JDK 25" backlog entry closes
  when the branch is merged.
- **Rebase conflicts to expect**: the weekly `bump-pins` PR rewrites the `openjdk-21-runtime` tag/digest line in
  `service.Containerfile` and its `Pin` in `bump_pins.py` (keep the 25 lines and re-resolve with
  `scripts/bump-pins.sh`); any change to the `actions/setup-java` steps in ci/e2e/mutation/codeql (SHA bumps sit next
  to `java-version`); the stack wording lines in CLAUDE.md, README.md, PLAN.md, architecture.md, conformance.md and the
  ADR index row. WP104's `tofu-check` job in ci.yml is already in the branch base (no conflict); `main` gained only
  WP108 (web) since the cut and `git merge-tree` with it is clean today.
