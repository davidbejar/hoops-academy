package com.hoopsacademy.core.domain.roster;

import com.hoopsacademy.common.tenancy.TenantRole;

/** Role of a person within a team's staff; the person must hold the matching tenant role. */
public enum StaffRole {
    COACH(TenantRole.COACH),
    ASSISTANT_COACH(TenantRole.ASSISTANT_COACH);

    private final TenantRole tenantRole;

    StaffRole(TenantRole tenantRole) {
        this.tenantRole = tenantRole;
    }

    public TenantRole tenantRole() {
        return tenantRole;
    }
}
