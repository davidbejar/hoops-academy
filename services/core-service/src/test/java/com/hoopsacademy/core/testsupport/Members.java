package com.hoopsacademy.core.testsupport;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.common.testing.TenantUserCallback;
import com.hoopsacademy.common.testing.TenantUserRegistry;
import java.util.EnumSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Stream;
import org.junit.jupiter.params.provider.Arguments;

/**
 * Signs the {@code @TestSecurity(user = TenantUser.SUBJECT)} caller into a tenant with any role set (for
 * parameterised role-matrix tests, where a fixed {@code @TenantUser} annotation cannot vary the roles).
 */
public final class Members {

    private Members() {}

    /** Replaces the caller's memberships with exactly this one. */
    public static void signIn(String tenant, Set<TenantRole> roles) {
        TenantUserRegistry.clear();
        TenantUserRegistry.register(new AuthzContext(TenantUser.SUBJECT,
                TenantUserCallback.defaultPersonId(TenantId.parse(tenant)), TenantId.parse(tenant),
                roles.isEmpty() ? Set.of() : EnumSet.copyOf(roles), Set.of(), Set.of(), Optional.empty()));
    }

    public static void signIn(String tenant, TenantRole... roles) {
        signIn(tenant, roles.length == 0 ? Set.of() : EnumSet.copyOf(List.of(roles)));
    }

    /** A fresh ACTIVE tenant id. */
    public static String newTenant() {
        String id = UUID.randomUUID().toString();
        CoreDb.tenant(id);
        return id;
    }

    /**
     * The role sets of the authz matrix (each role alone plus the unions ADMIN+COACH and COACH+PARENT) and whether
     * the set contains ADMIN — the only role that may write tenant profile, logo, members and guardian links.
     */
    public static Stream<Arguments> roleSetsWithAdminFlag() {
        return Stream.of(
                Arguments.of(EnumSet.of(TenantRole.ADMIN), true),
                Arguments.of(EnumSet.of(TenantRole.COACH), false),
                Arguments.of(EnumSet.of(TenantRole.ASSISTANT_COACH), false),
                Arguments.of(EnumSet.of(TenantRole.PARENT), false),
                Arguments.of(EnumSet.of(TenantRole.PLAYER), false),
                Arguments.of(EnumSet.of(TenantRole.ADMIN, TenantRole.COACH), true),
                Arguments.of(EnumSet.of(TenantRole.COACH, TenantRole.PARENT), false));
    }
}
