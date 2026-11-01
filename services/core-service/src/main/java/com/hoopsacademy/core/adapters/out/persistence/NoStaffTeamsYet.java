package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.core.application.port.StaffTeamsQuery;
import com.hoopsacademy.core.domain.membership.PersonId;
import io.quarkus.arc.DefaultBean;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Set;
import java.util.UUID;

/** WP3 has no team tables yet; WP4 provides the real {@link StaffTeamsQuery} bean, which replaces this default. */
@DefaultBean
@ApplicationScoped
class NoStaffTeamsYet implements StaffTeamsQuery {

    @Override
    public Set<UUID> staffTeamsOf(PersonId person) {
        return Set.of();
    }
}
