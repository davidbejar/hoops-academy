package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.domain.membership.PersonId;

/** Appends to the bound tenant's audit trail inside the current tenant transaction (default datasource). */
public interface AuditLog {

    void record(AuditEvent event);

    /**
     * Appends to the bound tenant's trail on behalf of {@code actor}, a person of that tenant, where no
     * {@code AuthzContext} names the caller's person (the first sign-in through {@code /me}, which binds the tenant
     * with {@code TenantScope.runAs}).
     */
    void recordAs(PersonId actor, AuditEvent event);

    /**
     * Appends to {@code tenant}'s trail while {@link SharedLoginPersons} has bound the current transaction to that
     * tenant (RLS rejects any other). The actor keeps its subject but has no person in that tenant.
     */
    void recordFor(TenantId tenant, AuditEvent event);
}
