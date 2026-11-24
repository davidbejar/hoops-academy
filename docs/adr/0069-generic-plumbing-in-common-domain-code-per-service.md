# ADR-0069: generic plumbing lives once in common-quarkus; domain code stays per service

- Status: Accepted (amends ADR-0053)
- Date: 2026-11-24
- Related: ADR-0017 (Problem+JSON, observability), ADR-0039 and ADR-0048 (languages, Accept-Language), ADR-0045
  (acceptances), ADR-0051 §3 (pdf-service callers), ADR-0053 (duplication gate), ADR-0062 and ADR-0066 (earlier moves
  into common), ADR-0064 (pdf-service's Problem vocabulary), decision 104 of 2026-11-23,
  [WP137](../wp/WP137-common-plumbing-properties-poms-test-support.md), audit 2026-11-23 LIB-02..LIB-13, X-04, X-06,
  X-07, X-09, X-10, X-12, X-13

## Context
The audit of 2026-11-23 found the same plumbing written once per Quarkus service: three `InvalidRequestException`s
and mappers (and a hand-built `urn:hoops:problem:` for 415 and 502), three page result types and three `PageMeta`
records, three Accept-Language parsers with three es/en/id enums, three `Clock` producers in three scopes, two
pdf-service clients with two key families and two levels of answer checking, two paged-query builders with two APIs,
25 identical lines in the three `application.properties`, the test-library versions pinned in up to six poms with the
surefire/JaCoCo/`keycloak-it` blocks copied into each service, and test support (contract filters, log capture,
tenant-bound JDBC, the credentials check) copied between the test trees. ADR-0053 left copies *between* modules "for a
later look"; ADR-0062 and ADR-0066 took that look for the replica pipeline and the membership rule. Decision 104 asks
the same for the rest of the generic plumbing.

## Decision
1. **What is shared (common-quarkus main)**: code with no service-specific meaning that the contracts or an ADR fix
   once.
   - `problem`: `InvalidRequestException` (every violation, `of(field, code, message)`) and its mapper; the
     `MismatchedInputException` mapper (a body value of the wrong type is a `validation` Problem naming the field,
     never the value); `ProblemType.UNSUPPORTED_MEDIA_TYPE` (415) and `IDENTITY_PROVIDER_UNAVAILABLE` (502, core.yaml's
     slug). A body that is not JSON stays Quarkus REST's `about:blank` 400 in all three services: Quarkus wraps the
     parser's exception before any mapper sees it (athlete's mapper for it never ran).
   - `paging`: `PageRequest`, `PageResult<T>`, `PageMeta` (common.yaml's `PageMeta`) next to `PageOffset`.
   - `i18n`: `AppLanguage` (es, en, id; the legacy `in`) and `AcceptLanguage.negotiate` (ADR-0048). The services keep
     their own uses: core's `AppLocale` (stored user preference), athlete's `ContentLocale` (template texts) map from
     it; game uses `AppLanguage` directly for the sheet.
   - `time.ClockProducer`: a `@DefaultBean` UTC clock; a service or test brings its own `Clock` bean to replace it.
   - `persistence.PagedQuery` + `QueryConditions`: the JPQL page and count built from constant fragments, every value
     bound; one semgrep acceptance for the one class.
   - `client.PdfServiceClients`: building the pdf-service client (optional `hoops.pdf.url`, the caller's time-outs,
     its service token) and the `%PDF-` check of an answer. The time-outs stay per service on purpose (core's export
     transaction waits, so its are shorter).
   - `META-INF/microprofile-config.properties`: the settings identical in the three services (datasource kind, schema
     handling, OIDC role path, early tokens, broker defaults, the seven Dev Services topics, OTel build keys, the test
     profile's OIDC/JaCoCo/require-sub keys). A service's file still overrides; `LibraryDefaultsContract` (test-jar)
     shows each service sees them and restates none of the library's values.
2. **What is shared (test-jar)**: `ContractFilters` (strict, responses only, undeclared status tolerated, simulated
   bearer), `LogCapture`, `RlsTestDatabase.bindTenant` (the only place a test binds a tenant), and
   `NoBuiltInCredentialsContract` (core now runs it too, with ADR-0044 §9's mail password as its one named exemption).
3. **What is shared (root pom)**: the versions of assertj, wiremock and json-schema-validator, the surefire groups, the
   JaCoCo agent settings, the `>= 90 %` rule for every `com.hoopsacademy.*.domain*` package and the `keycloak-it`
   profile. A service pom lists only what it adds (Flyway, Kafka, scheduler, mailer, …) and its PIT scope.
4. **What stays per service, and why**: everything that says what a request or an event *means* for that service:
   domain exceptions beyond the generic ones, the per-resource page DTOs and query parameters (one record per contract
   schema; OAS 3.0.3 has no generics), core's and athlete's `PatchBody` (ADR-0053 lists them; X-08 is outside this
   decision), the WireMock resources (each stubs another set of collaborators under other keys), the core-event test
   builders (different APIs over different replicas), the per-service `@Scheduled` and `@Incoming` shims (ADR-0062),
   and the language enums that are stored or carry domain meaning.
5. **One copy of the projection vectors**: `libs/contracts/vectors` is the only copy; game's `ProjectionVectorsTest`
   writes and reads it and the web app's projector test reads it (amends ADR-0014's "copied to"); the two
   byte-equality checks and `apps/web/tool/sync_vectors.sh` are gone.

## Consequences
- A fix to one of these (a 415 Problem, a quality-value parse, a page envelope, a test filter mode) is made and
  tested once; PIT covers the pure ones once in common (`docs/quality/mutation.md`).
- Behaviour visible to clients: core and game answer a body value of the wrong type with athlete's `validation`
  Problem naming the field (before: `about:blank` 400); core refuses a pdf-service answer that is not a PDF (503, as
  game); core reads `hoops.pdf.*` (the chart and compose set only `PDF_SERVICE_URL`). Contracts are unchanged except
  finance.yaml (1.1.0 declares the 413 and 415 it always answered).
- pdf-service's vocabulary guard (ADR-0064) now finds `unsupported-media-type` in `ProblemType`; only
  `method-not-allowed` stays its own.
- **ADR-0053 amended**: a copy between Java modules of generic plumbing (not domain code) is not accepted; it goes to
  common-quarkus or its test-jar. Domain copies keep ADR-0053's rule.

## Alternatives considered
- **A `common-quarkus-testing` module with compile-scope dependencies** (LIB-10's option): would make the test-jar's
  dependencies transitive, but adds a module and moves every fixture; the services' test dependency lists stay.
- **Moving the WireMock resources, the core-event builders and `TokenAudienceKeycloakTest`**: each differs per service
  in keys, stubs or API, or needs a Keycloak run to prove; the saving is a few dozen lines each.
- **Sharing more contract components through `common.yaml`** (LIB-07): would rename generated Dart types while the web
  app changes in parallel, for no answer that changes; left for a contract round.
