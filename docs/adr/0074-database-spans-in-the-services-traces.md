# ADR-0074: The services report their SQL as spans of the request that runs it

- Status: Accepted (amends ADR-0046)
- Date: 2026-11-24
- Related: decision 116 of 2026-11-24, [WP143](../wp/WP143-database-spans-in-traces.md), ADR-0046 (collector, traces
  and logs), ADR-0043 and the privacy threat model (P-07, P-11), ADR-0069 (shared settings in common-quarkus),
  ADR-0011 (tenant binding per transaction)

## Context
Until now a trace stopped at the service: Envoy -> core -> game showed which service was slow, not which statement.
Decision 116 asks core, game, athlete and finance to report their database calls as spans. The constraints: no span may
carry a bound value, a tenant's data or a statement with literals (P-11 stance, ADR-0046 "no tenant id in telemetry");
`set_config('app.tenant_id', ...)` runs in every transaction; the cost per request has to be known.

## Decision
1. **Java services: OpenTelemetry's JDBC wrapper**, switched on once with the build-time key
   `quarkus.datasource.jdbc.telemetry=true` in common-quarkus' shared settings (ADR-0069). `LibraryDefaultsContract` and
   the chart test's build-key check know it; no service sets it. Nothing new on the classpath (`opentelemetry-jdbc`
   came with `quarkus-opentelemetry`).
2. **finance-service: a query tracer of its own** (`internal/platform/telemetry.QueryTracer`, about 60 lines) set on the
   pool by `persistence.NewPool`, which `main` uses. Not `otelpgx`: one more module (and its licence and `govulncheck`
   surface) for what pgx's `QueryTracer` interface gives in a page, and a tracer that never reads the arguments cannot be
   configured to capture them. No layer gains an import (the tracer is in `platform`, the pool in an adapter).
3. **What a database span holds** (the Java wrapper's attributes, the same keys in finance): `db.system=postgresql`,
   `db.operation`, `db.name`, `db.sql.table` (Java), `db.statement`, and (Java) `server.address`, `server.port`,
   `db.connection_string` without credentials. **`db.statement` is the parameterised text**: the Java wrapper's
   sanitiser replaces every literal by `?` (on by default; Quarkus offers no switch to capture parameters), finance
   replaces string literals by `?` and keeps its `$n` placeholders. **Bound values never**: neither instrumentation
   reads them. Span names: `SELECT core.team` (Java), `SELECT` / `BEGIN` / `COMMIT` (finance).
4. **A refused statement.** The Java wrapper records the driver's exception as a span event (type, message, stack). It
   carries no value because PostgreSQL leaves out the `DETAIL` that quotes a key or row (`Key (...)=(...)`, `Failing row
   contains`) when the table has row-level security for the role, and every table here forces RLS for the app roles
   (`RlsSchemaMetaTest`); proved on `core.team` (a duplicate name: the event names the constraint, not the name or the
   tenant). Finance keeps only the SQLSTATE (`db.response.status_code`, status `SQLSTATE 23505`) and no server text.
   Residual, not tested: a driver or server message that echoes malformed input (an unparsable value); the services
   validate input before it reaches SQL.
5. **The `set_config` span is kept.** It is `select set_config(?, ?, true)` (Java, the setting name sanitised too) or
   `select set_config(?, $1, true)` (finance): the tenant id is a bound value and never on the span. It costs one span
   per transaction, and it is the evidence that the tenant binding ran in the transaction that read the rows, which is
   the first thing to look at when RLS answers nothing. Dropping it would need a sampler that recognises statement text.
6. **A database span needs a parent.** A statement outside any request or job span (core's outbox poll, every second;
   the replica consumers; the jobs that are not traced) would be a trace of its own with no request to explain it (core:
   shown by `DatabaseSpansTest.aStatementOutsideAnySpanStartsNoTrace` before this decision). Java: the `Sampler` bean
   `DatabaseSpansNeedAParent` (common-quarkus) is the configured `parentbased_traceidratio` (ratio from the runtime
   `quarkus.otel.traces.sampler.arg`) and drops a `CLIENT` span with `db.system` and no parent. Quarkus takes a
   `Sampler` bean instead of the one it builds from `quarkus.otel.traces.sampler`, so the bean refuses to start for any
   other value of that key: the key keeps deciding. Quarkus still wraps the bean to keep `/q/*` untraced (tested). Finance:
   the tracer starts no span when the context carries none. This is not sampling a request's spans away: every span of a
   sampled request is kept.
7. **Cost**, one typical request with the SDK on (tests, Testcontainers PostgreSQL), spans per request:

   | Request | Before | After | Database spans |
   |---|---|---|---|
   | core `GET /api/core/teams/{id}/players` | 1 | 5 | `set_config`, team, team_player, player+person |
   | game `GET /api/game/matches/{id}/events` | 1 | 5 | `set_config`, match, match_summary, match_event |
   | athlete `GET .../training-sessions/{id}/attendance` | 1 | 5 | `set_config`, session, attendance, planned_absence |
   | finance `GET /api/finance/dues` | 1 | 11 | 10: two transactions of `BEGIN`, `set_config`, `SELECT`s, `COMMIT` |

   No request comes near "a few dozen". The Grafana request and error panels count `SPAN_KIND_SERVER` spans only, so
   they are unchanged; Tempo stores about five times the spans per request (11 times for finance's list).

## Consequences
- A slow request in Tempo shows its statements and their durations; the tenant binding shows as its own span.
- The services' images must be rebuilt (a build-time key); with the SDK off the wrapper records nothing.
- `quarkus.otel.traces.sampler` can only be `parentbased_traceidratio` while `DatabaseSpansNeedAParent` exists; another
  sampler means changing the bean.
- Tests: `RecordedSpans` (an in-memory `SpanExporter` bean), `SampledTrace`, `RequestTrace` and `TracingProfile` in the
  test-jar; `DatabaseSpansTest` in core, game and athlete greps every exported span (names, attributes, events) for a
  seeded name, e-mail, note and the tenant id; finance's `TestTheDuesListShowsItsSQLUnderTheRequestSpanAndNoValue` does
  the same for a payment note.

## Alternatives considered
- **`otelpgx` for finance**: see 2; its `WithIncludeQueryParameters` option is exactly what must never be on.
- **Dropping the `set_config` span** (a sampler matching the statement): one span per transaction saved, the evidence of
  the binding lost; see 5.
- **Tracing the scheduler (`quarkus.scheduler.tracing.enabled`)** instead of dropping parentless spans: the outbox poll
  would then be one trace per second with its statements; worth it for the nightly jobs, a separate decision.
- **`logServerErrorDetail=false` on the JDBC URL** against values in error text: not needed while every table forces RLS
  (4), and it would change every error text the services log, for a case no table has today.
