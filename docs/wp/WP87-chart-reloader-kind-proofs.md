# WP87 — Chart: Reloader on Secret rotation, remaining kind proofs, rate-limit load guard, Testcontainers flake

Model: Opus. Wave 1 (2026-11-06, fifth round): runs alongside WP72 (web), WP78 (athlete), WP81 (core), WP83
(workflows; it wants kind for a ZAP full scan at its end: tell the orchestrator when you are done with kind). You own
`deploy/helm/**`, `deploy/kind/*`, `Tiltfile`, `.trivyignore.yaml`, `docs/runbooks/{kind,rotate-secrets,events,
deploy-related}.md`, `docs/adr/0012-*.md` (amendment), and for the flake only
`libs/common-quarkus/src/test/java/com/hoopsacademy/common/testing/**`, `.testcontainers.properties` / test
`application.properties` of the three services (Testcontainers settings only). Depends on: WP65 (ESO), WP66/WP71
(broker Secrets, bootstrap Job), WP63 (`ratelimit-check.sh`), WP46. Skills: podman-dev-env, owasp-security,
systematic-debugging, verification-before-completion. Worktree: `~/code/hoops-wt/wp87-chart-reloader`, branch
`wp87-chart-reloader`.

Decision 63 of 2026-11-06: Stakater Reloader (pinned) restarts the pods that read a rotated Secret; the kind proofs
not yet run are run; `ratelimit-check.sh` warns on high load; the Testcontainers flake is fixed or contained.

## Scope
1. **Reloader**: install pinned (OCI chart by version + digest, or manifests) from `up.sh` like ESO; annotate the
   Deployments/StatefulSets that read Secrets (`reloader.stakater.com/auto` or explicit lists) in the chart behind
   `reloader.enabled` (on in kind values); chart tests: annotations present on every workload that mounts/env-reads a
   Secret (derive the list from the render, red first), none when disabled; kubeconform; snapshots. kind proof:
   rotate `GAME_APP_PASSWORD` through ESO and a `hoops-redpanda-game-service` password: the pods restart without a
   manual rollout; `smoke.sh` green after. `rotate-secrets.md` updated (drop the manual restart notes), ADR-0012
   amendment. Chart 0.7.0 → 0.8.0.
2. **Remaining kind proofs** (WP71/WP65 open points): a deploy with `events.enabled=false` (+ the services healthy,
   no broker warnings), the game replica flip (`--set game.rosterSource=replica`), `tilt ci` on the current chart,
   `up.sh --eso` with the events, `up.sh --eso --deploy`; record each in `kind.md` "Verification status".
3. **Load guard**: `ratelimit-check.sh` (and `smoke.sh`) print the Podman VM load average and warn/skip the timing
   checks above a threshold (document the number; runbook symptom D).
4. **Testcontainers flake**: `AthleteDatabaseRoleTest` / `ReplicaAuthzRulesTest` "localhost:2375 failed to respond"
   on a Quarkus restart under load. Systematic debugging first (docker-java connection pool/keep-alive against the
   Podman socket? `TESTCONTAINERS_HOST_OVERRIDE`? the resource restarting the container?): fix or contain (retry on
   the resource start with backoff), proven by running the athlete module 3× while two other builds run.
5. **Docs**: runbooks as above; `.trivyignore.yaml` if Reloader adds a policy hit (with justification + expiry).

## Acceptance
- [ ] `deploy/helm/tests/run.sh` ALL CHART TESTS PASSED with the new assertions (red first); `shellcheck -S warning`,
      `actionlint` (if touched), `trivy fs` misconfig clean
- [ ] kind: rotation proof (both secrets) with pod restarts observed; the five remaining proofs recorded; cluster
      deleted at the end
- [ ] Flake: root cause or containment described with evidence; athlete module 3/3 green under load
- [ ] Handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the lines
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01Fuaj1aLz4Zxsb2XaUQBcMq`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Keep the Mac awake for long runs: `caffeinate -dims -t 14400 &`,
  kill it before reporting.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
