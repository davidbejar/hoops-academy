# ASVS 5.0 Level 2 checklist — Hoops Academy

Version 2026-11 (WP17). This uses **ASVS 5.0.0** numbering; 4.0 IDs are not used. The checklist covers the controls
this system implements or depends on, with evidence (tests, files) and explicit gaps. Requirements that do not apply
are listed at the end: no XML, no WebRTC, no GraphQL, no server-side templating, no own password storage (Keycloak
does authentication, ADR-0005).

Where a row names only a chapter (for example "V3 (headers)"), the exact requirement ID was not pinned in this
review. Verify it against the upstream chapter file before an external assessment.

Legend: **Met**, **Partial**, **Gap** (open), **N/A**. Paths are relative to the repo root; `core`, `game` and
`athlete` mean `services/<name>-service/src/test/java/...`.

## V1 Encoding and Sanitization
| ID | Requirement (abridged) | Status | Evidence |
|---|---|---|---|
| 1.2.1 | Context-appropriate output encoding | Met | JSON only (Jackson); Problem bodies via `Problem` record. No HTML rendering server-side. Flutter renders text widgets, with no HTML sinks (review F-*, "what is fine") |
| 1.2.4 | Parameterised queries / ORM | Met | JPQL with bound parameters; ArchUnit `HoopsArchitectureRules` (native SQL only in `*Repository`); `TenantHeaderFilterTest.malformedHeaderIsBadRequest` (`acme' or 1=1`) |
| 1.2.5 | OS command parameterisation | N/A | No OS calls in the services |
| 1.3.2 | No eval / dynamic code | Met | No scripting engines in the backend. Web CSP has no `'unsafe-eval'` (`infra/compose/nginx.conf`) |

## V2 Validation and Business Logic
| ID | Requirement | Status | Evidence |
|---|---|---|---|
| 2.2.1 | Allow-list validation against business expectations | Met | Bean Validation on DTOs + contract validation of every request/response (`Contract.*` filters); `ProblemExceptionMappersTest.invalidBodyIsValidationProblem`; logo magic bytes `TenantLogoResourceTest.svgGifAndUnknownTypesAreUnsupported`; event JSON Schema (`libs/contracts/events`) |
| 2.2.2 | Validation at a trusted service layer | Met | Server-side validation as above; client-side logo checks are UX only (Flutter review) |
| 2.3.1 | Business flows in sequence | Met | Approval state machine `ApprovalRequest` (NOT_PENDING 409, `aDecidedRequestCannotBeDecidedAgain`); optimistic locking → 409 `CONCURRENT_MODIFICATION` (`twoConcurrentDecisionsHaveExactlyOneWinner`); measurement same-day race → 409 `MEASUREMENT_EXISTS_FOR_DATE` (`athlete MeasurementSameDayRaceTest`) |
| V2 (anti-automation) | Rate limits on expensive/abusable functions | Met | nginx `limit_req` zones for the token endpoint and `events:batch` (429); Envoy Gateway global rate limits per client IP in the chart (`BackendTrafficPolicy`, 60/min token endpoint and login form, 120/min `events:batch`, shared by every Envoy replica, ADR-0031/ADR-0033; `deploy/helm/tests/run.sh` assertions, `deploy/kind/ratelimit-check.sh` on kind, WP36; ingress-nginx `limit-rpm` until WP36); `events:batch` ≤ 500 events |

## V3 Web Frontend Security
| ID | Requirement | Status | Evidence |
|---|---|---|---|
| V3 (CSP) | Content-Security-Policy with no unsafe script sources | Partial | `infra/compose/nginx.conf` and `deploy/containers/web-nginx.conf`: `script-src 'self' 'wasm-unsafe-eval'` + hash of the inline SW registration. `https://www.gstatic.com` and `fonts.gstatic.com` are allowed until the web build self-hosts CanvasKit (F-09). `style-src 'unsafe-inline'` is needed by the Flutter engine |
| V3 (headers) | nosniff, frame protection, referrer policy, COOP | Met | nginx (SPA) + services (`common SecurityHeadersTest`: X-Content-Type-Options, X-Frame-Options DENY, Referrer-Policy, CSP `default-src 'none'`, CORP) |
| V3 (CORS) | CORS allow-list, no wildcard with credentials | Met | `common CorsTest` (allowed 5173 origin, foreign origin gets no ACAO, no credentials); `hoops.cors.origins` |
| V3 (HSTS) | HSTS on HTTPS | Partial | The chart's HTTPS listener sets HSTS (`max-age=31536000; includeSubDomains`) through a `ClientTrafficPolicy` (Envoy Gateway, ADR-0031); off on kind (it would pin every `localhost` port). Compose is HTTP-only (dev); no production deployment exists yet |
| V3 (cache) | Sensitive/app-shell caching controls | Met | `Cache-Control: no-cache` for `index.html`, `sw.js`, `flutter_service_worker.js` (nginx); logo `private, max-age` (`TenantLogoResourceTest`) |

## V4 API and Web Service
| ID | Requirement | Status | Evidence |
|---|---|---|---|
| V4 (content type) | Correct `Content-Type`, Problem+JSON errors | Met | `ProblemExceptionMappersTest` (content type on every mapper), contract validation of responses |
| V4 (methods) | Unsupported methods rejected | Met | `ProblemExceptionMappersTest.jaxRsHttpErrorsKeepTheirStatus` (405 Problem) |
| V4 (body size) | Request size limits | Met | `common RequestBodyLimitTest` (413 Problem `REQUEST_TOO_LARGE`), `core TenantLogoResourceTest.aBodyAboveTheHttpLimitIsStillAProblem` |

## V5 File Handling
| ID | Requirement | Status | Evidence |
|---|---|---|---|
| V5 (size) | File size limits | Met | 512 KB logo (`TenantLogoResourceTest.sizeLimitIs512Kilobytes`) + 2 MB HTTP limit |
| V5 (type) | Type validation by content, not name/declared type | Met | `theStoredTypeComesFromTheMagicBytesNotFromTheDeclaredType`, SVG/GIF → 415 |
| V5 (serve) | Served files cannot execute | Met | Stored in Postgres (ADR-0009), served with nosniff + `CSP default-src 'none'`, never from the web root |

## V6 Authentication (delegated to Keycloak, realm `infra/keycloak/realm-academy.json`)
| ID | Requirement | Status | Evidence |
|---|---|---|---|
| 6.2.1 | Password length ≥ 8 (15 recommended) | Met (12) | `passwordPolicy: length(12) and notUsername and notEmail` |
| 6.2.4 | Block top-3000 common passwords | Gap | Keycloak `passwordBlacklist` needs a deployed list file; not configured (follow-up) |
| 6.2.5 / 6.2.7 / 6.2.8 | No composition rules; paste allowed; no truncation | Met | Policy has no character-class rules; Keycloak login form |
| 6.2.10 | No forced rotation | Met | No `forceExpiredPasswordChange` in the policy |
| 6.2.12 | Breached-password check | Gap | Not available in stock Keycloak 26 without an extension |
| 6.3.1 | Brute-force / credential-stuffing controls | Met | `bruteForceProtected: true` (realm), token-endpoint rate limit (nginx `limit_req` / Envoy Gateway global rate limit, ADR-0033) |
| 6.3.2 | No default accounts | Met | Realm export has no users; seed users are dev-only scripts; Keycloak admin from env, compose only |
| 6.3.3 | MFA or documented factor combination | Gap | OTP not required (product decision: minors/parents; offer optional OTP for ADMIN/super_admin — follow-up) |

## V7 Session Management (OIDC tokens)
| ID | Requirement | Status | Evidence |
|---|---|---|---|
| 7.2.1 | Token verification in a trusted backend | Met | `quarkus-oidc` bearer validation in every service; `ProblemExceptionMappersTest.anonymousCallOfARoleProtectedResourceIsA401Problem` |
| 7.2.4 | New token on (re-)authentication | Met | Keycloak authorization-code + PKCE flow |
| 7.4.1 | Session unusable after logout/expiry | Partial | Online logout revokes the refresh token and ends the SSO session. **Offline/failed logout keeps the local tokens (F-03, apps/web)** |
| 7.4.2 | Sessions end when an account is disabled | Partial | Keycloak disables the user; the access token stays valid until expiry (short lifetime). Member deactivation removes the membership immediately (`deactivationRevokesTheMembershipButKeepsHistory`) |

## V8 Authorization
| ID | Requirement | Status | Evidence |
|---|---|---|---|
| 8.2.1 | Function-level access control | Met | `@RequiresTenantRole` + role-matrix tests per resource (`Members.roleSetsWithAdminFlag` in core; game/athlete matrices against `docs/domain/authz-matrix.md`) |
| 8.2.2 | Data-level access (IDOR/BOLA) | Partial | RLS + `GenericRlsIsolationTest`/`RlsSchemaMetaTest` (all services, incl. `core.audit_event`); cross-tenant 404 tests (`anotherTenantsMembersAreNotFound` etc.). **Gap F-01**: the game event feed exposes other players' stat events to PARENT/PLAYER |
| 8.3.1 | Enforced at a trusted service layer | Met | Application-layer authz (ArchUnit layering), `TenantHeaderFilterTest`, `/internal` `@RolesAllowed("service")`, `/platform` `super_admin` (`PlatformTenantResourceTest.nonSuperAdminIsForbidden`) |

## V9 / V10 Self-contained tokens, OAuth & OIDC
| ID | Requirement | Status | Evidence |
|---|---|---|---|
| V9 (signature/issuer/exp) | Token integrity and validity checked | Met | `quarkus-oidc` (JWKS, issuer = public URL; `smoke.sh` issuer check in kind) |
| V9 (subject) | Caller identified by the immutable `sub` claim | Met | `CallerSubject` rejects a JWT without `sub` with a 401 (`common MissingSubjectTest`, `core MeWithoutSubjectTest`); realm clients carry the `basic` scope |
| V9 (audience) | Token intended for this service | Gap (accepted) | No `aud` check: a realm token for client `web` is accepted by every service by design (F-14). Follow-up: an audience mapper + `quarkus.oidc.token.audience` |
| V10 (PKCE, public client) | Code flow with PKCE S256, no implicit flow | Met | realm `web` client: public, `pkce.code.challenge.method=S256`, implicit off; Flutter oidc package validates state/nonce (Flutter review) |
| V10 (redirect URIs) | Exact redirect URI allow-list | Met | realm `web` client: explicit URIs (8080, 5173, kind publicUrl rewrite), no wildcards beyond the path |

## V11 / V12 Cryptography and Communication
| ID | Requirement | Status | Evidence |
|---|---|---|---|
| 11.x | Approved algorithms | Met (delegated) | Keycloak RS256 signing keys; SHA-256 logo ETag (non-security use); no custom crypto |
| 12.1.1 / 12.2.1 / 12.2.2 | TLS 1.2+ externally, trusted certs | Partial | Realm `sslRequired: external`; the Gateway's HTTPS listener terminates TLS with a certificate Secret created outside the chart (kind: self-signed `hoops-gateway-tls`, ADR-0031); no production certificate yet. Compose is HTTP on localhost (dev only) |

## V13 Configuration
| ID | Requirement | Status | Evidence |
|---|---|---|---|
| V13 (secrets) | No secrets in code/config; secret management | Met | ADR-0012, gitleaks pre-commit + CI (`ci.yml` `secrets-scan`), no defaults in game/athlete (`NoBuiltInCredentialsTest`), `helm template \| gitleaks` in `deploy/helm/tests/run.sh` |
| V13 (debug/admin surfaces) | No debug or admin endpoints exposed | Met | `/q/**` not routed (smoke check), `/auth/admin` 403 at nginx / the Gateway unless explicitly enabled, `/internal` 403, Keycloak `start` (not `start-dev`) in kind |
| V13 (dependencies) | Components free of known vulnerabilities | Partial | CI: OWASP dependency-check `-Psecurity-scan` (CVSS ≥ 7 fails, suppression file), `trivy fs`, Trivy image scan (HIGH/CRITICAL, ignore-unfixed). The local NVD run was not completed (see WP17 handover) |

## V14 Data Protection
| ID | Requirement | Status | Evidence |
|---|---|---|---|
| 14.2.1 | No sensitive data in URLs | Met | Ids only in paths; search `q` is a name fragment (admin only); tokens only in the `Authorization` header (Flutter review) |
| 14.3.1 | Client storage cleared on session end | Gap | F-03 / F-07: tokens and the drift DB survive a failed logout (apps/web) |
| V14 (minimisation in logs/audit) | No personal data in logs | Met | Audit metadata has field names only (`MemberResourceTest.inviteProvisionsALoginAndSendsTheSetupEmail` asserts no e-mail or name; `patchUsesMergeSemanticsAndKeepsInvariants` asserts no phone); request logging off |

## V15 Secure Coding and Architecture
| ID | Requirement | Status | Evidence |
|---|---|---|---|
| V15 (SBOM/inventory) | Dependency inventory and pinned versions | Partial | Maven BOM-pinned versions, Flutter `pubspec.lock`, pinned image tags (`nginx-unprivileged:1.30-alpine`, Keycloak 26.8.1, mailpit tag). No SBOM is published yet |
| V15 (isolation) | Least-privilege components | Met | Non-owner DB roles, NOBYPASSRLS (`PostgresRlsResourceTest`), non-root read-only containers (chart security assertions), NetworkPolicies |

## V16 Security Logging and Error Handling (all L2)
| ID | Requirement | Status | Evidence |
|---|---|---|---|
| 16.2.1 | when/where/who/what in entries | Met | `core.audit_event` (at, tenant, actor sub + person, action, target); JSON logs with `tenantId`/`traceId` MDC (`TenantHeaderFilterTest.theBoundTenantIsInTheLoggingMdcOfTheRequest`, `TenantContextTest`) |
| 16.2.2 | Synchronised time | Met (platform) | DB `now()` for audit rows; container hosts NTP |
| 16.2.5 | Sensitive data handled in logs | Met | See V14; Problem 500 has no detail (`unexpectedExceptionIs500WithoutAnyDetail`) |
| 16.3.1 | Authentication events logged | Partial (delegated) | Keycloak login events need `eventsEnabled` in the realm (see the realm export / handover); the services log 401s only implicitly |
| 16.3.2 | Failed authorization logged | Gap | 403/404 decisions are not logged as security events (follow-up: a log line in the authz interceptor) |
| 16.3.3 | Security-relevant events (admin actions) | Met | Audit trail for members/roles, approvals, guardian links, tenant lifecycle, profile/settings/logo: `MemberResourceTest`, `GuardianLinkResourceTest`, `PlayerResourceTest`, `ApprovalRequestResourceTest`, `TenantResourceTest`, `TenantLogoResourceTest`, `PlatformTenantResourceTest` |
| 16.3.4 | Unexpected errors logged | Met | `ProblemExceptionMappers.unexpected` logs with traceId |
| 16.4.1 | Log injection prevented | Met | JSON formatter in prod escapes values; audit metadata is jsonb |
| 16.4.2 | Logs protected from modification | Met (DB) / Partial (logs) | `AuditEventRlsTest` (append-only trigger, platform insert-only); container logs depend on the cluster log pipeline |
| 16.4.3 | Logs shipped off-box | Gap | No log shipper/OTel collector deployed yet (OTel off by default; configuration only) |
| 16.5.1 | Generic error messages | Met | `ProblemExceptionMappersTest.unexpectedExceptionIs500WithoutAnyDetail`, 503 without upstream internals |

## Not applicable
V1.5 XML parsers (no XML), V17 WebRTC, GraphQL/SOAP sections of V4, own password storage and recovery (Keycloak),
server-side templating/HTML sanitisation.

## Open gaps summary (→ FOLLOW-UPS.md)
- F-01 game event feed authz (8.2.2) — fixed in WP33 (ADR-0030).
- F-03 / F-07 / F-08 web logout and storage (7.4.1, 14.3.1).
- 6.2.4 password blocklist, 6.2.12 breached passwords, 6.3.3 MFA for privileged roles.
- Token audience (V9).
- 16.3.1 Keycloak events, 16.3.2 authorization-failure logging, 16.4.3 log shipping.
- Production TLS certificates (the Gateway API chart supports them, ADR-0031; none issued); SBOM.
