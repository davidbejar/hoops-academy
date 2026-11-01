package com.hoopsacademy.common.tenancy;

import java.util.Optional;

/**
 * Port implemented by each service: core reads its membership tables, game/athlete call core's
 * {@code /internal/authz} (cached). Called by {@link TenantHeaderFilter} with the requested tenant already bound
 * in {@link TenantContext}, so RLS-protected lookups work.
 */
public interface AuthzContextResolver {

    /** @return the caller's context in {@code tenantId}, or empty when they are not a member. */
    Optional<AuthzContext> resolve(String subject, TenantId tenantId);
}
