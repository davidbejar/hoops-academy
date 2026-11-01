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

## 2. Generic data-driven isolation (`GenericRlsIsolationTest`)
For every tenant table: as migrator insert one row for tenant A and one for B (column values from
`information_schema` + per-table `fixtureOverrides()` for NOT NULL/FK columns); then as the app role with
`app.tenant_id = A` assert: `select count(*) = 1`; `update … where id = B.id` → 0 rows; `delete` → 0 rows;
`insert` with `tenant_id = B` → SQLSTATE 42501; with the variable unset any select raises (function raises).
If a table needs special fixtures, override `fixtureOverrides()` in the service's subclass — never exclude it.

## 3. API-level tests (per resource)
- `@TenantUser(tenant = A, roles = {COACH})` creates a resource; `@TenantUser(tenant = B)` GET by id → **404**;
  B sending `X-Tenant-Id: A` while not a member → 404; missing header → 400.
- Role matrix: `@ParameterizedTest` over all roles and the unions `ADMIN+COACH`, `COACH+PARENT`; expected
  statuses come from `docs/domain/authz-matrix.md`.
- `super_admin` without membership calling `/api/**` → 404; `/platform/**` without `super_admin` → 403.

## Test connection rules
- Tests connect as `<svc>_app` (non-owner). The Testcontainers resource in common-quarkus starts Postgres with
  `infra/db/init/01_roles_schemas.sql` and runs Flyway as `<svc>_migrator`.
- Never set `quarkus.hibernate-orm.database.generation` to anything but `none`/`validate`.
- If a test "needs" superuser to pass, the production code is wrong, not the test.
