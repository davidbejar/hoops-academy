# libs/contracts — API contracts (source of truth)

| File | What |
|---|---|
| `openapi/common.yaml` | Shared components only: `Problem` (RFC 9457), `X-Tenant-Id` header, paging (`page`, `size` ≤ 200, `PageMeta`), standard error responses, `bearerAuth`, `UsageReport`, `Gender`, `Locale`, `PersonRef` |
| `openapi/core.yaml` | core-service: `/platform/**`, `/api/core/**`, `/internal/**` |
| `openapi/game.yaml` | game-service: `/api/game/**`, `/internal/usage/{tenantId}` |
| `openapi/athlete.yaml` | athlete-service: `/api/athlete/**`, `/internal/usage/{tenantId}` |
| `events/match-event.schema.json` | JSON Schema 2020-12 of a match event (`$defs` per type, dispatch on `type`) |
| `events/examples/match-events.valid.json` | One valid event per type — shared test vectors |
| `events/core.<aggregate>.schema.json` | JSON Schema 2020-12 of the roster events core publishes on topic `core.<aggregate>` (seven topics, section "Events") |
| `events/examples/core.<aggregate>.valid.json` | Valid events of each topic (every type) — shared test vectors for the consumers |

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
- **No `allOf` composition** (`StrictValidatorCompatibilityTest`, ADR-0027): every request and response object is a
  plain object, and `allOf` only wraps a single `$ref` (to add `nullable`, a description or a narrowing `enum`). A
  schema that carries the fields of another one repeats them and names its bases in `x-extends: [Base, …]`
  (`AgeCategory` → `AgeCategoryInput`, `ShotEvent` → `MatchEventBase, PlayerAttribution`, …); the test keeps every
  repeated property identical to its base (the MatchEvent `type` may narrow `MatchEventType` to one value). Field
  groups that are not wire types of their own (`PersonalData`, `AuditInfo`, `MatchEventBase`, `PlayerAttribution`)
  live under `components.x-mixins`: generators and validators ignore them, and a mixin no schema extends fails the
  test. Reason: swagger-request-validator, in its default strict configuration, adds `additionalProperties: false`
  to every object schema with `properties`, so each part of an `allOf` would reject the other parts' fields.
- **Clearing a field: the `clear` list** (`UpdateRequestClearListContractTest`, ADR-0032; adopted by athlete 2.1.0,
  core and game follow). In an `Update*Request` an absent or `null` property is unchanged; the properties to set to
  null are named in `clear: [<name>, …]`, an `enum` of exactly the request's optional, nullable properties
  (`uniqueItems`), so a typo or a required property fails the strict validator. A property both in `clear` and given a
  value is a 400. Reason: the generated Dart clients omit null properties, so they cannot send an explicit null.

## Events (core roster topics, `CoreEventSchemasTest`)

core writes every change of a person, player, team, team assignment, team staff entry, guardian link or academy to its
transactional outbox in the same transaction and publishes it to Redpanda (ADR-0008 amended, ADR-0036, WP67). One
schema file per topic, `events/<topic>.schema.json`; the consumers (game, athlete) validate what they read against it.

- **Topics** `core.person`, `core.player`, `core.team`, `core.team-player`, `core.team-staff`, `core.guardian-link`,
  `core.tenant` (the list of `infra/compose/redpanda-topics.sh`; the test fails when the two differ). Kafka key
  `<tenantId>:<aggregateId>`; value the JSON envelope below.
- **Envelope** (identical in every file): `eventId` (uuid, the outbox row id: the same on every redelivery),
  `type`, `version`, `tenantId`, `aggregateId` (uuid), `occurredAt` (UTC instant, `…Z`), `payload`. Closed objects
  (`additionalProperties: false`).
- **Types** `<aggregate>.changed` on every topic; `<aggregate>.removed` only where a record can disappear
  (`team-staff`, `guardian-link`). A payload is a `$defs/<Aggregate><Verb>` object; every field is required and an
  absent value is an explicit `null`.
- **State transfer**: a `changed` event carries the whole current aggregate (the topics are compacted, ADR-0036), not
  the fields that changed; a `removed` event carries the identity only and is followed by a tombstone (null value) for
  the same key.
- **Delivery**: at least once, in outbox order per key. Consumers ignore an `eventId` they have applied and never let an
  older `occurredAt` overwrite a newer one; they bind the tenant from `tenantId`, never from a request.
- **Versioning**: `version` is the topic's major version, `1` for an unsuffixed topic. An **additive** change (a new
  payload field, a new `.removed` type, a new enum value consumers may treat as unknown) keeps the topic and the
  version: consumers must accept it after they are updated, so add the field to the schema first, deploy the
  consumers, then the producer. A **breaking** change (removing or renaming a field, changing a type or the meaning
  of a value, a new key) is a new topic `<topic>.v2` with `version` 2 and its own schema file
  `events/<topic>.v2.schema.json`; core publishes both until every consumer has moved, then the old topic is retired
  (ADR needed).

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

`verify` runs the JUnit suite (swagger-parser, networknt json-schema-validator and swagger-request-validator) and then
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

Use the validator's **default configuration**: no `withResolveCombinators`, no message muted. It then rejects any
request or response field the contract does not declare, and it checks every `MatchEvent` (oneOf + discriminator)
directly — the contract is written for it (see "No `allOf` composition" above). The only levels the tests lower are
deliberate test modes, never contract gaps: `validation.request` for calls that send a forbidden request on purpose
(response still validated), and in core `validation.response.status.unknown` for fault-injection tests that provoke
an undeclared 500. game-service's tests send a placeholder bearer token (`Bearer test`; the caller is simulated) so
the security requirement is checked too.

Match events: game-service validates each submitted event individually against `events/match-event.schema.json`
(networknt json-schema-validator, Jackson 2 line `2.0.x`) so one invalid event is answered `REJECTED/SCHEMA_INVALID`
instead of failing the whole batch. Tests that exercise rejection on purpose therefore validate the response only
(`Contract.RESPONSES_ONLY`). Every `<Type>Event` fixes its `type` (`type: {allOf: [{$ref: MatchEventType}], enum:
[<TYPE>]}`), so exactly one `oneOf` branch matches for any spec-compliant validator. The `allOf`-wrapped spelling is
deliberate: a plain inline `{type: string, enum: [<TYPE>]}` makes dart-dio drop the `MatchEventType` import of every
variant (135 analyzer errors, checked with openapi-generator 7.26.0).

### Known validator quirks

- **Gone (WP29): `allOf` + `additionalProperties`.** Composed schemas made every real response fail ("property … is
  not defined in the schema"), so the services and e2e muted `additionalProperties` or flattened with
  `withResolveCombinators(true)`, which in turn dropped `nullable` on `allOf`-wrapped fields; and the `MatchEvent`
  feed could not be validated at all (`discriminator.oneOf.no_match_found`). Both disappeared with the plain-object
  rule; game's derived copy of game.yaml (`Contract.EVENTS`) is gone too.
- **Colons in paths** (`/api/game/matches/{matchId}/events:batch`, `/api/athlete/training-plans/{planId}:copy`,
  `:archive`, `:unarchive`, `/internal/players:batch`): the validator matches the template only when the colon is sent
  literally, and Quarkus REST answers 404 for a percent-encoded `%3A`. REST-assured tests call these paths with
  `urlEncodingEnabled(false)`; the generated Dart (dio) and Quarkus REST clients send the colon unencoded; the nginx
  gateway and the ingress must forward the path unchanged (no `proxy_pass` URI part that would re-normalise it).
