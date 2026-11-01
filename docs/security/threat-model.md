# Threat model — Hoops Academy (STRIDE per trust boundary)

Version 2026-11 (WP17). Scope: compose stack and kind/Helm deployment; three Quarkus services; Keycloak realm
`academy`; PostgreSQL 17 with RLS; Flutter Web PWA. Companion documents: `review-2026-11.md` (findings),
`asvs-checklist.md` (controls with evidence), ADR-0005/0006/0011/0012/0013/0017.

## Assets
| Asset | Why it matters |
|---|---|
| Minors' personal data (names, birth dates, gender, guardian links) | GDPR special care (children); the main confidentiality asset |
| Health & fitness data (injuries, measurements, availability) | Health data (GDPR art. 9) |
| Match statistics, attendance | Integrity (eligibility, rosters, published stats) |
| Tenant isolation | One academy must never see another's data |
| Credentials & tokens (Keycloak users, client secrets, DB role passwords) | Account takeover, lateral movement |
| Audit trail (`core.audit_event`) | Accountability for administrative actions |

## Actors
Anonymous internet user; authenticated member (ADMIN, COACH, ASSISTANT_COACH, PARENT, PLAYER) of a tenant; member of
another tenant; platform `super_admin`; a compromised service pod; a person with physical access to a shared device;
a developer/CI pipeline (supply chain).

## Data-flow overview
```
Browser (PWA, IndexedDB/drift, localStorage tokens)
   │  HTTPS (ingress) / HTTP (compose :8080)
   ▼
nginx / ingress-nginx ──/auth──▶ Keycloak ──▶ Postgres (keycloak db)
   │  /api/core,/platform  /api/game  /api/athlete      (/internal → 403, /auth/admin → 403, /q/** not routed)
   ▼
core-service ◀──/internal (client-credentials token, role `service`)── game-service, athlete-service
   │                                                       │
   └──────── Postgres `hoops` (core_app / core_platform / game_app / athlete_app; *_migrator for Flyway) ─┘
```

## 1. Browser ↔ nginx / ingress
| STRIDE | Threat | Mitigations (evidence) | Residual |
|---|---|---|---|
| S | Stolen/forged bearer token | Keycloak-signed JWT validated by `quarkus-oidc` (issuer, signature, expiry); PKCE S256 public client `web` (realm export) | No audience check (Info, review F-14) |
| S | Credential stuffing / brute force on login and token endpoint | Keycloak brute-force detection; password policy `length(12) and notUsername and notEmail`; nginx/ingress `limit_req` on `/auth/realms/*/protocol/openid-connect/token` (429) | No MFA (ASVS gap) |
| T | Tampering with requests (tenant header, ids) | Server-side authz: `TenantHeaderFilter` (membership → else 404), `@RequiresTenantRole` + `Authz` checks, RLS | — |
| T | XSS / script injection into the SPA | CSP `script-src 'self' 'wasm-unsafe-eval'` (+ hash for the inline SW registration, gstatic while CanvasKit is CDN-loaded), no HTML sinks in the app (Flutter review); API responses carry `CSP: default-src 'none'` and `nosniff` | gstatic allowed until `--no-web-resources-cdn` (F-09) |
| T | Clickjacking | `X-Frame-Options: DENY` + `frame-ancestors 'none'` at nginx and services | — |
| R | User denies an administrative action | `core.audit_event` with actor sub + person (ADR-0017) | No audit read endpoint (contract follow-up) |
| I | Enumeration of tenants/members via status codes | Non-members get 404 (never 403); uniform Problem bodies without internals | Invite reveals existing Keycloak account (F-11) |
| I | Stale SPA/service worker served after a fix | `Cache-Control: no-cache` for `index.html`, `sw.js`, `flutter_service_worker.js` | — |
| D | Flooding `events:batch` / large bodies | `limit_req` on `events:batch`; batch ≤ 500 events; 2 MB body limit → 413 Problem; nginx `client_max_body_size` | No per-tenant quotas |
| E | Reaching internal or admin surfaces | `/internal/**` → 403 at nginx and ingress (+ NetworkPolicy); `/auth/admin/**` → 403 unless `HOOPS_EXPOSE_KC_ADMIN=true` (compose) / `keycloak.exposeAdminConsole` (Helm); `/q/**` not routed | — |

## 2. Services ↔ Keycloak
| STRIDE | Threat | Mitigations | Residual |
|---|---|---|---|
| S | Service impersonation with a stolen client secret | Secrets from env/K8s Secrets only (ADR-0012); gitleaks pre-commit + CI; no defaults in `application.properties` (game/athlete fixed in WP17) | Secrets static (no rotation automation) |
| T | Token/JWKS tampering in transit | In-cluster HTTP to Keycloak (NetworkPolicy-restricted); issuer pinned to public URL; `KC_HOSTNAME_BACKCHANNEL_DYNAMIC` | Cluster-internal HTTP, no mTLS |
| R | Unattributed user provisioning | `member.invited` audit + Keycloak admin events (Keycloak side) | — |
| I | Over-privileged service account | `core-service` SA holds only `manage-users`/`view-users`; game/athlete hold only realm role `service` | `manage-users` is broad (Keycloak has no finer role) |
| D | Keycloak outage blocks onboarding | 502 `IDENTITY_PROVIDER_UNAVAILABLE`, nothing committed (saga); token validation uses cached JWKS | — |
| E | Admin console exposure | Blocked at proxy/ingress; kind uses `start` (not `start-dev`); `sslRequired: external` | Admin user from env in compose (dev only) |

## 3. game / athlete ↔ core (`/internal`)
| STRIDE | Threat | Mitigations | Residual |
|---|---|---|---|
| S | A user token calling `/internal/**` | `@RolesAllowed("service")` (realm role held only by the three service accounts); `/internal` blocked at proxy/ingress | — |
| T | Forged tenant id in internal calls | Internal endpoints bind `TenantScope.runAs(tenantId)` → RLS; authz context comes from core's DB, never from the caller | — |
| I | Over-sharing in authz/roster responses | DTOs limited to ids, roles, team ids, display names | — |
| D | core outage cascades | 2 s timeouts, 30 s cache, 503 `UPSTREAM_UNAVAILABLE` Problems; readiness stays UP with a `core: unreachable` indicator | — |
| E | Compromised game pod reads core data | NetworkPolicy (same namespace + ingress controller only); `service` role reaches `/internal` only | A compromised pod can query any tenant's authz via `/internal` (by design) |

## 4. Services ↔ PostgreSQL
| STRIDE | Threat | Mitigations | Residual |
|---|---|---|---|
| S | Connecting as owner/superuser | App roles are NON-owner, NOBYPASSRLS; Flyway as `*_migrator`; CNPG managed roles | — |
| T | Cross-tenant writes | `ENABLE`+`FORCE` RLS on every tenant table, `WITH CHECK` on `app.current_tenant()`; `RlsSchemaMetaTest`/`GenericRlsIsolationTest` in every service | Native SQL relies on RLS alone (ADR-0006) |
| T | Rewriting history | `core.audit_event` append-only trigger; `core_platform` insert-only (`AuditEventRlsTest`) | Migrator can delete (retention) |
| R | — | Audit trail as above | — |
| I | Reading other tenants / SQL injection | RLS; JPQL/parameterised native SQL only (ArchUnit: native SQL only in `*Repository`); `app.current_tenant()` raises when unset | — |
| D | Connection exhaustion | Role connection limits (CNPG), pool sizes | — |
| E | Platform role reading tenant content | `core_platform` grants limited to registry/usage/billing/outbox-append/audit-append (`TenantRegistryRlsTest`) | — |

## 5. Offline device storage (PWA)
| STRIDE | Threat | Mitigations | Residual |
|---|---|---|---|
| S | Next user on a shared device inherits the session | Logout revokes tokens + end-session when online | **Medium F-03**: offline/failed logout keeps tokens (fix in apps/web) |
| T | Tampered offline events replayed | Server validates every event (JSON Schema, roster, authz at sync time); UUIDv7 ids, `clientSeq`, `EVENT_ID_REUSED` | — |
| R | Events recorded under another user | Outbox scoped by tenant + person; sync uses the current user's token | — |
| I | Cached match data readable by the next user / DevTools | No health data or birth dates cached | **Low F-07**: drift DB not wiped on logout; some reads keyed by matchId only |
| I | Tokens readable by injected script | CSP; no XSS sinks found | **Low F-08**: tokens (incl. `offline_access` refresh token) in localStorage |
| D | Quota/eviction loses unsynced events | Visible pending counter; sync on reconnect | Cold-start offline not supported yet (FOLLOW-UPS) |

## 6. Admin uploads (tenant logo)
| STRIDE | Threat | Mitigations | Residual |
|---|---|---|---|
| S | Non-admin upload | ADMIN only (role matrix test `everyMemberReadsOnlyAdminsWrite`) | — |
| T | Polyglot/SVG with script, content-type spoofing | Magic-byte detection PNG/JPEG/WebP only; SVG/GIF → 415; stored type = detected type; served with `nosniff`, `CSP default-src 'none'`, `CORP same-origin` | Image parsers in browsers (decoding bugs) |
| R | Who changed the logo | `tenant.logo_replaced` / `tenant.logo_removed` audit | — |
| I | Logo of another tenant | RLS + tenant header; `anotherTenantsLogoIsNotFound` | — |
| D | Oversized uploads | 512 KB domain limit (413 `LOGO_TOO_LARGE`); 2 MB HTTP limit (413 `REQUEST_TOO_LARGE`); nginx 10 MB | Stored in Postgres (ADR-0009) |
| E | — | No server-side image processing (no decoder attack surface) | — |

## Out of scope / assumptions
TLS termination and certificates in production (ingress choice open, FOLLOW-UPS); backup encryption; Keycloak
server hardening beyond the realm export; DDoS beyond per-IP rate limits; email deliverability (SPF/DKIM).
