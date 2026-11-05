# WP30 — Infra hygiene: e2e readiness, Tiltfile chart sync, image and dependency pins

Model: Sonnet. Depends on: WP17, WP18. Skills: verification-before-completion, podman-dev-env, owasp-security
(supply chain). Worktree: `~/code/hoops-wt/wp30-infra-hygiene`, branch `wp30-infra-hygiene`.

Four small items from FOLLOW-UPS "Infra, CI, e2e". No application code.

## Scope
1. **`e2e/bin/services-up.sh`** treats any HTTP answer from `/q/health/ready` as ready and its comment says
   game/athlete have no health extension; all three services have `quarkus-smallrye-health` since WP17. Wait for
   HTTP 200 and `"status":"UP"` in the body; fix the comment. Keep the 180 s budget and the log hint.
2. **Tiltfile**: call `scripts/sync-chart-files.sh` before `k8s_yaml(helm(...))` so the chart's copies of the realm
   and init SQL are current (the chart tests already check drift). Verify with `tilt alpha tiltfile-result` or a dry
   parse if Tilt is installed; otherwise bash-level review and say so.
3. **`deploy/containers/service.Containerfile`**: pin `ubi9/openjdk-21-runtime` by digest (trivy DS-0001); record
   the tag the digest corresponds to in a comment. The `images` workflow builds it; a local `podman build` of one
   service proves the pin resolves.
4. **Root `pom.xml` guava pin**: check whether the Quarkus BOM (3.40.1.1) already ships guava ≥ 33.7.2
   (`./mvnw dependency:tree -Dincludes=com.google.guava:guava` in one service); if so remove the pin, if not leave it
   and note the BOM version.

## Acceptance
- [ ] `shellcheck e2e/bin/services-up.sh` clean; the script still starts the three services on the compose stack
      (`docs/runbooks/e2e.md`) if the stack is free (`podman ps` shows no `hoops` containers); otherwise a
      bash `-n` check plus a note
- [ ] `just helm-test` (or the chart test command in the justfile) green
- [ ] `podman build` of one service image succeeds with the pinned digest
- [ ] `./mvnw -B -ntp -q validate` green after the pom change; if the pin was removed, `./mvnw -B -ntp -T 1C verify`
      green (fresh)
- [ ] Handover appended

## Working rules (all WPs of this wave)
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Other agents work in parallel in sibling worktrees and share the Podman machine; only one compose stack can run on
  this machine.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected,
  do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md (WP26 owns them); notes go in this file's Handover.
- Finish per the `work-package` skill: verification with evidence, `## Handover` appended.
- Final report to the orchestrator, at most 300 words: built, verified (commands and results), left out and why.

## Handover
- Built: (1) `e2e/bin/services-up.sh` waits for HTTP 200 + `"status":"UP"`, comment fixed, shellcheck clean (loop var `_`, SC1091 disabled for optional sourced files); runbook sentence updated. (2) Tiltfile runs `scripts/sync-chart-files.sh` before `helm(...)`. (3) `service.Containerfile` `RUNTIME_IMAGE` pinned to `ubi9/openjdk-21-runtime:1.24@sha256:cfa544ef...b9335` (multi-arch index of tag 1.24, resolved 2026-11-05; comment says bump tag and digest together). (4) Guava pin in root `pom.xml` kept: without it Quarkus BOM 3.40.1.1 still resolves guava 33.6.0-jre (checked in core, game and athlete); the pin gives 33.7.2-jre.
- Verified: `shellcheck e2e/bin/services-up.sh` clean; services-up.sh against the compose stack printed core/game/athlete ready and each `/q/health/ready` returned UP, then services-down and `just down`; `tilt alpha tiltfile-result` parsed (Error null, with a temporary .env, removed); `deploy/helm/tests/run.sh` ALL CHART TESTS PASSED (there is no `just helm-test` recipe); `podman build` of game-service (APP_SOURCE=host) with the pinned digest succeeded; `./mvnw -B -ntp -q validate` green. Pom unchanged, so the full `verify` was not required.
- Decisions/ADRs: none.
- Open points: the digest is not auto-bumped (no Renovate/Dependabot for Containerfile ARGs); the guava pin can go once the Quarkus BOM ships >= 33.7.2.
