# libs/contracts — API contracts (source of truth)

| File | What |
|---|---|
| `openapi/common.yaml` | Shared components only: `Problem` (RFC 9457), `X-Tenant-Id` header, paging (`page`, `size` ≤ 200, `PageMeta`), standard error responses, `bearerAuth`, `UsageReport`, `Gender`, `Locale`, `PersonRef` |
| `openapi/core.yaml` | core-service: `/platform/**`, `/api/core/**`, `/internal/**` |
| `openapi/game.yaml` | game-service: `/api/game/**`, `/internal/usage/{tenantId}` |
| `openapi/athlete.yaml` | athlete-service: `/api/athlete/**`, `/internal/usage/{tenantId}` |
| `events/match-event.schema.json` | JSON Schema 2020-12 of a match event (`$defs` per type, dispatch on `type`) |
| `events/examples/match-events.valid.json` | One valid event per type — shared test vectors |

The jar ships these files as classpath resources: `classpath:openapi/core.yaml`, `classpath:events/match-event.schema.json`, …

## Conventions (enforced by `OpenApiConventionsTest`)

- OpenAPI **3.0.3** (not 3.1: dart-dio and swagger-request-validator support for 3.1 is partial; 3.0.3 is fully
  supported by every tool in the chain). Consequence: the OpenAPI `MatchEvent` cannot `$ref` the 2020-12 JSON Schema,
  so both are maintained side by side and `MatchEventSchemaConsistencyTest` fails on any drift (types, schema names,
  required fields, payload shapes, enum values).
- Paths are absolute (`servers: [{url: /}]`) because core-service serves three path families.
- Every operation: camelCase unique `operationId`, `tags`, `summary`, bearer security, `400/401/403/404` Problem
  responses (`application/problem+json`), `409`/`422` where a state conflict / domain rule applies.
- Upstream failures (`CrossServiceContractTest`): every `/api/game/**` and `/api/athlete/**` operation declares
  `503` → `common.yaml#/components/responses/ServiceUnavailable` (code `UPSTREAM_UNAVAILABLE`), because the tenant
  filter of those services resolves the caller through core's `/internal/authz` on every call. core's tenant and
  platform operations call no peer synchronously except the ones that create or change a login (`createTenant`,
  `addTenantAdmin`, `updateTenantAdmin`, `issueTenantAdminTemporaryPassword`, `inviteMember`, `updateMember`,
  `issueMemberTemporaryPassword`, `createPlayer`, `approveApprovalRequest`), which call Keycloak and declare
  `502` → `UpstreamIdentityProvider` (code `IDENTITY_PROVIDER_UNAVAILABLE`). `getTenantUsage` never fails for a peer:
  it lists the peer in `unavailableServices`.
- `/internal/usage/{tenantId}` answers 200 with zero counters for an unknown tenant in every service.
- Tenant-scoped operations (`/api/**` except `GET|PATCH /api/core/me`) take the required `X-Tenant-Id` header;
  `/platform/**`, `/internal/**` and `/me` never do. Non-members get **404** — hence 404 on every operation.
- `/internal/**` operations are tagged `Internal` and marked `x-internal: true` (not generated into the Flutter client).
- Ids are `uuid`; dates `date`; instants `date-time` (UTC). Unbounded lists use the `<Resource>Page` envelope
  `{items, page}`; small bounded lists are plain arrays.
- Names follow `docs/domain/glossary.md`; the `Authz:` line of each operation summarises `docs/domain/authz-matrix.md`.

## Versioning policy

- Each spec has its own `info.version` (SemVer), starting at `1.0.0`. The Maven artifact version is the repo version.
- **Minor** (`1.x.0`): additive, backwards-compatible changes — new operations, new optional request fields, new
  response fields, new optional query parameters, new values of *request-only* enums.
- **Major**: anything else — removing/renaming operations, fields or parameters, making an optional field required,
  changing a type or format, tightening constraints, changing status codes, **adding a value to a response enum**
  (generated clients map unknown values to a fallback `unknownDefaultOpenApi`, but business logic still breaks).
  Open sets that must evolve freely (e.g. `ProjectionWarning.code`, `UsageReport.counters`) are plain strings/maps.
- A major change needs an ADR and a migration note in the PR; services and the web app are released together from the
  monorepo, so no parallel `/v2` paths are kept in v1 unless an ADR decides otherwise.
- **Patch**: descriptions/examples only.

## Build and validation

```
source scripts/env.sh
./mvnw -pl libs/contracts verify
```

`verify` runs the JUnit suite (swagger-parser + networknt json-schema-validator) and then
`openapi-generator-maven-plugin:validate` (strict) for `common`, `core`, `game` and `athlete`.
Quick check of one file: `openapi-generator validate -i libs/contracts/openapi/game.yaml`.

## Regenerating the Flutter clients

```
just gen-api                       # = scripts/gen-api.sh → apps/web/packages/{core,game,athlete}
scripts/gen-api.sh game            # one service
API_OUT_ROOT=/tmp/api scripts/gen-api.sh   # elsewhere (e.g. to inspect a change)
```

Generator: brew `openapi-generator` **7.26.0** (same version as the Maven plugin; the script warns on mismatch),
`dart-dio` + `built_value` (json_serializable cannot handle the discriminated `oneOf`), `enumUnknownDefaultCase=true`.
The script replaces each package directory, then runs `dart pub get` and `build_runner` (`GEN_API_BUILD=0` to skip).
Generated code is never edited; `.openapi-generator/` metadata is git-ignored.

Known generator limitation: for the logo upload (`putTenantLogo`) dart-dio always sends `Content-Type: image/png`;
the contract therefore lets the server decide the format from the magic bytes.

## Validating service responses against the contract

Services depend on this module in test scope and validate every REST-assured exchange with
[swagger-request-validator](https://bitbucket.org/atlassian/swagger-request-validator)
(`com.atlassian.oai:openapi-request-validator-restassured` — the relocated name of
`swagger-request-validator-restassured`, same 3.0.0 code and `com.atlassian.oai.validator` packages — version managed
in the root `pom.xml`):

```xml
<dependency><groupId>com.hoopsacademy</groupId><artifactId>contracts</artifactId><scope>test</scope></dependency>
<dependency><groupId>com.atlassian.oai</groupId><artifactId>openapi-request-validator-restassured</artifactId></dependency>
```

```java
// Pass the plain classpath location. Do NOT pass getResource(...).toString(): from a jar: URL swagger-parser cannot
// resolve the relative $ref to ./common.yaml (verified; PackagedResourcesTest covers the supported form).
static final OpenApiValidationFilter CONTRACT = new OpenApiValidationFilter(
        OpenApiInteractionValidator.createForSpecificationUrl("/openapi/core.yaml").build());

given().filter(CONTRACT).header("X-Tenant-Id", tenantId).when().get("/api/core/teams").then().statusCode(200);
```

Match events: game-service validates each submitted event individually against `events/match-event.schema.json`
(networknt json-schema-validator, Jackson 2 line `2.0.x`) so one invalid event is answered `REJECTED/SCHEMA_INVALID`
instead of failing the whole batch. Tests that exercise rejection on purpose should therefore disable request
validation for `submitMatchEvents` (`.withLevel("validation.request", ValidationReport.Level.IGNORE)` on that call)
while keeping response validation. Every `<Type>Event` fixes its `type`
(`type: {allOf: [{$ref: MatchEventType}], enum: [<TYPE>]}`), so exactly one `oneOf` branch matches for any
spec-compliant validator (before WP2c PERIOD_START/PERIOD_END and SUB_IN/SUB_OUT were structurally identical). The
`allOf`-wrapped spelling is deliberate: a plain inline `{type: string, enum: [<TYPE>]}` makes dart-dio drop the
`MatchEventType` import of every variant (135 analyzer errors, checked with openapi-generator 7.26.0). swagger-request-
validator, however, only selects the branch once combinators are resolved, and resolving drops that sibling `enum`;
game-service's tests therefore validate events against a derived copy that spells the type as the plain enum
(`support/Contract.EVENTS`) — the same constraint.

### Known validator quirks

- **`allOf` + `additionalProperties`**: schemas composed with `allOf` (`InviteMemberRequest`, `TrainingSchedule`,
  `PlannedAbsence`, `TrainingPlan`, `PhysicalTestResult`, the `<Type>Event`s, …) are checked part by part, so with
  `additionalProperties: false` semantics each part reports the other parts' properties as "additional". Either build
  the validator with `withResolveCombinators(true)` (flattens `allOf`; core and game do this) or set
  `validation.request.body.schema.additionalProperties` / `validation.response.body.schema.additionalProperties` to
  `IGNORE` (athlete). Side effect of resolving combinators: `nullable` on an `allOf`-wrapped request field
  (`jerseyNumber: {allOf: [...], nullable: true}`) is dropped, so a request sending `null` there is validated
  response-only.
- **Colons in paths** (`/api/game/matches/{matchId}/events:batch`, `/api/athlete/training-plans/{planId}:copy`,
  `:archive`, `:unarchive`, `/internal/players:batch`): the validator matches the template only when the colon is sent
  literally, and Quarkus REST answers 404 for a percent-encoded `%3A`. REST-assured tests call these paths with
  `urlEncodingEnabled(false)`; the generated Dart (dio) and Quarkus REST clients send the colon unencoded; the nginx
  gateway and the ingress must forward the path unchanged (no `proxy_pass` URI part that would re-normalise it).
