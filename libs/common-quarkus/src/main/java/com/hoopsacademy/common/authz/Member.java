package com.hoopsacademy.common.authz;

import com.hoopsacademy.common.tenancy.TenantRole;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

/**
 * An active person of the bound tenant with a login, and their tenant roles (ADR-0066).
 *
 * @param personId the person in this tenant
 * @param roles    their tenant roles, possibly empty
 */
public record Member(UUID personId, Set<TenantRole> roles) {

    public Member {
        Objects.requireNonNull(personId, "personId");
        roles = Set.copyOf(roles);
    }

    public boolean has(TenantRole role) {
        return roles.contains(role);
    }
}
