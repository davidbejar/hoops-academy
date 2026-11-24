# WP143 — Services, observability: the SQL calls of every service appear in its traces

Model: Opus · medium. Wave 1 (2026-11-24, tenth round): runs alongside WP142 (pins: infra, chart, workflows). You own
the telemetry settings and their tests in `libs/common-quarkus` (append your lines at the end of
`META-INF/microprofile-config.properties`; WP142 changes one pin line there), `services/core-service`,
`services/game-service`, `services/athlete-service` and `services/finance-service`, and the compose collector file
only if a span attribute must be dropped there. pdf-service has no database: nothing to do there. Depends on: nothing
(ADR-0046 and its amendments are the context). Skills: work-package, quarkus-hexagonal-service, go-hexagonal-service,
owasp-security, test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp143-database-spans-in-traces`, branch `wp143-database-spans-in-traces`.

Decision 116 of 2026-11-24: a trace no longer ends at the service: core, game, athlete and finance report their
database calls as spans. ADR-0074 is reserved for you (an amendment of ADR-0046 if that is all it is).

## Scope
1. **Java services**: `quarkus.datasource.jdbc.telemetry=true` is a build-time property: set it once in
   common-quarkus' shared properties (ADR-0069) and prove with a test per service that a request yields a database
   span under the request's span (the in-memory span exporter the tests already use, or add one in the test-jar). The
   contract test that each service sees the library's values, and `deploy/helm/tests/run.sh`'s check of the OTel build
   keys, must know the new key.
2. **finance-service**: pgx has no tracer today: add one (`otelpgx` or a small tracer of your own behind the existing
   telemetry adapter; a new dependency needs the licence and `govulncheck` gates green and a line in the archtest if
   it adds an import to a layer). Test: a request yields a database span.
3. **Privacy (P-11, ADR-0043)**: a span must not carry a bound parameter value, a tenant's data or a full statement
   with literals. Decide what the statement attribute holds (parameterised text is acceptable, values never) and prove
   it with a test that greps the exported spans for a seeded name and e-mail. The `set_config` tenant binding runs on
   every transaction: say in the ADR whether its span is kept or dropped, and why.
4. **Cost**: measure the span count of one typical request before and after (core's team roster read, game's feed,
   athlete's session sheet, finance's dues list) and record it; if a request yields more than a few dozen database
   spans, that is a finding for the handover, not something to hide by sampling.
5. **Proof on compose**: with `just observability-up` running, one request per service shows the database spans in
   Tempo. If the owner's stack cannot be used from the worktree, say "not run": the orchestrator does it at merge.

## Acceptance
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` and `just test-go` green (fresh; totals; coverage gates
      met)
- [ ] The privacy test fails when a value is put on a span (shown red first)
- [ ] `deploy/helm/tests/run.sh` green; ADR written and added at the end of `docs/adr/README.md`
- [ ] Red tests committed before each change
- [ ] Handover appended: what was built, fresh verification with totals, what was not run, open points

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then a plain `git commit` with explicit paths, one at a time and not from a
  helper script (never `git add -A`, never `--no-verify`: the session refuses it). The pre-commit hooks run and may
  trim whitespace: re-add and commit again. Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation
  test before every commit (it resyncs the Podman VM clock itself); it is expected, do not try to bypass it; if it
  times out under load, retry when a build has finished. End every commit message with a `Co-Authored-By:` line
  naming the model that did the work.
- If your context runs low, stop at a green commit, append a handover part (what is done, what comes next in order)
  and report; a fresh agent continues in this worktree.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.
- Do not read, copy or print any `.env`. The compose stack that is running is the owner's: do not `just down` it, do
  not remove or recreate its volumes. What needs the real stack or the owner's database comes back "not run" in the
  handover; the orchestrator runs it from the main checkout at merge time.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
- Built:
  - **Java** (core, game, athlete): `quarkus.datasource.jdbc.telemetry=true` appended to common-quarkus'
    `META-INF/microprofile-config.properties` (build-time; Agroal hands out connections through OpenTelemetry's JDBC
    wrapper, already on the classpath). `LibraryDefaultsContract` and `deploy/helm/tests/run.sh`'s OTel build-key check
    know the key (and that no service restates it).
  - `DatabaseSpansNeedAParent` (common-quarkus, a `Sampler` bean): the configured `parentbased_traceidratio` (ratio
    from `quarkus.otel.traces.sampler.arg`) that drops a database `CLIENT` span without a parent, so core's outbox poll
    (every second) and other background statements start no trace of their own. Refuses to start if
    `quarkus.otel.traces.sampler` is anything else (Quarkus uses a Sampler bean instead of that key).
  - Test-jar: `RecordedSpans` (in-memory `SpanExporter` bean), `SampledTrace` (a sampled `traceparent` / context),
    `RequestTrace` (root, database spans, ancestry, all exported text), `TracingProfile` (SDK on, simple processor,
    OTLP off: no test span reaches a collector on localhost:4317).
  - `DatabaseSpansTest` in core (roster read; privacy grep; a refused insert on `core.team`; a statement outside any
    span; `/q/health/ready` with a sampled traceparent leaves no span), game (feed; roster name and note text) and
    athlete (session sheet; an attendance note written as a bound value).
  - **finance**: `telemetry.QueryTracer` (pgx `QueryTracer`, no new module): client span per statement under the
    request/job span, `db.system`, `db.operation`, `db.name`, `db.statement` (string literals -> `?`, `$n` kept), no
    span without a parent, a refused statement keeps its SQLSTATE only (no server text, no exception event).
    `persistence.NewPool` sets it; `main` builds the pool with it; the REST test harness (`newTracedAPI`) uses the
    same constructor plus `otelhttp` as `main` does.
- Span counts, one request, SDK on (tests): core roster read 1 -> 5 (4 database: `set_config`, team, team_player,
  player+person); game feed 1 -> 5 (4); athlete session sheet 1 -> 5 (4); finance dues list 1 -> 11 (10: two
  transactions of BEGIN, `set_config`, SELECTs, COMMIT). Nothing near "a few dozen". Outbox poll: per-poll statement
  count not measured (in the test profile the poll returns before the database); the orphan test shows such
  statements no longer become traces.
- Privacy: red shown with a value planted on the server span (`Span.current().setAttribute(...)` with the roster DTO in
  `TeamPlayerResource.list`, not committed): `noSpanOfTheRosterReadCarriesAValueATenantOrAName` failed on
  "Zelphine", "Quorrowby"; reverted, green. The Java exception event of a refused insert names the constraint only:
  PostgreSQL leaves out the `DETAIL` that quotes the key when the table has RLS for the role (all tables force it).
- Verified (fresh, after the last code change):
  - `./mvnw -B -ntp -o -T 1C verify -Dquarkus.http.test-port=0`: BUILD SUCCESS, 3,794 tests, 0 failures, 0 errors,
    32 skipped, all coverage checks met. (The earlier run, before the sampler, had one wall-clock failure in core
    `TenantUsageResourceTest.aPeerSlowerThanTheTimeoutCountsAsUnavailable`, 3583 ms > 3400 ms while the commit hook's
    Keycloak check ran alongside; green alone and in the fresh run.)
  - `just test-go`: gofmt, tidy, golangci-lint 0 issues, tests ok, coverage module 88.68 %, domain 98.84 %,
    govulncheck: no vulnerabilities reached (go.mod unchanged).
  - `bash deploy/helm/tests/run.sh`: ALL CHART TESTS PASSED (237 ok; red before the key, only the three build-key
    checks). No chart snapshot changed.
  - `just isolation-check` (6 Java + 4 Go tests) and `just db-role-check` (13 + 2) passed in the worktree (no `.env`
    needed). `just docs-build` strict: no issues.
- Not run: the Tempo proof on compose (`just observability-up` reads the owner's `.env`). At merge, from the main
  checkout with `just up` running: rebuild/restart the services from the merged code (a build-time key), then
  `just observability-up`, start core/game/athlete with `QUARKUS_OTEL_SDK_DISABLED=false` (`./mvnw -pl
  services/<svc>-service quarkus:dev`) and finance with `HOOPS_OTEL_SDK_DISABLED=false` (`just finance-up`), make one
  request each (team players list, match events feed, session attendance, `GET /api/finance/dues`). In Grafana
  (http://localhost:3000, Explore, Tempo) search `{ span.db.system = "postgresql" }` or by service: each request's trace
  shows the server span with 4 (finance 10) child spans named `SELECT core.team` etc. (finance `SELECT`, `BEGIN`,
  `COMMIT`); `db.statement` holds `?`/`$n`, never a value; `select set_config(?, ?, true)` is the first child; no trace
  consists of database spans alone (the outbox poll leaves none).
- Decisions/ADRs: ADR-0074 (amends ADR-0046, pointer amendment added there; line at the end of `docs/adr/README.md`):
  statement attribute = parameterised text, values never; `set_config` span kept (evidence of the tenant binding,
  tenant id is a bound value); database spans need a parent; finance's own tracer instead of `otelpgx`.
- Open points / follow-ups:
  - `quarkus.otel.traces.sampler` can only stay `parentbased_traceidratio` while `DatabaseSpansNeedAParent` exists.
  - Residual (untested): a driver/server message that echoes malformed input could reach a Java exception event; the
    services validate input before SQL.
  - Tracing the scheduled jobs (`quarkus.scheduler.tracing.enabled`) would give the nightly jobs traces with their
    SQL; a separate decision.
  - The compose collector file is unchanged (no attribute needed dropping).
