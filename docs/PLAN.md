# Hoops Academy — Multitenant Basketball Academy Platform: Build Plan

## Context

A greenfield application for basketball academies. Each academy (tenant) tracks its players' progress
across **games** (live box-score entry), **training** (calendar, plans, completion, attendance,
absences) and **physical development** (fitness tests against age norms, height/weight history,
injuries). Tenants are fully isolated. A platform super-admin onboards/withdraws academies and sees
usage statistics. Billing is out of scope now but must be easy to add.

The source spec is `dummy_project2_specs.md` (the only file in the directory; no git repo yet). The
plan is designed to be **executed by separate AI coding agents**, each on the most suitable model
(Sonnet for routine work, Opus for security-critical / intricate logic). Fable is used only for this
plan and, per the user's update on 2026-11-01, also executes it, delegating work packages to Sonnet/Opus
agents and adjusting the plan where needed as long as the intended application and core features are
preserved.

### Decisions locked with the user (2026-11-01)

| Topic | Decision |
|---|---|
| Repo location | **`~/code/hoops-academy`** (outside OneDrive). The OneDrive folder keeps spec + plan + a README pointer |
| Repo shape | Single monorepo |
| Backend | Java 21 LTS, **Quarkus 3.x** (latest, pinned in WP0), Maven multi-module, hexagonal layering per service |
| Services (v1) | **3 services**: `core-service`, `game-service`, `athlete-service` (see §1.2) + nginx/ingress, Keycloak, Postgres |
| Frontend | **Flutter Web (Dart)** mobile-first PWA; no Node anywhere in the toolchain |
| Auth | **Keycloak** = authentication only (OIDC/PKCE). Tenant roles live in our DB, not in tokens |
| Roles | Tenant: `ADMIN`, `COACH`, `ASSISTANT_COACH`, `PARENT`, `PLAYER` (union per user). Platform: realm role `super_admin` |
| Age rule | Per-tenant setting `age_rule`, **default `BIRTH_YEAR`** (season reference year − birth year); `BIRTHDAY` (actual age) also implemented |
| Database | **PostgreSQL 17**, one database, **schema per service**, non-owner app role per service, `tenant_id` + **Row-Level Security**; local = one container, k8s = CloudNativePG |
| Containers | Podman (rootful machine) + `podman compose` → kind (podman provider) + Helm + Tilt |
| Events | v1 synchronous REST behind a `RosterPort`; v2 outbox + Redpanda (designed, optional WP19) |
| Billing | Extension points only: `billing.plan`, `billing.tenant_subscription`, `EntitlementService` port (noop impl), outbox events |
| Languages | UI trilingual from the start: **Spanish, English, Indonesian** (`es`, `en`, `id`); locale per user with tenant default |
| Academy logo | Tenant has a **logo uploaded by an ADMIN** (PNG/JPEG/WebP/SVG-sanitised, ≤ 512 KB, stored in Postgres `core.tenant_logo` bytea, served with ETag caching; object storage is a documented extension) |

### Environment found on this machine

Present: Java 23, podman 6.1.4, kubectl, brew, a `docker` CLI shim. Missing: maven, kind, helm, tilt,
flutter/dart, podman-compose, gitleaks, node (intentionally absent).

---

## 1. Architecture

### 1.1 Monorepo layout

```
~/code/hoops-academy/
├── CLAUDE.md                      # conventions, commands, DoD — agents read this first
├── .claude/skills/                # clean-code, owasp-security, tdd + project-local skills (§4)
├── docs/{adr,domain,wp,runbooks}/ # ADRs, domain rules & authz matrix, WP briefs/handovers
├── pom.xml                        # parent: Quarkus BOM, Java 21, JaCoCo/PIT/ArchUnit/dependency-check
├── libs/
│   ├── common-quarkus/            # tenant context, RLS interceptor, authz, Problem+JSON, test fixtures (test-jar)
│   └── contracts/                 # OpenAPI yaml ×3, JSON Schemas for match events, Dart client gen config
├── services/{core-service,game-service,athlete-service}/
├── apps/web/                      # Flutter PWA
├── infra/
│   ├── db/init/01_roles_schemas.sql   # schemas, roles, app.current_tenant() — shared by compose, tests, CNPG
│   ├── keycloak/                      # realm export (no credentials) + kcadm seed script
│   └── compose/                       # compose.yaml, nginx.conf
├── deploy/{helm/hoops,kind}/      # umbrella chart + subcharts; kind config & install scripts
├── Tiltfile
├── e2e/                           # black-box journey tests (Java) + Flutter integration tests
├── scripts/                       # bootstrap.sh, doctor.sh, podman-env.sh, gen-api.sh
├── justfile, .env.example, .gitleaks.toml, .pre-commit-config.yaml, .editorconfig, .gitignore
└── .github/workflows/             # ci.yml, images.yml
```

### 1.2 Services and bounded contexts

Three services keep each agent lane self-contained (one Flyway schema, one Helm subchart, one OpenAPI
contract each) while the only cross-service surface is a single port.

| Service | Bounded contexts | Owned tables (schema) |
|---|---|---|
| **core-service** | Tenancy, Identity & Membership, Roster & Eligibility, Approvals, Platform stats, Billing seams | `core`: `tenant`, `tenant_settings`, `tenant_logo`, `app_user` (global, keycloak `sub`), `person`, `membership_role`, `player`, `guardian_link`, `season`, `age_category`, `team`, `team_player`, `team_staff`, `eligibility_case`, `approval_request`, `usage_snapshot`, `outbox`; `billing`: `plan`, `tenant_subscription` |
| **game-service** | Match operations & statistics (offline-first, event-sourced) | `game`: `match`, `match_roster`, `match_event` (append-only), `match_player_stats`, `match_summary` (projections), `sync_receipt` |
| **athlete-service** | Training & attendance; Athlete health & fitness | `athlete`: `training_schedule`, `training_session`, `training_plan`, `plan_item`, `plan_assignment`, `plan_completion`, `planned_absence`, `attendance`, `injury`, `body_measurement`, `physical_test_type`, `physical_test_result`, `physical_test_norm` |

Why not more: tenant sign-up must atomically create tenant + first ADMIN membership (so platform and
academy belong together); training and health data share actors, authz shape and roster dependency.
No custom API gateway: nginx (local) / ingress-nginx (kind) route `/api/core|game|athlete/**`, `/auth`,
`/`; each service validates JWTs with `quarkus-oidc`; `/internal/**` is blocked at the proxy.

DB roles: `core_app`, `game_app`, `athlete_app` (no ownership, no `BYPASSRLS`, grants only on own
schema), `*_migrator` (own tables, run Flyway), `core_platform` (super-admin datasource: `tenant`,
`usage_snapshot`, `billing.*` only). Same init SQL in compose, Testcontainers and CNPG.

### 1.3 Multitenancy and authorization

- **Keycloak**: realm `academy`; clients `web` (public PKCE), `core-service`/`game-service`/
  `athlete-service` (confidential, service accounts for `/internal` calls). Only `super_admin` lives in
  Keycloak. Core provisions users on invite via `keycloak-admin-client` (create user + required-action
  email). Access token 5 min; SSO idle ≥ 4 h so a match can be scored offline.
- **Per request**: frontend sends `Authorization` + `X-Tenant-Id` (chosen in a tenant switcher fed by
  `GET /api/core/me`). A `ContainerRequestFilter` in `common-quarkus` builds `AuthzContext{sub,
  personId, tenantId, roles, staffTeamIds, linkedPlayerIds, ownPlayerId}` — core from its DB, the other
  services via `RosterPort.authzContext()` (REST to core `/internal/authz/{tenant}/{sub}`, 30 s cache).
  Non-member → **404** (never leak existence). Resources use `@RequiresTenantRole(...)` plus
  fine-grained checks (`Authz.canEnterStatFor(playerId)`); `@RolesAllowed` only for `super_admin` and
  the `service` role.
- **RLS, two layers**: (1) Hibernate discriminator multitenancy (`@TenantId`) so every query is tenant
  filtered by construction; (2) a `@Transactional`-bound interceptor runs
  `select set_config('app.tenant_id', :t, true)` and every tenant table has
  `ENABLE + FORCE ROW LEVEL SECURITY` with a policy on `app.current_tenant()`, a function that
  **raises** if the variable is unset (forgotten tenant = loud error, not empty list). Global tables
  (`training_plan` templates, `physical_test_norm`, `tenant`, `app_user`) are allow-listed with
  explicit policies. `hibernate-orm.database.generation=none`, Flyway as migrator role, validate mode in
  tests.
- **Super admin**: `/platform/**` requires `super_admin`, skips the tenant filter, uses the
  `core_platform` datasource; cross-service counts via `/internal/usage/{tenant}` with a
  client-credentials token. Super admin cannot read tenant content.
- **Jobs**: `TenantScope.runAs(tenantId, work)` opens a transaction with the variable set; jobs
  iterate tenants from the platform datasource in each tenant's timezone.
- **Automatic isolation tests** (in `common-quarkus` test-jar, inherited by every service):
  schema meta-test (every `tenant_id` table has RLS + FORCE + policy, others allow-listed);
  generic data-driven RLS test (A/B rows: select=1, cross update/delete=0, cross insert → 42501,
  unset variable → raises); API cross-tenant 404 tests; role-matrix tests parameterised over roles
  and unions; ArchUnit (no `@Transactional` in resources, no native SQL outside repositories, no
  `tenantId` field without `@TenantId`); one CI-only suite with a real Keycloak Testcontainer.

### 1.4 Cross-service data access

v1: `RosterPort` (`teamRoster`, `player`, `authzContext`, `playersBirthAndGender`) implemented as a
Quarkus REST client to core `/internal/**` with client-credentials token, 30 s Caffeine cache, 2 s
timeout → 503 Problem+JSON. Game denormalises `display_name`/jersey at roster creation so offline sync
never depends on core. Tests via WireMock stubs generated from the OpenAPI contract; core validates its
`/internal` responses against the same contract.
v2 (WP19, optional): `core.outbox` polled (`FOR UPDATE SKIP LOCKED`) → Redpanda
(`quarkus-messaging-kafka`, Dev Services) → `*_ref` replica tables; port adapter swapped behind a flag.
Billing subscribes to the same topics; `EntitlementService.check(tenant, PLAYERS|TEAMS)` is already
called from `createTeam`/`addPlayer` with a noop implementation.

### 1.5 Frontend (Flutter Web PWA)

`oidc` package (PKCE, `web/redirect.html`), `go_router` with auth guard, Riverpod, Dio interceptors
(bearer, `X-Tenant-Id`, Problem+JSON), clients generated with `openapi-generator-cli` jar (`dart-dio`),
Material 3 mobile-first theme, deferred libraries per feature, `flutter build web
--pwa-strategy=offline-first`, standard CanvasKit build (no COOP/COEP — it breaks Keycloak iframes),
Drift on `sqlite3.wasm` with IndexedDB fallback for the offline event queue, `fl_chart`, `intl` + ARB files for `es`, `en`, `id` (Indonesian).
Served from `nginxinc/nginx-unprivileged`.

---

## 2. Domain model and rules (acceptance basis)

### Roster & eligibility (core)
- `person(tenant, user_id nullable, names, birth_date, gender, contact)`; `membership_role(person, role)`
  (PLAYER requires birth_date + gender); `player(status PENDING_APPROVAL|ACTIVE|ORPHAN|WITHDRAWN)`;
  `guardian_link(guardian_person, player)`; `season` (non-overlapping, `reference_year`);
  `age_category(code U12, max_age inclusive, rank; NULL = senior)` seeded U8…U18, SENIOR, editable;
  `team(season, name/alias, age_category, gender_policy MALE|FEMALE|MIXED)`;
  `team_player(jersey, joined/left, play_up_levels, invalidated_at, invalid_reason)` (a player may be on
  several teams); `team_staff(team, person, COACH|ASSISTANT_COACH)` — "coach trains N categories" is
  derived from staffed teams (single source of truth for authz).
- Pure `eligibility` package: `AgeFunction` strategy (`BIRTH_YEAR` default / `BIRTHDAY`);
  `naturalCategory`; `eligibility(player, team, asOf) → ELIGIBLE | PLAY_UP(n) | INELIGIBLE(reason)` with
  reasons `CATEGORY_TOO_LOW, PLAY_UP_LIMIT_EXCEEDED, GENDER_POLICY, MISSING_BIRTH_DATE, MISSING_GENDER,
  PLAYER_NOT_ACTIVE`. Invariants: team rank ≥ natural rank; play-up ≤ `tenant.max_play_up_levels`
  (null = unlimited); gender policy; ORPHAN ⇔ ACTIVE player with no valid open assignment.
- Evaluator never deletes: it sets `invalidated_at` + reason and opens `eligibility_case` (OPEN →
  RESOLVED by ADMIN or the team's staff). Triggered nightly per tenant (catches `BIRTHDAY` mode) and
  synchronously by `POST /seasons/{id}/rollover` (clones teams into the new season, returns orphan
  list — the real orphan generator under `BIRTH_YEAR`). Assignment UI only offers eligible teams.

### Approvals (core)
`approval_request(action ADD_PLAYER|WITHDRAW_PLAYER, payload, requester, status
PENDING|APPROVED|REJECTED|CANCELLED, decider, note)`. ADMIN executes immediately (audit row
auto-approved); COACH without ADMIN creates PENDING; assistants cannot request. ADD creates the player
as `PENDING_APPROVAL` (visible to admins + requester only); approval applies the optional team
assignment through the eligibility-checked command (may 422 and stay PENDING). WITHDRAW keeps the
player ACTIVE until approval. Only PENDING can be decided; one PENDING per (action, player).

### Match statistics (game) — append-only events + projections
- `match(team, season, opponent, home/away, scheduled_at, venue, status SCHEDULED|LIVE|FINISHED|
  CANCELLED, period_count, period_minutes)`; `match_roster(player, display_name, jersey, is_starter)`.
- `match_event(id = client UUIDv7, match, server_seq, device_id, client_seq, type, player, period,
  clock_seconds_remaining, payload jsonb, recorded_by, recorded_at_client, received_at, voided_by)`;
  unique (id), unique (match, device_id, client_seq). Types: `PERIOD_START/END`, `SUB_IN/OUT`,
  `SHOT{points 1|2|3, made}`, `ASSIST`, `REBOUND{OFF|DEF}`, `TURNOVER`, `STEAL`, `BLOCK`,
  `FOUL{PERSONAL|TECHNICAL|UNSPORTSMANLIKE}`, `OPPONENT_SCORE`, `TIMEOUT`, `VOID{target}`, `NOTE`. Each
  has a JSON Schema in `libs/contracts`. Server validates **schema + authz only**, never domain
  consistency (an impossible SUB becomes a projection *warning*; staff fix with VOID) — required for
  offline tolerance across multiple scorers.
- `POST /matches/{id}/events:batch` → per-event `ACCEPTED|DUPLICATE|REJECTED{reason}`; locks the match
  row and re-projects `match_player_stats` (pts, fg 1/2/3 made/att, ast, oreb, dreb, tov, stl, blk, pf,
  seconds_played, was_starter, warnings) and `match_summary` (scores, period scores, `last_server_seq`).
  Ordering `(period, clock desc, recorded_at_client, server_seq)`; `GET /events?after=seq` lets other
  devices merge. Minutes derive from starters + period/sub events.
- Authz: team staff → any event + state transitions; PARENT → player-attributed stat events for linked
  players only, VOID of own events only, never clock/period/opponent/roster; PLAYER read-only.

### Training (athlete)
`training_schedule` (weekday, time, duration, location, validity) materialised 8 weeks ahead into
`training_session` (ad-hoc sessions allowed, `plan_id` nullable, PLANNED|DONE|CANCELLED);
`training_plan` + `plan_item` (global templates `tenant_id NULL`, seeded ~10; copy-on-use into tenant);
`plan_assignment` (exactly one of team/player, due date) fans out to current roster at read time;
`plan_completion(assignment, player, DONE|PARTIAL|NOT_DONE)` by self / linked parent / team staff;
`planned_absence(player, from, to, reason)` by parent/player/staff; `attendance(session, player,
PRESENT|LATE|ABSENT|EXCUSED, minutes_late)` by staff; read model overlays absences as "expected absent".

### Health & fitness (athlete)
`injury(player, occurred_on, body_part, severity, expected_return_on ≥ occurred_on, actual_return_on,
OPEN|RECOVERED)` → player shown unavailable in rosters; `body_measurement(player, measured_on, height_cm,
weight_kg)` unique per day, editable by parent + staff; `physical_test_type(code, unit,
higher_is_better)`; `physical_test_result`; `physical_test_norm(test, gender, age range, band
POOR…EXCELLENT, min/max; tenant rows override global)`. Expected level = band for (gender, age at
measurement, value). Seeds must cite sources; uncited values are flagged "reference pending" in the UI.

### Authorization matrix (oracle for role-matrix tests)

| Capability | ADMIN | COACH (team staff) | ASSISTANT (team staff) | PARENT (linked) | PLAYER (self) |
|---|---|---|---|---|---|
| Members, roles, teams, categories, seasons | yes | – | – | – | – |
| Add / withdraw player | direct | via approval | – | – | – |
| Assign players, resolve orphan cases | yes | own teams | – | – | – |
| Match create/start/finish, roster, clock | yes | yes | yes | – | – |
| Enter stat events | yes | all team | all team | linked only | – |
| View match stats | yes | yes | yes | linked | self |
| Training schedule/sessions/plans | yes | yes | yes | read | read |
| Mark plan completion | yes | team | team | linked | self |
| Planned absence | yes | yes | yes | linked | self |
| Attendance (late/missing) | yes | yes | yes | – | – |
| Injuries | yes | yes | yes | linked | – |
| Height/weight | yes | yes | yes | linked | read |
| Physical tests | yes | yes | yes | read | read |
| Tenant lifecycle, usage stats | `super_admin` only | | | | |

Tenant withdrawal: logins blocked immediately, data retained for a configurable period, purge job is v2.

---

## 3. Engineering standards (apply to every work package)

- **TDD** (red → green → refactor), tests committed before implementation. Backend: JUnit 5, AssertJ,
  Mockito, jqwik (property tests), `@QuarkusTest` + Testcontainers Postgres **as the non-owner app
  role** (Dev Services' superuser connection would silently bypass RLS — the most dangerous false green
  in this project), REST Assured, WireMock for peers, ArchUnit, swagger-request-validator against the
  contracts; JaCoCo ≥ 80 % lines / ≥ 90 % in `domain`; PIT on domain modules. Frontend: `flutter test`,
  golden tests, `integration_test` on Chrome against compose. E2E journey suite in `e2e/`.
- **Clean code / hexagonal**: `domain` (no framework) → `application` (use cases, ports) →
  `adapters/{in/rest,out/persistence,out/keycloak,out/client}`; value objects (`TenantId`, `PlayerId`,
  `Age`); small classes, intention-revealing names; ArchUnit enforces layering.
- **Security**: OWASP ASVS L2 checklist; Bean Validation; Problem+JSON without stack traces; CORS
  allow-list; security headers at proxy; rate limits on `/auth` and batch ingest; audit log for admin
  actions; dependency-check + Trivy + gitleaks gates; non-root UBI-micro/distroless images; least
  privilege DB roles; secrets never in git.
- **Secrets**: `.env.example` committed, `.env`/`values-local.yaml`/keys ignored; gitleaks +
  `detect-private-key` pre-commit and CI (full history scan at WP0); Keycloak realm export without
  credentials, dev users seeded via `kcadm` from env; kind: CNPG-generated Secrets referenced by
  `existingSecret`, others created by Tilt from env; ADR for External Secrets Operator beyond local.
- **Definition of Done per WP**: `./mvnw verify` / `flutter test` green, coverage gates met, contracts
  updated and validated, ADR if a decision was made, `docs/wp/<id>.md` handover, conventional commits,
  no TODO without an issue reference.

---

## 4. Skills (from the internet) and project-local skills

Installed/vetted in **WP0** — read each `SKILL.md` and any hooks before adopting (malicious skills have
been found in the wild; Trail of Bits maintains a curated marketplace for that reason):

| Purpose | Source | How |
|---|---|---|
| TDD discipline, systematic debugging, verification-before-completion | `obra/superpowers` | `/plugin marketplace add obra/superpowers-marketplace` → `/plugin install superpowers@superpowers-marketplace` |
| Clean code operating contract | `markoa/clean-code-skill` | copy `skills/clean-code/` → `.claude/skills/clean-code/` |
| OWASP Top 10 / ASVS 5 checklists, secure patterns | `agamm/claude-code-owasp` | copy `.claude/skills/owasp-security/` into repo |
| Security audit workflows | `trailofbits/skills` (+ `skills-curated`) | `/plugin marketplace add trailofbits/skills`; install `audit-context-building`, `testing-handbook-skills` |
| Reference implementations | `anthropics/skills` | `/plugin marketplace add anthropics/skills` |

Project-local skills to write: `quarkus-hexagonal-service` (add use case/endpoint/migration with RLS
here), `tenant-isolation-testing`, `flutter-feature` (screen + provider + repository + tests),
`podman-dev-env` (socket, Ryuk, troubleshooting), `work-package` (how an agent starts/finishes a WP).
`CLAUDE.md` states when each applies.

---

## 5. Work packages, lanes and model assignment

Model rule: **Opus** for security boundaries, tenancy, concurrency, offline sync, intricate domain
rules, contracts, and Podman/kind/Tilt quirks; **Sonnet** for scaffolding, CRUD, screens, docs, CI,
seeds. Each WP gets a brief in `docs/wp/<id>.md` (written in WP0 from this plan) and runs as one
`Agent` with `model: sonnet|opus`; the orchestrating session is Opus.

| ID | Package | Depends on | Model | Lane |
|---|---|---|---|---|
| WP0 | Repo bootstrap, toolchain, conventions, skills, secrets hygiene | — | Sonnet | — |
| WP1 | Local infra: compose, Postgres init SQL, Keycloak realm, nginx | WP0 | Sonnet | ∥ WP2a/2b |
| WP2a | `common-quarkus`: tenant context, RLS, authz, Problem+JSON, test fixtures | WP0 | **Opus** | ∥ |
| WP2b | API contracts (OpenAPI ×3, event JSON Schemas, Dart gen) | WP0 | **Opus** | ∥ |
| WP3 | core: tenancy, identity, membership, platform endpoints | WP1, 2a, 2b | **Opus** | CORE |
| WP4 | core: seasons, categories, teams, eligibility engine, orphan job, rollover | WP3 | **Opus** | CORE |
| WP5 | core: approvals workflow | WP4 | Sonnet | CORE |
| WP6 | game: match + roster CRUD, `RosterPort` REST adapter | WP2a, 2b | Sonnet | GAME |
| WP7 | game: event ingest, idempotency, projections, parent rule | WP6 | **Opus** | GAME |
| WP8 | athlete: schedule, sessions, attendance, absences | WP2a, 2b | Sonnet | ATHLETE |
| WP9 | athlete: plans, templates, assignments, completion | WP8 | Sonnet | ATHLETE |
| WP10 | athlete: injuries, measurements, tests + norms (cited seeds) | WP8 | Sonnet | ATHLETE |
| WP11 | Flutter shell: PKCE auth, routing, tenant switcher, generated clients, design system, PWA | WP2b | Sonnet | WEB |
| WP12 | Flutter: admin & roster (incl. academy profile + logo upload), approvals inbox, orphan cases, invitations | WP11, WP5 contract | Sonnet | WEB |
| WP13 | Flutter: live match scoring, offline queue + sync | WP11, WP7 contract | **Opus** | WEB |
| WP14 | Flutter: training, attendance, health & fitness, player profile, super-admin console | WP11, WP9/10 contract | Sonnet | WEB |
| WP15 | Usage statistics aggregation + `/internal/usage` in game/athlete | WP3, 6, 8 | Sonnet | close |
| WP16 | kind + Helm + Tilt + CNPG + Keycloak-in-kind + secrets | WP1 + one service image | **Opus** | INFRA (early) |
| WP17 | Security hardening, observability, CI gates | all services | **Opus** | close |
| WP18 | E2E journey suite (compose and kind) + Flutter integration tests | WP12–14, WP16 | Sonnet | close |
| WP19 | v2 outbox + Redpanda + replicas (optional) | WP17 | **Opus** | post-v1 |
| WP20 | Docs (user guides per role, runbooks, architecture), final spec-conformance review | WP18 | Sonnet (docs) + **Opus** (review) | close |

Parallelism: `WP0 → {WP1 ∥ WP2a ∥ WP2b} → {CORE ∥ GAME ∥ ATHLETE ∥ WEB} (+ INFRA once an image
builds) → {WP15 ∥ WP17 ∥ WP18} → WP20`. ≈ 22 agent runs (Opus 11, Sonnet 11).

### Package details (scope → acceptance)

**WP0 — Bootstrap (Sonnet).** `scripts/bootstrap.sh`: `brew install temurin@21 maven kind helm
tilt podman-compose gitleaks pre-commit openapi-generator trivy just && brew install --cask flutter`;
`podman machine init --rootful --cpus 6 --memory 12288`, `sudo podman-mac-helper install`;
`scripts/doctor.sh` checks socket, Ryuk (`ryuk.container.privileged=true` in
`~/.testcontainers.properties`), versions. `git init` at `~/code/hoops-academy`; parent `pom.xml`
(Quarkus BOM pinned to latest 3.x), module skeletons, `.gitignore`, `.env.example`, `justfile`
(`up`, `test`, `kind-up`, `doctor`), pre-commit (gitleaks, detect-private-key), ADR-0001…0008 (repo
outside OneDrive, monorepo, Quarkus, Flutter, Keycloak-auth-only, RLS tenancy, 3 services, sync REST
v1 / Redpanda v2), skills (§4), `CLAUDE.md`, all `docs/wp/*.md` briefs, CI skeleton, README pointer in
the OneDrive folder. → `./mvnw -q validate` ok; `pre-commit run --all-files` ok; committing a fake AWS
key is blocked; a throw-away `@QuarkusTest` with Postgres Testcontainer passes on Podman.

**WP1 — Local infra (Sonnet).** `compose.yaml`: `postgres:17` (init SQL creating schemas, roles,
`app.current_tenant()`), Keycloak 26 (`start-dev --import-realm`, `KC_HTTP_RELATIVE_PATH=/auth`,
`KC_HOSTNAME=http://localhost:8080/auth`, proxy headers), nginx `:8080` routing, MailHog; realm export
without credentials; `kcadm` seed for dev users from env. → stack healthy; OIDC discovery reachable;
`psql` as `core_app` cannot read `game.*`.

**WP2a — common-quarkus (Opus).** `TenantContext`, `TenantHeaderFilter`, `AuthzContext`,
`@RequiresTenantRole`, `TenantTransactionInterceptor` (set_config), Hibernate `TenantResolver`,
`TenantScope.runAs`, Problem+JSON mappers, `ServiceTokenClientFilter`, test-jar (`PostgresRlsResource`,
`RlsSchemaMetaTest`, `GenericRlsIsolationTest`, `@TenantUser`). → filter tests (400/404/super_admin
only on `/platform`); interceptor correct across `REQUIRES_NEW`; generic RLS tests pass on a sample
migration and fail when a policy is dropped.

**WP2b — Contracts (Opus).** `core.yaml`, `game.yaml`, `athlete.yaml`, shared `problem.yaml`,
`X-Tenant-Id` param, `/internal` tagged, JSON Schema per event type, spec validation in Maven,
`dart-dio` generation (`scripts/gen-api.sh`), WireMock stubs for `/internal`. → specs lint clean;
generated Dart compiles.

**WP3 — core: tenancy/identity (Opus).** Flyway V1–V4 with RLS; `/platform/tenants`
(create = tenant + seeded categories + first ADMIN provisioned in Keycloak; suspend; withdraw), `/me`,
tenant profile incl. `PUT/GET/DELETE /api/core/tenant/logo` (ADMIN upload, magic-byte + size validation,
SVG sanitised or rejected, ETag/Cache-Control on read),
members + roles, guardian links, `/internal/authz`, `/internal/usage`, platform datasource,
`EntitlementService` + noop, outbox table. → RLS suites green; cross-tenant 404s; super_admin blocked
from `/api/core/**` without membership; contract validation on every response.

**WP4 — core: roster & eligibility (Opus).** Seasons, categories, teams, assignments, staff; pure
eligibility package with both `AgeFunction`s; `eligibility_case`; nightly job; rollover endpoint. →
jqwik properties (never lower category, gender policy, play-up limit, idempotent status derivation);
year-boundary/leap-day cases; two-tenant job isolation; rollover orphan list.

**WP5 — core: approvals (Sonnet).** → admin path leaves audit row; coach path hides
PENDING_APPROVAL player from parents/players; approve with ineligible team → 422 and stays PENDING;
double decide → 409.

**WP6 — game: match & roster (Sonnet).** → role matrix; adapter timeout → 503; RLS suite.

**WP7 — game: stat events (Opus).** → two threads posting overlapping batches == single-threaded
replay; re-post → all DUPLICATE, projection unchanged; table-driven minutes tests (re-entry, period
boundaries, overtime); parent SHOT for linked player ok, other player / PERIOD_START / VOID of coach
event → 403.

**WP8–10 — athlete (Sonnet).** → idempotent schedule materialisation incl. DST; attendance matrix
and absence overlay; global templates read-only via RLS policy test on nullable `tenant_id`;
copy-on-use; completion permissions; norm band precedence and age edges; seed file with citations.

**WP11 — Flutter shell (Sonnet).** → guard/switcher widget tests; login against compose Keycloak in
`integration_test` (chromedriver); Lighthouse "installable"; CanvasKit build with deferred features.

**WP12 / WP14 — Flutter screens (Sonnet).** → widget tests with mocked clients; role-aware UI and
server-403 handling; orphan dashboard; approvals inbox; growth and test-vs-norm charts; super-admin
console.

**WP13 — Flutter live match + offline (Opus).** Drift store, `pending_events` with UUIDv7 +
`(device_id, client_seq)`, local projector sharing JSON test vectors exported from WP7, background sync
with backoff handling `ACCEPTED|DUPLICATE|REJECTED` individually (never silent drop), pull
`?after=seq`, proactive token refresh, queue preserved on 401, tap-player→action UI, undo = VOID,
"N unsynced" indicator. → Dart passes WP7 vectors; offline scenario 50 queued → 50 ACCEPTED → replay
50 DUPLICATE; expired-refresh path keeps queue.

**WP15 — Usage stats (Sonnet).** → `GET /platform/tenants/{id}/usage` aggregates 3 services; nightly
snapshot; WireMock peers.

**WP16 — kind + Helm + Tilt (Opus).** `KIND_EXPERIMENTAL_PROVIDER=podman`, kind config with
8080/8443 port maps, ingress-nginx, CNPG operator + `hoops-db` (init SQL via `postInitApplicationSQL`)
+ `keycloak-db`, Keycloak production mode from official image with own templates (realm ConfigMap,
admin Secret, slow readiness), umbrella chart + per-service subchart (Deployment, Service, Ingress path,
probes, SecurityContext, NetworkPolicy, `existingSecret`), Flutter nginx chart, Tiltfile with
`custom_build` → Quarkus Jib tar → `kind load image-archive` (no local registry tricks), Flutter via
`podman build`, secrets from env via `secret_from_dict`, `values-local.yaml` ignored. → `tilt up` from
clean machine all green; `helm lint`/template snapshots; smoke `/api/core/me` through ingress;
`helm template | gitleaks detect --pipe` clean.

**WP17 — Hardening & observability (Opus).** dependency-check, Trivy, security headers, CORS,
rate limits, ZAP baseline in CI against compose, audit log, threat model, `/internal` exposure review,
Keycloak hardening (brute force, password policy), Micrometer + OpenTelemetry, JSON logs with
tenant/correlation ids, readiness/liveness. → ZAP no high/medium; Trivy no critical; checklist in
`docs/security.md` with evidence.

**WP18 — E2E (Sonnet).** Journey: super admin creates tenant → admin invites coach/parent → coach adds
player (approval) → assignment → match scored by parent + coach (one offline) → season rollover
produces orphan → resolved; cross-tenant 404s. Runs against compose and kind.

**WP19 — v2 events (Opus, optional).** → replica equals core after replay; idempotent consumer;
adapter swap passes the same contract tests.

**WP20 — Docs & final review.** User guides per role, runbooks (onboard tenant, rotate secrets,
CNPG backup/restore, kind rebuild), architecture overview, roadmap (billing, events, native images,
push notifications, purge job); Opus pass: spec §2 conformance checklist, simplification, ADR
completeness.

### How to execute

1. Approve the plan; `/model opus`. Clone/initialise at `~/code/hoops-academy`; the OneDrive folder
   keeps `dummy_project2_specs.md`, this plan and a README pointer.
2. Run WP0 (Sonnet agent). Then WP1 ∥ WP2a ∥ WP2b as three parallel `Agent` calls with the listed
   models, each briefed with `docs/wp/<id>.md` + `CLAUDE.md`.
3. Launch the four lanes in parallel; start WP16 as soon as `core-service` builds an image. Before
   starting a dependent WP, the orchestrator runs `./mvnw verify` / `flutter test` itself.
4. Close with WP15 ∥ WP17 ∥ WP18, then WP20. Say "use a workflow" to run a whole wave via the
   Workflow tool once the pattern is stable.

---

## 6. Verification (end-to-end)

1. `just doctor && ./mvnw verify` — unit/integration/arch/contract/RLS tests, JaCoCo and PIT gates, on
   Podman as non-owner DB roles.
2. `just up && ./mvnw -pl e2e verify` — compose journey incl. cross-tenant 404s and approval/rollover.
3. `cd apps/web && flutter test && flutter test integration_test -d chrome` against compose.
4. Manual mobile check (Chrome device toolbar or phone on LAN): coach logs in → live match → airplane
   mode → enter stats → reconnect → server box score equals local; parent cannot enter for other
   players.
5. `just kind-up && tilt up` — stack green; rerun e2e against ingress; code change redeploys.
6. `gitleaks detect` (full history) clean; `trivy image` no CRITICAL; dependency-check no unsuppressed
   CVSS ≥ 7; ZAP baseline no high/medium.

## 7. Key risks and mitigations

- **False-green RLS** via superuser/owner connections → shared init SQL, non-owner app roles
  everywhere, schema meta-test, `app.current_tenant()` raising when unset, ArchUnit placement rules.
- **Keycloak issuer mismatch** (browser vs in-cluster URL) → fixed `KC_HOSTNAME`, `quarkus.oidc.
  token.issuer` configured explicitly in compose and kind; budgeted in WP1/WP16.
- **Podman quirks** → rootful machine, `podman-mac-helper`, privileged Ryuk, Jib + `kind load
  image-archive` instead of Docker-specific Tilt/registry recipes; all images multi-arch for Apple
  Silicon.
- **Offline sync** → idempotent client ids, per-event results, schema+authz-only validation, shared
  test vectors between Java projector and Dart projector, SSO idle ≥ 4 h, no COOP/COEP.
- **Contract drift between lanes** → OpenAPI specs are the single source of truth, Dart clients
  generated, every service response validated against them in tests.
- **Invented reference norms** → citations mandatory in seed files; uncited values flagged in UI.
- **Domain/time** → `date` birth dates, tenant timezone for ages and jobs, leap-day and Dec-31 tests;
  rollover wizard made prominent so orphans do not appear "mysteriously".

## 8. Assumptions

- A user may belong to several tenants (parent with children in two academies); tenant chosen per
  session. Children without logins exist as `person` rows with `user_id NULL`.
- UI in Spanish, English and Indonesian from the start; locale per user (tenant default), timezone per tenant.
- Email only for invitations (Keycloak → MailHog locally); push notifications deferred.
- Native-image builds, Redpanda events, billing, data purge job and Pact broker are explicitly v2.
