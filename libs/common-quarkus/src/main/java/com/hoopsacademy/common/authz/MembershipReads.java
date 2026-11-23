package com.hoopsacademy.common.authz;

import com.hoopsacademy.common.client.CoreMembership.TenantStatus;
import com.hoopsacademy.common.tenancy.TenantId;
import java.time.ZoneId;
import java.util.Objects;
import java.util.Optional;

/**
 * Everything a replica reads to resolve a login's membership in the bound tenant (ADR-0066): the tenant, the login's
 * active person and that person's relations. Implemented by game and athlete over their roster replicas.
 */
public interface MembershipReads extends MemberRelations {

    /** The tenant's lifecycle status and IANA zone, as the store last learnt them. */
    record TenantState(TenantStatus status, ZoneId timezone) {

        public TenantState {
            Objects.requireNonNull(status, "status");
            Objects.requireNonNull(timezone, "timezone");
        }

        /** Only an ACTIVE tenant has members: a SUSPENDED or WITHDRAWN one answers 404 to everyone. */
        public boolean active() {
            return status == TenantStatus.ACTIVE;
        }
    }

    /** The tenant's own row; empty when it is not the bound tenant or the store does not know it. */
    Optional<TenantState> tenant(TenantId tenant);

    /** The active person whose login is {@code subject}. */
    Optional<Member> activeMember(String subject);
}
