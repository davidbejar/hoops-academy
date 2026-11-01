package com.hoopsacademy.common.authz;

import com.hoopsacademy.common.problem.AccessDeniedException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.enterprise.context.RequestScoped;
import java.util.List;
import java.util.UUID;

/**
 * Fine-grained, relation-based checks of the current caller (see {@code docs/domain/authz-matrix.md}).
 * Typical use in a resource: {@code authz.require(authz.isAdmin() || authz.isStaffOf(teamId), "Not staff")}.
 */
@RequestScoped
public class Authz {

    private final TenantContext tenantContext;

    public Authz(TenantContext tenantContext) {
        this.tenantContext = tenantContext;
    }

    public boolean hasAnyRole(TenantRole... anyOf) {
        return caller().hasAnyRole(List.of(anyOf));
    }

    public boolean isAdmin() {
        return caller().hasRole(TenantRole.ADMIN);
    }

    public boolean isStaffOf(UUID teamId) {
        return caller().isStaffOf(teamId);
    }

    public boolean isGuardianOf(UUID playerId) {
        return caller().isGuardianOf(playerId);
    }

    public boolean isSelf(UUID playerId) {
        return caller().isSelf(playerId);
    }

    /** @throws AccessDeniedException (→ 403 Problem) with {@code reason} as detail when not {@code allowed} */
    public void require(boolean allowed, String reason) {
        if (!allowed) {
            throw new AccessDeniedException(reason);
        }
    }

    private AuthzContext caller() {
        return tenantContext.authz()
                .orElseThrow(() -> new AccessDeniedException("No tenant membership in the current context"));
    }
}
