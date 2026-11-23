# ADR-0064: pdf-service takes no token clock leeway and uses the shared Problem type names

- Status: Accepted
- Date: 2026-11-24
- Related: ADR-0051, ADR-0052 (Problem+JSON, JWT verification), ADR-0034 (service tokens), WP132, audit of 2026-11-23
  (X-11), decisions 104 and 112

## Context
The same two rules existed in several languages with different values. pdf-service allowed 5 s of clock leeway on
`exp` and `nbf` (the Go finance-service 10 s; the Java services set none) and named four Problem types differently
from `common-quarkus`' `ProblemType` (`validation-failed`, `unauthenticated`, `invalid-token`, `auth-unavailable`,
`too-many-rows` against `validation`, `unauthorized`, `upstream-unavailable`, `domain-rule-violation`). Nothing
checked either.

## Decision
1. **Leeway 0 s.** The Java services configure no `quarkus.oidc.token.lifespan-grace`; Quarkus OIDC then uses jose4j's
   default allowed clock skew, 0 s. pdf-service takes that value (`LEEWAY_SECONDS = 0` in `auth.rs`). Callers fetch a
   fresh service token well before the end of its five minutes, so no legitimate call needs a grace period.
2. **Problem types are `ProblemType`'s slugs**: 400 `validation`, 401 `unauthorized` (no token and invalid token; the
   `code` stays `UNAUTHENTICATED` / `INVALID_TOKEN` and tells them apart), 422 `domain-rule-violation` (code
   `TOO_MANY_ROWS`), 503 `upstream-unavailable` (code `AUTH_UNAVAILABLE`); `forbidden`, `not-found`,
   `payload-too-large`, `internal-error` were already equal. `unsupported-media-type` and `method-not-allowed` are
   not in the Java enum and stay pdf-service's own (Go has the first one too).
3. **A guard**: a unit test in `problem.rs` reads `ProblemType.java` and fails when a pdf-service Problem uses a slug
   that is not in it (apart from the two above) or a different status.

## Consequences
- `pdf.yaml` names no slug, so it is unchanged. core and game turn every pdf-service failure into their own 503 and do
  not read `type`; their stubs may keep any slug, nothing breaks.
- A token that expired less than 5 s ago is now refused (401 `INVALID_TOKEN`); a skewed clock between caller and
  pdf-service shows up as that refusal, as it does in the Java services.
