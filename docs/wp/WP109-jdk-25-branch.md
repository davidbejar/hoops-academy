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
- [ ] Findings of scope 1 recorded with their sources
- [ ] `./mvnw -B -ntp -T 1C clean verify -Dquarkus.http.test-port=0` green on JDK 25 (fresh; totals), or the
      blocker named with evidence
- [ ] One service image built on the 25 images and healthy; the digest pin explained
- [ ] No quality gate lowered, no exclusion added without a justification
- [ ] **The handover is your last commit and touches only this file**, so the orchestrator can bring it to `main`
      without the rest of the branch
- [ ] Handover: what changed, what the owner should look at before merging, the conflicts to expect when the
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
