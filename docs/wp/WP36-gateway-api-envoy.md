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
- [x] Chart tests green; `helm template` renders no `Ingress` objects; `kubectl apply --dry-run=server` on kind clean
- [x] Smoke (`smoke.sh core game athlete`) through the Gateway on kind green; e2e journey on kind green or the
      blocking step documented with evidence
- [x] Rate limit proven on kind (burst of requests → 429) and documented
- [x] `actionlint .github/workflows/*.yml` clean; runbooks updated; ADR written; handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected,
  do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- **ingress-nginx dependencies found and replaced:** 3 Ingress templates (hoops-service: prefix, health regex+rewrite,
  `limit-rpm`; keycloak: `/auth` with `proxy-buffer-size`, rate-limited, admin deny; web: `/` + `/internal`), the
  `ingressControllerNamespace` of 3 NetworkPolicies, kind (`up.sh` install + 429 configmap patch, `kind-config.yaml`
  ports 80/443 + `ingress-ready` label), Tiltfile/justfile/smoke.sh/runbook wording, chart tests. `e2e/bin` had none
  (the e2e journey reaches the gateway at `localhost:8090`, now a kind port mapping to the Envoy NodePort).
- **Built:** chart 0.2.0 with Gateway `hoops`, GatewayClass switch (`gateway.gatewayClass.create`, on for kind),
  EnvoyProxy (kind: NodePort 30080/30443, Service `envoy-gateway-system/hoops-gateway`), one HTTPRoute per prefix, exact
  health rewrites, deny routes to the web 403 location, BackendTrafficPolicy local limits per client IP (60/min token +
  login form, 120/min `events:batch`, regex also covers `%3A`), ClientTrafficPolicy per listener (drop client
  `X-Forwarded-Host/Port`, HSTS on HTTPS only, optional trusted XFF hops), 60 s route timeouts, Keycloak routes set
  `X-Forwarded-Host` to the public host. Values renamed `ingress.*` -> `route.*`. kind: Envoy Gateway v1.9.3 (Gateway API
  v1.6.1 CRD version asserted by `up.sh`), `kindest/node:v1.36.4` pinned, self-signed TLS Secret. New
  `deploy/kind/ratelimit-check.sh`; smoke.sh checks the gateway. ADR-0031; runbooks kind, e2e, release, troubleshooting;
  architecture.md.
- **Verified:** `deploy/helm/tests/run.sh` ALL CHART TESTS PASSED (74 checks, kubeconform 144/144, 5 snapshots incl. new
  `umbrella-tls`); 0 `Ingress` in the default, kind and TLS renders; `helm package` OK; `kubectl apply --dry-run=server` of
  the kind render clean; Gateway Programmed, 12 HTTPRoutes and 4 policies Accepted; `smoke.sh core game athlete` SMOKE
  PASSED; e2e journey on kind 21 tests, 0 failures, 0 skipped, 159 s (first green run on kind); `ratelimit-check.sh`
  PASSED (events: first 429 at #124 of 250; token: #62 of 130; `%3A` shares the bucket; the web pod's IP has its own
  bucket); actionlint and `shellcheck -S warning` clean; `./mvnw validate` OK. `just test` not run: no Java, pom,
  contract, web or compose file changed. Cluster deleted with `deploy/kind/down.sh`.
- **Found on kind and fixed:** behind Envoy, Keycloak's discovery advertised `http://localhost/...` without `:8090`
  (Envoy sends no `X-Forwarded-Host`); chart test + smoke check added.
- **Decisions/ADRs:** ADR-0031. The kind exposure uses a NodePort mapping instead of a port-forward; the port-forward of
  `svc/hoops-gateway` is documented for other clusters.
- **Environment (not code):** the Podman VM clock runs slow or stalls (59 min, then 15 min behind), so Testcontainers
  tokens look expired and the commit hook fails with 401; re-synced with
  `podman machine ssh "sudo date -u -s @$(date +%s)"` before each commit. Flutter `font-subset` hung (built with
  `--no-tree-shake-icons`); a CNPG image pull stalled. All three are in kind.md troubleshooting.
- **Open points:** local limits are per Envoy replica and burst = rpm (no multiplier); no gateway body-size limit
  (services enforce 2M); `tilt ci` not re-run; e2e MailHog checks skipped on kind (Mailpit API is `/api/v1`);
  docs/security (threat model, ASVS, review) still name ingress-nginx; the Podman VM clock drift needs a host-level fix.
