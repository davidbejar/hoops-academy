package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.domain.membership.PersonId;
import java.util.List;

/**
 * Cross-tenant membership index ({@code core.user_membership_index}): which tenants a login belongs to.
 * {@link #register}/{@link #unregister} run in the bound tenant's transaction; {@link #ofSubject} reads across
 * tenants but only the caller's own rows (subject-scoped RLS policy).
 */
public interface MembershipRepository {

    record IndexedMembership(TenantId tenant, PersonId person) {}

    void register(String subject, PersonId person);

    void unregister(PersonId person);

    List<IndexedMembership> ofSubject(String subject);

    /**
     * Whether {@code subject} is linked to an active person of a tenant other than the bound one (the
     * {@code LOGIN_SHARED} rule, ADR-0023). Runs inside the bound tenant's transaction and reveals only this boolean,
     * never which tenants.
     */
    boolean linkedInAnotherTenant(String subject);

    /**
     * The active persons of tenants other than the bound one that {@code subject} is linked to, for the super admin's
     * login e-mail move ({@link SharedLoginPersons}, ADR-0026). Runs inside the bound tenant's transaction; the ids
     * stay inside core and are never returned to a caller.
     */
    List<IndexedMembership> inOtherTenants(String subject);
}
