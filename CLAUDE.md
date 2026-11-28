# Hoops Academy — agent guide

Multitenant platform for basketball academies: roster & eligibility, live match statistics (offline-first),
training/attendance, athlete health & fitness. Read this file first, then `docs/HANDOVER.md` (current state, pending user actions, lessons). The original request
is `docs/SPEC.md` (verbatim), the plan `docs/PLAN.md` (see its implementation notes), what was built vs the spec
`docs/conformance.md`, open items `docs/wp/FOLLOW-UPS.md`. The old OneDrive planning folder is archived: never write there.

## Stack (fixed decisions — see docs/adr)
- Java 25, Quarkus 3.x, Maven multi-module, hexagonal layering per service. Three services: `core-service`,
  `game-service`, `athlete-service`. Shared code in `libs/common-quarkus` (tenancy, Problem+JSON, paging and
  `PagedQuery`, the roster replica pipeline, the membership rule, the settings all three share; ADR-0062, ADR-0066,
  ADR-0069); domain code stays per service. API contracts in `libs/contracts`.
- `pdf-service` in Rust (ADR-0051, ADR-0052): Cargo workspace `services/pdf-service` outside the reactor (crates =
  layers), toolchain pinned in `rust-toolchain.toml`; internal only, called by core and game. Skill `rust-service`.
- `finance-service` in Go (ADR-0051, ADR-0055, ADR-0056): module `services/finance-service` outside the reactor
  (`internal/domain` → `application` → `adapters`, checked by `internal/archtest`), Go pinned by go.mod's `toolchain`
  line, schema `finance` (`finance_app` / `finance_migrator`), `/api/finance/**`, contract `finance.yaml`.
  Skill `go-hexagonal-service`.
- PostgreSQL 19 (ADR-0073: one minor in compose, chart and test harnesses), one database, schema per service,
  `tenant_id` + Row-Level Security (RLS). App roles are NON-OWNER roles (`core_app`, `game_app`, `athlete_app`,
  `finance_app`); Flyway (finance: its Go runner) runs as `*_migrator`. The roles are listed once, in
  `infra/db/init/01_roles_schemas.sql` (ADR-0006 amendment).
- Keycloak = authentication only (realm `academy`). Tenant roles (`ADMIN`, `COACH`, `ASSISTANT_COACH`,
  `PARENT`, `PLAYER`) live in `core.membership_role`. Platform `super_admin` is a Keycloak realm role. The realm URL
  is `OIDC_AUTH_SERVER_URL` everywhere, the Admin API base `KEYCLOAK_ADMIN_URL` (ADR-0071).
- Flutter Web PWA in `apps/web` (es / en / id). No Node anywhere.
- Podman, not Docker. `podman compose` locally; kind + Helm + Tilt for k8s.

## Commands
```
source scripts/env.sh        # JDK 25 + Podman socket for Testcontainers (always do this first)
just doctor                  # toolchain check
just up / just down          # local stack: Postgres, Keycloak, nginx, MailHog, Redpanda
just test                    # ./mvnw verify (unit + integration + arch + RLS suites + coverage gates), then test-rust, test-go
just test-rust               # pdf-service: rustfmt, clippy -D warnings, tests + coverage gates, cargo deny
just test-go                 # finance-service: gofmt, golangci-lint, tests (RLS + isolation suites) + coverage gates, govulncheck
just finance-up              # finance-service in compose on :8085 (needs just up)
just isolation-check         # academy A logs in (real Keycloak), cannot read academy B; Claude hook runs it before git commit
just db-role-check           # no service connects as table owner / superuser / BYPASSRLS; Claude hook runs it before git push
just mutation [module]       # PIT on the rule code, on demand (not in verify); fails below the baseline; docs/quality/mutation.md
./mvnw -pl services/core-service quarkus:dev
just web-test                # flutter test
just web-format              # dart format apps/web (80 columns); CI runs web-format-check
just docs-serve / docs-build # documentation site of docs/ (Zensical, ADR-0057): preview on :8000 / strict build; main is published to GitHub Pages
just scan                    # gitleaks + dependency-check
```

## Non-negotiable rules
1. **TDD.** Follow `.claude/skills/test-driven-development`. Red → green → refactor, test committed first.
2. **Tenant isolation.** Every tenant table: `tenant_id uuid not null`, `ENABLE` + `FORCE ROW LEVEL SECURITY`,
   policy on `app.current_tenant()`. Every new table is covered by `RlsSchemaMetaTest` and
   `GenericRlsIsolationTest` from `common-quarkus` (test-jar). Never connect tests as a superuser/owner.
3. **Authz in the application layer.** `@RequiresTenantRole` + fine-grained `Authz` checks; non-members get
   404, never 403. The matrix in `docs/domain/authz-matrix.md` is the oracle for role-matrix tests.
4. **Hexagonal.** `domain` (no framework imports) → `application` (use cases, ports) → `adapters`
   (`in/rest`, `out/persistence`, `out/client`, `out/keycloak`). ArchUnit enforces it.
5. **Contracts first.** OpenAPI in `libs/contracts` is the source of truth; responses are validated against
   it in tests; Dart clients are generated (`just gen-api` → `apps/web/packages/<svc>`), never hand-written.
6. **Secrets never in git.** Placeholders only in `.env.example`; gitleaks runs pre-commit and in CI.
7. **Verification before completion.** Follow `.claude/skills/verification-before-completion`: run the
   full command, read the output, then claim.
8. **Clean code.** Follow `.claude/skills/clean-code`. Value objects over primitives (`TenantId`, `PlayerId`).
9. **Security.** Use `.claude/skills/owasp-security` when touching auth, uploads, config, dependencies.
10. **Debugging.** Use `.claude/skills/systematic-debugging` before proposing any fix.

## Conventions
- Package root `com.hoopsacademy.<service>`; sub-packages `domain`, `application`, `adapters.in.rest`,
  `adapters.out.persistence`, …; tests mirror packages. Integration tests end with `IT`? No: all tests run
  in `verify` via surefire; `@QuarkusTest` classes end with `Test`, pure unit tests too. Use `@Tag("rls")`
  for the generic RLS suites.
- Flyway: `db/migration/V<nn>__<snake_case>.sql`, one concern per file; every tenant table created with the
  `app.enable_tenant_rls('<schema>.<table>')` helper.
- REST: resources under `/api/<service>/...`, platform under `/platform/...`, internal under `/internal/...`.
  Problem+JSON (`application/problem+json`) for all errors; no stack traces.
- Commits: Conventional Commits (`feat(core): …`, `test(game): …`, `chore(infra): …`).
- Work packages: brief in `docs/wp/WP<n>-<slug>.md`; when done append a `## Handover` section (what was
  built, how verified, open points) to the same file. Execute one with `.claude/skills/work-package`; plan and
  run a round with `.claude/skills/wp-round`.

## Definition of Done (every work package)
`just test` green (coverage ≥ 80 % lines, ≥ 90 % in `domain`), RLS suites green for new tables, OpenAPI
updated + validated, ADR added if a decision was made, a new or changed trust boundary, service, data store or
agent guardrail reflected in the threat model that covers it (ADR-0077), handover section written, no TODO without an issue.
