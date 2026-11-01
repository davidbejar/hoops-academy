# WP17 — Security hardening, observability, CI gates

Model: Opus. Depends on: all services, WP11. Skills: owasp-security, verification-before-completion.

## Scope
- Run the OWASP skill review over each service and the Flutter auth/offline code; fix findings; threat model doc
  (`docs/security/threat-model.md`), ASVS L2 checklist with evidence (`docs/security/asvs-checklist.md`).
- Gates: dependency-check (`-Psecurity-scan`) in CI with suppression file discipline; Trivy image scan in images workflow;
  ZAP baseline against compose stack (CI job, allowed-failures list); gitleaks full history (already).
- Runtime: security headers + CORS allow-list at nginx/ingress; rate limiting for `/auth` and `events:batch`; audit
  log table/stream for admin actions (member/role changes, approvals, tenant lifecycle); Keycloak hardening review
  (brute force, password policy, no `start-dev` in kind, admin console not exposed via ingress).
- Observability: Micrometer Prometheus + OpenTelemetry traces (OTLP, disabled by default locally), JSON logs with
  tenantId/traceId MDC, health/readiness probes verified under Helm.

## Acceptance
- [ ] ZAP baseline: no High/Medium; Trivy: no CRITICAL; dependency-check: no unsuppressed CVSS ≥ 7
- [ ] audit events emitted for all admin actions (tests); headers verified by e2e; `/internal` unreachable via proxy and ingress (tests)
- [ ] `docs/security/*` complete with evidence links

## Handover

### Built
**Security review and documentation** (`docs/security/`)
- `review-2026-11.md` lists 21 findings. By severity: Critical 0, High 0, Medium 5, Low 13, Info 3. 11 are fixed in
  this WP and 10 are open; 7 of the open ones are in `apps/web`, which was read-only for this WP.
- `threat-model.md` has STRIDE tables for six trust boundaries: browser ↔ proxy, services ↔ Keycloak, services ↔ core
  `/internal`, services ↔ Postgres, offline device storage, and admin uploads.
- `asvs-checklist.md` is an ASVS 5.0 L2 checklist with evidence and explicit gaps.
- `docs/adr/0017-audit-trail-observability-and-http-hardening.md` is the new ADR.

**libs/common-quarkus** (library defaults that every service inherits)
- New dependencies: `quarkus-micrometer-registry-prometheus` (`/q/metrics`), `quarkus-opentelemetry`
  (`quarkus.otel.sdk.disabled=true`; enable it with env) and `quarkus-logging-json` (on in `%prod` only).
- `TenantContext` mirrors the bound tenant into the MDC key `tenantId`. This covers both the request filter and
  `TenantScope` jobs.
- `RequestBodyLimit`: a declared body above `quarkus.http.limits.max-body-size` (2M) gets a 413 Problem with code
  `REQUEST_TOO_LARGE`. `ProblemType.PAYLOAD_TOO_LARGE` was added for it.
- Security headers on every path except `/q/**`: nosniff, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`,
  `CSP: default-src 'none'; frame-ancestors 'none'`, and `CORP: same-origin`.
- CORS allow-list from `hoops.cors.origins` (env `HOOPS_CORS_ORIGINS`, default `http://localhost:5173`), with no
  credentials. Access logging is off.
- `CallerSubject` is now public and rejects a JWT without `sub` with a 401 Problem. This was the e2e finding (F-21).
  `hoops.security.require-sub=false` exists only in the `%test` profiles, because `@TestSecurity` alone yields a JWT
  with no claims.

**libs/contracts**
- core 2.1.0 declares 502 `UpstreamIdentityProvider` on `createPlayer` and `approveApprovalRequest`, and documents
  that a player with an e-mail gets a login.

**services/core-service**
- V9 `core.audit_event`:
  - RLS tenant table.
  - Append-only: a trigger rejects UPDATE and DELETE with 42501 for every role except `core_migrator`.
  - `core_platform` can only insert.
- `AuditLog` and `PlatformAuditLog` ports with adapters in `adapters/out/audit`. Each event also writes one log line
  on category `hoops.audit`.
- Audited actions:
  - members: `member.invited`, `.updated`, `.roles_replaced`, `.deactivated`;
  - guardian links: `guardian_link.created`, `.removed`;
  - players: `player.requested`, `.approved`, `.rejected`, `.withdrawn`, `approval.cancelled`;
  - tenant: `tenant.created`, `.suspended`, `.reactivated`, `.withdrawn`, `.master_data_changed`,
    `.profile_changed`, `.settings_changed`, `.logo_replaced`, `.logo_removed`.
  - Metadata never contains personal data: only ids, role names and the names of changed fields.
- The audit trail has no REST endpoint, because the contract has none. It is a contract follow-up.
- Player logins: `CreatePlayer` (ADMIN path) and `ApproveRequest` (ADD_PLAYER) reuse the invitation saga through
  `PlayerLogin`. Keycloak is called first, then the transaction runs with the setup e-mail last, and the Keycloak user
  is compensated on failure. A failing invitation leaves the approval request PENDING.
- The members list hides the persons of PENDING_APPROVAL and REJECTED players.
- `RepairOnboarding` and `OnboardingRepairJob` close the onboarding crash window:
  - it runs every 10 min under `runExclusive("core.onboarding-repair")`, with a 15 min grace and a 7 day look-back;
  - it removes registry rows and subscriptions of tenants that have no `tenant_settings`;
  - it is configured by `hoops.core.onboarding-repair-cron` and `.grace` / `.look-back`.
- `CallerIdentity` uses `CallerSubject`.

**services/game-service and services/athlete-service** (done by a sub-agent of this WP)
- `quarkus-smallrye-health` in both. Readiness includes the DB. `CoreReachabilityCheck` is always UP and reports
  `core: reachable|unreachable`; it probes `/q/health/live` with a 1 s timeout and caches the result for 10 s.
- The default credentials (`change-me` and empty values) are removed.
- athlete: a same-day measurement race now returns 409 `MEASUREMENT_EXISTS_FOR_DATE`.

**Infra** (done by a sub-agent of this WP)
- **Keycloak realm:**
  - password policy `length(12) and maxLength(128) and notUsername and notEmail`; brute-force settings unchanged;
    `sslRequired: external`;
  - `web` client: adds `http://localhost:5173/*` as redirect and post-logout URI and as web origin;
  - `basic` added to `defaultClientScopes` of web, core-service, game-service and athlete-service;
  - kind runs `start`; compose keeps `start-dev`.
- **compose nginx** (`infra/compose/nginx.conf` plus `infra/compose/nginx/*.conf` snippets):
  - `limit_req` zones `auth` (60 r/min, burst 30) and `events` (120 r/min, burst 60), both answering 429;
  - `Cache-Control: no-cache` on `index.html`, `sw.js`, `flutter_service_worker.js` and the bootstrap files;
  - CSP compatible with CanvasKit. It hashes the inline service-worker registration and temporarily allows gstatic
    (F-09). `redirect.html` has its own CSP;
  - XFO, COOP, CORP, Permissions-Policy;
  - `/auth/admin` and `/auth/realms/master` answer 403 unless `HOOPS_EXPOSE_KC_ADMIN=true` (documented in
    `.env.example`). The flag selects which snippet compose mounts;
  - image `nginx:1.30-alpine`; `extra_hosts host.containers.internal:host-gateway`.
- `deploy/containers/web-nginx.conf` carries the same header set and CSP.
- **Helm:**
  - rate-limited Ingresses for the token endpoint and for `events:batch` (regex, no rewrite);
  - an admin-deny Ingress routing `/auth/admin` and the master realm to the web 403 page (flag
    `keycloak.exposeAdminConsole`);
  - TCP probe overrides removed;
  - `HOOPS_CORS_ORIGINS` and `QUARKUS_OTEL_SDK_DISABLED` env, Prometheus pod annotations;
  - mailpit as Service `mailhog` in kind only;
  - chart symlinks replaced by copies plus `scripts/sync-chart-files.sh`, called from `up.sh`, with a drift check in
    `run.sh`;
  - `up.sh` patches ingress-nginx to answer 429 for rate limits.
- **CI** (`.github/workflows/ci.yml`):
  - `dependency-check` job: `-Psecurity-scan`, `secrets.NVD_API_KEY`, NVD cache, CVSS ≥ 7 fails;
  - `trivy-fs` job: vuln, misconfig and secret scanners, HIGH and CRITICAL, `.trivyignore.yaml` (each entry has a
    reason and an expiry);
  - `zap-baseline` job: compose stack plus core on the host, then `.zap/baseline.conf` and `scripts/zap-gate.py`
    (fails on High or Medium alerts that are not accepted);
  - `helm-chart-tests` job: `run.sh` plus `helm package`.
  - `images.yml` keeps the Trivy image gate (HIGH,CRITICAL, ignore-unfixed, exit 1).
- **Root pom:** guava is pinned to 33.7.2-jre for CVE-2026-102554 (HIGH; the Quarkus BOM ships 33.6.0).

### Verified (fresh, read in full)
- `source scripts/env.sh && ./mvnw -q clean verify` from the root: exit 0, every coverage gate met.

| Module | Test classes | Tests | Failures/errors/skipped | Lines |
|---|---|---|---|---|
| libs/common-quarkus | 29 | 164 | 0/0/0 | 95.4 % |
| libs/contracts | 5 | 99 | 0/0/0 | – |
| services/core-service | 58 | 427 | 0/0/0 | 98.6 % |
| services/game-service | 23 | 193 | 0/0/0 | 98.3 % |
| services/athlete-service | 36 | 578 | 0/0/0 | 97.2 % |
| **total** | 151 | **1 461** | 0 | |

- **TDD.** Each new test was seen failing before its code existed:
  - common: 13 failures in the headers, CORS, metrics, 413 and MDC tests; 2 in `MissingSubjectTest`;
  - core: 8 failures and 16 errors across the audit assertions, player-login tests, members filter and
    `AuditEventRlsTest`; `MeWithoutSubjectTest` was also red first;
  - `OnboardingRepairTest` was red at compile time only;
  - the athlete health test was not seen red, and the sub-agent reported this as a deviation.
- `deploy/helm/tests/run.sh`: ALL CHART TESTS PASSED (5 lints, 4 snapshots, kubeconform 85/85, all assertions).
- `helm template … -f values-kind.yaml | gitleaks detect --pipe`: no leaks.
- `gitleaks detect --no-git`: 14 hits, all in the local git-ignored `.env`; no hits in tracked files.
- `trivy fs` (vuln + secret, HIGH/CRITICAL): 0 findings after the guava pin. `trivy config`: 0 HIGH beyond the
  accepted Keycloak read-only-rootfs entry (KSV-0014, expires 2027-03-31).
- **ZAP baseline** ran against a throwaway nginx using the new config and serving the real `apps/web/build/web`:
  0 FAIL. One Medium (10055 `style-src 'unsafe-inline'`, which Flutter needs) is accepted in `.zap/baseline.conf`
  with justification. One Low (COEP) remains.
- **Throwaway Keycloak 26.8.1** importing the new realm: access tokens carry `sub` for web and core-service, and the
  password policy rejects 8-character passwords and the username.
- **Headless Chrome:** CanvasKit renders under the CSP and `redirect.html` runs with 0 violations.
- **curl on the throwaway nginx:**
  - 429 after the burst on the token endpoint and on `events:batch`;
  - 403 on `/auth/admin`, the master realm (including `..` and `%2e%2e` variants) and `/internal`;
  - `no-cache` on the app shell.

### Not executed, and why
- **OWASP dependency-check:** no NVD API key is available here, and the initial NVD download without one takes hours.
  The CI job is configured with `secrets.NVD_API_KEY`. `trivy fs` covered Maven and pub vulnerabilities instead.
- **CI workflows:** none were run (no runner here). They parse as YAML; actionlint is not installed.
- **ZAP against compose:** the running `hoops-nginx` belongs to another lane and was not restarted, so it still serves
  the old config. ZAP ran against a throwaway nginx instead, and the Keycloak pages were not crawled. The CI job
  covers both.
- **kind:** the new ingress rules (rate limits, admin deny) were checked by rendering and assertions only, not on a
  live cluster.
- **Headers verified by e2e:** the e2e/ suite belongs to another lane. The service headers are covered by
  `SecurityHeadersTest`; the proxy headers by curl and the chart assertions.
- **JSON log output in `%prod`:** configuration only. No prod-profile jar was started.

### Actions for others
- **Re-import the realm:** compose imports it only once, so run `just down && podman volume rm hoops_pgdata && just up`.
  This is needed for `basic`/`sub`, the 5173 URIs and the password policy. kind renders the same realm from the chart
  copy (`scripts/sync-chart-files.sh` keeps it in sync).
- **e2e lane:** it uses the master-realm `admin-cli` and the Admin API, so set `HOOPS_EXPOSE_KC_ADMIN=true` in `.env`
  (then `just down && just up`), or `keycloak.exposeAdminConsole: true` in `values-local.yaml` on kind.
- **Tiltfile:** add `local('scripts/sync-chart-files.sh')` before `k8s_yaml(helm(...))`.
- **apps/web:** fix F-03, F-07, F-08, F-09, F-10, F-19 and F-20. After any change to the inline scripts in
  `index.html` or `redirect.html`, run `scripts/csp-hashes.py` and update both nginx CSPs.
- **`deploy/containers/service.Containerfile`:** pin the `ubi9/openjdk-21-runtime` tag (trivy DS-0001).
- Open product and contract decisions: F-01 (game event feed), F-11 (inviting an existing Keycloak account), an audit
  read endpoint, and token audience (F-14). All are in FOLLOW-UPS.md.
- No git commands were run.
