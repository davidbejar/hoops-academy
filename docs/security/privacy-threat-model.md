# Privacy threat model — Hoops Academy (LINDDUN per trust boundary)

Version 2026-11-28 (WP150, decisions 119–122; first version 2026-11-15, WP112, decision 102). Companion to
[`threat-model.md`](threat-model.md) (STRIDE: same assets, actors, data-flow overview and trust boundaries, the same
boundary numbers), [`review-2026-11.md`](review-2026-11.md) (security findings F-xx / SD-xx) and
[`asvs-checklist.md`](asvs-checklist.md); the build system has its own model (`agentic-threat-model.md`, MAESTRO).
Method and rating: [ADR-0077](../adr/0077-threat-modelling-methods.md). Scope: the tree of `main` at 8eec8325 for §1–§8
(core, game, athlete, `libs/common-quarkus`, `libs/contracts`, `apps/web`, the realm export, compose and the chart),
and at cc4fb3e2 for §9 and §10 (`pdf-service`, `finance-service`, both built since the eighth round,
[ADR-0051](../adr/0051-polyglot-services-finance-in-go-pdf-renderer-in-rust.md)), for the tenth round's changes
(PostgreSQL 19, [ADR-0073](../adr/0073-postgresql-19.md); database spans,
[ADR-0074](../adr/0074-database-spans-in-the-services-traces.md)) and for the rows corrected in WP150 (see
[Status after the tenth round](#status-after-the-tenth-round-2026-11-28-wp150)).

**Project nature.** Hoops Academy is a learning project with test and demo data, not a commercial product
([ADR-0025](../adr/0025-one-login-many-academies-easy-sign-up.md)). One login in several academies is a feature; F-11
(an invite reveals and links an existing login) and F-22 (pre-account hijacking) are **accepted by design**. Severities
below rate the risk for the project as it runs today; a separate column says which findings must be closed before real
academies (real children) use it. The privacy impact of the accepted decisions is still described where it applies.

**Method.** LINDDUN (Linking, Identifying, Non-repudiation, Detecting, Data disclosure, Unawareness, Non-compliance),
one table per trust boundary. Each mitigation names the class, migration, configuration or ADR it lives in; every one was
looked up in the tree (see [Verification](#verification)). "Not verified" in a row means exactly that.

| Category | Question asked at each boundary |
|---|---|
| **L** Linking | Can items of interest about one person be tied together (across records, academies, systems)? |
| **I** Identifying | Can a person be identified from data that was meant to be pseudonymous or minimal? |
| **N** Non-repudiation | Is a person bound to an action or record in a way they cannot deny, where that harms them? |
| **D** Detecting | Can someone learn that a person or a record exists (membership, account) without reading it? |
| **DD** Data disclosure | Is more personal data collected, kept, shared or shown than the purpose needs? |
| **U** Unawareness | Do the people concerned know what is collected and can they see or influence it? |
| **NC** Non-compliance | Does the processing meet data-protection law (GDPR: art. 5 principles, art. 8 children, art. 9 health, arts. 15–20 rights, art. 30/35) |

## Personal data inventory

| Data | Subjects | Where it lives (copies included) | Who reads it |
|---|---|---|---|
| Names, e-mail, phone, birth date, gender, locale, invitation state | members and players (many minors) | `core.person` (V2); `core.app_user` (e-mail, V2); Keycloak user (username = e-mail, first/last name, ADR-0023); replicas `game.person_ref` / `player_ref` and `athlete.*_ref` (display name, birth date, gender, `subject`; game V4, athlete V6); every version in `core.outbox` (V3) and the compacted Redpanda topics `core.person` / `core.player` (ADR-0036); `game.match_roster.display_name` (V1) | members of the academy per `docs/domain/authz-matrix.md`; the super admin for logins only (V18) |
| Guardian links | parents, players | `core.guardian_link` (V2); replicas `*.guardian_link_ref`; outbox and topic `core.guardian-link` | ADMIN writes; drives PARENT access to health, stats, absences and dues |
| Health and fitness (GDPR art. 9) | players | `athlete.injury` (body part, free-text description, severity, dates), `athlete.body_measurement` (height, weight), `athlete.physical_test_result` (value, notes) (athlete V3); availability derived from injuries | `HealthAccess`: ADMIN, staff of the player's team, the linked PARENT, the PLAYER; former staff up to the season's end (ADR-0042) |
| Attendance, planned absences | players | `athlete.attendance` (status, free-text `note`), `athlete.planned_absence` (free-text `reason`) (athlete V1) | staff roles; PARENT linked; PLAYER self (`ManagePlannedAbsences`) |
| Match events and stats | players, the recorder | `game.match_event` (append-only; `recorded_by_person_id`, `recorded_by_display_name`, `device_id`; game V2), projections; offline copy in the browser | `StatVisibility`, `EventVisibility` (ADR-0030) |
| Author snapshots | members | `athlete.*.recorded_by_name` / `reported_by_name` / `created_by_name`, `game.match_event.recorded_by_display_name` | whoever reads the record |
| Audit trail | members, the super admin | `core.audit_event` (V9: actor `sub`, person id, action, target id, metadata), one `hoops.audit` log line per row (`AuditEventRepository`) | ADMIN of the academy (super admin masked), super admin (ADR-0029) |
| Security events | any caller | `hoops.security` log lines with `sub`, tenant, roles, route (`SecurityEventLog`, ADR-0043); Keycloak events with username (= e-mail) and IP, 30 days (realm `eventsExpiration` 2592000) | operators of the log backend; Keycloak admins |
| Academy requests | non-members | `core.academy_request` (V17: name, e-mail, role, academy name, reason) | super admin |
| Exports | as the roster | CSV files on the downloader's device (ADR-0048) | whoever holds the file |
| Device storage | the signed-in user, the players of cached matches | browser: OIDC tokens and settings in localStorage, drift DB (IndexedDB/OPFS) with matches, roster names and jersey numbers, events | the device user |
| Finance | families (what a player owes, paid, waived; payment day and method), the recorders of payments, staff (salaries as expense lines) | schema `finance` (ADR-0056): `due` and `payment` with free-text reasons and notes (V3), `expense` with description and note (V20), `audit_event` (V4); roster replica `person_ref` (login `subject`, roles, display name), `player_ref` (person, display name, status), team, assignment, staff and guardian-link refs (V5, V10, V11; no birth date, gender or contact data); the dues and expenses CSV files on the downloader's device | ADMIN; PARENT linked and PLAYER self (their dues, without reasons, notes or voided payments); a team's current COACH the status only (decision 96, `domain/access.go`) |
| PDF request bodies | as the roster CSV (guardians' names, e-mails, phones; birth dates) and the match sheet (the box score) | in flight only, core / game → `pdf-service`; the PDF on the downloader's device | nobody in pdf-service (no database, nothing logged: §9) |

## Data-flow overview
The STRIDE overview, plus the flows that carry personal data outside the request path (events, telemetry) and the two
services of ADR-0051:
```
Browser (PWA: localStorage tokens + settings, drift DB, downloaded CSV/PDF files)
   │  HTTPS (Gateway) / HTTP (compose :8080, kind :8090)
   ▼
nginx / Envoy Gateway ──/auth──▶ Keycloak ──▶ Postgres (keycloak db: users, 30-day events)
   │  /api/core,/platform  /api/game  /api/athlete  /api/finance
   ▼
core-service ◀──/internal── game, athlete          core, game ──/internal/pdf/*──▶ pdf-service (no route)
   │  outbox ──▶ Redpanda (compacted core.* topics) ──▶ replicas in game, athlete, finance
   └── PostgreSQL 19 `hoops` (schemas core / game / athlete / finance, RLS)
services ──OTLP (traces incl. database spans, logs incl. hoops.audit / hoops.security)──▶ otel-collector ──▶ backend
                                                     (LGTM pod on kind and compose, 24 h; in-memory Jaeger on the cloud values)
```

## 1. Browser ↔ nginx / Envoy Gateway
| LINDDUN | Threat | Mitigations (evidence) | Residual |
|---|---|---|---|
| L | A login's memberships in several academies are joined in one view (the chooser, `/me`) | Intended (ADR-0025 §2); an academy's APIs need `X-Tenant-Id` and a membership (`TenantHeaderFilter`, non-members 404); one academy never sees another's data (RLS, `GenericRlsIsolationTest`) | Whoever sees the device sees every academy of that login (Info) |
| L | The super admin links one person across academies | `GET /platform/users` reads only logins and their persons' names, roles, active flag (V18 column grants, `PlatformUserReadRlsTest`); persons without a login (young players), birth dates, phones, guardian links stay invisible | By design (decision 71); the platform knows that one adult is a member of academies A and B |
| I | API responses identify people to members who do not need it | Role-matrix tests per resource (oracle `docs/domain/authz-matrix.md`); the event feed filtered like the box score (`EventVisibility`, `StatVisibility`, ADR-0030, `MatchEventFeedRoleMatrixTest`); health confined to the player's own teams (`HealthAccess`, `HealthRoleMatrixTest`); members list leaves out PENDING/REJECTED players (F-16) | Team-level events show who recorded them (`recordedBy`, a parent's name) to every reader of the feed; training data (planned absences with their free-text reason) is readable by every staff role of the academy, not only the player's team staff (P-06) |
| N | A parent or coach is bound to a recorded event or a health write | `recorded_by_person_id` + display name on events and athlete records; VOID instead of delete (game V2) | By design (accountability for minors' data); an author cannot have their name removed from an append-only event (P-01) |
| D | Learning that a person is a member, or that an e-mail has a login | Non-members 404, never 403 (CLAUDE.md rule 3, `TenantHeaderFilter`); public academy request answers 202 whatever the e-mail (ADR-0044 §2) | F-11 (accepted): an invite reveals an existing login; `LOGIN_SHARED` / `EMAIL_TAKEN` (409, core contract `updateMember`, `IssueTemporaryPassword`) tell an ADMIN that a member's login is active in another academy or that the address has a login (P-08); inside one academy `HealthAccess` answers 403 (not 404) when a filter names a player the caller may not read (ids are UUIDs: Info) |
| DD | Bulk extraction of minors' data through the API or exports | Paging limits (`PageOffset`, page size ≤ 200 on lists); exports limited to 10,000 rows, `Cache-Control: no-store` (`CsvResponse`), current staff only for the roster (ADR-0048 amendment, decision 83); gateway rate limits for the three export paths and the public request (`deploy/helm/hoops/values.yaml` `rateLimits`), the same brake in compose nginx (`infra/compose/nginx.conf`, `export-limits.conf`; finance's two exports: §10); services log no bodies (`quarkus.http.access-log.enabled=false` in `common-quarkus`, `TeamRosterExportTest.theContentIsNeverLogged`) | A downloaded roster CSV or PDF (minors' birth dates, guardians' phones and e-mails) leaves every control |
| DD | The SPA or service worker caches API data | Service worker network-only for `/api/`, `/auth/`, `/platform/`, `/internal/` (`apps/web/web/sw.js` `NETWORK_ONLY_PREFIXES`) | — |
| U | People do not know what is collected about them or their children | Not mitigated: no privacy notice in the web app, the landing page or the academy request form (no such text in `apps/web/lib/l10n/*.arb`); Keycloak clients `consentRequired: false` | P-05 |
| U | A member cannot see or correct their own data | `PATCH /api/core/me` changes one's own name (WP91); everything else through the academy's ADMIN | No self-service view of what an academy holds (health, absences, events, audit rows about me) (P-01) |
| NC | Children's data (art. 8) and health data (art. 9) processed without a recorded legal basis, consent or impact assessment | Not mitigated (no DPIA, no records of processing; ADR-0050 Consequences already says real academies bring GDPR obligations) | P-05 |

## 2. Services ↔ Keycloak
| LINDDUN | Threat | Mitigations (evidence) | Residual |
|---|---|---|---|
| L | One Keycloak user is the key that joins a person across academies, services, logs and replicas | Keycloak holds no academy data: tenant roles live in `core.membership_role` (ADR-0005); the `sub` is an opaque id | The same `sub` appears in `core.audit_event`, `hoops.audit` / `hoops.security` lines and the replicas of every academy (see §8, P-07); by design (ADR-0025) |
| I | Keycloak's event store and log identify people (e-mail, IP) | Events limited to authentication types, kept 30 days (`infra/keycloak/realm-academy.json` `eventsExpiration` 2592000); admin events without representation (`adminEventsDetailsEnabled: false`, `adminEventsExpiration` 2592000); never passwords or tokens (`RealmSecurityEventsKeycloakTest`) | Username (= e-mail) and client IP in the events for 30 days, and in Keycloak's stdout log for as long as the environment keeps it (ADR-0043 PII exception) |
| N | Login history binds a person to sign-in times and places | 30-day expiry as above | Accepted for investigations (ADR-0043) |
| D | Account existence learnt through Keycloak | `registrationAllowed: false`; brute-force detection; the public request never answers by e-mail (ADR-0044) | F-11 / F-22 accepted (ADR-0025): an academy can create a login for any address without proof of ownership |
| DD | core's service account reads every user of the realm | Only `manage-users` / `view-users` (STRIDE §2) | `manage-users` is realm-wide (Keycloak has no finer role) |
| U | A login is linked into another academy without its owner knowing | — | F-11 / F-22 accepted by design; ADR-0025 "If the project went commercial" lists the fixes (verification, consent, notification) |
| NC | Logins are never erased | A login is deleted only as onboarding compensation (`LoginProvisioning.compensate` → `KeycloakIdentityProvider.delete`); logins outlive suspended / withdrawn academies on purpose (ADR-0025 §5) | No path deletes a login whose last membership ended (P-01, P-02) |

## 3. game / athlete ↔ core (`/internal`)
| LINDDUN | Threat | Mitigations (evidence) | Residual |
|---|---|---|---|
| L | game and athlete build person profiles from core's answers | Answers limited to ids, roles, team ids, display names (STRIDE §3); authz context computed by core (`MembershipLookup`), or in replica mode by the same rule over the local replica (common's `MembershipRule`, ADR-0066) | — |
| I | Internal DTOs carry more than the caller needs | As above; health stays in athlete and never travels to core | Core's roster contract requires birth date and gender of every player (`ReplicaPlayer.hasBirthDateAndGender` filters on them), so game receives both (P-10) |
| N | — | Not applicable (service-to-service) | — |
| D | A service learns memberships of other academies | `TenantScope.runAs(tenantId)` on internal endpoints, RLS; `@RolesAllowed("service")`; token audience per service (ADR-0034, `TokenAudienceKeycloakTest`) | A compromised pod may ask for any tenant (by design, STRIDE §3) |
| DD | Responses cached longer than membership | 30 s cache (`hoops.core.cache-ttl`) | A removed member keeps reading game/athlete data up to 30 s (ADR-0025 Consequences) |
| U | — | Not applicable | — |
| NC | — | Not applicable | — |

## 4. Services ↔ PostgreSQL
| LINDDUN | Threat | Mitigations (evidence) | Residual |
|---|---|---|---|
| L | Records of one person joined across academies inside the database | One `person` row per academy; `tenant_id` + `ENABLE`/`FORCE` RLS on every tenant table (`app.enable_tenant_rls`, `RlsSchemaMetaTest`); the shared-login e-mail sync touches only linked active persons (`LoginEmailSync`, `SharedLoginPersonsTest`, ADR-0026); core_platform reads only logins and their names (V18) | The membership index `core.user_membership_index` (V2) and the platform policies link a login's persons on purpose (ADR-0013, ADR-0029 amendment) |
| I | Health data readable in clear by anyone with DB access | Non-owner app roles without BYPASSRLS (`just db-role-check`); health only in schema `athlete`; cloud system disk encrypted (`infra/tofu/main.tf` `system_disk_encrypted`, ADR-0050); a major move's dump is written under `umask 077` to a 0700 directory outside the repository (`scripts/pg-major-move.sh`, ADR-0073) | No column-level encryption; backups not designed (STRIDE out of scope); a major move leaves full copies of every schema behind, the old volume and the `pg_dumpall` file, with no rule that deletes them (ADR-0073 §3, the runbook "a new PostgreSQL major"; P-14) |
| N | Append-only stores bind people for ever | `core.audit_event` append-only trigger (V9, `AuditEventRlsTest`); metadata holds field names, never values (`AuditEvent` javadoc, `ChangedFields`); names resolved at read time, not stored (ADR-0029) | Audit rows keep `actor_sub` and person ids with no retention (P-02); the rule "no personal data in metadata" is a convention, not a test; the super admin's free-text `reason` is the documented exception (ADR-0029) |
| D | — | Covered at boundary 1 | — |
| DD | Personal data kept after its purpose ended | Replica bookkeeping pruned (`ReplicaRetentionJob` in game and athlete: `applied_event` after 7 days, inspected `parked_event` after 30 days, ADR-0037); `parked_event` keeps coordinates and messages, never the record's value (athlete V6 comment); soft-removed replica rows keep no name or login (game V6, athlete V9); withdrawn tenants marked with `retain_until` (`hoops.tenant.withdrawn-retention=P365D`, `TenantLifecycle`) | Nothing deletes a withdrawn tenant after `retain_until`, old audit rows or decided academy requests (P-02); published `core.outbox` rows (every `PersonChanged` / `PlayerChanged` payload: name, birth date, gender, `sub`) are never deleted (P-03); author snapshots (`recorded_by_name`, `match_roster.display_name`) survive renames (P-09) |
| U | Health writes and reads leave no trace the player or family could ask for | Only the author snapshot on each health record (athlete V3) | athlete and game have no audit trail: a read, an update or a delete of a child's injury is not recorded (P-04) |
| NC | Erasure (art. 17), rectification of copies (art. 16), portability (art. 20) | Rectification of names reaches the replicas through `PersonChanged` / `PlayerChanged` events (`RosterEventAppender`) | No erasure or export path for a person: no `DELETE` of a person or player in the core contract; `person.removed` / `player.removed` are emitted only when the row is gone (`RosterEventAppender`), which no use case does (P-01) |

## 5. Offline device storage (PWA)
| LINDDUN | Threat | Mitigations (evidence) | Residual |
|---|---|---|---|
| L | A stable device id links one person's events across matches and academies | `device_id` regenerated after every wipe and user switch (`MatchStore.wipe` clears the device row; `MatchStore.bindOwner`, `match_owner_test.dart`) | Stable for one user on one device across academies until sign-out (Info) |
| I | The next user of a shared device reads cached names and events | No health data, birth dates or contact data cached: the drift tables hold matches, roster display names and jersey numbers, events (`match_database.dart`); cache keyed by tenant and person (F-07, `match_store_scope_test.dart`); sign-out clears the tenant, wipes the DB and forgets the tokens (`lib/app/sign_out.dart`, `sign_out_test.dart`, `match_store_wipe_test.dart`) | Data stays on the device until the next sign-in (then `bindOwner` wipes it) when a user closes the browser without signing out; storage is not encrypted (browser storage, DevTools) |
| N | Unsynced events of a previous user attributed to the next | Outbox rows carry tenant + person; sync uses the current token (STRIDE §5) | — |
| D | The selected academy in localStorage reveals a membership | Cleared on sign-out (`selectedTenantIdProvider.clear()` in `sign_out.dart`) | As above while signed in |
| DD | Tokens with profile claims (name, e-mail) in localStorage | No `offline_access`; refresh rotation (F-08, ADR-0034); CSP, no XSS sinks | Tokens in browser storage (F-08 residual) |
| U | A user does not know unsynced events are dropped at sign-out | Explicit warning before the wipe (ADR-0019) | — |
| NC | — | Device data is a cache of server data; covered by the server-side rows | — |

## 6. Admin uploads (tenant logo)
| LINDDUN | Threat | Mitigations (evidence) | Residual |
|---|---|---|---|
| L | — | A logo is academy data, not personal data | — |
| I | Image metadata (EXIF: GPS, camera owner) in an uploaded photo | Stored as uploaded (no server-side image processing, STRIDE §6) | A photo with EXIF location would be served unchanged to members (Info; not verified whether any client strips it) |
| N | Who replaced the logo | `tenant.logo_replaced` / `tenant.logo_removed` audit (ADR-0017) | — |
| D | Another academy's logo | RLS + tenant header (`TenantLogoResourceTest.anotherTenantsLogoIsNotFound`) | — |
| DD | — | 512 KB limit, magic-byte types only | — |
| U | — | Not applicable | — |
| NC | — | Not applicable | — |

## 7. core → Redpanda → replicas (roster events)
The STRIDE model takes it up as boundary 7 in the eleventh round (decision 119, WP148);
[ADR-0036](../adr/0036-redpanda-event-broker.md) covers its security. It is here because it copies personal data.

| LINDDUN | Threat | Mitigations (evidence) | Residual |
|---|---|---|---|
| L | Events tie a person's roles, teams and guardian links over time | Topics per aggregate keyed `<tenant>:<id>`; SASL/SCRAM per service with prefixed ACLs, NetworkPolicy (ADR-0036 §7); event payloads carry display name, `subject`, roles, birth date, gender, link ids only (`libs/contracts/events/core.*.schema.json`) | Compacted topics keep the latest state per key with `retention.ms=-1` (ADR-0036 §6) |
| I | Birth date and gender travel to every consumer | Required by the roster contract (P-10) | game stores both for every player |
| N | — | Not applicable | — |
| D | — | Consumers read only `core.*` (ACL) | — |
| DD | Copies outlive the person in core | Soft removals null every state column (game V6, athlete V9, finance V5 and V10); tombstones kept 7 days | A person is never deleted in core, so no removal is ever emitted for them (P-01); the outbox history stays (P-03) |
| U | — | Not applicable | — |
| NC | Erasure must reach the topic, the outbox and every replica | The `.removed` + tombstone mechanism exists and is applied by the three consumers (game, athlete: ADR-0037 amendment; finance: V5, V10, `adapters/in/events`) | No use case triggers it (P-01) |

## 8. Services → OpenTelemetry collector → log and trace backend
| LINDDUN | Threat | Mitigations (evidence) | Residual |
|---|---|---|---|
| L | Logs tie one person's activity across academies | Logs carry ids, not names: `hoops.audit` lines (`AuditEventRepository`: action, target, actor `sub`, tenant) and `hoops.security` events (`SecurityEventLog`: `sub`, tenant, roles, route template); no tenant id on spans or resources (ADR-0046, collector `attributes/strip-ids` in `deploy/helm/hoops/templates/observability.yaml`) | The same `sub` with different `tenantId`s in one log store links a person's academies and activity; retention of shipped logs is the backend's and none is set (P-07) |
| I | Request bodies, tokens or names in logs and spans | HTTP access log off (`quarkus.http.access-log.enabled=false`); OIDC's token-quoting WARN muted (`io.quarkus.oidc.runtime.OidcProvider` at ERROR); security-event values stripped and capped, never a claim of an unverified token (ADR-0043; Rust `security.rs`, Go `platform/security`); `url.path`, `url.query`, Kafka keys deleted from spans (collector `attributes/strip-ids`); `TeamRosterExportTest.theContentIsNeverLogged`; pdf-service and finance as §9 and §10. **Database spans** (ADR-0074): `db.statement` is the parameterised text, never a bound value, the tenant id of `set_config` is a bound value; a refused statement keeps the SQLSTATE only in finance and carries no `DETAIL` in Java because every table forces RLS; `DatabaseSpansTest` (core, game, athlete) and finance's `TestTheDuesListShowsItsSQLUnderTheRequestSpanAndNoValue` grep every exported span for seeded names, e-mails, notes and the tenant id; the collector's debug exporter is `basic` everywhere (`values.yaml`, `values-kind.yaml`, `values-cloud.yaml`) | Log content depends on every log statement (no automated PII check beyond the export, pdf and finance tests); `strip-ids` does not touch the new `db.*` attributes (they carry no value by construction, not by the collector); exception events on server spans keep the exception message: game's `NotFoundException`s name the match or player id (`MatchLookup`, `GetPlayerSeasonStats`), and a driver message that echoes refused input could reach a Java exception event (ADR-0074 §4, not tested) (P-15) |
| N | Security events attribute refused requests to a person | By design (ASVS 16.3.2) | — |
| D | — | Not applicable | — |
| DD | Logs kept indefinitely | The LGTM pod (kind, compose profile `observability`) keeps logs, traces and metrics 24 h, without persistence (`values.yaml` `observability.lgtm.retention`, WP120); the cloud values' Jaeger keeps traces in memory | A real backend's retention is the environment's (ADR-0046); database spans multiply the stored spans by about five (ADR-0074 §7), not their content (P-07) |
| U | — | Not applicable (operational data) | — |
| NC | — | Storage limitation applies to logs too | P-07 |

## 9. core / game → `pdf-service`
Built by WP111 (the renderer, ADR-0052), WP116 (core's roster PDF), WP117 (game's match sheet), WP122 and WP132.
Evidence is in `services/pdf-service` unless another path is given.

| LINDDUN | Threat | Mitigations (evidence) | Residual |
|---|---|---|---|
| L | The renderer collects rosters of many academies | Stateless: no database, no broker, no file written (no `std::fs` write in `crates/*/src`); the only outbound calls are the two reads of Keycloak's discovery document and JWKS (`adapters/src/auth.rs`); egress limited to DNS, Keycloak and the chart's collector (`charts/pdf-service/templates/networkpolicy.yaml`) | — |
| I | Request bodies (minors' names, birth dates, guardians' contacts) reach logs, spans or Problems | The body is parsed and rendered, never logged nor put on a span: the request span and the access line carry method, route template, status and duration only (`adapters/src/http.rs`, `telemetry.rs`; `tests/logs.rs` `nothing_of_the_body_reaches_a_log_line_or_a_span`); Problems name the field path and a code, never a value (`problem.rs`; `validation_failures_name_the_field_never_the_value`, `too_many_players_is_422_naming_the_list_never_the_children`, domain `errors_describe_themselves_without_values`); the security event's `tenantId` is always empty and its subject is the calling service's `sub` (`security.rs`); the callers log nothing of the roster or the sheet on success or failure (core `TeamRosterPdfTest.theContentIsNeverLogged`, `whenPdfServiceCannotRenderTheAnswerIsA503ThatAuditsAndLogsNothingOfTheRoster`; game `MatchSheetPdfResourceTest.aRenderedSheetLogsNoName`, `aPdfServiceFailureIs503AndNoNameIsLogged`) | — |
| N | A print binds a member to having taken minors' contact data away | core audits every roster print with the row count and the format only (`team.roster_exported`, `TeamRosterPdfTest.everyPrintIsAuditedWithTheRowCountAndTheFormatOnly`) | The match sheet is not audited (`GetMatchSheetPdf`: "a read every member has"); by design |
| D | Anyone calls the renderer | No gateway route; NetworkPolicy admits core and game only (decision 89); a token needs audience `pdf-service`, the realm role `service` and a `sub` (`auth.rs`); a `web` token is refused (`tests/api/http.rs` `a_web_client_token_is_refused`) | Compose publishes it on the host's loopback (`127.0.0.1:8084`, `infra/compose/compose.yaml`), still behind the bearer check (Info) |
| DD | A PDF carries more than its readers see | Same authz as the CSV (decision 83: `TeamRosterPdfTest.roleMatrix`, `aNonMemberGetsNotFoundAndNothingIsRendered`) and as the box score (`MatchSheetPdfResourceTest.everyMemberGetsTheSheetWithTheLinesTheBoxScoreShowsThem`, `aNonMemberAnotherTenantsMatchAndAnUnknownMatchAre404WithoutRendering`); body limit 413 and list limits 422 (`http.rs`, `team_roster.rs`); the PDF's metadata holds the document title, the academy, the language and the creator, no person (`render.rs`); answers `Cache-Control: no-store` (core `ExportResponse`, game `MatchSheetPdfResource`) | The printed roster carries guardians' names, e-mails and phones and players' birth dates, as the CSV (decision 83); paper cannot be recalled (P-11) |
| U | Guardians do not know their contact data is printed | Labels in the reader's language (decision 90, `labels.rs`) | Nothing tells a guardian that the roster (CSV or PDF) shows their phone and e-mail to the team's staff (joins P-05) |
| NC | — | Processor-like role inside the platform; nothing stored | — |

## 10. Browser ↔ `finance-service`
Built by WP118 (stack, settings, fee plans, ADR-0055), WP119 (dues, payments, roster replica), WP121 and WP124 (web),
WP123 (expenses, balance, exports), domain rules in ADR-0056. Evidence is in `services/finance-service` unless another
path is given.

| LINDDUN | Threat | Mitigations (evidence) | Residual |
|---|---|---|---|
| L | Payment history linked to the child's roster, health or attendance | Schema `finance` with RLS on every tenant table and its own non-owner roles (`finance_app` / `finance_migrator`, ADR-0055; `TestNoTenantReadsOrChangesAnotherTenantsRows`); the roster comes from core's topics (consumer user `finance-service` may consume `core.` only: `deploy/helm/hoops/values.yaml` `events.users`), no REST call to another service; the replica keeps no birth date, gender or contact data (V5, V10, V11; `TestAPlayerEventDropsBirthDateAndGender`, `TestAPersonEventKeepsLoginRolesAndActiveOnly`) | The replica keeps each member's login `subject` and display name (V5, V11), so the same `sub` ties finance records to the person's other services, as §2 |
| I | A coach identifies which families are behind | Decision 96: a current COACH of the team reads the status only, no amounts, reasons, expenses or balance; ASSISTANT_COACH nothing (`domain/access.go`; `TestACurrentCoachOfTheTeamReadsItsStatusAndAnAssistantNothing`, `TestTheCoachSeesStatusOnlyAndTheFamilyNoReasonsNotesOrVoidedPayments`) | By design: which families are behind is disclosed to the team's coach (P-12) |
| N | A waiver, an amount change or a voided payment binds a family to a hardship | Every write is audited in `finance.audit_event`, append-only for the app role (V4 trigger, `TestAuditEventsAreAppendOnly`); metadata holds ids, enum values and changed field names only, never a reason, note, description or amount (`TestReasonsAndNotesNeverReachLogsOrAudit`, `TestUpdatingAPlanAuditsTheChangedFieldNamesOnly`, `TestAnExpenseIsRecordedListedCorrectedAndDeleted`); reasons and notes at most 200 characters, read by ADMIN only (V3, V20, `finance.yaml`) | The free text itself is kept in clear on the due, the payment (a voided one with its reason and who voided it) and the expense, for as long as the row exists; "no health or family details, no named person's salary" is a contract rule, no check (P-12) |
| D | A member learns that another family has dues, or that an academy uses finance | Non-members and unknown or suspended academies 404 (`TestRoleMatrixOfDuesPaymentsAndTheReads` `stranger`, `TestCrossTenantDuesAndPaymentsAreRefused`, `TestAuthenticationAndTheTenantHeader`); a parent or player asking for another player gets 403 whether the player exists or not (`parent2` on an unknown player, same test) | A member without the role gets 403, not 404 (members may know the academy exists; Info) |
| DD | Exports and lists hand out more than the purpose needs | Dues and expenses exports ADMIN only (`TestRoleMatrixOfExpensesBalanceAndExports`), at most 10,000 rows (`TestAnExportOfMoreThanTenThousandRowsIsRefused`), audited (`dues.exported`, `expenses.exported`), never a reason or note (`TestTheDuesExportFollowsTheCsvSpec`, `TestTheExpensesExportFollowsTheCsvSpec`), formula guard, `Cache-Control: no-store` (`rest/exports.go`); rate-limited at the gateway (`charts/finance-service/values.yaml` `rateLimits`) and in compose nginx (`infra/compose/nginx.conf`); Problems name fields, never values (`TestInvalidRequestsAreProblemsNamingFieldsNeverValues`); spans carry no value (`TestTheDuesListShowsItsSQLUnderTheRequestSpanAndNoValue`); parked events without their value (`TestParkedEventsAreWrittenWithoutTheirValue`) | A downloaded dues CSV (player names, amounts, statuses) leaves every control; the expense `description` (1–120 characters, free text) is in the list and the expenses CSV, and "no names with salaries" is a contract rule, no check; an unexpected error is logged with its error text (`rest/problem.go`, "request failed"), whose content is not tested (to verify) |
| U | Families do not know what is recorded about their payments | PARENT (linked) and PLAYER (self) read their dues: amount, status, period, plan and the valid payment's day and method (ADR-0056, `CanReadPlayerDues`) | A family never sees why a due was waived, changed or a payment voided (ADR-0056's minimal choice); nothing reads `finance.audit_event` through the API (no audit path in `finance.yaml`; core's audit list reads `core.audit_event` only), so a request for "who changed my dues" needs SQL (joins P-01) |
| NC | Financial data of identifiable families (not art. 9, but sensitive; ADR-0051: "the same care as health data") | Replica bookkeeping: applied event ids deleted after 7 days (`application/retention.go`, `TestTheRetentionRunnerDeletesOldAppliedEventIDs`) | Nothing deletes dues, payments, expenses, audit rows or parked events; the retention of finance records (tax law may require years) is not decided (P-02) |

## Data-subject rights and retention (status)
| Right / store | Today | Evidence |
|---|---|---|
| Access (art. 15) | Partly: each member reads what the matrix allows; no "everything about me" view or export | authz matrix; P-01 |
| Rectification (art. 16) | ADMIN edits a person; own name via `PATCH /api/core/me`; copies follow through events | `MemberCommands`, `RosterEventAppender` |
| Erasure (art. 17) | Not designed: deactivate, withdraw or reject only; health records and absences can be deleted one by one | core contract (no person/player `DELETE`); athlete `DELETE` on injuries, measurements, test results, absences |
| Portability (art. 20) | Not designed (roadmap: "a per-tenant export for data portability (not designed)") | `docs/roadmap.md`; P-01 |
| Withdrawn academy | Marked, kept until `retain_until` (365 days), then nothing deletes it | `TenantLifecycle`, V1 `retain_until`; P-02 |
| `core.audit_event` | Kept for ever (v2 purge job) | ADR-0029 §6; P-02 |
| `core.academy_request` | Kept for ever (v2 purge job) | ADR-0044; P-02 |
| `core.outbox` (published) | Kept for ever | V3, `JpaOutboxQueueRepository` (marks `published_at`, never deletes); P-03 |
| Replica bookkeeping | 7 / 30 days (game, athlete); finance: applied ids 7 days, parked events kept | `ReplicaRetentionJob` (game, athlete); finance `application/retention.go` |
| Finance: dues, payments, expenses, `finance.audit_event` | Kept for ever; period not decided | finance V3, V4, V20 (only `applied_event` is ever deleted); P-02 |
| Keycloak events | 30 days | realm `eventsExpiration`, `adminEventsExpiration` |
| Shipped logs and traces | 24 h in the LGTM pod (kind, compose profile); in memory on the cloud values; a real backend's own | `values.yaml` `observability.lgtm.retention`, ADR-0046 amendment (WP120); P-07 |
| Database copies of a major move (old volume, `pg_dumpall` file) | Kept until someone deletes them | ADR-0073 §3, `scripts/pg-major-move.sh`, runbook "a new PostgreSQL major"; P-14 |
| Device data | Until sign-out or the next user's sign-in | `MatchStore.wipe`, `bindOwner` |

## Findings

P-01 to P-13 keep the severity of WP112: the security review's rubric (a concrete path, then impact), applied to the
project as it runs today (learning project, demo data); they are not re-rated here. Findings from P-14 on are rated on
the scale of [ADR-0077](../adr/0077-threat-modelling-methods.md): likelihood (L) and impact (I) Low 1, Medium 2, High 3,
likelihood for the project as exposed today, impact as if a real academy's data were in it; the product L×I is the
rating: 6 or 9 High, 3 or 4 Medium, 1 or 2 Low. "Gate" = must be closed or consciously accepted before real academies
use the system.

| ID | Severity | Gate | Title | Location | Proposed action |
|---|---|---|---|---|---|
| P-01 | Medium | yes | No erasure, export or "about me" path for a person: persons and players are never deleted, so no `.removed` event reaches the replicas or topics; author snapshots and append-only events keep names; a parent or player cannot obtain their data (GDPR arts. 15, 17, 20) | core contract (no person/player `DELETE`), `RosterEventAppender`, game V2 (append-only), `docs/roadmap.md` | An ADR for data-subject rights: per-person erasure as pseudonymisation (null the person's data, keep ids; emit `.removed`; replace author snapshots; purge the outbox rows of that aggregate) and a per-person JSON export assembled across core, game, athlete (and finance); then a work package |
| P-02 | Medium | yes | No retention enforcement: withdrawn academies stay after `retain_until`, `core.audit_event` and decided academy requests (non-members' names and e-mails) are kept for ever | `TenantLifecycle`, V1, V9, V17; FOLLOW-UPS "[v2] Purge job" | Schedule the v2 purge job (as `core_migrator`, the only role the audit trigger lets delete) with explicit periods per store, written down in one table (this document's retention table is the starting point); include finance records when their legal period is known |
| P-03 | Low | yes | Published `core.outbox` rows are never deleted: the table holds every historic `PersonChanged` / `PlayerChanged` payload (display name, birth date, gender, `sub`), so old values survive a correction and any future erasure | core V3, `JpaOutboxQueueRepository` | A small core job (cluster lock, as `ReplicaRetentionJob`) deleting published rows older than the 7-day tombstone retention; independent of the v2 purge job |
| P-04 | Low | yes | Health records of minors (art. 9) are written, changed, read and deleted without an audit trail: athlete keeps only the author snapshot on create, a delete leaves nothing | athlete-service (no audit port), athlete V3 | Record health writes and deletes (and exports when they exist) in an athlete audit table or through core's trail; decide whether reads of another person's health records are logged |
| P-05 | Low | yes | No privacy notice, legal basis or consent record: nothing tells members, parents or academy requesters what is collected, why, for how long and who sees it; children's (art. 8) and health (art. 9) data have no recorded basis; no DPIA or records of processing | `apps/web/lib/l10n/*.arb` (no such text), landing and academy request form, realm `consentRequired: false` | A privacy notice page (es / en / id) linked from the landing, the request form and the app menu; a short DPIA and records-of-processing note in `docs/security/`; for real academies, the academy as controller and the platform as processor (a data-processing agreement) |
| P-06 | Low | no | The free-text `reason` of a planned absence (and an attendance `note`) is readable by every staff role of the academy, not only the player's team staff, and parents type health details into it ("knee surgery"), outside `HealthAccess` | `ManagePlannedAbsences` (staff: any player), athlete V1 | Limit absence reasons and attendance notes to ADMIN and the player's team staff (as `HealthAccess`), or replace the reason by a category and a hint "no medical details" |
| P-07 | Low | no | Shipped logs link one person across academies (`sub` with each `tenantId` in `hoops.audit` and `hoops.security` lines) and are kept without any retention; kind prints log bodies in the collector | `AuditEventRepository`, `SecurityEventLog`, ADR-0046, `values-kind.yaml` `debugVerbosity: normal` | WP120 (the LGTM backend this round) sets a log and trace retention (e.g. 30 days, as Keycloak's events) and Grafana access for operators only; record it in the ADR-0046 amendment |
| P-08 | Info | no | `LOGIN_SHARED` and `EMAIL_TAKEN` (409) tell an academy ADMIN that a member's login is an active member of another academy, or that an address already has a login elsewhere | core contract `updateMember`, temporary password; `IssueTemporaryPassword`, `LoginEmailSync` | Same family as F-11: record it as accepted in ADR-0025's consequences (or answer one neutral code) |
| P-09 | Info | no | athlete's author snapshot falls back to `preferred_username` (the e-mail, ADR-0023) when the token has no `name`, and shows it to parents and players in `recordedBy`; snapshots also keep old names after a rename | `athlete CallerActor`; athlete V1, V3 | Fall back to a neutral label, never the username; resolve names at read time where the replica has them |
| P-10 | Info | no | Data minimisation of the replicas: game (and athlete) store every player's birth date and gender because core's roster contract requires them; no game rule using them beyond that filter was found (not verified exhaustively); finance does not (WP119, see the status) | game V4 `player_ref`, `ReplicaPlayer`, `libs/contracts/events/core.player.schema.json` | WP119 stores only what finance needs (no birth date, gender or `subject` unless a rule needs it); check whether game needs them and drop them from its replica if not |
| P-11 | Low | no | `pdf-service` (modelled while planned): parse and validation errors can quote request values (names, birth dates) into Problem details or the callers' logs; the roster PDF reproduces guardians' contact data on paper | ADR-0051 §3, decision 89, WP111 / WP116 / WP117 | WP111: generic 400/422 details that never echo input, a test that a known personal value appears in no response and no log line; WP116 / WP117: never log a `pdf-service` Problem body; WP116 decides whether guardians' contacts belong on the printed roster |
| P-12 | Low | no | finance (modelled while planned): free-text reasons and notes (waive, amount change, void, payment, expense) will carry hardship or salary details into the audit trail and exports; a team's coach learns which families are behind (decision 96, by design); parent visibility of reasons, export rate limits and record retention are undecided | ADR-0051 §2, decisions 95–97, WP118 / WP119 / WP123 | Keep reasons and notes out of audit metadata and logs (or list them as a named exception, as `tenant.suspended`'s reason); decide in WP119 whether a family sees reasons; gateway rate limits on the finance export paths (WP123); retention period for finance records (joins P-02) |
| P-13 | Low | no | A guardian link is created by one ADMIN, with no confirmation and no notification to the player (with a login) or the other guardians; a wrong link gives an adult read and write access to a child's health records (and, since WP119, the child's dues and payments) | authz matrix "Members, roles, guardian links: ADMIN"; `guardian_link.created` audit (ADR-0017) | Show a player and existing guardians who is linked (and when a link is added) in their own profile; for real academies, a second ADMIN confirmation or the existing guardian's acknowledgement |
| P-14 | Medium (L1 × I3 = 3) | yes | A PostgreSQL major move leaves two full copies of the database behind: the old volume (no longer declared, so `down -v` keeps it) and the `pg_dumpall` file (every schema: minors' data, health records, finance, the roles' password verifiers). Both are kept "as the way back" with no period and no rule that deletes them; the dump is not encrypted, only protected by file modes (0700 directory, 0600 file). L1: only the owner's account on the owner's machine reaches them; I3: with real academies, a complete copy of everyone's data outside every RLS and retention control | ADR-0073 §3, `scripts/pg-major-move.sh` (`--out`, "never removes a volume"), `docs/runbooks/postgresql-major.md` | A dated rule in the runbook and the script's closing message: once the new major is verified (a set number of days), delete the dump and the old volume, or encrypt the dump if it must stay; for real academies, fold it into a backup and retention ADR with the periods of P-02 |
| P-15 | Medium (L3 × I1 = 3) | no | Exception events on server spans keep the exception message: game's `NotFoundException`s name the match or player id ("Match <uuid> not found", "Player <uuid> not found"), seen in Tempo at the WP143 merge; a driver message that echoes refused input could reach a Java exception event (ADR-0074 §4, not tested). The collector's `strip-ids` does not touch exception events. L3: every 404 of those use cases writes one; I1: pseudonymous ids in a 24 h store today (a name, if an echo ever happens, would be more) | game `MatchLookup`, `GetPlayerSeasonStats`, `IngestEventBatch`; ADR-0074 §4; FOLLOW-UPS "Ids in exception messages on spans" | Messages without ids (the Problem already names the resource), or the exception event's message dropped for 4xx; a test that a refused statement's span holds no seeded value (the case ADR-0074 left untested); settles the P-11 / ADR-0043 question in FOLLOW-UPS |

**Counts:** P-01 to P-13 (WP112 rubric): Critical 0 · High 0 · Medium 2 · Low 8 · Info 3. P-14 and P-15 (ADR-0077
scale): High 0 · Medium 2 · Low 0. Gate before real academies: P-01 to P-05 and P-14.

Accepted by design and not repeated as findings: F-11 and F-22 (ADR-0025). Their privacy impact, for the record: under
F-22 an admin of academy A who created a login for someone else's address enters academy B as that person once B
invites the address, and reads what that person may read there (a parent's linked children, including health records);
under F-11 the owner of a login is linked into another academy without being asked.

## Status after the eighth round (2026-11-16, WP125)
Recorded on 2026-11-16, when pdf-service (WP111, WP116, WP117) and finance-service (WP118, WP119, WP123) had been
built and §9 and §10 still described them as planned (WP150 rewrote both, see the next section). What the round
changed, from the handovers and the code (no new review was done):

| ID | Status | Evidence |
|---|---|---|
| P-07 | Partly mitigated | WP120 (ADR-0046 amendment): logs and traces expire after 24 h in the LGTM pod on kind and in the compose profile (Loki's minimum; P-07 suggested up to 30 days); Grafana is an anonymous Viewer behind a ClusterIP Service, no admin login; kind's collector is back to `debugVerbosity: basic` (no log bodies); the dashboards' queries drop subject, roles and tenant (chart tests). Still open: `values-cloud.yaml` keeps the in-memory Jaeger, the shipped lines still carry `sub` with each `tenantId`, a real backend's retention is the environment's |
| P-10 | Mitigated for finance | WP119: finance's roster decoder never reads birth date or gender (`TestAPlayerEventDropsBirthDateAndGender`). Unchanged for game and athlete |
| P-11 | Mitigated in code; residual by design | WP111: Problems name the field path and a code, never a value (`validation_failures_name_the_field_never_the_value`, `too_many_players_is_422_naming_the_list_never_the_children`, `logs.rs`); WP116 (`TeamRosterPdfTest`) and WP117 (`LogCapture`) find no player, guardian or team name in core's and game's logs on success or failure. The printed roster carries guardians' names, e-mails and phones, as the CSV (decision 83) |
| P-12 | Partly mitigated | WP119, WP123, ADR-0056: reasons and notes never in audit metadata (ids, period, method, counts, field names), logs or the CSV exports; families see no reasons, notes or voided payments; `dues:export` and `expenses:export` rate-limited at the gateway and in compose nginx (WP118). Open: the coach sees who is behind (by design, decision 96); retention of finance records (P-02) |
| P-13 | Wider | Since WP119 a guardian link also opens the child's dues and payments |
| P-01..P-06, P-08, P-09 | Open | Nothing in the round addressed them; P-01's per-person export and P-02's periods now include finance |

## Status after the tenth round (2026-11-28, WP150)
What WP150 changed in this document, from the code on `main` at cc4fb3e2, ADR-0073 and ADR-0074:

| Where | Change |
|---|---|
| Header, inventory, data-flow overview | pdf-service and finance-service as built (no "planned"); PostgreSQL 19; database spans; the telemetry backends as configured |
| §1 DD | Compose nginx has the export brake now (`infra/compose/nginx.conf`); the residual names the roster PDF too |
| §4 I | A major move's copies (old volume, dump): P-14 |
| §7 DD, NC | finance is the third consumer and applies soft removals (V5, V10) |
| §8 I, DD | Database spans (ADR-0074: parameterised statements, no bound value, tested per service); exception messages on spans: P-15; the LGTM pod's 24 h retention replaces "WP120 builds the backend this round" |
| §9, §10 | Rewritten as built, with evidence in code and tests; new residuals: compose's loopback port of pdf-service (Info), the roster's guardians' contacts and unawareness (joins P-05), the finance audit trail that no API reads (joins P-01), finance records and parked events that nothing deletes (P-02), the expense description as free text in the CSV (P-12), 403 inside an academy (Info) |
| Retention table | finance stores, the 24 h LGTM retention, a major move's copies |
| Findings | P-14 (Medium, gate) and P-15 (Medium), on the ADR-0077 scale; P-10 to P-13 worded as built. P-01 to P-09 unchanged; P-10, P-11, P-12, P-13 as in the eighth round's status |

## Verification
Every mitigation above was looked up in the tree on 2026-11-15 (worktree `wp112-linddun`, base 8eec8325): migrations
(core V1, V2, V3, V9, V14, V17, V18; game V1, V2, V4; athlete V1, V3, V6, V9), classes (`TenantHeaderFilter`,
`HealthAccess`, `ManagePlannedAbsences`, `CallerActor`, `AuditEvent`, `ChangedFields`, `AuditEventRepository`,
`ReadAuditTrail` / `AuditEntry.Actor.maskedForAcademy`, `RosterEventAppender`, `JpaOutboxQueueRepository`,
`LoginProvisioning`, `KeycloakIdentityProvider`, `LoginEmailSync`, `TenantLifecycle`, `ReplicaRetentionJob`,
`ReplicaPlayer`, `EventVisibility`, `StatVisibility`, `SecurityEventLog`, `CsvResponse`, `RosterCsv`, `MatchStore`),
tests (`HealthRoleMatrixTest`, `MatchEventFeedRoleMatrixTest`, `PlatformUserReadRlsTest`, `SharedLoginPersonsTest`,
`AuditEventRlsTest`, `RealmSecurityEventsKeycloakTest`, `TokenAudienceKeycloakTest`, `TeamRosterExportTest.theContentIsNeverLogged`,
`TenantLogoResourceTest.anotherTenantsLogoIsNotFound`, web `sign_out_test.dart`, `match_store_wipe_test.dart`,
`match_owner_test.dart`), configuration (`common-quarkus` `microprofile-config.properties`, core `application.properties`,
`infra/keycloak/realm-academy.json`, `deploy/helm/hoops/values*.yaml`, `templates/observability.yaml`, `apps/web/web/sw.js`,
`infra/tofu/main.tf`) and contracts (`core.yaml`, `athlete.yaml`, `game.yaml`, `events/core.*.schema.json`).

Not verified: whether any client strips EXIF from logos (§6); whether a game rule reads `birthDate` / `gender` beyond the
replica filter (P-10, searched by name only); backups (out of scope, as in the STRIDE model). No test was run: this
work package changes documentation only.

WP150 (2026-11-28, base cc4fb3e2) looked up every row of §9 and §10 and the corrected rows in the tree: pdf-service
(`crates/adapters/src/{auth,http,problem,render,security,telemetry}.rs`, `crates/domain/src/{team_roster,error}.rs`,
`tests/logs.rs`, `tests/api/http.rs`, the chart's `networkpolicy.yaml`, `infra/compose/compose.yaml`); its callers
(core `TeamRosterPdfTest`, `ExportResponse`; game `MatchSheetPdfResourceTest`, `MatchSheetPdfResource`,
`GetMatchSheetPdf`); finance-service (migrations V3, V4, V5, V10, V11, V20; `domain/access.go`,
`application/retention.go`, `adapters/in/rest/{exports,handler,problem}.go`, `adapters/in/events/decode.go`,
`adapters/out/persistence/replica.go`; the tests named in §10; `finance.yaml`; the chart's `values.yaml` and
`networkpolicy.yaml`; `infra/compose/nginx.conf`); ADR-0073, ADR-0074, `scripts/pg-major-move.sh`,
`docs/runbooks/postgresql-major.md`, `deploy/helm/hoops/values*.yaml`, `templates/observability.yaml`; game
`MatchLookup`, `GetPlayerSeasonStats`, `IngestEventBatch`. Read, not run: the tests are cited by name and assertion.

To verify (WP150): what finance's "request failed" log line can contain (`rest/problem.go` logs the error text of an
unexpected error; no test seeds a value into one); whether a driver message can echo refused input into a Java
exception event (ADR-0074 §4, P-15); the rows of §1–§8 that WP150 did not touch were not re-checked against the code
(only the claims the tenth round changed and the "planned" or "this round" wording).
