package com.hoopsacademy.core.domain.roster;

import com.hoopsacademy.core.domain.membership.PersonId;
import java.time.LocalDate;
import java.util.Objects;

/** A coach or assistant coach attached to a team since a date. */
public record TeamStaffMember(TeamId team, PersonId person, StaffRole role, LocalDate since) {

    public TeamStaffMember {
        Objects.requireNonNull(team, "team");
        Objects.requireNonNull(person, "person");
        Objects.requireNonNull(role, "role");
        Objects.requireNonNull(since, "since");
    }

    public TeamStaffMember withRole(StaffRole newRole) {
        return new TeamStaffMember(team, person, newRole, since);
    }

    public TeamStaffMember forTeam(TeamId other, LocalDate from) {
        return new TeamStaffMember(other, person, role, from);
    }
}
