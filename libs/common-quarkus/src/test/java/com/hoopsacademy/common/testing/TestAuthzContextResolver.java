package com.hoopsacademy.common.testing;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.AuthzContextResolver;
import com.hoopsacademy.common.tenancy.TenantId;
import jakarta.annotation.Priority;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Alternative;
import java.util.Optional;

/**
 * Test replacement for the service's real resolver, backed by {@link TenantUserRegistry}. It is a prioritized
 * alternative, so it wins over the production bean wherever the test-jar is on the classpath. A test that must
 * exercise the real resolver excludes it: {@code quarkus.arc.exclude-types=com.hoopsacademy.common.testing.TestAuthzContextResolver}.
 */
@Alternative
@Priority(1)
@ApplicationScoped
public class TestAuthzContextResolver implements AuthzContextResolver {

    @Override
    public Optional<AuthzContext> resolve(String subject, TenantId tenantId) {
        return TenantUserRegistry.find(subject, tenantId);
    }
}
