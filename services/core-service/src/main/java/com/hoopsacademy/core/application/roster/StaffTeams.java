package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.core.application.port.StaffTeamsQuery;
import com.hoopsacademy.core.application.port.TeamStaffRepository;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.roster.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/** team_staff is the single source of truth for {@code staffTeamIds} (/internal/authz, /me, Authz.isStaffOf). */
@ApplicationScoped
public class StaffTeams implements StaffTeamsQuery {

    private final TeamStaffRepository staff;

    public StaffTeams(TeamStaffRepository staff) {
        this.staff = staff;
    }

    @Override
    public Set<UUID> staffTeamsOf(PersonId person) {
        return staff.teamsOf(person).stream().map(TeamId::value).collect(Collectors.toSet());
    }
}
