package com.hoopsacademy.core.application.export;

import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.roster.AgeCategory;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import com.hoopsacademy.core.domain.roster.TeamStaffMember;
import java.util.List;

/**
 * The content of a team roster export (ADR-0048): the players of the team's open assignments with their natural
 * category in the team's season and their active guardians, then the team's staff.
 */
public record RosterSheet(ExportOrigin origin, String teamName, List<PlayerLine> players, List<StaffLine> staff) {

    /** A player: their person, natural category ({@code null} when none), assignment and active guardians. */
    public record PlayerLine(Person person, AgeCategory naturalCategory, TeamPlayer assignment, List<Person> guardians) {

        public PlayerLine {
            guardians = List.copyOf(guardians);
        }
    }

    /** A staff member and their person. */
    public record StaffLine(TeamStaffMember member, Person person) {}

    public RosterSheet {
        players = List.copyOf(players);
        staff = List.copyOf(staff);
    }

    /** The rows of the file below its header. */
    public int rows() {
        return players.size() + staff.size();
    }
}
