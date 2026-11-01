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
}
