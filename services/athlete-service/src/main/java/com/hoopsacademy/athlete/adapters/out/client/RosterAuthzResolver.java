package com.hoopsacademy.athlete.adapters.out.client;

import com.hoopsacademy.athlete.application.MemberContext;
import com.hoopsacademy.athlete.application.RosterPort;
import com.hoopsacademy.athlete.application.TenantStatus;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.AuthzContextResolver;
import com.hoopsacademy.common.tenancy.TenantId;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Optional;

/**
 * Resolves the caller's {@link AuthzContext} through the {@link RosterPort} (core's {@code /internal/authz}). Only
 * members of an ACTIVE tenant resolve: a suspended or withdrawn tenant looks like a non-member (404).
 */
@ApplicationScoped
public class RosterAuthzResolver implements AuthzContextResolver {

    private final RosterPort roster;

    RosterAuthzResolver(RosterPort roster) {
        this.roster = roster;
    }

    @Override
    public Optional<AuthzContext> resolve(String subject, TenantId tenantId) {
        return roster.authzContext(tenantId, subject)
                .filter(member -> member.tenantStatus() == TenantStatus.ACTIVE)
                .map(MemberContext::authz);
    }
}
