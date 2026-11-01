package com.hoopsacademy.game.application;

import com.hoopsacademy.common.tenancy.TenantRole;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/** A member's authorization in a tenant as core reports it, including the tenant's lifecycle status. */
public record MemberAccess(
        String subject,
        UUID personId,
        TenantStatus tenantStatus,
        Set<TenantRole> roles,
        Set<UUID> staffTeamIds,
        Set<UUID> linkedPlayerIds,
        Optional<UUID> ownPlayerId) {

    public enum TenantStatus {
        ACTIVE,
        SUSPENDED,
        WITHDRAWN
    }

    /** Suspended or withdrawn tenants have no usable membership (the caller gets 404). */
    public boolean tenantUsable() {
        return tenantStatus == TenantStatus.ACTIVE;
    }
}
