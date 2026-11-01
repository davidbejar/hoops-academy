# Hoops Academy — agent guide

Multitenant platform for basketball academies: roster & eligibility, live match statistics (offline-first),
training/attendance, athlete health & fitness. Read this file first; the full plan lives in `docs/PLAN.md`.

## Stack (fixed decisions — see docs/adr)
- Java 21, Quarkus 3.x, Maven multi-module, hexagonal layering per service. Three services: `core-service`,
  `game-service`, `athlete-service`. Shared code in `libs/common-quarkus`; API contracts in `libs/contracts`.
- PostgreSQL 17, one database, schema per service, `tenant_id` + Row-Level Security (RLS). App roles are
  NON-OWNER roles (`core_app`, `game_app`, `athlete_app`); Flyway runs as `*_migrator`.
- Keycloak = authentication only (realm `academy`). Tenant roles (`ADMIN`, `COACH`, `ASSISTANT_COACH`,
  `PARENT`, `PLAYER`) live in `core.membership_role`. Platform `super_admin` is a Keycloak realm role.
- Flutter Web PWA in `apps/web` (es / en / id). No Node anywhere.
- Podman, not Docker. `podman compose` locally; kind + Helm + Tilt for k8s.

## Commands
```
source scripts/env.sh        # JDK 21 + Podman socket for Testcontainers (always do this first)
just doctor                  # toolchain check
just up / just down          # local stack: Postgres, Keycloak, nginx, MailHog
just test                    # ./mvnw verify (unit + integration + arch + RLS suites + coverage gates)
./mvnw -pl services/core-service quarkus:dev
just web-test                # flutter test
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
   it in tests; Dart clients are generated (`just gen-api`), never hand-written.
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
  built, how verified, open points) to the same file.

## Definition of Done (every work package)
`just test` green (coverage ≥ 80 % lines, ≥ 90 % in `domain`), RLS suites green for new tables, OpenAPI
updated + validated, ADR added if a decision was made, handover section written, no TODO without an issue.
