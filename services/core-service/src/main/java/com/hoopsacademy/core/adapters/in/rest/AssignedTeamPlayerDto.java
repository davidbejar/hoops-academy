package com.hoopsacademy.core.adapters.in.rest;

import com.fasterxml.jackson.annotation.JsonUnwrapped;
import com.hoopsacademy.core.application.roster.AssignPlayerToTeam.Assigned;
import com.hoopsacademy.core.domain.roster.JerseySource;

/** Contract {@code AssignedTeamPlayer}: the {@code TeamPlayer} fields plus the rule that chose the number. */
public record AssignedTeamPlayerDto(@JsonUnwrapped TeamPlayerDto assignment, JerseySource jerseySource) {

    static AssignedTeamPlayerDto of(Assigned assigned) {
        return new AssignedTeamPlayerDto(TeamPlayerDto.of(assigned.view()), assigned.jerseySource());
    }
}
