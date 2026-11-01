package com.hoopsacademy.core.application.authz;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import jakarta.enterprise.context.ApplicationScoped;

/**
 * {@code /internal/authz/{tenantId}/{sub}} for game/athlete: the membership INCLUDING the tenant status, so callers
 * apply the same suspended/withdrawn rule as core (treat non-ACTIVE as non-member).
 */
@ApplicationScoped
public class InternalAuthz {

    private final TenantScope tenantScope;
    private final MembershipLookup lookup;

    public InternalAuthz(TenantScope tenantScope, MembershipLookup lookup) {
        this.tenantScope = tenantScope;
        this.lookup = lookup;
    }

    public MemberAuthz of(TenantId tenant, String subject) {
        return tenantScope.runAs(tenant, () -> lookup.find(subject))
                .orElseThrow(() -> new NotFoundException("No active membership"));
    }
}
