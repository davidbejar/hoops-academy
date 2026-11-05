# WP36 — Gateway API (Envoy Gateway) replaces ingress-nginx

Model: Opus. Wave 4 (last): starts after every other WP is merged. Depends on: WP16, WP17, WP18. Skills:
podman-dev-env, owasp-security, verification-before-completion. Worktree: `~/code/hoops-wt/wp36-gateway-api`,
branch `wp36-gateway-api`.

Decision 10 of 2026-11-05: ingress-nginx is retiring upstream; the Helm chart, its rate limiting
(`limit-rpm` annotations), the kind setup, Tilt, the e2e port-forward scripts and the runbooks target it. Move to
the Gateway API with Envoy Gateway as the implementation.

## Scope
- Read the chart (`deploy/`), `scripts/sync-chart-files.sh`, the chart tests, `Tiltfile`, `e2e/bin/*`, the kind
  scripts and `docs/runbooks/{deploy,e2e,release}.md` first; list every ingress-nginx dependency in your notes.
- Chart: `GatewayClass` (documented as provided by the cluster, with a values switch to create it), `Gateway`,
  one `HTTPRoute` per service prefix (`/api/core`, `/api/game`, `/api/athlete`, `/platform`, `/auth` → Keycloak,
  `/` → web) replacing the Ingress templates; the `events:batch` and `%3A` path cases keep working (there is a chart
  test and an e2e step); TLS as before.
- Rate limiting: Envoy Gateway `BackendTrafficPolicy` local rate limit replacing `limit-rpm`, same numbers as
  ingress-nginx and nginx compose (`infra/nginx`), per client IP.
- Security headers / body size: whatever the Ingress annotations set (search the templates), reproduced with Gateway
  API or Envoy policies; note anything that has no equivalent.
- kind: install Envoy Gateway in the kind bootstrap script (pinned version); Tilt and `up.sh --deploy` follow.
- e2e: port-forward the Gateway's Envoy service instead of the ingress controller; the journey runs on kind
  (`docs/runbooks/e2e.md`), which has never been green on kind: make it green or document exactly where it stops.
- Chart tests updated (helm unittest or the existing mechanism), `actionlint` on the workflows, runbooks and
  `docs/adr/00NN-gateway-api.md` (why Envoy Gateway, what the compose nginx still does, upgrade path).
- Keep the compose stack (`infra/nginx`) unchanged: local development does not use the chart.

## Acceptance
- [ ] Chart tests green; `helm template` renders no `Ingress` objects; `kubectl apply --dry-run=server` on kind clean
- [ ] Smoke (`smoke.sh core game athlete`) through the Gateway on kind green; e2e journey on kind green or the
      blocking step documented with evidence
- [ ] Rate limit proven on kind (burst of requests → 429) and documented
- [ ] `actionlint .github/workflows/*.yml` clean; runbooks updated; ADR written; handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected,
  do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.
