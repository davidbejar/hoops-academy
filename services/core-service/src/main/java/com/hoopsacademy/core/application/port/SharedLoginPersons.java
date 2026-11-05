package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.application.port.MembershipRepository.IndexedMembership;
import com.hoopsacademy.core.domain.identity.UserId;

/**
 * The person rows of OTHER tenants that link the same login as a person of the bound tenant, for the super admin's
 * login e-mail move only (WP31, ADR-0026). Each call runs inside the bound tenant's transaction as core_app: it binds
 * {@code app.tenant_id} to the linked person's tenant for its own statements (RLS in force there) and restores the
 * bound tenant before returning, so the writes commit or roll back with the bound tenant's transaction.
 */
public interface SharedLoginPersons {

    /**
     * Whether a person of the linked tenant other than the linked person uses {@code email} (case-insensitive, the
     * per-tenant uniqueness of e-mails).
     *
     * @throws IllegalArgumentException when {@code linked} belongs to the bound tenant
     */
    boolean emailTaken(IndexedMembership linked, String email);

    /**
     * Sets the linked person's e-mail when that person is active and links {@code login}, then appends {@code event}
     * to that tenant's audit trail; false, with nothing written, otherwise.
     *
     * @throws IllegalArgumentException when {@code linked} belongs to the bound tenant
     */
    boolean changeEmail(IndexedMembership linked, UserId login, String email, AuditEvent event);
}
