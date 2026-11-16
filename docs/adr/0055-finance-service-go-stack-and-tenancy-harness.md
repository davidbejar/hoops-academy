# ADR-0055: finance-service in Go: standard library HTTP, pgx, franz-go, a Flyway-named runner, the same gates

- Status: Accepted
- Date: 2026-11-16
- Records: the stack items ADR-0051 §5 left to the brief of WP118 (decisions 92-99), the Go counterparts of the Java
  harness (ADR-0051 §4)
- Related: ADR-0006 / ADR-0011 (RLS, tenant per transaction), ADR-0017 (audit), ADR-0031 / ADR-0033 (gateway, rate
  limits), ADR-0034 (audience per service), ADR-0036 / ADR-0037 (events, replicas), ADR-0043 (security events, SBOM),
  ADR-0045 (SAST), ADR-0046 (OTLP), ADR-0048 (exports), ADR-0052 (the Rust counterpart), ADR-0054 (distroless),
  ADR-0056 (the finance model), `libs/contracts/openapi/finance.yaml`, `.claude/skills/go-hexagonal-service/SKILL.md`

## Context
ADR-0051 decided an academy finance service in Go and left frameworks, the migration tool, mutation testing and the
toolchain pins to the work package. A Go service gets nothing of `libs/common-quarkus`: tenant binding, membership
resolution, authz, Problem+JSON, security events, the RLS meta and isolation suites, the database role check and ArchUnit
all have to exist again, equal in strength, before the first endpoint (rule 2).

## Decision
### Libraries (few, mainstream, pure Go)
- **HTTP**: the standard library `net/http` (method and wildcard patterns of Go 1.22+); no framework. Custom methods
  (`{id}:archive`) are one path segment split by the handler. `otelhttp` names the server span after the contract's route
  template.
- **SQL**: `jackc/pgx/v5` with `pgxpool`; constant SQL with bound parameters only (optional filters as `$n is null or ...`),
  every statement also names `app.current_tenant()` on top of the RLS policy (two layers, as Hibernate's `@TenantId` filter
  plus RLS in Java).
- **Kafka**: `twmb/franz-go` (pure Go, SASL/SCRAM-SHA-256, manual commits after processing).
- **Event schemas**: `santhosh-tekuri/jsonschema/v6` (JSON Schema 2020-12, formats asserted) on embedded copies of
  `libs/contracts/events/core.*.schema.json`; a test fails when a copy differs from the contract.
- **JWT**: `golang-jwt/jwt/v5`, RS256 only, keys from the realm's JWKS (read on first use, again for an unknown key id at
  most every 30 s), issuer from discovery unless `OIDC_ISSUER`, audience `finance-service`, `exp` and `sub` required; the
  realm unreachable is 503 `AUTH_UNAVAILABLE`, never a 401.
- **OpenAPI in tests**: `getkin/kin-openapi` (`openapi3filter`) validates every request the tests expect to be accepted
  and every answer against `finance.yaml` (the counterpart of `OpenApiValidationFilter`). The service has no generated
  server code: handlers and DTOs are written by hand, strict JSON (`DisallowUnknownFields`) stands for the contract's
  `additionalProperties: false`, and the Java contract suites (`OpenApiSpecs.SERVICES`, strict validator, clear lists,
  the generator's validation) cover `finance.yaml` like the three other contracts.
- **Telemetry**: OpenTelemetry Go SDK, OTLP over HTTP/protobuf (4318, as pdf-service), traces and logs (`otelslog`
  bridge), parent-based ratio sampling; `log/slog` JSON lines on stdout always.
- **Tests**: `testcontainers-go` (Postgres 17 with `infra/db/init`, Redpanda at the chart's pin).

### Migrations
A small runner in `internal/adapters/out/persistence` (`Migrate`), not a library: files `db/migration/V<n>__<snake_case>.sql`
(Flyway's names, so the convention of the Java services holds; no other Go tool reads them), compiled into the binary,
applied at start as `finance_migrator`, each in its own transaction with its history row in `finance.schema_history`
(version, description, CRC32 checksum), under `pg_advisory_lock` so two replicas take turns. A changed applied file or a
history version without a file stops the start. `finance_app` has no grant on the history. Numbers: V1-V9 WP118,
V10-V19 WP119, V20-V29 WP123. goose and golang-migrate were not chosen: their file names differ and the runner is
70 lines with tests.

### Tenancy (rule 2) and authz (rule 3)
- Roles `finance_migrator` (owner of schema `finance`) and `finance_app` (non-owner, `NOBYPASSRLS`, DML by default
  privileges) in `infra/db/init/01_roles_schemas.sql` (and the chart copy; CNPG managed roles). `02_passwords.sh` sets their
  passwords only when given, so test resources and `.env` files from before finance keep working.
- **Tenant per transaction** (ADR-0011): `Transactions.InTenant` runs `set_config('app.tenant_id', <id>, true)` first in
  every transaction; stores take the transaction from the context and refuse to work without one; the nil UUID is never a
  tenant (`domain.TenantID`).
- **Harness** (`internal/testsupport/rls`, run by `internal/adapters/out/persistence/rls_test.go` as `finance_app`, never
  owner or superuser): the schema inspection (every table with `tenant_id` has it `uuid not null`, RLS enabled and forced,
  every permissive policy restricting reads and writes to `app.current_tenant()`; tables without it listed with a reason:
  `schema_history`, `parked_event`, `replica_tenant`); the generic isolation suite per tenant table (fixtures as the migrator
  bound to fresh tenants A and B, parents of foreign keys inserted first; as the app bound to A: no foreign rows, update /
  delete of B's rows touch 0, moving a row to B and inserting for B fail with 42501, an unbound read fails with 42501); the
  database role check (`finance_app` as the service ships it: not superuser, not BYPASSRLS, no CREATE on the database or a
  schema, not owner or member of an owner). Each is proven to fail on planted violations (tables without RLS, not forced,
  with an open policy, a nullable tenant, an undeclared global table; a leaking policy; the owner and the superuser).
- **Layering** (`internal/archtest`, the ArchUnit counterpart): `internal/domain` imports only a list of standard packages,
  `internal/application` adds `context` and the domain, nothing but tests (and the test support) imports
  `internal/testsupport`; proven on planted files.
- **Hooks**: `just isolation-check` runs core's `CrossTenantAccessTest` and then the Go `TestCrossTenant*` tests (through the
  API with tokens of a test realm key, and through the service's own pool); `just db-role-check` adds the Go role tests;
  `run_go_tests` fails when the `-run` filter matches nothing. The Go API part uses a test realm, not a real Keycloak: the
  real login is core's part of the same hook.
- **Membership**: from the service's replica of `core.tenant` and `core.person` (ADR-0037 rules, built in this WP because the
  tenant filter needs it): an active person with the token's `sub` in an ACTIVE academy, no REST call into core. Non-members
  get 404 (`not_member`), members without the role 403 (`role`), from the use cases (authz in the application layer).
- **Audit** (ADR-0017 without common-quarkus): `finance.audit_event`, the same columns and append-only trigger as
  `core.audit_event`, written by the use cases through the `AuditLog` port in the change's transaction and logged on
  `hoops.audit`; metadata holds ids, enum values and changed field names only (P-12).
- **Security events** (ADR-0043): the fields, message and `hoops_authz_denied_total{kind}` of `SecurityEventLog`, every
  kind at 0 from the start; never a token or a request value.

### Gates (`just test-go` = `services/finance-service/scripts/check.sh`, also the end of `just test` and CI job `go`)
| Java gate | Go counterpart |
|---|---|
| compiler, formatter | `gofmt -l` (no file may need a change), `go mod tidy -diff`, `go mod verify` |
| SpotBugs, PMD / CPD (ADR-0053) | `golangci-lint` v2 with `.golangci.yml`: complexity (cyclop 12, gocognit 20, nestif, funlen), duplication (dupl 100), unused code, error handling (errcheck, errorlint, wrapcheck, nilerr), gosec, rows/sql close checks, revive, gocritic |
| JaCoCo 80 % / 90 % domain | `go test -coverpkg=./...` + `scripts/coverage_gate.py` (statements; `cmd/` and the test support out) |
| ArchUnit | `internal/archtest` |
| `RlsSchemaMetaTest`, `GenericRlsIsolationTest`, `DatabaseRoleMetaTest` | `internal/testsupport/rls` |
| dependency-check | `go tool govulncheck` (reachable code; a tool dependency pinned by go.sum) and Trivy on the image |
| CodeQL java, Semgrep p/java | CodeQL `go` (manual build), Semgrep `p/golang` |
| PIT (mutation) | not yet: see below |

- **Pins**: `go 1.27.0` with `toolchain go1.27.4` in go.mod (GOTOOLCHAIN=auto fetches it on an older local Go; the image
  and CI use exactly it), `go.sum` committed, golangci-lint 2.15.0 (Homebrew locally, a SHA-256-checked archive in CI),
  govulncheck v1.9.0 as a `tool` line. Bootstrap installs `go` and `golangci-lint`; `just doctor` checks the pinned Go and
  golangci-lint v2. Dependabot `gomod` weekly with the 7-day cooldown.
- **Mutation testing**: not in this WP. The rule code (`internal/domain`) is at 97.9 % statement coverage with focused tests;
  the candidate is `go-gremlins/gremlins` behind a `just mutation-go` recipe with a baseline like `docs/quality/mutation.md`,
  as for Rust (`cargo-mutants`). Recorded as a follow-up, not a gate.

### Delivery
- **Image** `deploy/containers/finance.Containerfile`: `golang:1.27.4-trixie` builder, `CGO_ENABLED=0`, `-trimpath`,
  no VCS stamp; runtime `gcr.io/distroless/static-debian13:nonroot`; both by index digest. User 65532, read-only root file
  system, 28.7 MB; Go embeds the module list, so Trivy scans and lists the modules (SBOM). `images.yml` job `finance` starts
  it read-only against a throwaway Postgres before the Trivy gate.
- **Compose**: profile `finance` on 127.0.0.1:8085 (`just finance-up`, which first creates the roles on an existing database
  with `infra/compose/finance-db.sh`), nginx `/api/finance/` with the export brake on `dues:export` / `expenses:export`.
- **Chart 0.12.0**: sub-chart `finance-service` 0.1.0 (alias `finance`, off by default, on in kind and cloud): HTTPRoutes for
  `/api/finance` and its health, the two exports rate-limited (10/min, 2/s per IP, P-12); NetworkPolicy in only from the
  Envoy proxies, out only to DNS, Postgres, Keycloak, Redpanda (with events) and the collector; the broker user
  `finance-service` (read `core.*`, groups `finance-service.*`) with its Secret and ESO entry, used by the consumer of WP118
  and WP119; Tilt resource `finance-service` (port 18085, `--no-finance`).
- **Realm**: bearer-only client `finance-service`; audience mapper `finance-service` on `web` (the browser calls finance
  through the gateway). finance-service calls no other service, so it has no service account and no secret.

## Alternatives rejected
- **A Go web framework (gin, echo, chi)**: the standard mux covers the routes; one dependency less to audit.
- **sqlc / an ORM**: generated code adds a tool to the chain for a dozen statements; hand-written SQL stays constant.
- **oapi-codegen server stubs**: the strict validation and Problem shapes would be fought rather than used; the contract is
  enforced by the tests and the Java contract suites instead.
- **Membership through core's `/internal/authz`** (game's and athlete's `rest` mode): needs a confidential client, a
  secret and a synchronous dependency; ADR-0051 §2 asks for the replica.
- **Reusing the `hoops-service` sub-chart**: its environment is Quarkus-specific (`QUARKUS_*`) and its NetworkPolicy has no
  egress; a sub-chart of its own keeps the Go names and closes egress.

## Consequences
- Tenant binding, authz, security events and the Problem shape exist in Java and in Go (and partly in Rust); a change to
  one of them is made in each. The black-box guards stay: the hooks, the contract suites, the chart tests.
- The Go tests start a Postgres (and once a Redpanda) per test binary: `-p 2` in `check.sh` keeps the 2-CPU VM usable.
- `.env` needs `FINANCE_MIGRATOR_PASSWORD`, `FINANCE_APP_PASSWORD` and `REDPANDA_FINANCE_SERVICE_PASSWORD` for kind
  (`deploy/kind/env-keys.sh` requires them) and `just finance-up`.
