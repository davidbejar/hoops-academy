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
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
