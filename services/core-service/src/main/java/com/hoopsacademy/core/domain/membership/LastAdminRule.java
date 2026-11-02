package com.hoopsacademy.core.domain.membership;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.tenancy.TenantRole;
import java.util.Set;

/** A tenant always keeps at least one active ADMIN. */
public final class LastAdminRule {

    public static final String LAST_ADMIN = "LAST_ADMIN";

    private LastAdminRule() {}

    public static void checkRoleChange(Set<TenantRole> current, Set<TenantRole> next, long activeAdmins) {
        if (current.contains(TenantRole.ADMIN) && !next.contains(TenantRole.ADMIN)) {
            requireAnotherAdmin(activeAdmins);
        }
    }

    public static void checkDeactivation(Set<TenantRole> current, long activeAdmins) {
        if (current.contains(TenantRole.ADMIN)) {
            requireAnotherAdmin(activeAdmins);
        }
    }

    private static void requireAnotherAdmin(long activeAdmins) {
        if (activeAdmins <= 1) {
            throw new ConflictException(
                    "An academy needs at least one active administrator: add another administrator first", LAST_ADMIN);
        }
    }
}
