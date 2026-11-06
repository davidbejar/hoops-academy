# ADR-0033: Global rate limits at the gateway (Envoy rate limit service + Redis)

- Status: Accepted
- Date: 2026-11-06
- Related: decision 18 of 2026-11-06, WP40, ADR-0031 (its decision 4 is replaced here), ADR-0017 (HTTP hardening),
  ADR-0012 (Secrets)

## Context
ADR-0031 limited the token endpoint, the login form and `events:batch` with Envoy Gateway **local** rate limits: a token
bucket per client IP inside each Envoy replica. With N proxy replicas a client gets about N times the limit (each new
connection may land on another replica), so the brute-force brake on the login weakens exactly when the edge is scaled
out. Decision 18 of 2026-11-06: the limits become global, shared by every Envoy replica.

## Decision
1. **Global rules, same numbers.** Each rate-limited HTTPRoute keeps its own `BackendTrafficPolicy` with
   `rateLimit.global.rules`: `sourceCIDR {type: Distinct}` for `0.0.0.0/0` and `::/0` (one counter per client IP),
   60 requests/minute on the token endpoint and the login form, 120/minute on `events:batch` (regex including `%3A`).
   No `local` rules are left (the chart tests assert it). `rateLimit.type: Global` is not written: Envoy Gateway v1.9
   marks the field deprecated ("Use Global and/or Local fields directly"); `global` alone selects the global limiter.
2. **Envoy Gateway's rate limit service.** Envoy Gateway is installed with
   `config.envoyGateway.rateLimit.backend {type: Redis, redis.url: <host:port>}` and then runs the Envoy `ratelimit`
   service itself (Deployment `envoy-gateway-system/envoy-ratelimit`, pods labelled
   `app.kubernetes.io/name: envoy-ratelimit`); every proxy replica asks it over gRPC before forwarding a request on a
   limited route. The cluster operator owns that install (the chart cannot configure it); kind pins the values in
   `deploy/kind/up.sh` next to the version pins, `docs/runbooks/release.md` lists them for other clusters and the
   chart's NOTES print them.
3. **Redis in the chart behind a switch.** `rateLimit.redis.enabled` (on for kind, off by default) renders
   `ratelimit-redis`: one replica of `redis:<tag>-alpine` (pinned by tag like the chart's other images, optional
   digest), in memory only (`--save ""`, no AOF), `maxmemory` 24 MB with LRU, `CONFIG` renamed away, non-root (uid 999),
   read-only root FS, all capabilities dropped, no service-account token, memory limit 64 Mi. Off: an external Redis,
   named in `rateLimit.redis.url`. **No password inside the cluster:** the store holds only counters with a one-minute
   TTL; the access control is the NetworkPolicy, which admits only the `envoy-ratelimit` pods of `envoy-gateway-system`
   (namespace AND pod label in one `from` entry) and denies all egress. Verified on kind: a pod in `hoops` and an
   unlabelled pod in `envoy-gateway-system` time out, a pod with the rate-limit label gets `PONG`. A shared or external
   Redis that needs a password or TLS gets it through Envoy Gateway (`redis.urlRef` to a Secret in
   `envoy-gateway-system`, `redis.tls.certificateRef`), never through values (ADR-0012).
4. **Fail open: `failClosed: false`** (Envoy Gateway's name for the ext rate limit filter's `failure_mode_deny`; false
   is also its default, set explicitly). When the rate limit service or Redis does not answer within
   `rateLimit.timeout`, requests pass unlimited. Reason: the limits are a brake, not an access control. Keycloak's
   brute-force detection and password policy stay in force on the login, and the services keep their own bounds
   (batch at most 500 events, 2 MB bodies). Failing closed would make one small Redis pod a single point of failure for
   every login and for the offline sync of the bench (Envoy answers 500 instead). The timeout is 100 ms instead of
   Envoy Gateway's 20 ms default so a busy 2-CPU node does not fail open by accident; while Redis is down each limited
   request waits up to that timeout. Tested on kind (`deploy/kind/ratelimit-check.sh redis-down`, 2 Envoy replicas):
   Redis scaled to 0, 130 `events:batch` requests in 15 s, all passed, no 429. The rate limit service stayed up,
   logged the Redis errors and reconnected by itself. After Redis was back, the first 429 was again request #121.
5. **Counting semantics change: fixed windows instead of a token bucket.** The rate limit service counts per
   client IP, route and calendar minute (windows aligned to the clock, key TTL one minute). Within a minute at most
   `rpm` requests pass; across a minute boundary a client can send up to 2 x `rpm` in a short time (end of one window,
   start of the next). The local bucket allowed at most `rpm` in a burst, then refilled continuously. Accepted: the
   sustained rate is the same, and the shared counter is worth more than the smoother burst. A Redis restart empties
   the counters, which lets a client start a fresh minute early.
6. **No request body-size limit at the gateway** (unchanged from ADR-0031, accepted again with decision 18): the
   services' `quarkus.http.limits.max-body-size` (2M, 413 Problem) is the control. A gateway limit needs
   `BackendTrafficPolicy.requestBuffer`, which buffers every request of the route.

## Proof on kind (2026-11-06, Envoy Gateway v1.9.3, ratelimit image `5ae0682e`, Redis 8.10.3)
`deploy/kind/ratelimit-check.sh` waits for a fresh window, then sends 2 x `rpm` + 10 requests from one client IP. It
expects the first 429 at request `rpm` + 1 exactly, and with several replicas it checks that every replica served
part of the burst.
| Envoy replicas | events:batch (120/min) | token endpoint (60/min) |
|---|---|---|
| 1 | 250 sent, 120 passed, first 429 at #121 | 130 sent, 60 passed, first 429 at #61 |
| 2 | 250 sent, 120 passed, first 429 at #121 (both replicas in the access logs) | 130 sent, 60 passed, first 429 at #61 |
With the local limits of ADR-0031 each replica had its own bucket, so the same burst over 2 replicas could pass up to
twice as many requests (expected from the design, not measured).

## Consequences
- One more dependency at the edge: the `envoy-ratelimit` Deployment (kind: 10m / 32-128 Mi) and Redis (10m / 16-64 Mi).
  If Envoy Gateway runs without a rate limit backend, nothing counts the global rules and the routes are unlimited. `helm install` prints the values
  the Envoy Gateway install needs, and the runbook check is `Accepted=True` on every BackendTrafficPolicy.
- Limited requests pay one gRPC call plus one Redis round trip; only the three limited routes do.
- Behind a load balancer, `gateway.clientIPDetection.numTrustedHops` still decides which IP is counted (ADR-0031).
- The compose nginx keeps `limit_req` (per process, burst 30 / 60); the limits there are local by nature.

## Alternatives considered
- **Local limits divided by the replica count**: wrong as soon as an HPA changes the count or the load balancer
  spreads clients unevenly.
- **Fail closed**: rejected (point 4). It can be switched on in the Envoy Gateway install (`failClosed: true`, 500s
  while Redis is down) if the limits ever become a hard control.
- **Redis with persistence or a replica / Sentinel**: not needed for one-minute counters; the Envoy Gateway URL
  accepts a Sentinel or Cluster list if the edge ever needs it.
- **Global and local together** (a local bucket in front of the global counter): more moving parts, no need yet.
