# WP63 — kind: proofs not re-run on chart 0.4.0

Model: Sonnet. Wave 1 (2026-11-06, fourth round): runs alongside WP52, WP56, WP58, WP60, WP64; you are the only
agent using kind. You own `deploy/kind/*`, `Tiltfile`, `docs/runbooks/{kind,troubleshooting}.md`; the chart
templates only if a proof fails because of them (say so). Depends on: WP40, WP42, WP46 handovers. Skills:
podman-dev-env, systematic-debugging, verification-before-completion. Worktree:
`~/code/hoops-wt/wp63-kind-proofs`, branch `wp63-kind-proofs`.

Decision 45 of 2026-11-06: every kind proof is green on the current chart.

## Scope
1. `just kind-up --deploy --from-host` on chart 0.4.0 (Redis ACL, per-second rules): Gateway Programmed, policies
   Accepted, `smoke.sh core game athlete`, `ratelimit-check.sh` (per-minute, burst, `redis-down`).
2. **Two Envoy replicas**: scale the proxy to 2 and re-run `ratelimit-check.sh`; the first 429 lands at the same
   request number (shared counter) and both replicas serve traffic (evidence: pod logs or metrics).
3. **`tilt ci`** on the fresh cluster (`just tilt ci -- --from-host`); fix Tiltfile/values-kind drift; runtime.
4. **Controller-restart branch of `up.sh`**: exercise the path that restarts the Envoy Gateway controller after a
   config change (change a rate-limit value, re-run `up.sh`, prove the new config is live); fix it if it is broken.
5. e2e journey on kind once (21/21 with mail checks); delete the cluster at the end.
6. Runbooks: anything learned; the 18080 port-forward note stays.

## Acceptance
- [ ] Every proof above green with numbers in the handover; cluster deleted
- [ ] `shellcheck -S warning` clean on touched scripts; `deploy/helm/tests/run.sh` green if a template changed
- [ ] Handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents run Testcontainers builds and the compose stack (WP56 owns ports 8080/5432) on the same machine;
  keep the cluster to the kind values and delete it when done.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
