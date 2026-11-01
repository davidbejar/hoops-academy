# WP2b — libs/contracts: OpenAPI ×3, event JSON Schemas, Dart generation

Model: Opus. Depends on: WP0. Parallel with WP1, WP2a. Reads: docs/PLAN.md §1.2–1.5, §2; docs/domain/authz-matrix.md.

## Scope
- `openapi/common.yaml`: Problem schema (RFC 9457), `X-Tenant-Id` header param, pagination params/envelope, ids as uuid,
  standard error responses, security scheme `bearer` (JWT).
- `openapi/core.yaml`: /platform/tenants (CRUD + suspend/withdraw + usage), /api/core/me, /api/core/tenant (profile,
  settings, logo PUT/GET/DELETE multipart/binary), members & roles, guardian links, seasons (+rollover), age categories,
  teams, team players (assign/unassign/validate), team staff, players (+approval flow), approval requests,
  eligibility cases, /internal/authz/{tenantId}/{sub}, /internal/usage/{tenantId}, /internal/teams/{id}/roster,
  /internal/players (batch by ids).
- `openapi/game.yaml`: matches (CRUD, start/finish/cancel), roster, `POST /matches/{id}/events:batch` (per-event
  results), `GET /matches/{id}/events?after=`, box score, player season stats, /internal/usage.
- `openapi/athlete.yaml`: schedules, sessions, attendance, absences, plans/templates/items, assignments, completions,
  injuries, measurements, test types, results (+expected band), norms, /internal/usage.
- `events/match-event.schema.json` + one `$defs` entry per event type (discriminator `type`), shared by game-service
  validation and Flutter.
- Maven module `contracts`: packages YAML/JSON as resources; `openapi-generator-maven-plugin` `validate` goal in
  `verify`; optional `spectral`-free lint via generator validation; Dart `dart-dio` generation config
  (`scripts/gen-api.sh` using the brew `openapi-generator` CLI, output `apps/web/lib/api/<svc>`).
- `README.md` describing versioning (`info.version`, breaking-change policy) and how to regenerate.

## Acceptance
- [x] `./mvnw -pl libs/contracts verify` validates all three specs + JSON Schema syntax
- [x] every operation has `operationId`, tags, security, 401/403/404 Problem responses; tenant endpoints declare `X-Tenant-Id`
- [x] `scripts/gen-api.sh` produces Dart that compiles (`dart analyze` on the generated package) — may be verified in WP11 if Flutter not yet installed; note it
- [x] event schema rejects an unknown type and a SHOT without `points`

## Handover

### Built
- `libs/contracts/openapi/common.yaml` — components only: `Problem` (RFC 9457, aligned with WP2a's
  `com.hoopsacademy.common.problem.Problem`: `type` = `urn:hoops:problem:<slug>`, `title`, `status`, `detail`, `instance`,
  `traceId`, `violations[]` + optional `code`), `ProblemViolation`, `TenantIdHeader` (`X-Tenant-Id`, uuid, required),
  `TenantIdPath`/`TenantIdQuery`, `Page`/`Size` (≤ 200) + `PageMeta` (envelope `<Resource>Page {items, page}`),
  `FromDate`/`ToDate`/`PlayerIdQuery`/`TeamIdQuery`/`SeasonIdQuery`, responses `BadRequest`, `Unauthorized`, `Forbidden`,
  `NotFound`, `Conflict`, `Unprocessable`, `PayloadTooLarge`, `UnsupportedMediaType`, `bearerAuth` (JWT), shared
  `Gender`, `Locale`, `PersonRef`, `UsageReport`.
- `openapi/core.yaml`, `openapi/game.yaml`, `openapi/athlete.yaml` — everything in the WP scope, with every enum from the
  plan (TenantRole, StaffRole, TenantStatus, PlayerStatus, GenderPolicy, Gender, AgeRule, EligibilityResult,
  EligibilityReason, EligibilityCaseStatus/Resolution, ApprovalAction/Status, MatchStatus, MatchEventType,
  MatchEventResultStatus, MatchEventRejectionReason, AttendanceStatus, CompletionStatus, InjurySeverity/Status, NormBand,
  TrainingSessionStatus, DayOfWeek). Each operation has an `Authz:` line summarising the authz matrix.
- `events/match-event.schema.json` — JSON Schema 2020-12, `$defs` per event type (15) + payloads, dispatch on `type` via
  `if/then` (the JSON Schema form of the discriminator); `events/examples/match-events.valid.json` — one valid event per
  type (test vectors for WP7/WP13).
- Maven module `contracts` (jar; resources `openapi/**`, `events/**` at the jar root): `openapi-generator-maven-plugin:validate`
  (strictSpec) for core/game/athlete in `verify`; JUnit 6 suite (79 tests) with swagger-parser 2.1.48,
  networknt json-schema-validator 2.0.8, AssertJ 3.27.7 (explicit versions in the module pom):
  `OpenApiConventionsTest` (parse w/o messages, 3.0.3, bearer security, camelCase unique operationId, tags, summary,
  400/401/403/404 on every op, every 4xx/5xx is `application/problem+json` Problem, typed 2xx bodies, `X-Tenant-Id`
  required on tenant paths and absent on `/platform`, `/internal`, `/me`, path families, `/internal` tagged + `x-internal`,
  uuid path ids, `size` ≤ 200), `MatchEventJsonSchemaTest` (schema valid vs 2020-12 meta-schema, all examples valid,
  rejects unknown type, SHOT without `points`, SHOT points 4, SHOT without payload, REBOUND without player, VOID without
  target, malformed id, missing clientSeq), `MatchEventSchemaConsistencyTest` (OpenAPI ↔ JSON Schema: type lists,
  discriminator mapping, schema names, required fields, payload shapes and enum values), `PackagedResourcesTest`.
- `scripts/gen-api.sh` (executable): dart-dio + built_value, `enumUnknownDefaultCase=true`, `pubName=hoops_<svc>_api`,
  `pubVersion` = spec `info.version`, no generated tests/docs; replaces `$API_OUT_ROOT/<svc>` (default
  `apps/web/lib/api`, created as needed) and runs `dart pub get` + `build_runner` (`GEN_API_BUILD=0` skips); optional
  service args; warns if the CLI is not 7.26.0.
- `libs/contracts/README.md` — conventions, versioning policy, regeneration, response validation with
  swagger-request-validator-restassured.

### Verified (fresh, 2026-11-01)
- `source scripts/env.sh && ./mvnw -pl libs/contracts clean verify` → exit 0, `Tests run: 79, Failures: 0, Errors: 0`,
  `validate-core|game|athlete: No validation issues detected`, BUILD SUCCESS, no compiler warnings.
- Red check: temporarily removing `X-Tenant-Id` from a path, a 403 from an op, adding a type only to the OpenAPI enum and
  dropping `points` from the JSON `ShotPayload.required` made exactly the five corresponding tests fail; files restored.
- `API_OUT_ROOT=<scratch>/apps/web/lib/api scripts/gen-api.sh` → exit 0; `dart analyze` (Dart 3.13.7) in each package:
  **0 errors** (core 22 / game 11 / athlete 20 warnings, all generator-side `unused_import` / `unused_element_parameter`;
  run with `--no-fatal-warnings`). `/internal` APIs absent from the clients.
- Generated game client round-trips a `MatchEventBatch` (SHOT → `ShotEvent`, PERIOD_END → `PeriodEndEvent`) through
  built_value serializers in both directions.
- Loading the specs from the built jar: `readLocation("/openapi/core.yaml")` resolves `./common.yaml` (no messages);
  a `jar:` URL (`getResource(...).toString()`) does **not** — README tells services to use the classpath location.

### Acceptance checklist
| Item | Evidence |
|---|---|
| verify validates all three specs + JSON Schema syntax | plugin `validate` ×3 + `schemaIsValidAgainstTheDraft202012MetaSchema`; BUILD SUCCESS |
| operationId, tags, security, 401/403/404 Problem; tenant endpoints declare `X-Tenant-Id` | `OpenApiConventionsTest` (40 tests, green) |
| gen-api produces Dart that compiles | `dart analyze`: 0 errors in all three packages (verified here, not deferred to WP11) |
| event schema rejects unknown type and SHOT without `points` | `rejectsUnknownType`, `rejectsShotWithoutPoints` (green) |

### Operation counts
| Spec | Paths | Operations | `/platform` | `/api/<svc>` | `/internal` (x-internal) | Component schemas |
|---|---|---|---|---|---|---|
| core.yaml | 44 | 64 | 8 | 52 (incl. 2 × `/me`) | 4 | 82 |
| game.yaml | 11 | 14 | – | 13 | 1 | 54 |
| athlete.yaml | 28 | 56 | – | 55 | 1 | 57 |
| **total** | 83 | **134** | 8 | 120 | 6 | |

### Decisions (documented in README / spec descriptions; no ADR needed — none changes a locked decision)
- **OpenAPI 3.0.3**, not 3.1 (partial 3.1 support in dart-dio and swagger-request-validator). Hence the JSON Schema is
  duplicated and guarded by `MatchEventSchemaConsistencyTest` instead of `$ref`'d.
- **Absolute paths, `servers: [{url: /}]`** instead of `servers: /api/<svc>`: core serves `/api/core`, `/platform` and
  `/internal`; per-path `servers` overrides are not honoured by dart-dio, which would break platform calls.
- **dart-dio + built_value** (json_serializable fails on the discriminated `oneOf`); `enumUnknownDefaultCase=true` for
  forward-compatible enums.
- `MatchEvent` = `oneOf` of 15 `<Type>Event` schemas (`allOf` MatchEventBase [+ PlayerAttribution] [+ payload]) with a
  discriminator on `type`; the batch body is wrapped as `{events: [...]}` (≤ 500) for extensibility; stored events in the
  feed are `{serverSeq, event, recordedBy, receivedAt, voidedByEventId}`. REBOUND/FOUL payloads use `kind`
  (`OFFENSIVE|DEFENSIVE`, `PERSONAL|TECHNICAL|UNSPORTSMANLIKE`), TIMEOUT `side` (`OWN|OPPONENT`), VOID `targetEventId`.
  Per-event rejection reasons: `SCHEMA_INVALID`, `NOT_AUTHORIZED`, `MATCH_CANCELLED`, `CLIENT_SEQ_CONFLICT`.
- `/internal/teams/{teamId}/roster` and `/internal/players:batch` take a required `tenantId` **query** parameter (core needs
  the RLS tenant; internal calls carry no `X-Tenant-Id`). `/internal/**` ops are `x-internal: true`.
- `POST /players` answers 201 (ADMIN, ACTIVE) or 202 (COACH, PENDING_APPROVAL); `withdraw` 200/202 — both return
  `PlayerCommandResult {player, approvalRequest}` (admin path records the auto-approved audit request).
- `POST /seasons/{seasonId}/rollover`: `{seasonId}` is the *target* season, body `fromSeasonId`.
- Logo: raw `image/png|jpeg|webp` body ≤ 512 KB; the server detects the format from magic bytes (dart-dio always sends
  the first declared type, `image/png`); 413/415; GET with ETag/Cache-Control/304.
- Added beyond the brief (small, needed by the domain): `POST /platform/tenants/{id}/reactivate`, `PATCH /api/core/me`
  (locale), `GET /api/core/players/{id}/eligible-teams` (assignment UI offers eligible teams only),
  `PATCH /teams/{id}/players/{playerId}` (jersey), plan item reorder, `scope` on norms (EFFECTIVE/GLOBAL/TENANT).
- Usage: every service returns `UsageReport {service, counters: map}`; the platform aggregates into `TenantUsage` with
  `unavailableServices`.
- `validate` is not run on `common.yaml` alone (no operations → only "unused model" noise); its components are
  validated through the three service specs and parsed by `sharedComponentsParseWithoutMessages`.
- networknt json-schema-validator **2.0.x** (Jackson 2) rather than 3.x (Jackson 3 / `tools.jackson`), to match Quarkus 3.

### Open points
- **WP2a**: `Problem` record has no `code` member; the contract defines optional `code` (top level and per violation)
  so clients can branch on `PLAYER_INELIGIBLE`, `NOT_PENDING`, eligibility reasons. Please add it (or tell WP2b to drop it).
  `AuthzContext` in the contract additionally carries `sub`, `tenantId`, `tenantStatus` (superset of the Java record).
- **Infra (nginx / ingress)**: route `/platform/**` to core-service (the plan lists only `/api/core|game|athlete/**`), still
  block `/internal/**`.
- **WP11**: the plan puts generated packages under `apps/web/lib/api/<svc>` — nested packages inside the app's `lib/`;
  depend on them via `path:` and exclude `lib/api/**` in the app's `analysis_options.yaml` (generator warnings), or move
  them to e.g. `apps/web/packages/` (then set `API_OUT_ROOT`). The default `just gen-api` run was not executed here so
  that no generated Dart is committed.
- **WP3/WP5/WP7/WP9**: tests should load `"/openapi/<svc>.yaml"` (classpath location) in swagger-request-validator; for
  `submitMatchEvents` tests that send invalid events on purpose, ignore request validation (server rejects per event).
- Plan §5 mentions "WireMock stubs for `/internal`" for WP2b; not in this brief's scope — consumers (WP5/WP7/WP9) can
  derive stubs from the `Internal`-tagged operations; worth a small follow-up if wanted.
- `shellcheck` is not installed; `gen-api.sh` was checked with `bash -n` and by running it.
