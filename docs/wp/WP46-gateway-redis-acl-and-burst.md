# WP46 — Gateway: Redis ACL for the rate-limit service, burst cap per second

Model: Opus. Wave 1 (2026-11-06, third round): runs alongside WP43 (Java), WP48 (web) and WP50 (workflows); you own
`deploy/`, `Tiltfile` and the kind/deploy runbooks, and you are the only agent using kind. Depends on: WP40
(ADR-0033). Skills: podman-dev-env, owasp-security, verification-before-completion. Worktree:
`~/code/hoops-wt/wp46-gateway-hardening`, branch `wp46-gateway-hardening`.

Decision 27 of 2026-11-06: (a) the rate-limit service's Redis access is restricted by a Redis ACL, not only by the
NetworkPolicy; (b) the fixed one-minute windows get a second, per-second rule so a minute-boundary burst cannot pass
twice the limit.

## Scope
1. Read ADR-0033, the WP40 handover, `deploy/helm/hoops/templates/*redis*`, `deploy/kind/up.sh` (Envoy Gateway
   values: rate-limit backend) and `deploy/kind/ratelimit-check.sh`.
2. **ACL**: a Redis user for the rate-limit service with only the commands `envoyproxy/ratelimit` issues (check its
   source for the Redis commands it uses: INCRBY/EXPIRE/pipelines, PING, no scripting, no admin) on the key pattern it
   uses; `default` user disabled or reduced to nothing. Credentials: a Kubernetes Secret created by `deploy/kind/
   secrets.sh` on kind and documented for other clusters (ADR-0012 pattern: Secrets first), referenced by the Redis
   ConfigMap/args (ACL file or `--requirepass` + `ACL SETUSER` at start) and by the Envoy Gateway rate-limit backend
   configuration (Envoy Gateway v1.9 reads the Redis URL / auth from its config; find the supported way — URL with
   credentials or a Secret reference — and if the controller cannot take credentials at all, document that and fall
   back to a password-less user limited to the needed commands + the NetworkPolicy). Nothing secret in git
   (`gitleaks` on rendered output is already in the chart tests).
3. **Burst cap**: per limited route a second global rule with `unit: Second` (defaults: token and login form 10/s,
   `events:batch` 20/s; values-configurable next to the per-minute numbers). Both rules per client IP.
4. **Prove on kind**: `up.sh --deploy`; Gateway Programmed, policies Accepted; `ratelimit-check.sh` extended: the
   per-minute numbers as before, plus a tight burst (e.g. 40 requests in one second) that gets 429 from the per-second
   rule; a `redis-cli` from a pod with the limited user proving a disallowed command (e.g. `CONFIG GET`, `EVAL`) is
   refused and the default user cannot authenticate; the `redis-down` mode still fails open. Smoke green. Delete the
   cluster at the end.
5. **Docs**: ADR-0033 "Amendment 2026-11-06" (no new number), runbooks (kind, release §4, troubleshooting), threat
   model row for the rate-limit store, `docs/security/asvs-checklist.md` if it has a row for it. Chart version bump
   (0.3.0 → 0.3.1 or 0.4.0 if values changed shape), snapshots updated after review.

## Acceptance
- [ ] `deploy/helm/tests/run.sh` ALL CHART TESTS PASSED; `helm template` of kind values renders no credential
- [ ] kind: ratelimit-check PASSED incl. the per-second burst case; ACL proof recorded; redis-down still fails open;
      smoke green
- [ ] `shellcheck -S warning` clean on touched scripts; docs updated; handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents run Testcontainers builds on the same Podman machine; keep the cluster to the kind values and delete it
  when done.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.
