# ADR-0006: Shared schema multitenancy with Postgres Row-Level Security

- Status: Accepted
- Date: 2026-11-01

## Context
Academies must never see each other's data. Options: database per tenant (operational burden), schema per tenant (migration fan-out), shared schema with discriminator column.

## Decision
Shared schema with `tenant_id` on every tenant table, Hibernate discriminator multitenancy (`@TenantId`) plus Postgres RLS policies on `app.current_tenant()`, which raises if the transaction-local setting is missing. Application DB roles are non-owners without BYPASSRLS; Flyway runs as a separate migrator role. A shared test-jar provides schema meta-tests and generic isolation tests for every service.

## Consequences
Two independent isolation layers; forgetting the tenant is a loud failure. Requires discipline about transaction boundaries (interceptor sets the variable) and non-superuser test connections.
