# ADR-0006: Shared schema multitenancy with Postgres Row-Level Security

- Status: Accepted
- Date: 2026-11-01

## Context
Academies must never see each other's data. Options: database per tenant (operational burden), schema per tenant (migration fan-out), shared schema with discriminator column.

## Decision
Shared schema with `tenant_id` on every tenant table, Hibernate discriminator multitenancy (`@TenantId`) plus Postgres RLS policies on `app.current_tenant()`, which raises if the transaction-local setting is missing. Application DB roles are non-owners without BYPASSRLS; Flyway runs as a separate migrator role. A shared test-jar provides schema meta-tests and generic isolation tests for every service.

## Consequences
Two independent isolation layers; forgetting the tenant is a loud failure. Requires discipline about transaction boundaries (interceptor sets the variable) and non-superuser test connections.

## Amendment (WP139, 2026-11-24): the roles come from one list
The service roles are the rows between `-- roles: begin` and `-- roles: end` of `infra/db/init/01_roles_schemas.sql`
(role, schemas of its search path, connection limit, migrator or not). One `do` block derives from them what was five
hand-written lists and nine `alter role ... search_path` lines: attributes, connection limit, `connect` on the database,
`usage` on schema `app`, `execute` on `app.enable_tenant_rls` for migrators, the search path; it marks each role with the
comment `hoops service role`. `02_passwords.sh` sets the password of every marked role from `<ROLE>_PASSWORD` (each
required); `infra/db/roles.sh` prints the list for scripts and workflows; the Java (`BootstrapRoles`) and Go (`pgtest`)
test harnesses read it from the SQL. The lists that must stay literal (compose, `.env.example`, the chart's CNPG roles
and Secrets, kind) are checked against it by `scripts/tests/test_db_roles.py`. A fresh database has the same roles,
privileges, default privileges and role settings as before (compared in two throwaway PostgreSQL containers).
