package com.hoopsacademy.common.client;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.AuthzContextResolver;
import com.hoopsacademy.common.tenancy.TenantId;
import io.quarkus.arc.DefaultBean;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Optional;

/**
 * The tenant-filter port for services that do not own memberships (game, athlete): asks core through
 * {@link CoreRosterClient}. Only members of an ACTIVE tenant resolve; SUSPENDED/WITHDRAWN tenants and non-members get
 * 404 from the filter. A {@link DefaultBean}: core provides its own database-backed resolver, and tests replace it
 * with the test-jar's {@code TestAuthzContextResolver} alternative.
 */
@ApplicationScoped
@DefaultBean
public class RosterAuthzResolver implements AuthzContextResolver {

    private final CoreRosterClient core;

    public RosterAuthzResolver(CoreRosterClient core) {
        this.core = core;
    }

    @Override
    public Optional<AuthzContext> resolve(String subject, TenantId tenantId) {
        return core.membership(tenantId, subject).filter(CoreMembership::tenantActive).map(CoreMembership::context);
    }
}
