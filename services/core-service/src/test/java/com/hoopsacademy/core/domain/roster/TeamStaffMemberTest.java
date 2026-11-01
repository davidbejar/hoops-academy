package com.hoopsacademy.core.domain.roster;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.core.domain.membership.PersonId;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;

class TeamStaffMemberTest {

    @Test
    void aStaffEntryNeedsTeamPersonRoleAndDate() {
        TeamStaffMember coach = new TeamStaffMember(TeamId.random(), PersonId.random(), StaffRole.COACH, LocalDate.of(2026, 9, 1));
        assertThat(coach.withRole(StaffRole.ASSISTANT_COACH).role()).isEqualTo(StaffRole.ASSISTANT_COACH);
        assertThat(coach.withRole(StaffRole.ASSISTANT_COACH).since()).isEqualTo(coach.since());
        TeamId next = TeamId.random();
        assertThat(coach.forTeam(next, LocalDate.of(2027, 9, 1)))
                .isEqualTo(new TeamStaffMember(next, coach.person(), StaffRole.COACH, LocalDate.of(2027, 9, 1)));
        assertThatThrownBy(() -> new TeamStaffMember(null, PersonId.random(), StaffRole.COACH, LocalDate.now()))
                .isInstanceOf(NullPointerException.class);
    }
}
