# ADR-0027: Contracts without allOf composition, validated strictly everywhere

- Status: Accepted
- Date: 2026-11-05
- Supersedes: ADR-0016 §2, last sentence (game's tests validating events against a derived copy of game.yaml).
- Related: ADR-0016 (contracts v2), WP18 (e2e contract disagreements), WP29

## Context
Every REST-assured test and the e2e journey validate exchanges with swagger-request-validator. In its default
configuration that validator adds `additionalProperties: false` to every object schema that declares `properties`
and has no `additionalProperties` of its own. The contracts composed 33 schemas with `allOf` (`AgeCategory =
AgeCategoryInput + {id}`, `*WithPassword`, `TrainingSchedule`, the 15 `<Type>Event`s, …), so each part rejected the
other parts' fields and no real response could validate. The tests coped by muting the message
(`additionalProperties` → IGNORE in athlete, for requests in core, a pointer-based filter in e2e) or by flattening
with `withResolveCombinators(true)` (core, game events), which drops `nullable` on `allOf`-wrapped fields; game also
validated events against a rewritten copy of game.yaml, and e2e read the match-event feed unvalidated
(`discriminator.oneOf.no_match_found`). Undeclared response fields of composed schemas went unnoticed.

## Decision
1. **No `allOf` composition in the contracts.** Request and response objects are plain objects; `allOf` only wraps a
   single `$ref` (adding `nullable`, a description or a narrowing `enum`). A schema that carries another schema's
   fields repeats them and lists its bases in the vendor extension `x-extends`.
2. **Field groups that are not wire types** (`PersonalData`, `AuditInfo`, `MatchEventBase`, `PlayerAttribution`) move
   to `components.x-mixins`: generators and validators ignore them (openapi-generator's strict validation also rejects
   unused schemas), and `x-extends` may name them.
3. **`StrictValidatorCompatibilityTest`** (libs/contracts) enforces it: no multi-part `allOf` in any spec, every
   `x-extends` copy identical to its base (the MatchEvent `type` may narrow `MatchEventType`), no unused mixin, every
   MatchEvent variant extends `MatchEventBase`, and a feed with one event of every type passes the default validator
   while an undeclared property or a mismatching payload fails it.
4. **Tests use the validator's default configuration.** No `withResolveCombinators`, no muted schema message. The
   remaining lowered levels are test modes only: `validation.request` for deliberately invalid requests and core's
   `validation.response.status.unknown` for fault-injection tests that provoke an undeclared 500.
5. **Versioning:** the wire format is unchanged, so the specs take a patch bump (core 2.3.1, game 2.0.1, athlete
   2.0.1). The generated Dart API changes shape (no `$Foo` interface classes, variants no longer implement
   `MatchEventBase`), regenerated with `just gen-api`.

## Consequences
- An undeclared response field now fails the service tests and the e2e journey for every schema, events included.
- Duplication in the YAML (event variants repeat the seven base fields); drift is caught by the test above and, for
  events, by `MatchEventSchemaConsistencyTest` against the JSON Schema.
- Client code that built `$Foo(...)` objects or relied on `Foo implements FooInput` uses the concrete classes.
