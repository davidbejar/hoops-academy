package com.hoopsacademy.game.adapters.out.client;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.AuthzContextResolver;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.game.application.MemberAccess;
import com.hoopsacademy.game.application.RosterPort;
import io.quarkus.arc.Unremovable;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Optional;

/**
 * Resolves the caller's tenant membership through {@link RosterPort#authzContext}. A SUSPENDED or WITHDRAWN tenant
 * yields no membership, so its members get 404 like non-members.
 */
@ApplicationScoped
@Unremovable
public class RosterAuthzResolver implements AuthzContextResolver {

    private final RosterPort rosterPort;

    public RosterAuthzResolver(RosterPort rosterPort) {
        this.rosterPort = rosterPort;
    }

    @Override
    public Optional<AuthzContext> resolve(String subject, TenantId tenantId) {
        return rosterPort.authzContext(tenantId, subject)
                .filter(MemberAccess::tenantUsable)
                .map(access -> new AuthzContext(subject, access.personId(), tenantId, access.roles(),
                        access.staffTeamIds(), access.linkedPlayerIds(), access.ownPlayerId()));
    }
}
