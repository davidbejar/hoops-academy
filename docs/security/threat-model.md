# Threat model — Hoops Academy (STRIDE per trust boundary)

Version 2026-11-28 (WP148, decisions 119 and 120; first written in WP17, edge updated for the Gateway API in WP36 /
ADR-0031). Scope: the tree of `main` at cc4fb3e2: five services (core, game, athlete in Quarkus; `pdf-service` in Rust;
`finance-service` in Go), `libs/common-quarkus`, `libs/contracts`, the Flutter Web PWA, the Keycloak realm `academy`,
PostgreSQL 19 with RLS (ADR-0073), Redpanda (ADR-0036), the OpenTelemetry collector and the LGTM backend (ADR-0046),
the compose stack, the Helm chart (Envoy Gateway, CloudNativePG) for kind and the cloud, the OpenTofu module, and the
build and supply chain of the product. Companion documents: [`privacy-threat-model.md`](privacy-threat-model.md)
(LINDDUN, same boundary numbers), [`review-2026-11.md`](review-2026-11.md) (findings F-xx / SD-xx),
[`asvs-checklist.md`](asvs-checklist.md) (controls with evidence), and `agentic-threat-model.md` (WP149: the AI agents
that build the product). The method is recorded in ADR-0077 (WP150).

**Method.** STRIDE (Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of
privilege), one table per trust boundary; from PASTA a likelihood-and-impact rating and a few attack chains (decision
120). Each mitigation names the class, test, file or ADR it lives in; every one was looked up on this branch (see
[Verification](#verification)). Findings `TM-xx` are new or still open items; earlier ids (F-, SD-, P-) are referred to,
not issued again.

**Rating.** Likelihood (L) and impact (I) are each Low 1, Medium 2 or High 3; the rating is their product: **6 or 9
High, 3 or 4 Medium, 1 or 2 Low**, written `Medium (L1×I3)`. Likelihood is judged for the project as it is exposed
today: no cloud environment has been applied (`docs/HANDOVER.md`, Pending user action 1); compose publishes every port
on 127.0.0.1 (`infra/compose/compose.yaml`) and kind maps its Gateway to 127.0.0.1:8090 / 8453
(`deploy/kind/kind-config.yaml:12-18`); the internet-facing parts are the public GitHub repository
(`gh repo view --json visibility` → `PUBLIC`), its CI and the images on ghcr.io. So runtime threats are L1. The build
threats (§11) are live today, but each needs an upstream compromise (an official image, a registry, a release) or the
owner's credentials: rare events, so they are L1 too; a first incident of that kind would make them L2 and the
Medium ones High. Impact is judged as if a real academy's data (children, health, money) were in it. "Accepted" marks a residual a decision or ADR accepts; "—" means no residual.

## Assets
| Asset | Why it matters |
|---|---|
| Minors' personal data (names, birth dates, gender, guardian links, contacts) | GDPR special care (children); the main confidentiality asset. Copies: core, the replicas of game / athlete / finance, the compacted `core.*` topics, `core.outbox`, printed rosters |
| Health & fitness data (injuries, measurements, availability) | Health data (GDPR art. 9); schema `athlete` only |
| Finance data (dues, payments, waivers, expenses) | Sensitive family and salary data (ADR-0051: "the same care as health data"); schema `finance` |
| Match statistics, attendance | Integrity (eligibility, rosters, published stats) |
| Tenant isolation | One academy must never see another's data |
| Credentials & tokens | Keycloak users and their tokens; client secrets; DB role passwords (app and migrator); Redpanda SCRAM logins and its superuser; the rate-limit Redis login; the OpenTofu state passphrase; the `GITHUB_TOKEN` and registry login of CI |
| Audit trail (`core.audit_event`, `finance.audit_event`) and security events (`hoops.audit`, `hoops.security` log lines) | Accountability for administrative actions |
| Build artefacts (images on ghcr.io, the chart, the web bundle) | What a deployment runs; a tampered artefact holds every credential above |

## Actors
Anonymous internet user; authenticated member (ADMIN, COACH, ASSISTANT_COACH, PARENT, PLAYER) of a tenant; member of
another tenant; platform `super_admin`; a compromised service pod (with the credentials it holds); any other pod of
the namespace; an operator with `kubectl` or a port-forward; a person with physical access to a shared device; a
compromised dependency, base image or GitHub Action; the owner's GitHub account (the only collaborator); the AI coding
agents that write, test and commit the code (modelled in `agentic-threat-model.md`, WP149, not here).

## Data-flow overview
```
Browser (PWA: localStorage tokens + settings, drift DB, downloaded CSV/PDF)
   │  HTTPS (Gateway :443; kind 127.0.0.1:8453) / HTTP (Gateway :80; kind 127.0.0.1:8090; compose nginx 127.0.0.1:8080)
   ▼
nginx (compose) / Envoy Gateway (chart; rate limits in Redis) ──/auth──▶ Keycloak ──▶ Postgres (keycloak db)
   │  /api/core,/platform  /api/game  /api/athlete  /api/finance   (/internal → 403, /auth/admin → 403, /q/* only health)
   ▼
core ◀──/internal (service token, role `service`)── game, athlete;   core ──/internal/usage──▶ game, athlete
core, game ──/internal/pdf/* (service token, aud pdf-service)──▶ pdf-service   (no route, NetworkPolicy core + game)
core: outbox ──SASL/SCRAM, plaintext──▶ Redpanda (compacted core.* topics) ──▶ replicas in game, athlete, finance
core, game, athlete, finance ──▶ Postgres `hoops` (CloudNativePG; schemas core/game/athlete/finance, RLS, *_app roles)
all five services, Envoy ──OTLP, plaintext──▶ otel-collector ──▶ LGTM (kind, compose profile) / Jaeger (cloud)
GitHub (public repo) ──Actions──▶ ghcr.io images ──▶ chart (kind / cloud via install.sh) ◀── OpenTofu (Alibaba Cloud)
```

## 1. Browser ↔ nginx / Envoy Gateway
| STRIDE | Threat | Mitigations (evidence) | Residual | Rating |
|---|---|---|---|---|
| S | Stolen/forged bearer token | Keycloak-signed JWT validated by `quarkus-oidc` (issuer, signature, expiry) with an audience per service (`quarkus.oidc.token.audience`, core `application.properties:41`; `TokenAudienceKeycloakTest` in core, game, athlete; ADR-0034, F-14 fixed); PKCE S256 public client `web`, direct grants off (`infra/keycloak/realm-academy.json`); 5-minute access tokens (`accessTokenLifespan` 300), refresh rotation with reuse detection (`revokeRefreshToken`, `refreshTokenMaxReuse: 0`, F-08) | Tokens live in browser storage (F-08 residual) | Low (L1×I2) |
| S | Credential stuffing / brute force on login and token endpoint | Keycloak brute-force detection (`bruteForceProtected`, `failureFactor` 5); password policy `length(12) and maxLength(128) and notUsername and notEmail and passwordBlacklist(...)` (realm, ADR-0038); per-IP rate limit on the token endpoint and the login form: nginx `limit_req zone=auth` (`infra/compose/nginx.conf:66-73`), Envoy Gateway global limit 60/min (`charts/keycloak/values.yaml:38`, ADR-0031, ADR-0033); optional TOTP for every login (ADR-0038) | OTP is forced on nobody, the super admin included (ADR-0038 §3): one guessed or phished password opens a COACH's view of a team's health data or the platform API (TM-07) | Medium (L1×I3) |
| T | Tampering with requests (tenant header, ids) | Server-side authz: `TenantHeaderFilter` (membership, else 404), `@RequiresTenantRole` + `Authz` checks, role-matrix tests per resource (oracle `docs/domain/authz-matrix.md`), RLS | — | — |
| T | XSS / script injection into the SPA | CSP `script-src 'self' 'wasm-unsafe-eval'` + one hash, no CDN (`infra/compose/nginx/web-headers.conf`, `deploy/containers/web-nginx.conf:12`; `csp_hashes_test.dart`; F-09 fixed); no HTML sinks in the app; API responses carry `CSP: default-src 'none'`, `nosniff`, CORP (`common-quarkus` `microprofile-config.properties:28-32`) | `style-src 'unsafe-inline'` (Flutter's injected styles); Keycloak pages keep `script-src 'unsafe-inline'` (F-24 residual, accepted) | Low (L1×I2) |
| T | Clickjacking | `X-Frame-Options: DENY` + `frame-ancestors 'none'` at nginx (`web-headers.conf`) and in the services (`microprofile-config.properties:29,31`) | — | — |
| R | User denies an administrative action | `core.audit_event` with actor sub + person (ADR-0017); finance writes audited in `finance.audit_event` (finance `db/migration/V4__audit_event.sql`, append-only trigger); read by the academy ADMIN (super admin masked) and the super admin (ADR-0029) | game and athlete keep no audit trail: a health record's update or delete leaves no trace (P-04); no retention job (P-02) | Low (L1×I2) |
| I | Enumeration of tenants/members via status codes | Non-members get 404 (never 403, CLAUDE.md rule 3); uniform Problem bodies without internals | Invite reveals an existing Keycloak account (F-11) | Accepted (ADR-0025) |
| I | Stale SPA/service worker served after a fix | `Cache-Control: no-cache` for `index.html`, `sw.js`, `flutter_service_worker.js` (`nginx.conf:123-127`) | — | — |
| I | Credentials and tokens read on the wire | TLS at the Gateway's HTTPS listener (`templates/gateway.yaml:90`; kind and cloud set `gateway.tls.enabled: true`, `values-cloud.yaml:22-24`) | The HTTP listener on :80 serves every route, with no redirect and no HSTS (`hsts: ""`), and the cloud security group opens :80 to `0.0.0.0/0` (`infra/tofu/main.tf:21,129`); routes attach to both listeners (`hoops-lib` `_helpers.tpl:29-36`, no `sectionName`). A login over HTTP fails (`sslRequired: external`, secure context for Web Crypto; ADR-0050), so the residual is a first visit open to stripping (TM-06) | Low (L1×I2) |
| D | Flooding `events:batch` / large bodies | per-IP rate limit on `events:batch` (nginx `limit_req zone=events`, `nginx.conf:99-102`; Envoy Gateway 120/min + 20/s, `values.yaml:338-339`); batch ≤ 500 events (`IngestEventBatch.MAX_BATCH`); 2 MB body limit in the Quarkus services (`microprofile-config.properties:25`, F-12), 256 KiB in pdf-service, 64 KiB in finance; nginx `client_max_body_size 10m` | No per-tenant quotas and no general API rate limit (only token, `events:batch`, exports and the academy request are limited); the global limits fail open while Redis or the rate limit service is down (ADR-0033); no body-size limit at the Gateway (accepted) | Low (L1×I1) |
| T | Resetting or inflating the global rate-limit counters in the rate-limit store | NetworkPolicy on the in-chart `ratelimit-redis`; Redis ACL: `default` off, the only user `ratelimit` gets `PING`/`INCRBY`/`EXPIRE` on its keys (`templates/ratelimit-redis.yaml:58-59`, ADR-0033 amendment); `ratelimit-check.sh acl` on kind | Whoever holds the `ratelimit` login can inflate a counter or shorten its TTL; a wrong login makes the gateway fail open | Low (L1×I1) |
| E | Reaching internal or admin surfaces | `/internal/**` → 403 at nginx (`nginx.conf:60`) and at the Gateway (deny route to the web nginx, `charts/web/templates/web.yaml:64-87`); `/auth/admin` and `/auth/realms/master` → 403 unless `HOOPS_EXPOSE_KC_ADMIN=true` / `keycloak.exposeAdminConsole` (`charts/keycloak/values.yaml:46-47`); `/q/**` not routed except four exact health paths (`hoops-lib` `_httproute.tpl:27-52`) | — | — |

## 2. Services ↔ Keycloak
| STRIDE | Threat | Mitigations (evidence) | Residual | Rating |
|---|---|---|---|---|
| S | Service impersonation with a stolen client secret | Secrets from env / K8s Secrets only (ADR-0012); the realm export holds placeholders such as `${CORE_SERVICE_CLIENT_SECRET}` (`realm-academy.json:206,269,319`); no defaults (`NoBuiltInCredentialsTest` in core, game, athlete); gitleaks pre-commit + CI, GitHub push protection on | Secrets are static (no rotation); kind's `secrets.sh` takes `.env` as it is, only `deploy/cloud/install.sh:25` refuses `change-me` | Medium (L1×I3) |
| T | Token/JWKS tampering in transit | In-cluster HTTP to Keycloak (`KEYCLOAK_ADMIN_URL: http://keycloak:8080/auth`, `values.yaml:299`); issuer pinned to the public URL (`KC_HOSTNAME`, `KC_HOSTNAME_BACKCHANNEL_DYNAMIC`, `charts/keycloak/templates/keycloak.yaml:59-61`); pdf-service accepts RS256 only and requires a `kid` (`pdf-service` `crates/adapters/src/auth.rs`), finance RS256 only (`verifier.go:86`) | Cluster-internal HTTP, no mTLS; pdf-service's binary has no TLS stack (`reqwest` without TLS features, `crates/adapters/Cargo.toml:24`); a rotated-out key stays trusted until restart in pdf and finance (keys refetched only for an unknown `kid`) | Low (L1×I2) |
| R | Unattributed user provisioning or logins | `member.invited` audit; Keycloak login and admin events, 30 days (`eventsExpiration` 2592000, `adminEventsEnabled`) | Keycloak trusts `X-Forwarded-*` (`KC_PROXY_HEADERS=xforwarded`, `keycloak.yaml:62`) and the Gateway removes only client `X-Forwarded-Host/-Port` (`templates/gateway.yaml:105-107`): whether a client-chosen `X-Forwarded-For` becomes the IP in Keycloak's events is **to verify** (TM-14); compose nginx overwrites it (`nginx.conf:54`) | Low (L1×I1) |
| I | Over-privileged service account | `core-service` SA holds only `manage-users`/`view-users`; game and athlete hold only realm role `service`; `pdf-service` and `finance-service` clients have no service account (realm export); audiences least-privilege (`core-service` → game, athlete, pdf; `game-service` → core, pdf; `athlete-service` → core) | `manage-users` is realm-wide: core's secret can reset any login's password (see the S row and chain C) | Medium (L1×I3) |
| D | Keycloak outage blocks onboarding | 502 `IDENTITY_PROVIDER_UNAVAILABLE`, nothing committed (saga, `CoreExceptionMappers`); token validation uses cached keys; pdf-service answers 503 when the realm is unreachable (`an_unreachable_realm_is_503`) | — | — |
| E | Admin console exposure | Blocked at nginx / the Gateway (§1 E); the chart runs `start` (`keycloak.yaml:41`), compose `start-dev` (dev only); `sslRequired: external`; bootstrap admin from a Secret (`keycloak.yaml:52-54`) / `.env` (`compose.yaml:60-61`, required) | Any pod of the namespace reaches Keycloak's port, admin console included (Keycloak NetworkPolicy: Gateway namespace + `podSelector: {}`, `keycloak.yaml:255-266`) | Low (L1×I2) |

## 3. game / athlete ↔ core (`/internal`)
| STRIDE | Threat | Mitigations (evidence) | Residual | Rating |
|---|---|---|---|---|
| S | A user token calling `/internal/**` | `@RolesAllowed("service")` on `InternalResource:21`, `InternalRosterResource:31` and the usage resources of game and athlete; the realm role is held by the three service accounts only; audience per service (ADR-0034); `/internal` blocked at the edge | — | — |
| T | Forged tenant id in internal calls | Internal endpoints bind `TenantScope.runAs(tenantId)` → RLS (e.g. game `UsageResource:39`); the authz context comes from core's DB, never from the caller | — | — |
| I | Over-sharing in authz/roster responses | DTOs limited to ids, roles, team ids, display names; the roster carries birth date and gender (P-10) | Since ADR-0037 / ADR-0066 game and athlete read the roster and the authz context from their replica by default with events on (`GAME_ROSTER_SOURCE`, `values.yaml:345`); `/internal` stays the `rest` fallback | Low (L1×I1) |
| D | core outage cascades | 30 s cache (`hoops.core.cache-ttl`), timeouts, 503 `UPSTREAM_UNAVAILABLE` Problems (`common-quarkus` `UpstreamUnavailableException`); readiness stays UP with a `core: unreachable` indicator; in replica mode game and athlete do not call core per request | — | — |
| E | Compromised game pod reads core data | NetworkPolicy of the Quarkus services: Envoy Gateway namespace + every pod of the namespace (`charts/hoops-service/templates/networkpolicy.yaml:15-19`); `service` role reaches `/internal` only | A compromised pod can query any tenant's authz via `/internal` (by design); no egress policy on core, game, athlete (TM-02) | Low (L1×I2) |

## 4. Services ↔ PostgreSQL
| STRIDE | Threat | Mitigations (evidence) | Residual | Rating |
|---|---|---|---|---|
| S | Connecting as owner/superuser | App roles are NON-owner, NOBYPASSRLS (`infra/db/init/01_roles_schemas.sql`; CNPG managed roles `superuser: false`, `bypassrls: false`, `enableSuperuserAccess: false`, `charts/databases/templates/hoops-db.yaml:26,48-55`); `just db-role-check` | Every serving pod also holds its schema's **migrator** password (Flyway / the Go runner migrate at start-up: `CORE_MIGRATOR_PASSWORD` etc. as pod env, `values.yaml:320,356,380`; finance `migratorSecret`, `charts/finance-service/values.yaml:18`); the migrator owns the tables and may turn RLS off or delete audit rows (TM-01) | Medium (L1×I3) |
| T | Cross-tenant writes | `ENABLE`+`FORCE` RLS on every tenant table with `WITH CHECK` on `app.current_tenant()` (`app.enable_tenant_rls`, `01_roles_schemas.sql:39-46`); tenant bound per transaction with `set_config('app.tenant_id', ?, true)` (`TenantTransactions:22`; finance `persistence/tx.go`); `RlsSchemaMetaTest` / `GenericRlsIsolationTest` in every Quarkus service, finance `rls_test.go` (`TestNoTenantReadsOrChangesAnotherTenantsRows`) | Native SQL relies on RLS alone (ADR-0006); an injected statement could call `set_config` itself, so parameterised SQL is the only guard against that (ArchUnit: native SQL only in `*Repository`; Semgrep repo rules; finance pgx `$n`) | Low (L1×I2) |
| T | Rewriting history | `core.audit_event` and `finance.audit_event` append-only triggers; `core_platform` insert-only (`AuditEventRlsTest`) | Migrators can delete (retention, P-02), and serving pods hold them (TM-01) | see TM-01 |
| R | — | Audit trail as above | — | — |
| I | Reading other tenants / SQL injection | RLS; JPQL / parameterised SQL only; `app.current_tenant()` raises when unset (`01_roles_schemas.sql:27-32`) | The databases' NetworkPolicy admits every pod of the namespace (`charts/databases/templates/networkpolicy.yaml:15-16`), so passwords are the only layer; no `sslmode` set by the clients (TLS use **to verify**) (TM-09) | Low (L1×I2) |
| D | Connection exhaustion | Role `connectionLimit` (CNPG, `hoops-db.yaml:55`), pool sizes | core's roster print holds a DB transaction open during the pdf-service call (`PrintTeamRoster.print` is `@Transactional`, up to the 5 s read timeout) (TM-12) | Low (L1×I1) |
| E | Platform role reading tenant content | `core_platform` grants limited to registry/usage/billing/outbox-append/audit-append/login reads (`TenantRegistryRlsTest`, `PlatformUserReadRlsTest`) | — | — |

## 5. Offline device storage (PWA)
| STRIDE | Threat | Mitigations (evidence) | Residual | Rating |
|---|---|---|---|---|
| S | Next user on a shared device inherits the session | Sign-out forgets the tokens locally before the end-session redirect, also offline (`apps/web/lib/app/sign_out.dart`, `sign_out_test.dart`; F-03 fixed); no `offline_access` (F-08) | A user who closes the browser without signing out leaves a session that lasts until the SSO idle timeout (`ssoSessionIdleTimeout` 14400 s) | Low (L1×I2) |
| T | Tampered offline events replayed | Server validates every event (JSON Schema, roster, authz at sync time); UUIDv7 ids, `clientSeq`, `EVENT_ID_REUSED` (game `IngestEventBatch`) | — | — |
| R | Events recorded under another user | Outbox scoped by tenant + person (`match_store.dart`, `match_database.dart`); sync uses the current user's token (`sync_worker.dart`) | — | — |
| I | Cached match data readable by the next user / DevTools | No health data or birth dates cached; the drift DB is wiped on sign-out and when another `sub` signs in (`MatchStore.wipe`, `bindOwner`; `match_store_wipe_test.dart`, `match_owner_test.dart`; F-07 fixed) | Data stays, unencrypted, until the next sign-in when the browser is closed without signing out | Low (L1×I1) |
| I | Tokens readable by injected script | CSP; no XSS sinks found; refresh rotation (`oidc_refresh_rotation_test.dart`) | Tokens in localStorage (F-08 residual) | Low (L1×I2) |
| D | Quota/eviction loses unsynced events | Visible pending counter; sync on reconnect; airplane-mode cold start works (WP54, `tool/offline_cold_start.sh`, run locally only) | Eviction by the browser is not handled beyond the counter | Low (L1×I1) |

## 6. Admin uploads (tenant logo)
| STRIDE | Threat | Mitigations (evidence) | Residual | Rating |
|---|---|---|---|---|
| S | Non-admin upload | ADMIN only (`TenantLogoResourceTest.everyMemberReadsOnlyAdminsWrite`) | — | — |
| T | Polyglot/SVG with script, content-type spoofing | Magic-byte detection PNG/JPEG/WebP only (`core` `domain/logo/ImageFormat`, `LogoImage`); SVG/GIF → 415; stored type = detected type; served with `nosniff`, `CSP default-src 'none'`, `CORP same-origin` | Image parsers in browsers (decoding bugs) | Low (L1×I1) |
| R | Who changed the logo | `tenant.logo_replaced` / `tenant.logo_removed` audit (`AuditAction`, `TenantLogoService`) | — | — |
| I | Logo of another tenant | RLS + tenant header (`TenantLogoResourceTest.anotherTenantsLogoIsNotFound`) | EXIF metadata served unchanged (privacy model §6) | Low (L1×I1) |
| D | Oversized uploads | 512 KB domain limit (`TenantLogoResource:73-75`, 413 `LOGO_TOO_LARGE`); 2 MB HTTP limit (413 `REQUEST_TOO_LARGE`); nginx 10 MB | Stored in Postgres (ADR-0009) | Low (L1×I1) |
| E | — | No server-side image processing (no decoder attack surface) | — | — |

## 7. core → Redpanda → replicas (roster events)
The roster replicas of game, athlete and finance (ADR-0036, ADR-0037, ADR-0062) feed their authorisation: in replica
mode the membership comes from `person_ref` (`ReplicaAuthzResolver` in game and athlete; finance `ResolveMembership`).

| STRIDE | Threat | Mitigations (evidence) | Residual | Rating |
|---|---|---|---|---|
| S | A client connects as another service or anonymously | Chart: listener `authentication_method: sasl` (`templates/redpanda.yaml:38`), SCRAM per service (`values.yaml:143-147`), `kafka_enable_authorization: true`, `admin_api_require_auth: true` (`values.yaml:134-135`); NetworkPolicy admits Kafka only from the four users' pods and the bootstrap Job, the admin API only from the Job (`redpanda.yaml:171-207`) | Compose's broker runs without auth (`--mode=dev-container`, published on 127.0.0.1 only); the NetworkPolicy trusts the `app.kubernetes.io/name` label of any pod in the namespace; the Quarkus clients default to an empty SASL password (`KAFKA_SASL_PASSWORD:` in core `application.properties:107`) | Low (L1×I2) |
| T | A consumer login, or a pod holding one, writes forged roster events | Prefixed ACLs: `core-service` produce on `core.`; game, athlete, finance consume on `core.` and their own groups only (`values.yaml:144-147`, `files/redpanda-bootstrap.sh`) | Proven by the rendered ConfigMap only (`deploy/helm/tests/run.sh`); no test tries a produce with a consumer login (**to verify** on kind) | Low (L1×I2) |
| T | Forged or malformed events reach a replica | JSON Schema 2020-12 from the contracts (`additionalProperties: false`); the key must equal `<tenantId>:<aggregateId>` of the envelope, a tenant event's aggregate must be its tenant (`CoreEventDecoder:84-107`; finance `decode.go`); invalid records parked (`CoreRosterConsumerTest.aRecordWhoseKeyNamesAnotherTenantIsParkedAndNeverApplied`); `applied_event` makes apply idempotent; upserts only when `occurred_at <= excluded.occurred_at` (`JdbcRosterReplicaRepository:213`) | The checks prove self-consistency, not origin: whoever holds core's SCRAM login can write any tenant's roster and so grant roles in the replicas (no signature; accepted, core is the source of truth and its login sits in core's pod); a far-future `occurredAt` would freeze a row | Low (L1×I2) |
| T | Kafka traffic read or altered on the pod network | — | `SASL_PLAINTEXT` (`hoops-lib` `_env.tpl:9`; finance supports no TLS): names, birth dates, gender and `sub` cross the pod network in clear | Accepted (ADR-0036 §7) |
| R | Evidence of rejected events removed | Parked records logged at WARN (`ReplicaConsumer.park`) and stored in `parked_event` | game and athlete app roles may `DELETE` parked rows (game `V6__replica_housekeeping.sql:66`) although ADR-0037 §4 says insert only (finance revokes it) | Low (L1×I1) |
| I | Personal data kept in the broker | Topics per aggregate, compacted, tombstones 7 days (`values.yaml:152-156`); finance drops birth date and gender on decode (P-10) | `retention.ms=-1`: the latest state per person stays until a removal that no use case emits (P-01) | Low (L1×I2) |
| D | A poison record stops a consumer | Contract violations are parked, not retried | A record that passes the schema but fails mapping stops the channel (`failure-strategy=fail`, `CoreEventDecoderTest.anyOtherMapperFailureIsABugAndIsNotParked`): replicas go stale (needs a core bug) | Low (L1×I1) |
| E | A replica grants more than core | The same membership rule in common (`MembershipRule`, ADR-0066); finance reads only ACTIVE tenants and active members (`persistence/stores.go`) | A removed member keeps access until the event is applied (seconds; longer while a consumer is down) | Low (L1×I1) |

## 8. Services → OpenTelemetry collector → log and trace backend
| STRIDE | Threat | Mitigations (evidence) | Residual | Rating |
|---|---|---|---|---|
| S | A pod sends telemetry as another service | Collector NetworkPolicy admits the five services' pods and the Envoy proxies only (`templates/observability.yaml:204-273`; `observability.clients`, `values.yaml:229`) | OTLP receivers on 4317/4318 have no TLS and no auth (`observability.yaml:70-74`); any admitted pod can write lines that look like another service's `hoops.audit` / `hoops.security` events (the database audit trail stays the record) | Low (L1×I1) |
| T | Telemetry altered between collector and backend | In-namespace only | Exporters use `tls: insecure: true` (`observability.yaml:45,48`) | Low (L1×I1) |
| R | — | `hoops.audit` lines mirror `core.audit_event` (`AuditEventRepository`); security events (`SecurityEventLog`, ADR-0043) | — | — |
| I | Tokens, bodies or personal data in logs and spans | HTTP access log off (`microprofile-config.properties:44`); OIDC's token-quoting WARN muted (`:59`); database spans without bound values (`DatabaseSpansTest` in core, game, athlete; finance `telemetry/database.go`, ADR-0074); pdf-service logs nothing of a body (`nothing_of_the_body_reaches_a_log_line_or_a_span`); trace attributes `url.*` and Kafka keys deleted (`attributes/strip-ids`) | `strip-ids` runs in the traces pipeline only; the logs pipeline has `memory_limiter` and `batch` (`observability.yaml:111-119`), so logs carry `sub`, tenant ids and, for an unmatched route, the concrete path (P-07); Grafana is an anonymous Viewer with `GF_USERS_VIEWERS_CAN_EDIT=true` (`observability.yaml:401-405`): whoever reaches its port reads every tenant's logs (ClusterIP, port-forward; compose 127.0.0.1:3000) (TM-10) | Low (L1×I2) |
| D | Flooding the collector | `memory_limiter` (refuses data, never the services' requests); OTLP export is asynchronous | Telemetry lost under load | Low (L1×I1) |
| E | — | The collector holds no token; it scrapes `/q/metrics` only (ADR-0046 amendment) | `/q/metrics` of the Quarkus services is open to every pod of the namespace | Low (L1×I1) |

## 9. core / game → `pdf-service`
| STRIDE | Threat | Mitigations (evidence) | Residual | Rating |
|---|---|---|---|---|
| S | A browser or another pod calls the renderer | No HTTPRoute (`charts/pdf-service`); NetworkPolicy admits core and game only, egress DNS, Keycloak and the collector (`charts/pdf-service/values.yaml:25-34`, `hoops-lib.networkPolicy`); RS256 JWT with audience `pdf-service`, `exp`, `nbf`, leeway 0 (`auth.rs:25`, ADR-0064), realm role `service` else 403; tests `a_web_client_token_is_refused`, `a_token_for_pdf_service_without_the_service_role_is_403` (`crates/adapters/tests/api/http.rs:77,125`); compose on 127.0.0.1:8084 | core's one client-credentials token carries the audiences game, athlete and pdf, so a service that receives it can replay it to pdf-service (pdf trusts every service alike) | Low (L1×I1) |
| T | Crafted input changes the document or the process | `deny_unknown_fields`; text length limits, control characters refused (`domain/src/text.rs`); fixed layout with bundled fonts, no caller markup, links, images or URLs (`the_pdf_carries_no_link_no_script_and_no_creation_date`); `unsafe_code = "forbid"` (`Cargo.toml:27`); callers check the `%PDF-` magic bytes (`PdfServiceClients`) | — | — |
| R | Who printed a roster | core audits `team.roster_exported` with the format (`PrintTeamRoster.print` → `ExportTeamRoster.exported`) | game's match sheet is not audited (game has no audit trail, P-04) | Low (L1×I1) |
| I | Request bodies (minors' names, guardians' contacts) in logs or Problems | Access log with method, route, status, duration only; Problems name the field path and a code, never a value (P-11 mitigated); responses `no-store`, `nosniff` | A printed roster carries guardians' contacts and cannot be recalled (decision 83) | Low (L1×I2) |
| D | Large or many renders exhaust the renderer or its callers | Body ≤ 256 KiB (`http.rs:28`); row limits → 422 (`MAX_PLAYERS` 60, `domain/src/team_roster.rs:16`); renders bounded by a semaphore of CPU count (`http.rs:44`); callers' read timeouts 5 s (core) / 10 s (game); the roster export path is rate-limited at the edge | No render timeout and no bound on the queue behind the semaphore; no CPU limit in the chart; core holds a DB transaction during the call (TM-12) | Low (L1×I1) |
| E | Escape from the renderer | Distroless `cc-debian13:nonroot` pinned by digest, `USER 65532`, read-only root FS, all capabilities dropped (`pdf.Containerfile`, chart securityContext); no database, broker or outbound network | — | — |

## 10. Browser ↔ `finance-service`
| STRIDE | Threat | Mitigations (evidence) | Residual | Rating |
|---|---|---|---|---|
| S | Forged or foreign token | golang-jwt with RS256 only, issuer, expiry required, leeway 0, audience `finance-service`, non-empty `sub` (`internal/adapters/in/oidc/verifier.go:86-101`); only `web` carries that audience (realm) | No `azp` check (no other client has the audience) | Low (L1×I1) |
| T | Cross-tenant reads or writes | `X-Tenant-Id` required; membership from finance's own replica, active member of an ACTIVE tenant, else 404 (`rest/handler.go`, `application/finance.go`); `finance_app` non-owner, NOBYPASSRLS, FORCE RLS on every tenant table, tenant bound per transaction (`persistence/tx.go`); `TestCrossTenantAccessThroughTheAPIIsRefused`, `rls_test.go` | — | — |
| T | Tampered amounts, CSV injection | Amounts 1..10^11 minor units (`domain/money.go`), ISO currency; pgx `$n` parameters; CSV formula guard (`export/csv.go`, `TestTheFormulaGuardPrefixesDangerousTextButNotNumbers`) | — | — |
| R | A treasurer denies a waiver or a voided payment | Every write audited in `finance.audit_event`, append-only trigger except for `finance_migrator` (`db/migration/V4__audit_event.sql`) | The serving process holds the migrator password (TM-01) | see TM-01 |
| I | A role sees more than decision 96 allows | ADMIN manages; a current COACH of the team reads status only; PARENT linked and PLAYER self read their dues; ASSISTANT_COACH nothing (`domain/access.go`); `TestRoleMatrixOfDuesPaymentsAndTheReads`, `TestRoleMatrixOfSettingsAndFeePlans`, `TestRoleMatrixOfExpensesBalanceAndExports`; responses `no-store`, `nosniff`, CSP `default-src 'none'` (`handler.go`) | The coach learns which families are behind (by design, P-12) | Accepted (decision 96) |
| D | Flooding | Body ≤ 64 KiB, paging 1..200, server timeouts (`cmd/finance-service/main.go:100-105`); exports rate-limited at the Gateway (`charts/finance-service/values.yaml:44-45`) and in nginx (`nginx.conf:113-116`), 10,000 rows | No general rate limit on `/api/finance/**` (as for the other APIs) | Low (L1×I1) |
| E | A member acts as ADMIN | Writes, lists and exports behind `asAdmin` (`application/finance.go`); distroless `static-debian13:nonroot` by digest, `USER 65532`; `gosec` in golangci-lint, `govulncheck` (`scripts/check.sh`) | — | — |

## 11. Build and supply chain of the product
The AI agents that write and commit the code are an actor here; their own threats (prompt injection, tool misuse,
permissions of the sessions) are modelled in `agentic-threat-model.md` (WP149). Repository settings were read on
2026-11-28 with `gh api repos/davidbejar/hoops-academy/...` (output quoted in the rows).

| STRIDE | Threat | Mitigations (evidence) | Residual | Rating |
|---|---|---|---|---|
| S | Someone pushes to `main` as the owner, or merges unreviewed code | One collaborator (`.../collaborators`); gitleaks and the tenancy hook run locally (`.pre-commit-config.yaml`, `.claude/settings.json` → `.claude/hooks/tenancy-gate.sh`) | `main` has no protection and no ruleset (`.../branches/main/protection` → `Branch not protected`, `.../rulesets` → `[]`); `images.yml` builds and pushes to ghcr.io on every push to `main` that touches service, library, web or image paths, without waiting for `ci`, `codeql` or `semgrep` (`.github/workflows/images.yml:15-19,59`; repository variable `IMAGE_REGISTRY` = `ghcr.io/davidbejar/hoops-academy`, `.../actions/variables`) (TM-03) | Medium (L1×I3) |
| T | A hijacked GitHub Action runs in CI | Every third-party `uses:` is a 40-character SHA (`grep -rhn "uses:" .github \| grep -vE "@[0-9a-f]{40}\|uses: \./"` prints nothing); top-level `permissions: contents: read` in every workflow; write scopes per job only (`packages: write` in `images.yml`, `pages`/`id-token` in `pages.yml`, `security-events` in CodeQL and Semgrep, `contents`/`pull-requests` in `bump-pins.yml`); no `pull_request_target` or `workflow_run`; fork PRs of first-time contributors need approval (`.../actions/permissions/fork-pr-contributor-approval` → `first_time_contributors`); Dependabot with a 7-day cooldown (SD-07) | `allowed_actions: all`, `sha_pinning_required: false` (`.../actions/permissions`); checkouts in the `packages: write` jobs keep the persisted token (only `bump-pins`, `codeql`, `semgrep` set `persist-credentials: false`) | Low (L1×I2) |
| T | A compromised dependency (Maven, Cargo, Go modules, pub) | Lock files committed (`Cargo.lock` + `--locked`, `go.sum` + `go mod verify`, `pubspec.lock`); `cargo deny` (crates.io only, `yanked = "deny"`), `govulncheck`, OWASP dependency-check `failBuildOnCVSS 7` (`pom.xml:298-304`), Trivy fs, CodeQL (java, rust, go) and Semgrep gating; Dependabot for all six ecosystems with a cooldown | The Maven wrapper has no `distributionSha256Sum` (`.mvn/wrapper/maven-wrapper.properties`); no checksum policy or enforcer in Maven; `flutter pub get` without `--enforce-lockfile` in `images.yml:77`; Semgrep registry rules fetched unpinned (TM-05) | Medium (L1×I3) |
| T | A tampered base image, tool or platform install | Runtime bases of the five services pinned by digest, distroless, non-root (`service.Containerfile:20`, `pdf.Containerfile:14`, `finance.Containerfile:15`); CI tools checked by SHA-256 (`ci.yml`, `setup-*` actions); Reloader, kind node, Redpanda, collector, LGTM, Jaeger by digest (ADR-0068, `deploy/lib/platform.sh`); k3s by SHA-256 (`infra/tofu/main.tf`) | Floating or tag-only: the Maven builder `maven:3-eclipse-temurin-25` that builds the shipped jars (`service.Containerfile:15`), `nginx-unprivileged:1.30-alpine` + `apk upgrade` (`web.Containerfile:12,38-46`), Flutter `channel: stable` (`setup-flutter/action.yml:10`), Trivy `0.76.2` (`image-publish/action.yml:42`), Keycloak `26.8.2`, CNPG `postgresql:19.0-minimal-trixie`, Redis, Mailpit in the chart; the CNPG operator applied from a branch URL with no checksum (`deploy/lib/platform.sh:14,61`); Envoy Gateway and ESO charts by version only (TM-04) | Medium (L1×I3) |
| T | An image on ghcr.io is replaced after the build | Images tagged with the 40-character commit SHA (`image-publish/action.yml:83-84`, `deploy/cloud/install.sh`); Trivy fails on fixable HIGH/CRITICAL; CycloneDX SBOMs attached as ORAS referrers (ADR-0043) | No signature or provenance (no cosign or attestation anywhere); the chart deploys by tag, not digest (`hoops-lib` `_helpers.tpl:25`) (TM-08) | Medium (L1×I3) |
| R | A change cannot be traced to a reviewed commit | Conventional Commits; `Co-Authored-By` lines name the model | No signed-commit requirement; no CODEOWNERS; no `SECURITY.md` for reporters of a vulnerability in a public repository (TM-13) | Low (L1×I1) |
| I | A secret is committed | gitleaks pre-commit (`v8.30.0`) and in CI over the full history (`ci.yml:18-25`); GitHub secret scanning and push protection on (`gh api repos/davidbejar/hoops-academy` → `secret_scanning_push_protection: enabled`); placeholders only in `.env.example` | `.gitleaks.toml:9-11` allow-lists every `docs/**/*.md` and `.claude/skills/**`, the files agents write most (TM-11); GitHub's non-provider patterns are off | Low (L1×I2) |
| I | The OpenTofu state leaks cloud credentials | State encrypted (pbkdf2 + AES-GCM, `enforced = true`, `infra/tofu/versions.tf:17-35`), passphrase `sensitive`, ≥ 16 characters; `*.tfstate*`, `*.tfvars` git-ignored; Alibaba keys from env only; provider lock file committed | State is local (no backend): its only copy is the owner's disk | Low (L1×I1) |
| D | CI or the registry is unavailable | Concurrency groups cancel superseded PR runs | — | — |
| E | A workflow token does more than its job | Default workflow permissions `read` (`.../actions/permissions/workflow`); `bump-pins.yml` opens a PR, never pushes to `main` | `can_approve_pull_request_reviews: true` (needed by `bump-pins`) lets a workflow approve PRs; `bump-pins` fetches the ESO CRDs without a checksum inside its `contents: write` job (`deploy/helm/tests/schemas/update-eso.sh:15`) | Low (L1×I2) |

## Attack chains
Each chain is a path across the boundaries above, with the control that breaks each step. **No control** marks the
step where nothing stands today.

**A. A coach's password → a team's health records (minors' and health data).**
1. Guess or phish the password of a COACH (§1 S). Broken by: brute-force detection after 5 failures, the 60/min
   per-IP limit, the password policy and blocklist. Phishing is not broken: **no control** forces a second factor
   (ADR-0038, TM-07).
2. Sign in from anywhere (§1 S). Nothing breaks it; the login is valid.
3. Read the health records of the team's players (`HealthAccess`). Bounded by the role: only the coach's own teams,
   never another academy (RLS, `TenantHeaderFilter`).
4. Copy them out (§1 D). Paging ≤ 200; health has no bulk export. Slows, does not stop.
5. Go unnoticed. **No control**: athlete keeps no read or write audit (P-04); the only trace is Keycloak's login event
   (30 days).

**B. One academy reads another (tenant isolation).**
1. Become an ADMIN of academy A: request an academy (public form, rate-limited 10/min) and have it approved by the
   super admin. Broken only by the super admin's judgement.
2. Create a login for an address you do not own and set its password (F-22). **No control**: accepted by design
   (ADR-0025).
3. Wait for academy B to invite that address: B's invitation links the existing login (F-11, accepted). You enter B as
   that person and read what that person may read there (a parent's linked children, with their health records).
4. Try to go beyond that person's rights in B: broken by `@RequiresTenantRole`, `Authz`, `HealthAccess` and RLS
   (role-matrix tests, `GenericRlsIsolationTest`).
5. Try to reach a third academy: broken by membership (404) and RLS.

   A variant without a person: an RCE in any service pod (§3 E) reads its schema's migrator password from the pod's
   environment (TM-01), connects as the table owner, turns `FORCE ROW LEVEL SECURITY` off and reads every academy of
   that schema; egress to the internet is open for core, game and athlete (TM-02). Only the absence of a known RCE
   stands before the first step (dependency gates, §11).

**C. One secret → every login (credentials).**
1. Obtain core's client secret: from a leaked `.env` (git-ignored; gitleaks, push protection), from a docs page
   (**no control**: gitleaks skips `docs/**/*.md`, TM-11), or from core's pod environment.
2. Get a token with `manage-users` and reset any login's password through the Admin API (§2 I). **No control** inside
   Keycloak (the role is realm-wide); the path needs a foothold in the cluster (Keycloak's NetworkPolicy, admin paths
   blocked at the edge).
3. Sign in as any member, the super admin included (no enforced OTP, TM-07).
4. Act as them: every academy that login belongs to. **No control** tells the attacker from the person: the audit rows
   name the impersonated login; only Keycloak's admin events show the password reset.

**D. A poisoned build → every academy (supply chain).**
1. Get code onto `main`: a hijacked dependency release (7-day cooldown, lock files, CVE gates), a floating base image
   or tool (TM-04, TM-05), or a push with the owner's credentials. **No control** on `main` itself: no branch
   protection or required checks (TM-03).
2. `images.yml` builds the image of every changed service and pushes it to ghcr.io (the registry variable is set)
   without waiting for the security workflows (TM-03). Trivy blocks known CVEs only.
3. A deployment pulls the image by tag (TM-08). **No control**: no signature or digest is checked.
4. The image runs with the service's app and migrator passwords, its broker login and client secret (TM-01): every
   academy's data in its schema.

## Findings
Only what was verified on this branch; an item that needs a live check says "to verify". Nothing was fixed (wave 2
fixes High and Medium). Ratings as defined at the top. Each finding says whether it is **new** or already **tracked**
(where); `docs/wp/FOLLOW-UPS.md` and the ADRs were searched for each.

| ID | Rating | Finding | Evidence | Proposed fix (work item) |
|---|---|---|---|---|
| TM-01 | Medium (L1×I3) | **New.** Every serving pod holds its schema's migrator password, so a compromised process can act as the table owner: turn RLS off, read every tenant, delete audit rows | `deploy/helm/hoops/values.yaml:320,356,380` (`*_MIGRATOR_PASSWORD` as pod env for core, game, athlete); `charts/finance-service/values.yaml:18` (`migratorSecret`); `services/core-service/src/main/resources/application.properties:28` (`quarkus.flyway.password`); finance `cmd/finance-service/main.go:1-2` ("migrates the schema as finance_migrator") | Run migrations in a separate Job or init container that alone mounts the migrator Secret; serving containers get only `*_app`; a chart test that no serving container references a migrator Secret; extend `just db-role-check` |
| TM-02 | Medium (L1×I3) | **New.** core, game, athlete and Keycloak have no egress NetworkPolicy: a compromised pod reaches the internet and every service in the cluster | `charts/hoops-service/templates/networkpolicy.yaml:13`, `charts/keycloak/templates/keycloak.yaml:258` (`policyTypes: [Ingress]`); pdf and finance do limit egress (`hoops-lib` `_networkpolicy.tpl:23,38-62`) | Use `hoops-lib.networkPolicy` for the Quarkus services with egress to DNS, Postgres, Keycloak, Redpanda, the collector, the peers they call (and SMTP for core); the same for Keycloak; chart tests |
| TM-03 | Medium (L1×I3) | **New.** `main` is unprotected, and images are built and pushed to ghcr.io from pushes to `main` without the security gates | `gh api repos/davidbejar/hoops-academy/branches/main/protection` → `Branch not protected` (HTTP 404); `.../rulesets` → `[]`; `.github/workflows/images.yml:15-19,59` (push to `main` with a path filter; push when `IMAGE_REGISTRY` is set, which it is: `.../actions/variables`; no dependency on `ci` / `codeql` / `semgrep`) | A ruleset on `main` (no force push, no deletion, required checks `ci`, `codeql`, `semgrep`); `images.yml` triggered by a successful `ci` run on `main` (`workflow_run`, checked head SHA) or a gate job |
| TM-04 | Medium (L1×I3) | **Partly tracked** (FOLLOW-UPS, cloud slice limits: "the Envoy Gateway chart and the CNPG manifest pinned by version, not digest"; `docs/runbooks/release.md` "Pins and bumps" names the floating ones). Build images, tools and platform installs that are not pinned by digest or checksum | `deploy/containers/service.Containerfile:15` (`maven:3-eclipse-temurin-25`); `web.Containerfile:12,38-46`; `.github/actions/setup-flutter/action.yml:10` (`channel: stable`); `.github/actions/image-publish/action.yml:42` (`aquasec/trivy:0.76.2`); `charts/keycloak/values.yaml:4`, `charts/databases/values.yaml:4`; `deploy/lib/platform.sh:14,61` (CNPG from branch `release-1.30`, no checksum); Envoy Gateway `--version v1.10.0`, ESO `--version 2.15.0` | Pin the remaining images by digest and add them to `scripts/bump-pins.sh`; Flutter by version + SHA; the CNPG manifest from the release tag with a SHA-256 check; OCI charts by digest |
| TM-05 | Medium (L1×I3) | **New**, except the Semgrep part (FOLLOW-UPS "SAST drift"). Gaps in dependency integrity: Maven wrapper without checksum, no Maven checksum policy, pub not held to the lock file in the image build, Semgrep rules unpinned | `.mvn/wrapper/maven-wrapper.properties` (no `distributionSha256Sum`); no `checksumPolicy` or enforcer in `pom.xml`; `.github/workflows/images.yml:77` (`flutter pub get`); `.github/workflows/semgrep.yml:3-5` (registry rulesets `p/...`) | `distributionSha256Sum` in the wrapper properties; strict checksums (`-C`) in `.mvn/maven.config`; `flutter pub get --enforce-lockfile` everywhere; Semgrep rules vendored or pinned by version |
| TM-06 | Low (L1×I2) | **Tracked** (FOLLOW-UPS cloud slice limits "no HTTP-to-HTTPS redirect"; `docs/runbooks/cloud.md:143`; ADR-0050 "No HSTS"). With TLS on, the Gateway's plain HTTP listener still serves every route (no redirect, HSTS empty) and the cloud opens port 80 to the internet; logins over HTTP fail (`sslRequired: external`), so a user's first plain-HTTP visit can be stripped or served a forged page | `deploy/helm/hoops/templates/gateway.yaml:84-90`; `charts/hoops-lib/templates/_helpers.tpl:29-36` (parentRefs without `sectionName`); `values-cloud.yaml:22-25` (`hsts: ""`); `infra/tofu/main.tf:21,129` | An HTTP→HTTPS `RequestRedirect` route on the `http` listener and every app route on `https` only when TLS is on; HSTS once a real certificate exists (cert-manager slice); chart test |
| TM-07 | Medium (L1×I3) | **Accepted by decision 39** (ADR-0038; FOLLOW-UPS "ASVS gaps left": 6.3.3 Partial), listed to revisit: an owner decision, not a fix for wave 2 without one. No second factor is required for anyone, the super admin and academy ADMINs included | `docs/adr/0038-keycloak-csp-password-blocklist-optional-otp.md` §3 ("Nobody is forced, the super admin included"); the realm keeps the built-in conditional OTP flow and lists no required actions | Revisit decision 39: require OTP for `super_admin` (and optionally ADMIN) through a conditional flow on the role; a Keycloak test; ADR-0038 amendment |
| TM-08 | Medium (L1×I3) | **Tracked, open** (ADR-0043: "No signed attestation ... left open"; `docs/runbooks/release.md`). Images are neither signed nor attested, and the chart deploys by tag | `grep -rn "cosign\|attest\|slsa" .github deploy scripts` prints nothing; `charts/hoops-lib/templates/_helpers.tpl:25` (`repository:tag`) | Keyless cosign signing and an SBOM / provenance attestation in `images.yml` (`id-token: write`); `install.sh` resolves and deploys by digest and verifies the signature |
| TM-09 | Low (L1×I2) | **New.** Postgres accepts connections from every pod of the namespace, and no client sets `sslmode`; whether connections use TLS is to verify | `charts/databases/templates/networkpolicy.yaml:15-16` (`podSelector: {}`); `values.yaml:297` (`jdbc:postgresql://hoops-db-rw:5432/hoops`); `charts/finance-service/values.yaml:16` | Admit only the service pods and the operator; `sslmode=verify-full` with the CNPG CA once checked on kind |
| TM-10 | Low (L1×I2) | **New** (the log content joins P-07). Logs skip the collector's id stripping, and Grafana gives every anonymous viewer edit (Explore) rights | `templates/observability.yaml:111-119` (logs pipeline without `attributes/strip-ids`), `:401-405` (`GF_AUTH_ANONYMOUS_ENABLED`, `GF_USERS_VIEWERS_CAN_EDIT=true`) | Decide which log attributes are needed (joins P-07); `GF_USERS_VIEWERS_CAN_EDIT=false` unless Explore is needed; state in ADR-0046 that Grafana is dev only |
| TM-11 | Low (L1×I2) | **New.** gitleaks skips every Markdown file under `docs/` and every skill file | `.gitleaks.toml:9-11` | Drop the blanket allow-list; allow the few known fake values by regex or fingerprint (`.gitleaksignore`) |
| TM-12 | Low (L1×I1) | **New.** pdf-service has no render timeout or queue bound, and core holds a DB transaction open during the call | `services/pdf-service/crates/adapters/src/http.rs:44` (semaphore, no timeout); core `PrintTeamRoster.print` (`@Transactional` around `printer.print`) | A render timeout and a bounded wait (503 when full) in pdf-service; core gathers the roster in one transaction, calls pdf-service outside it, audits in a second |
| TM-13 | Low (L1×I1) | **New.** No `SECURITY.md`, CODEOWNERS or signed-commit requirement in a public repository | `find . -path ./.venv-docs -prune -o \( -name SECURITY.md -o -name CODEOWNERS \) -print` prints nothing | A `SECURITY.md` with a private reporting channel (GitHub private vulnerability reporting); CODEOWNERS when a second maintainer joins |
| TM-14 | Low (L1×I1), to verify | **New.** A client-chosen `X-Forwarded-For` may become the IP in Keycloak's events behind the Gateway | `charts/keycloak/templates/keycloak.yaml:62` (`KC_PROXY_HEADERS=xforwarded`); `templates/gateway.yaml:105-107` (only `X-Forwarded-Host/-Port` removed) | On kind, sign in with a forged `X-Forwarded-For` and read the event; if it shows, set the client IP at the Gateway (`clientIPDetection`) and overwrite the header |

**Counts:** High 0 · Medium 7 · Low 7 (14 findings, one of them to verify; TM-07 is an accepted decision listed to revisit). Referred to and not issued again: F-08,
F-11, F-22, F-24 (review), P-01, P-02, P-04, P-07, P-10, P-12 (privacy model).

**To verify** (not rated): that a consumer's SCRAM login is refused a produce on `core.*` on kind (§7); whether the
JSON Schema error messages, logged and stored as the parked reason, ever quote a value (§7); whether kind's CNI and
k3s enforce NetworkPolicy (every NetworkPolicy row assumes it); whether a ghcr.io tag of the images can be overwritten
by a later workflow run (§11); Envoy's edge-span attributes (client address, user agent) in traces (§8).

## Out of scope / assumptions
TLS certificates in production (the Gateway's HTTPS listener uses a Secret created outside the chart; kind and the
cloud script create a self-signed one); backup encryption; Keycloak server hardening beyond the realm export; DDoS
beyond per-IP rate limits; email deliverability (SPF/DKIM); the AI agents that build the product
(`agentic-threat-model.md`); personal-data threats (LINDDUN, [`privacy-threat-model.md`](privacy-threat-model.md)).

## Verification
Looked up on branch `wp148-stride-threat-model-refresh` (base cc4fb3e2) on 2026-11-28: compose
(`infra/compose/compose.yaml`, `nginx.conf`, `nginx/*.conf`), the chart (`deploy/helm/hoops/values*.yaml`,
`templates/gateway.yaml`, `observability.yaml`, `redpanda.yaml`, `ratelimit-redis.yaml`, the sub-charts' NetworkPolicies,
routes and values, the `hoops-lib` templates), `infra/db/init/01_roles_schemas.sql`, the realm export, every service's
configuration, the classes and tests named in the rows, `.github/workflows/*`, `.github/actions/*`, the Containerfiles,
`deploy/lib/platform.sh`, `deploy/kind/kind-config.yaml`, `infra/tofu/*.tf`, `.gitleaks.toml`,
`.mvn/wrapper/maven-wrapper.properties`. Every backticked file, class, test and setting name in this document was then
checked mechanically against the tree (`git ls-files`, `git grep`, class + method for `Class.method` names); what does
not match is GitHub API output, a proposed name in a fix, or a glob. Repository settings by `gh api` on 2026-11-28
(they describe GitHub, not the tree). No test was run: this document changes no code.
