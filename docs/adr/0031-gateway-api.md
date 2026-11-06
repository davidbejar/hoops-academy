# ADR-0031: Gateway API with Envoy Gateway replaces ingress-nginx

- Status: Accepted; decision 4 (local rate limits) replaced by ADR-0033 (global rate limits, WP40)
- Date: 2026-11-06
- Related: decision 10 of 2026-11-05, WP36, ADR-0012 (Secrets), ADR-0017 (HTTP hardening), WP16/WP17 (chart, kind)

## Context
The Helm chart exposed the platform through ingress-nginx `Ingress` objects: one per service prefix, a regex + rewrite
Ingress for the health endpoints, dedicated Ingresses with `limit-rpm` / `limit-burst-multiplier` annotations for the
token endpoint, the login form and `events:batch`, and deny Ingresses that send `/internal`, `/auth/admin` and
`/auth/realms/master` to the web nginx's 403 location. kind installed ingress-nginx `controller-v1.15.1` and patched it
to answer 429. ingress-nginx is retiring upstream (best-effort maintenance only), so the production edge needed a
successor. Decision 10 of 2026-11-05: Gateway API, implemented by Envoy Gateway.

## Decision
1. **Standard Gateway API objects carry the routing**; implementation-specific objects carry only what the standard
   has no field for. The umbrella chart renders one `Gateway` (`hoops`, listener `http` :80, optional `https` :443 with
   `tls.mode: Terminate` and certificate Secrets created outside the chart) and the subcharts attach `HTTPRoute`s to it
   by name (`global.gateway.name`): one per prefix (`/api/core`, `/platform`, `/api/game`, `/api/athlete`, `/auth`,
   `/`), `/internal` and the Keycloak admin prefixes as longer prefixes to the web 403 location (a longer prefix wins in
   Gateway API precedence), health as **exact** matches with a `ReplaceFullPath` rewrite (only
   `/api/<svc>/q/health[/live|ready|started]`), and every rule with `timeouts.request: 60s` (Envoy's default is 15 s,
   ingress-nginx's proxy timeouts were 60 s).
2. **The `GatewayClass` belongs to the cluster.** The chart references `envoy-gateway` and renders it only with
   `gateway.gatewayClass.create: true` (kind). A platform team that runs Envoy Gateway for several applications keeps
   control of the class and its parameters.
3. **Envoy Gateway v1.9.3**, which bundles and requires Gateway API **v1.6.1** (compatibility matrix:
   https://gateway.envoyproxy.io/news/releases/matrix/; Kubernetes 1.33 to 1.36, so kind pins `kindest/node:v1.36.4`).
   kind installs it with its Helm chart (`oci://docker.io/envoyproxy/gateway-helm`); `deploy/kind/up.sh` pins both
   versions and fails when the installed CRDs' `gateway.networking.k8s.io/bundle-version` differs. The chart installs the
   CRDs of the Gateway API **experimental** channel (needed by Envoy Gateway's extended features); the Hoops chart uses
   only standard-channel fields of `GatewayClass`, `Gateway` and `HTTPRoute`.
4. **Rate limits are Envoy Gateway local rate limits** (`BackendTrafficPolicy.rateLimit.local`), one policy per
   rate-limited route, with `sourceCIDR: {type: Distinct}` rules for `0.0.0.0/0` and `::/0`, so every client IP has its
   own bucket: 60 requests/minute on the token endpoint and the login form, 120/minute on `events:batch`, the same
   sustained rates as compose nginx (`limit_req` 60r/m and 120r/m) and the former `limit-rpm` values. Over the limit:
   429. Local means per Envoy replica and no Redis; global rate limiting (Envoy's ratelimit service + Redis) is the
   upgrade when the proxy runs more than one replica and the limit must hold across them.
5. **`events:batch` keeps its byte-exact path.** The rate-limited route matches the RE2 regex
   `/api/game/matches/[^/]+/events(:|%3[Aa])batch` on the path as sent, without a rewrite. Envoy normalises paths
   (RFC 3986, adjacent slashes merged) but does not decode the reserved `%3A`, so the percent-encoded form also reaches
   the service unchanged, and the regex includes it so it cannot dodge the limit.
6. **Client-side policy per listener** (`ClientTrafficPolicy` `hoops-http` / `hoops-https`): client-supplied
   `X-Forwarded-Host` / `X-Forwarded-Port` are removed before routing (ingress-nginx overwrote them; Keycloak runs with
   `KC_PROXY_HEADERS=xforwarded`); HSTS (`max-age=31536000; includeSubDomains`, ingress-nginx's default on TLS hosts) is
   set on the HTTPS listener only and is off on kind (it would pin every `localhost` port); behind a load balancer
   `gateway.clientIPDetection.numTrustedHops` makes rate limits count the real client from `X-Forwarded-For`. One policy
   per listener because a listener-level policy replaces a Gateway-level one instead of merging.
7. **Keycloak routes set `X-Forwarded-Host` to the host of `keycloak.publicUrl`** (standard `RequestHeaderModifier`).
   With `KC_HOSTNAME_BACKCHANNEL_DYNAMIC` the token, JWKS and userinfo URLs in the discovery document are built from the
   forwarded headers; Envoy sets `X-Forwarded-Proto` but no `X-Forwarded-Host`, so Keycloak advertised
   `http://localhost/...` without `:8090` (found on kind). ingress-nginx sent the request host.
8. **kind exposes the Gateway through a NodePort.** An `EnvoyProxy` referenced from `Gateway.spec.infrastructure` names
   the Envoy Service `hoops-gateway` (namespace `envoy-gateway-system`) and pins node ports 30080/30443, which
   `kind-config.yaml` maps to `127.0.0.1:8090` / `:8453`; no `kubectl port-forward` is needed for the smoke test or the
   e2e journey (a port-forward of `svc/hoops-gateway` works on any cluster). NetworkPolicies admit the Envoy pods'
   namespace `envoy-gateway-system` instead of `ingress-nginx`.

### What has no direct equivalent
| ingress-nginx | Now |
|---|---|
| `limit-burst-multiplier: 5` (burst = 5 x rpm) | Envoy's local limit is a token bucket of `rpm` tokens refilled every minute: the same sustained rate, a burst of at most `rpm`. compose nginx keeps burst 30 / 60. |
| `limit-req-status-code: 429` (controller patch) | 429 is Envoy Gateway's default; nothing to patch. |
| `proxy-buffer-size: 128k` on Keycloak | Not needed: Envoy's header limits are 60 KiB by default, ingress-nginx's 4 KiB buffer was the reason for the annotation. |
| `proxy-body-size` (ingress-nginx default 1 MiB, never set) | No limit at Envoy (it streams bodies); the services reject bodies above `quarkus.http.limits.max-body-size` (2M) with a 413 Problem. A gateway limit would need `BackendTrafficPolicy.requestBuffer`, which buffers every request; not adopted. compose nginx keeps 10m. |
| `use-regex` + `rewrite-target: /q/health$1` | Exact matches + `ReplaceFullPath` (portable, narrower). |
| HSTS on TLS hosts (controller default) | `ClientTrafficPolicy.headers.lateResponseHeaders` on the HTTPS listener. |
| Security headers | None were set by the Ingresses: the services (common-quarkus) and the web nginx send them, unchanged. |

### Why Envoy Gateway
- It is the Envoy project's Gateway API implementation, conformant to the standard and extended channels, with
  policy CRDs that attach to standard routes instead of annotations, so the routes stay portable.
- Per-IP local rate limiting works without extra infrastructure (no Redis), which is what ingress-nginx gave us.
- Installed with a pinned Helm chart that also manages the Gateway API CRDs; small control plane for the 2-CPU machine.
- Rejected: NGINX Gateway Fabric (rate limiting and header policies less complete at the time), Istio / Cilium
  (service mesh or CNI change for an edge-only need), Traefik / Kong (their rate limits and policies live in their own
  CRDs or plugins with less Gateway API alignment), staying on ingress-nginx (retiring).

### What the compose nginx still does
Unchanged (`infra/compose/nginx.conf`): local development does not use the chart. It routes to the services on the host,
serves the web build, answers 403 for `/internal` and the Keycloak admin paths (unless `HOOPS_EXPOSE_KC_ADMIN=true`),
rate-limits with `limit_req` (same rates, burst 30 / 60) and adds the web security headers. The kind/Helm edge and the
compose edge must keep the same routes and limits; the chart tests and `docs/runbooks/troubleshooting.md` say where.

## Upgrade path
1. Pick the new Envoy Gateway version and read its row in the compatibility matrix (Gateway API version, Kubernetes
   range). Bump `ENVOY_GATEWAY_VERSION` and `GATEWAY_API_VERSION` in `deploy/kind/up.sh` together (and the kind node
   image if the Kubernetes range moved).
2. CRDs first: `helm upgrade` never updates CRDs. Apply them server-side before upgrading the controller:
   `helm pull oci://docker.io/envoyproxy/gateway-helm --version <v> --untar -d <tmp>` and
   `kubectl apply --server-side --force-conflicts -R -f <tmp>/gateway-helm/charts/crds/crds/` (Gateway API + Envoy
   Gateway CRDs as bundled with that release), then `helm upgrade eg oci://docker.io/envoyproxy/gateway-helm --version <v>
   -n envoy-gateway-system`. The chart's ValidatingAdmissionPolicy refuses a downgrade of the Gateway API CRDs.
3. `deploy/helm/tests/run.sh` (kubeconform against the CRD catalog), then on kind
   `helm template ... | kubectl apply --dry-run=server -f -` against the new CRDs, `deploy/kind/smoke.sh core game athlete`
   and `deploy/kind/ratelimit-check.sh`.
4. Beyond one proxy replica: switch the two rate-limited routes to global rate limiting (Redis), or accept that each
   replica keeps its own bucket.

## Consequences
- No `Ingress` objects; the chart needs a cluster with Envoy Gateway (or another Gateway API implementation for the
  routes; the rate limits and client policies are Envoy Gateway CRDs and would need their equivalents).
- Values renamed (`ingress.*` -> `route.*`, `networkPolicy.ingressControllerNamespace` -> `gatewayNamespace`), chart
  version 0.2.0; overlays written for 0.1.0 must be adapted.
- Local rate limits are per replica; a burst equals the per-minute rate instead of five times it.
