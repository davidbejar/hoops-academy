package com.hoopsacademy.common.testing;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Memberships known to {@link TestAuthzContextResolver}. Populated by {@link TenantUser} before each test and
 * cleared after it; tests may also {@link #register} extra memberships (e.g. a user in two tenants).
 */
public final class TenantUserRegistry {

    private record Key(String subject, TenantId tenantId) {}

    private static final Map<Key, AuthzContext> MEMBERSHIPS = new ConcurrentHashMap<>();

    private TenantUserRegistry() {}

    public static void register(AuthzContext membership) {
        MEMBERSHIPS.put(new Key(membership.subject(), membership.tenantId()), membership);
    }

    public static Optional<AuthzContext> find(String subject, TenantId tenantId) {
        return Optional.ofNullable(MEMBERSHIPS.get(new Key(subject, tenantId)));
    }

    public static void clear() {
        MEMBERSHIPS.clear();
    }
}
