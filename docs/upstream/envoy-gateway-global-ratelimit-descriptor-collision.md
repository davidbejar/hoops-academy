# Upstream issue draft: Envoy Gateway global rate limit, two rules with equal client selectors share one descriptor

Status: draft for the owner to file at https://github.com/envoyproxy/gateway/issues (decision 49, 2026-11-06).
Found in WP46 (`docs/wp/WP46-gateway-redis-acl-and-burst.md`); workaround in
`deploy/helm/hoops/charts/hoops-service/templates/httproute.yaml`; ADR-0033 amendment. Remove the workaround
and this file once a fixed release is pinned in `deploy/kind/up.sh`.

---

**Title:** Global rate limit: two rules on one BackendTrafficPolicy with identical `sourceCIDR` selectors (per
minute and per second) collapse into a single descriptor; every request is counted twice and the second rule
never applies

**Environment**
- Envoy Gateway v1.9.3, Gateway API CRDs v1.6.1, kind `kindest/node:v1.36.4`, Redis-backed global rate limit
  (`rateLimit.backend.type: Redis`), one Envoy proxy replica (also reproduced with two).

**What we configured**

One `BackendTrafficPolicy` targeting an `HTTPRoute`, with two global rules that differ only in the limit unit, both
keyed per client IP:

```yaml
spec:
  targetRefs:
    - {group: gateway.networking.k8s.io, kind: HTTPRoute, name: events}
  rateLimit:
    global:
      rules:
        - clientSelectors:
            - sourceCIDR: {type: Distinct, value: 0.0.0.0/0}
          limit: {requests: 120, unit: Minute}
        - clientSelectors:
            - sourceCIDR: {type: Distinct, value: 0.0.0.0/0}
          limit: {requests: 20, unit: Second}
```

**Expected**

Two independent counters per client IP: at most 120 requests per minute and at most 20 per second. A burst of 60
requests in one second should pass 20 and return 429 for 40; 250 requests paced over a minute should pass 120.

**Observed**

- The generated rate limit service configuration (`/rlconfig` on the `envoy-ratelimit` pod, and the xDS rate limit
  actions of the proxy) contains a single descriptor for the `sourceCIDR` selector; only the `MINUTE` limit is
  present.
- Every request increments that counter twice (one action per rule, same descriptor), so the first 429 arrives at
  request 61 of the 120/minute rule, and the per-second rule never fires (a burst of 60 in one second passes 60).

**Cause, as far as we traced it**

The descriptor key for a `sourceCIDR` client selector is built from the selector alone (`masked_remote_address` /
the CIDR value) without the rule index, so two rules whose selectors are equal produce the same descriptor entry
and the later rule overwrites or merges into the earlier one on the rate limit service side, while the proxy still
emits one rate limit action per rule.

**Workaround**

Add an always-true selector to the second rule so its descriptor differs:

```yaml
        - clientSelectors:
            - sourceCIDR: {type: Distinct, value: 0.0.0.0/0}
            - path: {type: PathPrefix, value: /}
          limit: {requests: 20, unit: Second}
```

With that, `/rlconfig` shows two descriptors (MINUTE and SECOND), the 120/minute rule fires at request 121, and
the burst of 60 passes 20.

**Reproduction**

1. `kind` cluster with Envoy Gateway v1.9.3, Redis backend for the global rate limit.
2. Apply the `BackendTrafficPolicy` above on any route.
3. `for i in $(seq 1 130); do curl -s -o /dev/null -w '%{http_code}\n' http://<gateway>/events; done | grep -n 429 | head -1`
   → first 429 at line 61 instead of 121.
4. `curl --parallel --parallel-max 60` 60 requests at once → 60 × 200 instead of 20 × 200 + 40 × 429.
5. Inspect `kubectl -n envoy-gateway-system exec deploy/envoy-ratelimit -- wget -qO- localhost:6070/rlconfig`.

**Suggested fix**

Include the rule index (or a per-rule suffix) in the generated descriptor key for client selectors, so rules with
equal selectors but different limits get distinct descriptors, as the API already allows several rules per policy.
