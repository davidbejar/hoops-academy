package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamStaffMember;
import java.util.List;
import java.util.Optional;
import java.util.Set;

/** Coaches and assistant coaches of the bound tenant's teams. */
public interface TeamStaffRepository {

    List<TeamStaffMember> ofTeam(TeamId team);

    Optional<TeamStaffMember> find(TeamId team, PersonId person);

    /** Inserts or replaces the (team, person) entry. */
    void save(TeamStaffMember member);

    void delete(TeamId team, PersonId person);

    Set<TeamId> teamsOf(PersonId person);
}
