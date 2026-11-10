package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.identity.UserId;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.tenant.TenantStatus;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.Set;

/**
 * Every login across academies with its person in each (GET /platform/users, decision 71), read through the platform
 * datasource (V18, ADR-0029 amendment): of a person only what an academy's member list shows as identity (name, roles,
 * active flag), never other personal data.
 */
public interface PlatformUsers {

    /** One login and its memberships, ordered by academy name. */
    record Login(UserId id, Optional<String> email, Instant createdAt, List<Membership> memberships) {

        public Login {
            memberships = List.copyOf(memberships);
        }
    }

    /** The login's person in one academy. */
    record Membership(TenantId tenant, String tenantName, String tenantSlug, TenantStatus tenantStatus, PersonId person,
            String givenName, String familyName, Set<TenantRole> roles, boolean active) {

        public Membership {
            roles = Set.copyOf(roles);
        }
    }

    /**
     * Logins ordered by e-mail (case-insensitive, none last), optionally those whose e-mail or a person's
     * "given family" name contains {@code query} (case-insensitive, literal).
     */
    PageResult<Login> list(Optional<String> query, PageRequest page);
}
