package com.hoopsacademy.game.application.replica;

import com.hoopsacademy.common.tenancy.TenantRole;
import java.util.Set;
import java.util.UUID;

/** An active member with a login, and their tenant roles. */
public record ReplicaPerson(UUID id, Set<TenantRole> roles) {

    public ReplicaPerson {
        roles = Set.copyOf(roles);
    }

    public boolean has(TenantRole role) {
        return roles.contains(role);
    }
}
