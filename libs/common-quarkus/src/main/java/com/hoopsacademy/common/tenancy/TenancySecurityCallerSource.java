package com.hoopsacademy.common.tenancy;

import com.hoopsacademy.common.security.SecurityCaller;
import com.hoopsacademy.common.security.SecurityCallerSource;
import io.quarkus.arc.Arc;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Set;
import java.util.stream.Collectors;

/** The caller of a security event as {@link TenantHeaderFilter} bound it: tenant, {@code sub} and tenant roles. */
@ApplicationScoped
public class TenancySecurityCallerSource implements SecurityCallerSource {

    private final TenantContext tenantContext;
    private final SecurityIdentity identity;

    public TenancySecurityCallerSource(TenantContext tenantContext, SecurityIdentity identity) {
        this.tenantContext = tenantContext;
        this.identity = identity;
    }

    @Override
    public SecurityCaller current() {
        if (!Arc.container().requestContext().isActive()) {
            return SecurityCaller.UNKNOWN;
        }
        String tenant = tenantContext.tenantId().map(TenantId::toString).orElse(null);
        return tenantContext.authz()
                .map(authz -> new SecurityCaller(tenant, authz.subject(),
                        authz.roles().stream().map(TenantRole::name).collect(Collectors.toSet())))
                .orElseGet(() -> new SecurityCaller(tenant, SecurityCaller.subjectOf(identity), Set.of()));
    }
}
