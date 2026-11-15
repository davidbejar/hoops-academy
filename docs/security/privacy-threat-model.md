# Privacy threat model — Hoops Academy (LINDDUN per trust boundary)

Version 2026-11-15 (WP112, decision 102). Companion to [`threat-model.md`](threat-model.md) (STRIDE: same assets, actors,
data-flow overview and trust boundaries), [`review-2026-11.md`](review-2026-11.md) (security findings F-xx / SD-xx) and
[`asvs-checklist.md`](asvs-checklist.md). Scope: the tree of `main` at 8eec8325 (core, game, athlete, `libs/common-quarkus`,
`libs/contracts`, `apps/web`, the realm export, compose and the chart) plus the two services of
[ADR-0051](../adr/0051-polyglot-services-finance-in-go-pdf-renderer-in-rust.md) that this round builds. Their code does
not exist in this tree: their rows are modelled from ADR-0051, decisions 86–103 (`docs/wp/FOLLOW-UPS.md`) and the briefs
WP111, WP116–WP119, WP123, and are marked **planned**.

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
| Guardian links | parents, players | `core.guardian_link` (V2); replicas `*.guardian_link_ref`; outbox and topic `core.guardian-link` | ADMIN writes; drives PARENT access to health, stats, absences (and finance, planned) |
| Health and fitness (GDPR art. 9) | players | `athlete.injury` (body part, free-text description, severity, dates), `athlete.body_measurement` (height, weight), `athlete.physical_test_result` (value, notes) (athlete V3); availability derived from injuries | `HealthAccess`: ADMIN, staff of the player's team, the linked PARENT, the PLAYER; former staff up to the season's end (ADR-0042) |
| Attendance, planned absences | players | `athlete.attendance` (status, free-text `note`), `athlete.planned_absence` (free-text `reason`) (athlete V1) | staff roles; PARENT linked; PLAYER self (`ManagePlannedAbsences`) |
| Match events and stats | players, the recorder | `game.match_event` (append-only; `recorded_by_person_id`, `recorded_by_display_name`, `device_id`; game V2), projections; offline copy in the browser | `StatVisibility`, `EventVisibility` (ADR-0030) |
| Author snapshots | members | `athlete.*.recorded_by_name` / `reported_by_name` / `created_by_name`, `game.match_event.recorded_by_display_name` | whoever reads the record |
| Audit trail | members, the super admin | `core.audit_event` (V9: actor `sub`, person id, action, target id, metadata), one `hoops.audit` log line per row (`AuditEventRepository`) | ADMIN of the academy (super admin masked), super admin (ADR-0029) |
| Security events | any caller | `hoops.security` log lines with `sub`, tenant, roles, route (`SecurityEventLog`, ADR-0043); Keycloak events with username (= e-mail) and IP, 30 days (realm `eventsExpiration` 2592000) | operators of the log backend; Keycloak admins |
| Academy requests | non-members | `core.academy_request` (V17: name, e-mail, role, academy name, reason) | super admin |
| Exports | as the roster | CSV files on the downloader's device (ADR-0048) | whoever holds the file |
| Device storage | the signed-in user, the players of cached matches | browser: OIDC tokens and settings in localStorage, drift DB (IndexedDB/OPFS) with matches, roster names and jersey numbers, events | the device user |
| **Planned**: finance | families (what a family owes and has paid), staff (salaries as expenses) | schema `finance` (ADR-0051 §2; WP118, WP119, WP123), its roster replica | ADMIN; PARENT linked; PLAYER self; a team's current COACH status only (decision 96) |
| **Planned**: PDF request bodies | as the roster and match sheet | in flight only, core/game → `pdf-service` (decision 89) | nobody (stateless, nothing stored or logged: ADR-0051 Consequences) |

## Data-flow overview
The STRIDE overview, plus the flows that carry personal data outside the request path (events, telemetry) and the two
planned services:
```
Browser (PWA: localStorage tokens + settings, drift DB, downloaded CSV/PDF files)
   │  HTTPS (Gateway) / HTTP (compose :8080, kind :8090)
   ▼
nginx / Envoy Gateway ──/auth──▶ Keycloak ──▶ Postgres (keycloak db: users, 30-day events)
   │  /api/core,/platform  /api/game  /api/athlete  [/api/finance planned]
   ▼
core-service ◀──/internal── game, athlete          core, game ──/internal/pdf/*──▶ pdf-service [planned, no route]
   │  outbox ──▶ Redpanda (compacted core.* topics) ──▶ replicas in game, athlete [finance planned]
   └── Postgres `hoops` (schemas core / game / athlete [/ finance planned], RLS)
services ──OTLP (traces, logs incl. hoops.audit / hoops.security)──▶ otel-collector ──▶ environment's backend
```

## 1. Browser ↔ nginx / Envoy Gateway
| LINDDUN | Threat | Mitigations (evidence) | Residual |
|---|---|---|---|
| L | A login's memberships in several academies are joined in one view (the chooser, `/me`) | Intended (ADR-0025 §2); an academy's APIs need `X-Tenant-Id` and a membership (`TenantHeaderFilter`, non-members 404); one academy never sees another's data (RLS, `GenericRlsIsolationTest`) | Whoever sees the device sees every academy of that login (Info) |
| L | The super admin links one person across academies | `GET /platform/users` reads only logins and their persons' names, roles, active flag (V18 column grants, `PlatformUserReadRlsTest`); persons without a login (young players), birth dates, phones, guardian links stay invisible | By design (decision 71); the platform knows that one adult is a member of academies A and B |
| I | API responses identify people to members who do not need it | Role-matrix tests per resource (oracle `docs/domain/authz-matrix.md`); the event feed filtered like the box score (`EventVisibility`, `StatVisibility`, ADR-0030, `MatchEventFeedRoleMatrixTest`); health confined to the player's own teams (`HealthAccess`, `HealthRoleMatrixTest`); members list leaves out PENDING/REJECTED players (F-16) | Team-level events show who recorded them (`recordedBy`, a parent's name) to every reader of the feed; training data (planned absences with their free-text reason) is readable by every staff role of the academy, not only the player's team staff (P-06) |
| N | A parent or coach is bound to a recorded event or a health write | `recorded_by_person_id` + display name on events and athlete records; VOID instead of delete (game V2) | By design (accountability for minors' data); an author cannot have their name removed from an append-only event (P-01) |
| D | Learning that a person is a member, or that an e-mail has a login | Non-members 404, never 403 (CLAUDE.md rule 3, `TenantHeaderFilter`); public academy request answers 202 whatever the e-mail (ADR-0044 §2) | F-11 (accepted): an invite reveals an existing login; `LOGIN_SHARED` / `EMAIL_TAKEN` (409, core contract `updateMember`, `IssueTemporaryPassword`) tell an ADMIN that a member's login is active in another academy or that the address has a login (P-08); inside one academy `HealthAccess` answers 403 (not 404) when a filter names a player the caller may not read (ids are UUIDs: Info) |
| DD | Bulk extraction of minors' data through the API or exports | Paging limits (`PageOffset`, page size ≤ 200 on lists); exports limited to 10,000 rows, `Cache-Control: no-store` (`CsvResponse`), current staff only for the roster (ADR-0048 amendment, decision 83); gateway rate limits for the three export paths and the public request (`deploy/helm/hoops/values.yaml` `rateLimits`); services log no bodies (`quarkus.http.access-log.enabled=false` in `common-quarkus`, `TeamRosterExportTest.theContentIsNeverLogged`) | A downloaded roster CSV (minors' birth dates, guardians' phones and e-mails) leaves every control; compose nginx has no export limit yet (WP115 adds it) |
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
| L | game and athlete build person profiles from core's answers | Answers limited to ids, roles, team ids, display names (STRIDE §3); authz context computed by core (`MembershipLookup`) | — |
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
| I | Health data readable in clear by anyone with DB access | Non-owner app roles without BYPASSRLS (`just db-role-check`); health only in schema `athlete`; cloud system disk encrypted (`infra/tofu/main.tf` `system_disk_encrypted`, ADR-0050) | No column-level encryption; backups not designed (STRIDE out of scope) |
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
Not a STRIDE boundary yet ([ADR-0036](../adr/0036-redpanda-event-broker.md) covers its security); added because it
copies personal data.

| LINDDUN | Threat | Mitigations (evidence) | Residual |
|---|---|---|---|
| L | Events tie a person's roles, teams and guardian links over time | Topics per aggregate keyed `<tenant>:<id>`; SASL/SCRAM per service with prefixed ACLs, NetworkPolicy (ADR-0036 §7); event payloads carry display name, `subject`, roles, birth date, gender, link ids only (`libs/contracts/events/core.*.schema.json`) | Compacted topics keep the latest state per key with `retention.ms=-1` (ADR-0036 §6) |
| I | Birth date and gender travel to every consumer | Required by the roster contract (P-10) | game stores both for every player |
| N | — | Not applicable | — |
| D | — | Consumers read only `core.*` (ACL) | — |
| DD | Copies outlive the person in core | Soft removals null every state column (game V6, athlete V9); tombstones kept 7 days | A person is never deleted in core, so no removal is ever emitted for them (P-01); the outbox history stays (P-03) |
| U | — | Not applicable | — |
| NC | Erasure must reach the topic, the outbox and every replica | The `.removed` + tombstone mechanism exists and is applied by both consumers (ADR-0037 amendment) | No use case triggers it (P-01) |

## 8. Services → OpenTelemetry collector → log and trace backend
| LINDDUN | Threat | Mitigations (evidence) | Residual |
|---|---|---|---|
| L | Logs tie one person's activity across academies | Logs carry ids, not names: `hoops.audit` lines (`AuditEventRepository`: action, target, actor `sub`, tenant) and `hoops.security` events (`SecurityEventLog`: `sub`, tenant, roles, route template); no tenant id on spans or resources (ADR-0046, collector `attributes/strip-ids` in `deploy/helm/hoops/templates/observability.yaml`) | The same `sub` with different `tenantId`s in one log store links a person's academies and activity; retention of shipped logs is the backend's and none is set (P-07) |
| I | Request bodies, tokens or names in logs and spans | HTTP access log off (`quarkus.http.access-log.enabled=false`); OIDC's token-quoting WARN muted (`io.quarkus.oidc.runtime.OidcProvider` at ERROR); security-event values stripped and capped, never a claim of an unverified token (ADR-0043); `url.path`, `url.query`, Kafka keys deleted from spans (collector); `TeamRosterExportTest.theContentIsNeverLogged` | Log content depends on every log statement (no automated PII check beyond the export test); kind's collector runs `debugVerbosity: normal` (prints log bodies); cloud and default are `basic` (`values-cloud.yaml`, `values.yaml`) |
| N | Security events attribute refused requests to a person | By design (ASVS 16.3.2) | — |
| D | — | Not applicable | — |
| DD | Logs kept indefinitely | — | No retention configured (ADR-0046: "retention belongs to that backend"); WP120 builds the backend this round (P-07) |
| U | — | Not applicable (operational data) | — |
| NC | — | Storage limitation applies to logs too | P-07 |

## 9. core / game → `pdf-service` (planned: WP111, WP116, WP117)
| LINDDUN | Threat | Mitigations (planned; evidence = ADR / decision / brief) | Residual |
|---|---|---|---|
| L | The renderer collects rosters of many academies | Stateless: no database, no broker, no outbound network (ADR-0051 §3); nothing stored | — |
| I | Request bodies (minors' names, birth dates, guardians' contacts for the roster) reach logs, spans or Problems | "Nothing from a request body is logged or put on a span" (ADR-0051 Consequences, WP111 scope 3); callers log nothing of the roster (WP116 scope 2) | Parse and validation errors of typical Rust deserialisers quote the offending value; if a Problem `detail` or a log line carries it, a child's name or birth date leaks into core/game logs (P-11) |
| N | — | Export audited by the calling service (`team.roster_exported` with the format, WP116) | game has no audit trail: the match sheet export is audited only "if the matrix asks for one" (WP117) |
| D | Anyone calls the renderer | No gateway route; NetworkPolicy admits core and game only; audience `pdf-service` and realm role `service`; a `web` token refused by test (decision 89, WP111 scopes 4–5) | — |
| DD | A PDF carries more than its readers see | Same authz as the CSV (decision 83) and the box score (WP117 scope 1: "if the sheet shows more than those readers see today, stop") | A printed roster with guardians' phones cannot be recalled (P-11) |
| U | — | Labels in the user's language (decision 90) | — |
| NC | — | Processor-like role inside the platform; no storage | — |

## 10. Browser ↔ `finance-service` (planned: WP118, WP119, WP121, WP123, WP124)
| LINDDUN | Threat | Mitigations (planned; evidence = ADR / decision / brief) | Residual |
|---|---|---|---|
| L | Payment history links a family's finances to the child's roster and attendance | Schema `finance` with RLS and its own roles (ADR-0051 §2); roster from events, no REST to core | The finance replica copies whatever core's events carry, including birth date and gender, unless WP119 drops them (P-10) |
| I | A coach identifies which families are behind on payments | Decision 96: COACH of the team sees status only, no amounts, no expenses, no balance; ASSISTANT_COACH nothing | By design: payment status of a family is disclosed to the coach (P-12) |
| N | A waiver or a voided payment binds a family to a hardship | Audit records for every write (WP119 scope 3, ADR-0017 pattern) | Free-text reasons (waive, amount change, void) and notes (payment, expense) will hold hardship or salary details; ADR-0017 forbids personal data in audit metadata (P-12) |
| D | A parent learns that another family has dues | Non-members 404, a parent of another player gets no existence leak (WP119 scope 4) | — |
| DD | Exports of dues and expenses | ADR-0048 spec, 10,000 rows, audit per export (WP123 scope 3) | Gateway rate limits for the finance export paths are not named in the briefs (P-12) |
| U | Families do not know what is recorded about their payments | Parent and player read their own dues and payments (decision 96) | Whether a family sees the waiver or void reason is not decided (P-12) |
| NC | Financial data of identifiable families (not art. 9, but sensitive; ADR-0051: "the same care as health data") | As above | Retention of finance records (tax law may require years) not decided; joins P-02 |

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
| Replica bookkeeping | 7 / 30 days | `ReplicaRetentionJob` (game, athlete) |
| Keycloak events | 30 days | realm `eventsExpiration`, `adminEventsExpiration` |
| Shipped logs and traces | The backend's; none set | ADR-0046; P-07 |
| Device data | Until sign-out or the next user's sign-in | `MatchStore.wipe`, `bindOwner` |

## Findings

Severity follows the security review's rubric (a concrete path, then impact), applied to the project as it runs today
(learning project, demo data). "Gate" = must be closed or consciously accepted before real academies use the system.

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
| P-10 | Info | no | Data minimisation of the replicas: game (and athlete) store every player's birth date and gender because core's roster contract requires them; no game rule using them beyond that filter was found (not verified exhaustively); the finance replica (WP119) would copy them too | game V4 `player_ref`, `ReplicaPlayer`, `libs/contracts/events/core.player.schema.json` | WP119 stores only what finance needs (no birth date, gender or `subject` unless a rule needs it); check whether game needs them and drop them from its replica if not |
| P-11 | Low | no | **Planned** `pdf-service`: parse and validation errors can quote request values (names, birth dates) into Problem details or the callers' logs; the roster PDF reproduces guardians' contact data on paper | ADR-0051 §3, decision 89, WP111 / WP116 / WP117 | WP111: generic 400/422 details that never echo input, a test that a known personal value appears in no response and no log line; WP116 / WP117: never log a `pdf-service` Problem body; WP116 decides whether guardians' contacts belong on the printed roster |
| P-12 | Low | no | **Planned** finance: free-text reasons and notes (waive, amount change, void, payment, expense) will carry hardship or salary details into the audit trail and exports; a team's coach learns which families are behind (decision 96, by design); parent visibility of reasons, export rate limits and record retention are undecided | ADR-0051 §2, decisions 95–97, WP118 / WP119 / WP123 | Keep reasons and notes out of audit metadata and logs (or list them as a named exception, as `tenant.suspended`'s reason); decide in WP119 whether a family sees reasons; gateway rate limits on the finance export paths (WP123); retention period for finance records (joins P-02) |
| P-13 | Low | no | A guardian link is created by one ADMIN, with no confirmation and no notification to the player (with a login) or the other guardians; a wrong link gives an adult read and write access to a child's health records (and finance, planned) | authz matrix "Members, roles, guardian links: ADMIN"; `guardian_link.created` audit (ADR-0017) | Show a player and existing guardians who is linked (and when a link is added) in their own profile; for real academies, a second ADMIN confirmation or the existing guardian's acknowledgement |

**Counts:** Critical 0 · High 0 · Medium 2 · Low 8 · Info 3 (13 findings; 2 of them on planned services). Gate before real
academies: P-01 to P-05.

Accepted by design and not repeated as findings: F-11 and F-22 (ADR-0025). Their privacy impact, for the record: under
F-22 an admin of academy A who created a login for someone else's address enters academy B as that person once B
invites the address, and reads what that person may read there (a parent's linked children, including health records);
under F-11 the owner of a login is linked into another academy without being asked.

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
replica filter (P-10, searched by name only); backups (out of scope, as in the STRIDE model); everything marked
**planned** (§9, §10, P-11, P-12), which rests on ADR-0051, decisions 86–103 and the briefs, not on code. No test was
run: this work package changes documentation only.
