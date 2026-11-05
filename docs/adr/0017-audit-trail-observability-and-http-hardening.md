# ADR-0017: audit trail, observability defaults and service-level HTTP hardening

- Status: Accepted; amended by ADR-0024 — player logins get a temporary password instead of the setup e-mail; amended by
  ADR-0029 — the trail is read by academy ADMINs and the super admin (core_platform gets a read policy)
- Date: 2026-11-02 (WP17)

## Context
WP17 has to add an audit trail for administrative actions, metrics/traces/structured logs, and defense-in-depth HTTP
controls to three services that share `libs/common-quarkus`. The contracts define no audit read endpoint. The
services sit behind nginx (compose) or ingress-nginx (kind), but must not depend on the proxy alone.

## Decision
**Audit trail.** Table `core.audit_event` (V9): `id, seq (identity), tenant_id, actor_sub, actor_person_id, action,
target_type, target_id, metadata jsonb, at`. It is a normal RLS tenant table (`app.enable_tenant_rls`), plus:
- **append-only.** A row trigger rejects UPDATE/DELETE with SQLSTATE 42501 for every role except `core_migrator`,
  which runs retention. RLS keeps cross-tenant attempts at 0 rows, so the generic isolation suite stays valid;
- **platform append.** `core_platform` holds INSERT only (grant + insert policy), and records tenant lifecycle and
  master-data changes from the platform transaction.

Written by application use cases through two ports in the same transaction as the change:
- `AuditLog` for the tenant datasource;
- `PlatformAuditLog` for the platform datasource.

The adapter fills in the actor from the JWT `sub` (or `system` for jobs) and the bound person. Each event is also
logged as one line on category `hoops.audit`, which is JSON in prod.

Actions:
- members: `member.invited`, `member.updated`, `member.roles_replaced`, `member.deactivated`;
- guardian links: `guardian_link.created`, `guardian_link.removed`;
- players and approvals: `player.requested`, `player.approved`, `player.rejected`, `player.withdrawn`,
  `approval.cancelled`;
- tenant: `tenant.created`, `tenant.suspended`, `tenant.reactivated`, `tenant.withdrawn`,
  `tenant.master_data_changed`, `tenant.profile_changed`, `tenant.settings_changed`;
- logo: `tenant.logo_replaced`, `tenant.logo_removed`.

Metadata carries no personal data. It holds ids, role and enum names, and the *names* of changed fields, never
values, names, e-mails or notes. There is no REST read endpoint: the contract has none, so it is a contract follow-up
(an ADMIN `GET /api/core/audit-events` or a super_admin view).

**Observability (library defaults, `common-quarkus`).**
- **Metrics.** `quarkus-micrometer-registry-prometheus` serves `/q/metrics`. It is scraped in-cluster and never
  routed by nginx or the ingress.
- **Traces.** `quarkus-opentelemetry` is included with `quarkus.otel.sdk.disabled=true`. An environment enables it
  with `QUARKUS_OTEL_SDK_DISABLED=false` and `QUARKUS_OTEL_EXPORTER_OTLP_ENDPOINT`; `traceId` then reaches the MDC,
  `Problem.traceId` and the logs.
- **Logs.** `quarkus-logging-json` is on in `%prod` only. `TenantContext` mirrors the bound tenant into the MDC key
  `tenantId`, including for `TenantScope` jobs. HTTP access logging is off by default.
- **Health.** `quarkus-smallrye-health` runs in all three services. game and athlete add a readiness check that never
  goes DOWN but reports whether core is reachable, so a core outage does not take them out of rotation (they answer
  503 Problems per request).

**HTTP hardening (library defaults).**
- **Body limit.** `quarkus.http.limits.max-body-size=2M`. `RequestBodyLimit` (a Vert.x route at order -3, before
  Quarkus' own limit handler at -2) answers a declared `Content-Length` above the limit with a 413 Problem
  `REQUEST_TOO_LARGE`.
- **Security headers.** These are sent on every path except `/q/**`: `X-Content-Type-Options`,
  `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`, `CSP: default-src 'none'; frame-ancestors 'none'` and
  `CORP: same-origin`.
- **CORS.** An allow-list from `hoops.cors.origins` (env `HOOPS_CORS_ORIGINS`, default `http://localhost:5173` for
  the Flutter dev server), with no credentials and no wildcard.

**Onboarding crash window (amends ADR-0013).** `RepairOnboarding` runs every 10 min under `runExclusive`. It deletes
registry rows (and subscriptions) older than 15 min, within a 7-day look-back, whose tenant has no `tenant_settings`.
The orphaned Keycloak login is logged for manual clean-up.

**Player logins (amends ADR-0013).** `CreatePlayer` (ADMIN path) and `ApproveRequest` (ADD_PLAYER) reuse the invitation
saga for players with an e-mail: Keycloak first, then the transaction with the setup e-mail last, and compensation on
failure. Both operations declare 502 (core contract 2.1.0).

## Alternatives rejected
- **Outbox as the audit trail.** It is an integration stream, published and pruned by WP19, and it carries payloads
  meant for consumers.
- **Revoking UPDATE/DELETE from `core_app`.** This breaks the generic RLS isolation check, which expects 0 rows rather
  than 42501 on a cross-tenant update; the trigger gives the same guarantee.
- **A `PROVISIONING` tenant status.** It needs a contract change and status handling everywhere; the repair job reuses
  the existing FK guard.
- **Security headers at the proxy only.** A misrouted path or a direct service port would ship without them.

## Consequences
- Every new administrative use case must call `AuditLog`; the tests assert the action names (see
  `docs/security/asvs-checklist.md`).
- `/q/metrics` is unauthenticated on the service port. NetworkPolicies and the proxy routing are what keep it
  internal.
- OTel adds a dependency even when disabled; enabling it is configuration only.
