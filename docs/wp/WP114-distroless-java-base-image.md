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
