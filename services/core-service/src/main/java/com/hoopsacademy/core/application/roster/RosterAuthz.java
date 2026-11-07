package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.common.authz.Authz;
import com.hoopsacademy.common.problem.AccessDeniedException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.roster.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Set;
import java.util.UUID;

/**
 * The roster rows of the authz matrix: assignments and case resolutions are ADMIN or the COACH of the team
 * (a COACH tenant role plus a team_staff row); eligibility reads are ADMIN or any team staff.
 */
@ApplicationScoped
public class RosterAuthz {

    private final Authz authz;
    private final TenantContext tenantContext;

    public RosterAuthz(Authz authz, TenantContext tenantContext) {
        this.authz = authz;
        this.tenantContext = tenantContext;
    }

    public boolean isAdmin() {
        return authz.isAdmin();
    }

    /** ADMIN, or COACH with a team_staff row for {@code team}. */
    public void requireCoachOf(TeamId team) {
        authz.require(authz.isAdmin() || isCoachOf(team), "Only ADMIN or the team's coach may change its roster");
    }

    /** ADMIN, or COACH / ASSISTANT_COACH with a team_staff row for {@code team}. */
    public void requireStaffOf(TeamId team) {
        authz.require(authz.isAdmin() || authz.isStaffOf(team.value()), "Only ADMIN or the team's staff");
    }

    public boolean isTeamStaffMember() {
        return authz.hasAnyRole(TenantRole.COACH, TenantRole.ASSISTANT_COACH);
    }

    /** Teams the caller is staff of (empty unless they hold a staff role). */
    public Set<UUID> staffTeams() {
        return isTeamStaffMember() ? caller().staffTeamIds() : Set.of();
    }

    /** Teams of ended seasons the caller was staff of (empty unless they hold a staff role; ADR-0042). */
    public Set<UUID> historicStaffTeams() {
        return isTeamStaffMember() ? caller().historicStaffTeamIds() : Set.of();
    }

    public PersonId callerPerson() {
        return new PersonId(caller().personId());
    }

    private boolean isCoachOf(TeamId team) {
        return authz.hasAnyRole(TenantRole.COACH) && caller().staffTeamIds().contains(team.value());
    }

    private AuthzContext caller() {
        return tenantContext.authz().orElseThrow(() -> new AccessDeniedException("No tenant membership"));
    }
}
