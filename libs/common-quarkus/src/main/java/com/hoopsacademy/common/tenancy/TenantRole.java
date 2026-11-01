package com.hoopsacademy.common.tenancy;

/** Per-tenant roles (stored in {@code core.membership_role}); roles are additive. */
public enum TenantRole {
    ADMIN,
    COACH,
    ASSISTANT_COACH,
    PARENT,
    PLAYER;

    boolean isTeamStaffRole() {
        return this == COACH || this == ASSISTANT_COACH;
    }
}
