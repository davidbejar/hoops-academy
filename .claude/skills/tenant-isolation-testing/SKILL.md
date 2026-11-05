---
name: tenant-isolation-testing
description: How tenant isolation is tested in Hoops Academy and how to extend the generic RLS/authz suites when adding tables or endpoints. Use when adding a table, a repository, an endpoint or when a RlsSchemaMetaTest/GenericRlsIsolationTest fails.
---

# Tenant isolation testing

Three layers, all mandatory for every service:

## 1. Schema meta-test (`RlsSchemaMetaTest` base class, common-quarkus test-jar)
Queries `pg_tables` / `pg_policies` for the service schema and asserts for every table:
- has `tenant_id` ⇒ `rowsecurity = true`, `forcerowsecurity = true`, ≥ 1 policy whose expression references
  `app.current_tenant()`;
- has no `tenant_id` ⇒ listed in `globalTables()` with a one-line justification.
Failing here means a migration forgot `select app.enable_tenant_rls('schema.table');`.

**Shared global + tenant tables** (templates, norms: global rows with a NULL owner next to tenant rows) are declared
in `nullableTenantTables()` as `"schema.table" -> owner column` (`tenant_id` nullable, or e.g. `owner_tenant_id`).
The inspector then requires: uuid owner column (nullable allowed), RLS enabled + FORCEd, a policy on
`app.current_tenant()` and **one policy per command** — select (`owner is null or owner = current`), insert / update /
delete (`owner = current`). Never a single `FOR ALL` policy: USING and WITH CHECK differ, and DELETE only evaluates
USING, so a FOR ALL policy that admits global rows lets a tenant delete them (WP9 lesson). `app.enable_tenant_rls` is
for `tenant_id not null` tables only; write the four policies by hand. Declare the same map in the service's
`GenericRlsIsolationTest` subclass (those tables are skipped there) and give them a dedicated isolation test (tenant A
reads global + own rows, cannot insert/update/delete global or B's rows, cannot make a row global or hand it over).

## 2. Generic data-driven isolation (`GenericRlsIsolationTest`)
For every tenant table: as migrator insert one row for tenant A and one for B (column values from
`information_schema` + per-table `fixtureOverrides()` for NOT NULL/FK columns); then as the app role with
`app.tenant_id = A` assert: `select count(*) = 1`; `update … where id = B.id` → 0 rows; `delete` → 0 rows;
`insert` with `tenant_id = B` → SQLSTATE 42501; with the variable unset any select raises (function raises).
If a table needs special fixtures, override `fixtureOverrides()` in the service's subclass — never exclude it
(the only exception are the declared `nullableTenantTables()`, which have their own isolation test).

## 3. API-level tests (per resource)
- `@TenantUser(tenant = A, roles = {COACH})` creates a resource; `@TenantUser(tenant = B)` GET by id → **404**;
  B sending `X-Tenant-Id: A` while not a member → 404; missing header → 400.
- Role matrix: `@ParameterizedTest` over all roles and the unions `ADMIN+COACH`, `COACH+PARENT`; expected
  statuses come from `docs/domain/authz-matrix.md`.
- `super_admin` without membership calling `/api/**` → 404; `/platform/**` without `super_admin` → 403.

## 4. Database role + end-to-end check (Claude Code hook on git commit / git push)
- **`DatabaseRoleMetaTest`** (test-jar, `@Tag("db-role")`; subclasses `Core/Game/AthleteDatabaseRoleTest`): every
  datasource user the service SHIPS with (`ShippedDatasources`: `src/main/resources/application.properties`, prod
  profile, no env) is `<svc>_app`, differs from the Flyway user, and passes `DatabaseRoleCheck` (not a superuser or
  BYPASSRLS, not owner of or member of the owner of any table, no CREATE on any schema). A new service or a new
  named datasource needs a subclass and nothing else. Runs before Claude's `git push`: `just db-role-check`.
- Why not just `select current_user` in a `@QuarkusTest`: `PostgresRlsResource` forces the user to `<svc>_app` at
  test time, and Quarkus exposes that as a generated `startup-override/application.properties` on the classpath.
  Read the source file, never `application.properties` from the classpath (that masked a wrong default once).
- **`CrossTenantAccessTest`** (core, `@Tag("keycloak")`, `RealLoginProfile`): academy A's admin logs in through a
  real Keycloak (password grant), and the real resolver maps the token. Through the API, B's records give 404 via the
  header and via ids, and A's lists never contain B's people. Under the API, in the app's own pool bound to A, B's
  rows are invisible and an unbound select raises 42501. A sanity test proves the login works. Runs before
  Claude's `git commit`: `just isolation-check`. Proven to fail when the app role gets BYPASSRLS; the API part stays 404 there (Hibernate
  `@TenantId` filter), which is the point of two layers.
- `.claude/hooks/tenancy-gate.sh` (PreToolUse on Bash) detects the git subcommand and blocks it (exit 2) when a
  check fails. The checks fail (never skip) when Podman is down, and fail when the `-Dtest` filter matches no tests.

## Scheduled jobs on several replicas
Jobs that iterate tenants run under `tenantScope.runExclusive("<svc>.<job>", work)` (Postgres
`pg_try_advisory_xact_lock`; another replica skips). The work runs outside the lock transaction, so each tenant still
gets its own `runAs` transaction. Test it by holding `pg_advisory_lock(TenantScope.advisoryKey(LOCK))` on a second
app-role connection: the job must skip, and run once the lock is released. Release it with `pg_advisory_unlock(...)` on
that connection before asserting the second run; closing the connection frees the lock only when the backend has exited,
which can lag (this made three job tests flaky until WP20).

## Test connection rules
- Tests connect as `<svc>_app` (non-owner). The Testcontainers resource in common-quarkus starts Postgres with
  `infra/db/init/01_roles_schemas.sql` and runs Flyway as `<svc>_migrator`.
- Never set `quarkus.hibernate-orm.database.generation` to anything but `none`/`validate`.
- If a test "needs" superuser to pass, the production code is wrong, not the test.
