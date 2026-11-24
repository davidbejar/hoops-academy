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
