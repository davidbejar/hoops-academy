# ADR-0011: Binding the tenant to transactions and to Hibernate

- Status: Accepted
- Date: 2026-11-01

## Context
ADR-0006 requires `app.tenant_id` to be set transaction-locally on every connection used for tenant data, and
Hibernate discriminator multitenancy (`@TenantId`) as a second layer. Two implementation constraints showed up in
WP2a:
1. `jakarta.transaction.Transactional.value()` (`TxType`) is a *binding* member, so one interceptor bound to
   `@Transactional` only matches one `TxType`. Programmatic `QuarkusTransaction` bypasses interceptors entirely.
2. Quarkus registers its own `CurrentTenantIdentifierResolver<String>` directly on the session factory; Hibernate
   types the tenant filter parameter after the entity field and rejects a `String` for a `UUID` field
   ("Argument assigned to filter parameter 'tenantId' is not of type 'java.util.UUID'"). Quarkus offers no hook to
   supply a non-String tenant identifier.

## Decision
- `common-quarkus` ships one small interceptor per `TxType` that can carry a transaction (REQUIRED, REQUIRES_NEW,
  MANDATORY, SUPPORTS) at priority `PLATFORM_BEFORE + 210`, i.e. just inside Narayana (200). It runs
  `select set_config('app.tenant_id', ?, true)` on the transaction's Agroal connection (the same one Hibernate uses)
  when a tenant is bound; a `TransactionSynchronizationRegistry` marker avoids repeating it for joined transactions.
  `REQUIRES_NEW` gets its own connection and its own `set_config`. `is_local = true` means nothing survives commit or
  rollback, so pooled connections never carry a tenant.
- Jobs use `TenantScope.runAs(tenant, work)` (own `QuarkusTransaction.requiringNew()`, binds and restores the
  context). Code that uses `QuarkusTransaction` directly for tenant data must call
  `TenantTransactions.bindCurrentTransaction()` first — preferably it uses `TenantScope`.
- Entities declare the discriminator as `@TenantId String tenantId` over a `uuid` column, and the datasource sends
  string parameters untyped (`stringtype=unspecified`) so Postgres infers `uuid`. The library contributes
  `quarkus.hibernate-orm.multitenant=DISCRIMINATOR`, `stringtype=unspecified` and `hoops.tenancy.header` as
  defaults in `META-INF/microprofile-config.properties` (ordinal 100; a service may override).

## Rejected alternatives
- Agroal `AgroalPoolInterceptor.onConnectionAcquire`: runs before/outside the JTA transaction, which forces a
  session-level setting that must be reset on return — a leak risk ADR-0006 forbids.
- Hibernate `StatementInspector`: can rewrite SQL but cannot execute statements on the connection.
- A custom `CurrentTenantIdentifierResolver<UUID>`: overwritten by Quarkus at boot.
- `UUID` entity field with a lenient custom `JavaType` for `UUID`: depends on Hibernate internals, global effect.

## Consequences
Domain/value code keeps `TenantId(UUID)`; only persistence entities hold the tenant as a String (read-only, filled
by Hibernate). With `stringtype=unspecified`, a native query whose string parameter has no type context (e.g.
`select ?`) may need an explicit cast. If Quarkus adds typed tenant identifiers, entities can switch to `UUID` and
the JDBC property can be dropped.
