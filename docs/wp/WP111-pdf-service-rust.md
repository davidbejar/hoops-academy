# WP111 — pdf-service in Rust: match sheet and team roster, toolchain through just, CI, images, chart, Tilt

Model: Opus · effort high. Wave 1 (2026-11-15, eighth round): runs alongside WP112 (privacy threat model, docs only),
WP113 (PMD: every `pom.xml`, `config/pmd`), WP114 (Java base image: `deploy/containers/service.Containerfile`, the
pin scripts) and WP115 (web academy chooser, `infra/compose/nginx.conf`). You own `services/pdf-service/**`,
`libs/contracts/openapi/pdf.yaml`, `deploy/containers/pdf.Containerfile`, `deploy/helm/**` (chart 0.10.0 → 0.11.0),
`deploy/kind/**`, `Tiltfile`, `infra/compose/compose.yaml`, `infra/keycloak/realm-academy.json`, `justfile`,
`scripts/doctor.sh`, `scripts/bootstrap.sh`, `.github/workflows/ci.yml`, `codeql.yml`, `semgrep.yml`,
`.github/dependabot.yml`, a new skill `.claude/skills/rust-service/`, the Stack / Commands lines of `CLAUDE.md` that
name the new service, `docs/adr/0052-*.md` and the amendment in `docs/adr/0051-*.md`. Shared with WP114, append
only: `.github/workflows/images.yml` and `scripts/build-images.sh` (you add the pdf image; WP114 may change the Java
runtime image argument). You touch no `pom.xml` and no Java source. You are the wave's only kind user. Depends on:
ADR-0051, ADR-0034, ADR-0043, ADR-0045, ADR-0046, ADR-0048. Skills: owasp-security, test-driven-development,
clean-code, podman-dev-env, verification-before-completion. Worktree: `~/code/hoops-wt/wp111-pdf-service`, branch
`wp111-pdf-service`.

Decision 89 of 2026-11-15 (owner): the service that owns the data calls `pdf-service` and returns the PDF; the
browser never calls it. Decision 90: match sheet / box score and team roster, in es / en / id. ADR-0052 is reserved
for the stack (HTTP framework, PDF engine, toolchain pins, coverage and layering tooling); amend ADR-0051 §3 / §5:
no gateway route, callers are core and game with their client-credentials token.

## Scope
1. **Toolchain**: Rust pinned in `rust-toolchain.toml`, `Cargo.lock` committed; `scripts/bootstrap.sh` installs it,
   `just doctor` checks it. `just test` runs Maven and then the Rust gates (`just test-rust`: `cargo fmt --check`,
   Clippy with warnings denied, tests, coverage ≥ 80 % lines and ≥ 90 % in `domain`, a dependency audit).
2. **Service** (hexagonal: `domain` without framework crates → `application` → `adapters`; the layering enforced by
   an automated check, e.g. workspace crates whose dependencies make a wrong import a compile error). No database, no
   broker, no outbound network. Contract first in `pdf.yaml` (1.0.0): `POST /internal/pdf/match-sheet` and
   `POST /internal/pdf/team-roster`, each taking the data to print plus the locale and the academy's name and time
   zone, answering `application/pdf`; errors Problem+JSON without stack traces. Responses and requests validated
   against the contract in tests. Shape the two request bodies from what game's box score and core's roster export
   hold today (ADR-0048, `services/game-service`, `services/core-service`); WP116 and WP117 build on your contract.
3. **Not an open renderer**: fixed templates only, no caller markup, fonts or URLs; fonts bundled (a licence note in
   `THIRD_PARTY`); body limit and row caps with a 413 / 422 Problem; deterministic output for a fixed input and
   clock. JWT validated against the realm with audience `pdf-service` and the realm role `service` (ADR-0034); a
   denial is a `hoops.security` event and counts in `hoops_authz_denied_total` (ADR-0043). Nothing from a request
   body is logged or put on a span (ADR-0046); traces and logs over OTLP.
4. **Realm**: client `pdf-service` (bearer only); the `pdf-service` audience mapper on the clients `core-service` and
   `game-service`, not on `web`. A test proves a `web` token is refused.
5. **Delivery**: `pdf.Containerfile` (non-root, read-only root FS, digest-pinned bases), SBOM and Trivy gate in
   `images.yml`; compose service on port 8084; chart sub-chart behind a switch with a NetworkPolicy that admits only
   core and game, no HTTPRoute; `PDF_SERVICE_URL` wired into core's and game's environment in compose and chart
   (they ignore it until WP116 / WP117); Tilt resource; chart tests and snapshots; CI job; Dependabot for cargo;
   CodeQL / Semgrep extended to Rust where they support it (say what they do not).
6. **Kind proof**: `up.sh --deploy` with the service on, a rendered PDF fetched from inside the cluster with a
   core-service token, the NetworkPolicy refusing another pod. Stop compose while proving on kind.
7. **Docs**: ADR-0052, ADR-0051 amendment, the skill for agents working on the Rust service, `CLAUDE.md` lines.

## Acceptance
- [ ] Contract `pdf.yaml` 1.0.0 validated in tests; both sheets render in es / en / id (a test reads the text back)
- [ ] Red tests committed before each change
- [ ] `just test` green (fresh; Maven totals unchanged, Rust totals and coverage); `actionlint` clean; chart tests green
- [ ] Trivy 0 HIGH / CRITICAL on the pdf image; kind proof recorded
- [ ] Handover appended: the exact request shapes, the token a caller needs, `PDF_SERVICE_URL` per environment, how to
      stub the service in a Java test, chart version, what WP118 (Go) can copy from your toolchain wiring

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first (JDK 25). Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then a plain `git commit` with explicit paths (never `git add -A`, never
  `--no-verify`: the session refuses it). The pre-commit hooks run and may trim whitespace in generated files: re-add
  and commit again. Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit
  (it resyncs the Podman VM clock itself); under load it can time out: retry when a build has finished, never bypass
  it. End every commit message with a `Co-Authored-By:` line that names the model you are.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Gate rules: constant SQL with bound parameters (CodeQL), no nil-tenant bind without a dated acceptance (Semgrep), no
  environment-derived program names in scripts and tests (Semgrep taint). Since WP113 the PMD / CPD gate runs in
  `verify`: stay inside its thresholds, add no exclusion without a reason.
- An OpenAPI generator run can leave whitespace-only diffs in the Dart packages: discard them. Regenerate only your
  package (`scripts/gen-api.sh <svc>`). `apps/web/pubspec.lock`: commit it only with a generated package's version
  bump; revert other drift. `apps/web/lib/l10n/*.arb`: keys next to the feature's existing keys, never at the end.
- Shared index files (`docs/adr/README.md`, `docs/domain/authz-matrix.md`): append at the end, one entry per line.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- Built:
  - `services/pdf-service`: Cargo workspace, crates = layers (`pdf-domain` -> `pdf-application` -> `pdf-adapters` +
    binary), `tests/layering.rs` pins the manifests. Toolchain 1.99.1 (`rust-toolchain.toml`), `Cargo.lock` committed.
    axum 0.8, krilla 0.8 with bundled Roboto (Apache-2.0, `THIRD_PARTY.md`), `jsonwebtoken` 12 against the realm's JWKS,
    OTLP over HTTP/protobuf. Contract `libs/contracts/openapi/pdf.yaml` 1.0.0 (in the contracts jar as
    `classpath:openapi/pdf.yaml`).
  - Gates: `just test` = Maven `verify` then `just test-rust` (`services/pdf-service/scripts/check.sh`: rustfmt, Clippy
    all+pedantic `-D warnings`, tests under cargo-llvm-cov, coverage gate 80 % / 90 % domain, `cargo deny`). Doctor and
    bootstrap install / check rustup, the pinned toolchain, cargo-llvm-cov, cargo-deny. CI job `rust`; CodeQL matrix
    with `rust` (build-mode none); Semgrep `p/rust`; Dependabot `cargo`.
  - Delivery: `deploy/containers/pdf.Containerfile` (cargo-auditable on `rust:1.99.1-slim-trixie`, runtime
    `distroless/cc-debian13:nonroot`, both by index digest; 49 MB, user 65532), `images.yml` job `pdf`,
    `build-images.sh pdf-service`; compose service `pdf-service` (profile `pdf`, `just pdf-up`, :8084); chart 0.11.0 with
    sub-chart `pdf-service` 0.1.0 (alias `pdf`; on in kind and cloud), no HTTPRoute, NetworkPolicy in: core-service and
    game-service only, out: DNS, Keycloak :8080, collector :4318; Tilt resource `pdf-service` (port 18084, `--no-pdf`).
  - Also (orchestrator notes): hoops-service pods run as 65532:65532 (ADR-0054); `deploy/kind/smoke.sh` reads metrics
    through `kubectl port-forward` (no curl in distroless) and checks pdf-service; Problem answers never repeat a request
    value (P-11: `violations` = field path + code; tests `validation_failures_name_the_field_never_the_value`,
    `too_many_players_is_422_naming_the_list_never_the_children`, `malformed_json_is_400`, `logs.rs`).
  - Realm: bearer-only client `pdf-service`; `seed-users.sh` creates it in an older compose realm. **Not done: the audience
    mappers** (see open points).
- Verified (2026-11-16):
  - `just test` fresh, exit 0: Maven 3,392 tests, 0 failures, 0 errors, 26 skipped (= WP113's total, unchanged; PMD gate
    on); Rust 100 tests, 0 failed; coverage 95.41 % lines workspace (2122/2224), 99.80 % domain (985/987); `cargo deny`:
    advisories, bans, licenses, sources ok. `just test-hooks` 39 tests OK (1 skipped).
  - `deploy/helm/tests/run.sh`: ALL CHART TESTS PASSED (lint, 7 snapshots re-recorded, kubeconform, new pdf assertions).
    `actionlint` clean on all workflows. Semgrep `p/rust` + `p/owasp-top-ten` + repo rules on `services/pdf-service`:
    0 findings. CodeQL Rust not run locally (CI only).
  - Trivy 0.76.1 on the pdf image (`--severity HIGH,CRITICAL --ignore-unfixed --exit-code 1`): exit 0, debian 13.7 and the
    rustbinary 0 findings. `scripts/sbom.sh generate`: CycloneDX 1.7 valid, 224 components, 208 cargo crates.
  - kind (`deploy/kind/up.sh --deploy --from-host`, compose stopped; the Java images on the distroless base of WP114,
    user 65532): all pods Ready; `smoke.sh core game athlete` SMOKE PASSED twice (52 ok each, events checks through
    port-forward). Run 1, realm as committed: core's token -> 401 (no pdf-service audience), no token 401, NetworkPolicy
    refused an unlabelled pod and an athlete-service-labelled pod (timeouts), gateway `/internal/pdf/...` 403. Run 2, after
    adding the two audience mappers **at runtime** with kcadm (not in git): a pod labelled core-service rendered the team
    roster fixture with core's token: 200, `application/pdf`, 18,145 bytes, `%PDF-`. Spans and log records of
    `service.name=pdf-service` in the collector; no fixture name in the pod log.
  - compose: `just pdf-up` built and started it; core's compose token -> 401 reason `audience` (keys and issuer by
    discovery work). Compose was restored afterwards (pdf-service container removed).
- Decisions/ADRs: ADR-0052 (stack, gates, delivery); ADR-0051 amended (§3 no gateway route, callers core and game; §5).
  Skill `.claude/skills/rust-service`. CLAUDE.md Stack / Commands lines.
- For WP116 (core) and WP117 (game):
  - Request shapes: `pdf.yaml` `TeamRosterRequest` {locale es|en|id, academy {name, timeZone IANA}, team {name, season?,
    category?}, players[<=60] {givenName, familyName, birthDate?, gender? MALE|FEMALE, ageCategory?, eligibility
    ELIGIBLE|PLAY_UP|INELIGIBLE, playUpLevels 0..20, jerseyNumber?, joinedOn, email?, phone?, guardians[<=4] {givenName,
    familyName, email?, phone?}}, staff[<=20] {role COACH|ASSISTANT_COACH, givenName, familyName, since, email?, phone?}}
    and `MatchSheetRequest` {locale, academy, match {teamName, opponentName, homeAway, scheduledAt, venue?, status,
    periodCount 1..8, periodMinutes 1..60}, score, periodScores[<=12] {period 1..12, team, opponent}, teamTotals StatLine,
    players[<=30] {displayName, jerseyNumber?, wasStarter, stats StatLine}}; StatLine = game's. Unknown properties are 400.
    Examples: `services/pdf-service/crates/adapters/tests/fixtures/{team-roster,match-sheet}.json`. Answer 200
    `application/pdf` with `Content-Disposition: attachment; filename="hoops-<academy>-roster-<team>-<yyyyMMdd>.pdf"`
    (match sheet: `...-match-sheet-<team>-<opponent>-...`) and `Cache-Control: no-store`: pass both on to the browser.
  - Token: the caller's own client-credentials token (`quarkus-oidc-client`, as for `/internal`), `aud` must contain
    `pdf-service`, realm role `service`. **WP116 must first add the mappers** (red: core's `RealmTokenPolicyTest` CsvSource
    `"core-service, game-service athlete-service pdf-service"` and `"game-service, core-service pdf-service"`; green: in
    `infra/keycloak/realm-academy.json` add to the `protocolMappers` of clients `core-service` and `game-service`
    `{"name": "audience pdf-service", "protocol": "openid-connect", "protocolMapper": "oidc-audience-mapper",
    "consentRequired": false, "config": {"included.client.audience": "pdf-service", "access.token.claim": "true",
    "id.token.claim": "false", "introspection.token.claim": "true"}}`, then `scripts/sync-chart-files.sh` and
    `deploy/helm/tests/run.sh --update`; `just seed-users` patches an existing compose realm). Never the `web` client.
  - `PDF_SERVICE_URL`: host / compose `http://localhost:8084` (`.env`, `e2e/bin/services-up.sh` default; start it with
    `just pdf-up`); kind and cloud `http://pdf-service:8084` (already in core's and game's chart env); Tilt debugging
    port 18084. Errors to map: 400/422 (a bug in the caller's mapping or over the row caps: 422 `TOO_MANY_ROWS`), 401/403
    (realm misconfiguration), 413, 503 `AUTH_UNAVAILABLE` (retry), 500.
  - Stub in a Java test: WireMock (or a Quarkus test resource) on `PDF_SERVICE_URL` answering 200
    `application/pdf` with a body starting `%PDF-` and the Problem cases; validate the received body against
    `classpath:openapi/pdf.yaml` schema `TeamRosterRequest` / `MatchSheetRequest` with the strict validator; optionally
    add `pdf` to `OpenApiSpecs.SERVICES`-style contract tests in `libs/contracts`.
  - Chart version 0.11.0 (sub-charts: hoops-service 0.9.0, pdf-service 0.1.0).
- For WP118 (Go): copy `services/pdf-service/scripts/check.sh` + `coverage_gate.py` as `just test-go`, the doctor and
  bootstrap lines, the CI job with SHA-256-checked tool downloads, the `images.yml` job (context = the service dir, its
  own `.containerignore`, distroless base by digest), the sub-chart + Tilt + compose-profile pattern, and ADR-0052's
  "counterparts of the Java gates" table.
- Open points / follow-ups:
  - **Needs the orchestrator / WP116**: the `pdf-service` audience mappers on `core-service` and `game-service` are not in
    the realm file, because they change core's `RealmTokenPolicyTest` (Java) and this WP was told to touch no Java; the
    exact patch is above. Until then core's and game's tokens are refused (401), as the first kind run shows.
  - The TDD order was kept per slice with red commits, except `tests/realm.rs` (verifier over HTTP, written after the
    verifier) and the renderer, whose first version was spiked before its red commit and re-applied after it.
  - Not covered by the existing tools (ADR-0052): no repository Semgrep rule for Rust; OWASP dependency-check has no Rust
    analyser (cargo deny + Trivy instead); no mutation testing for Rust (`cargo-mutants` candidate); CodeQL Rust runs in CI
    only. The pdf image pins are bumped by hand (not in `scripts/bump-pins.sh`, owned by WP114 this wave).
  - `just e2e` and the e2e journeys were not run (no journey uses pdf-service yet; WP116 / WP117 add them).
