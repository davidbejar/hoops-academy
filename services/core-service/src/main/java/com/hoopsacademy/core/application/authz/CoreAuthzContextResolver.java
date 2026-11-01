package com.hoopsacademy.core.application.authz;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.AuthzContextResolver;
import com.hoopsacademy.common.tenancy.TenantId;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Optional;

/**
 * core's implementation of the tenant filter port: reads memberships from its own tables. A SUSPENDED or WITHDRAWN
 * tenant answers "not a member", so every {@code /api/**} call of its users gets 404.
 */
@ApplicationScoped
public class CoreAuthzContextResolver implements AuthzContextResolver {

    private final MembershipLookup lookup;
    private final AuthzCache cache;

    public CoreAuthzContextResolver(MembershipLookup lookup, AuthzCache cache) {
        this.lookup = lookup;
        this.cache = cache;
    }

    @Override
    public Optional<AuthzContext> resolve(String subject, TenantId tenantId) {
        return cache.get(subject, tenantId, () -> lookup.find(subject))
                .filter(MemberAuthz::tenantActive)
                .map(MemberAuthz::context);
    }
}
