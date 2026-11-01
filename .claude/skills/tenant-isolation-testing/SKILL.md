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

## Scheduled jobs on several replicas
Jobs that iterate tenants run under `tenantScope.runExclusive("<svc>.<job>", work)` (Postgres
`pg_try_advisory_xact_lock`; another replica skips). The work runs outside the lock transaction, so each tenant still
gets its own `runAs` transaction. Test it by holding `pg_advisory_lock(TenantScope.advisoryKey(LOCK))` on a second
app-role connection: the job must skip, and run once the lock is released.

## Test connection rules
- Tests connect as `<svc>_app` (non-owner). The Testcontainers resource in common-quarkus starts Postgres with
  `infra/db/init/01_roles_schemas.sql` and runs Flyway as `<svc>_migrator`.
- Never set `quarkus.hibernate-orm.database.generation` to anything but `none`/`validate`.
- If a test "needs" superuser to pass, the production code is wrong, not the test.
