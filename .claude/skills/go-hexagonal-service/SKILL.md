---
name: go-hexagonal-service
description: "How to change the Go finance-service of Hoops Academy (services/finance-service): the layering, contract-first changes to finance.yaml, a use case, a store, a migration, the tenant-isolation harness, the replica consumer, the gates of just test-go, and the image, compose, chart and kind wiring. Use whenever changing anything under services/finance-service, finance.yaml, finance.Containerfile or the chart's finance-service sub-chart."
---

# Working on finance-service (Go)

Read first: ADR-0051 (why Go), ADR-0055 (stack, harness, gates, delivery), ADR-0056 (the finance model), the Finance
section of `docs/domain/authz-matrix.md`, `libs/contracts/openapi/finance.yaml`. The service behaves like the Quarkus
services (`.claude/skills/quarkus-hexagonal-service`, `.claude/skills/tenant-isolation-testing`); only the tools differ.

## Toolchain and gates
- Go is pinned by go.mod's `toolchain` line (Homebrew `go`; GOTOOLCHAIN=auto fetches the pin). `source scripts/env.sh`
  first: the tests start Postgres (and Redpanda) through Testcontainers on Podman.
- `just test-go` (also the end of `just test`, CI job `go`) = `scripts/check.sh`: gofmt, `go mod tidy -diff` / verify,
  golangci-lint (`.golangci.yml`; no `//nolint` without a reason), `go test -coverpkg=./...`, coverage gate (>= 80 %
  statements module, >= 90 % `internal/domain`; `cmd/` and test support outside), `go tool govulncheck` (`--offline` skips).
- Inner loop: `go test ./internal/domain/` (no container), `go test ./internal/adapters/in/rest/ -run Name`.
- A new module: `go get mod@vX.Y.Z`, `go mod tidy`, and check the image with Trivy (`scripts/build-images.sh finance-service`,
  then `trivy image --input <saved tar> --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1`).

## Layering (checked by internal/archtest; a planted file proves the check)
```
internal/domain          rules: ids (TenantID never nil), Currency / Amount, Cadence / Period, FeePlan, Membership and
                         the finance access rules (CanManageFinance, CanReadTeamStatus, CanReadPlayerDues), *Error kinds.
                         Standard packages of the allow-list only.
internal/application     use cases (Finance, Replica) and ports (Transactions, stores, AuditLog, MembershipSource, Clock,
                         IDs). Authorises first (403 code ROLE), one InTenant transaction per call. Domain + context only.
internal/adapters/in/rest     net/http routes of finance.yaml, auth + tenant filter, Problem+JSON, strict JSON, health
internal/adapters/in/oidc     token verification against the realm (audience finance-service)
internal/adapters/in/events   core topics -> replica (schemas embedded, parked records, manual commits)
internal/adapters/out/persistence  pgx stores, Transactions (set_config per transaction), the migration runner
internal/platform        config, ids (UUIDv7), security events + metric, telemetry (OTLP)
internal/testsupport     pgtest (Postgres with infra/db/init), rls (the harness), realm (test realm), contract (validator)
cmd/finance-service      wiring only
```

## Contract first (an endpoint)
1. `libs/contracts/openapi/finance.yaml`: 1.0.0 is the whole service; a change is additive (minor bump), names as in
   `common.yaml`, `additionalProperties: false` on requests, a `clear` list on `Update*Request` (ADR-0032), no `allOf` but
   single-ref wrappers. `./mvnw -pl libs/contracts verify` (the Java suites check finance.yaml too), then
   `scripts/gen-api.sh finance` and commit `apps/web/packages/finance` (and `apps/web/pubspec.lock` with the version bump).
2. Red: a test in `internal/adapters/in/rest/*_test.go` through `api.do` (real router, use cases, Postgres as finance_app,
   test realm): it validates every answer, and every accepted request, against finance.yaml. Add the role-matrix rows of
   `docs/domain/authz-matrix.md` (members without the role 403 with a security event, non-members 404) and a cross-tenant
   case. Red: the use case test with the fakes of `internal/application/fakes_test.go`.
3. Green: domain -> use case (authorise, `InTenant`, audit with field names only) -> store -> handler. Replace the route's
   entry in `rest/later.go` (the 501 list) and shorten `NotImplemented` in `feeplans_test.go`.

## Persistence and migrations
- `db/migration/V<n>__<snake_case>.sql`, one concern per file: V1-V9 WP118, V10-V19 WP119, V20-V29 WP123. Never edit an
  applied file (the runner refuses a changed checksum). Tenant tables: `tenant_id uuid not null`, primary key
  `(tenant_id, id)`, foreign keys including `tenant_id`, `select app.enable_tenant_rls('finance.<table>');`. A table
  without tenant_id needs a reason in `globalTables` of `persistence/rls_test.go` and revoked grants.
- Check constraints the catalogue cannot guess go into `fixtureOverrides` (never exclude a table from the suite).
- Stores take the transaction from the context (`txOf`), constant SQL with bound parameters, `tenant_id =
  app.current_tenant()` in every statement, optimistic locking with `version`.

## Tenancy, security, privacy (do not weaken)
- Never bind the nil UUID; never query outside `Transactions.InTenant`; tests never connect as owner or superuser.
- `just isolation-check` runs the Go `TestCrossTenant*` tests, `just db-role-check` the Go role tests: keep those names.
- Problems name the field and a code, never a value (P-11); reasons and notes (<= 200) never reach logs, spans, audit
  metadata or exports, and families never see them (P-12); the replica keeps no birth date or gender (P-10).
- Security events through `security.Events.Deny` (kinds of common-quarkus); every 401/403/404 of the filter writes one.

## Replica consumer (ADR-0037)
`internal/adapters/in/events`: add a topic to `Topics`, copy its schema from `libs/contracts/events` into `schemas/` (the
drift test compares them), decode only what the replica keeps, apply through `application.Replica` (idempotent per event
id, `occurred_at` guard, soft removals) and a store in `persistence/replica.go`. The broker user `finance-service` may read
`core.*` and use groups `finance-service.*` (chart `events.users`).

## Image, compose, chart, kind
- `deploy/containers/finance.Containerfile` (context `services/finance-service`): bump the golang tag + index digest with
  go.mod's toolchain line, and the distroless static digest. `images.yml` job `finance`.
- Compose: `just finance-up` (profile `finance`, :8085; roles on an existing database by `infra/compose/finance-db.sh`);
  nginx routes `/api/finance/`. On the host: `go run ./cmd/finance-service` with `FINANCE_*_PASSWORD` exported.
- Chart: sub-chart `charts/finance-service` (alias `finance`): routes, rate-limited exports, NetworkPolicy (in: gateway;
  out: DNS, Postgres, Keycloak, Redpanda, collector). `deploy/helm/tests/run.sh` (`--update` re-records snapshots).
- kind: `deploy/kind/up.sh --deploy --from-host` or `tilt up` (resource `finance-service`, port 18085, `--no-finance`).
