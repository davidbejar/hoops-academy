package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.application.roster.TeamPlayerService;
import com.hoopsacademy.core.application.roster.TeamPlayerService.TakenNumber;
import com.hoopsacademy.core.domain.roster.TeamId;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.List;
import java.util.UUID;

/** The jersey numbers taken on a team (any member, ADR-0048), for the jersey dialog. */
@Path("/api/core/teams/{teamId}/jersey-numbers")
@Produces(MediaType.APPLICATION_JSON)
public class TeamJerseyNumberResource {

    /** Contract {@code TakenJerseyNumber}. */
    public record TakenJerseyNumberDto(String jerseyNumber, RefDtos.PlayerRef player) {

        static TakenJerseyNumberDto of(TakenNumber taken) {
            return new TakenJerseyNumberDto(taken.number().value(),
                    new RefDtos.PlayerRef(taken.player().value(), taken.playerName()));
        }
    }

    private final TeamPlayerService assignments;

    public TeamJerseyNumberResource(TeamPlayerService assignments) {
        this.assignments = assignments;
    }

    @GET
    public List<TakenJerseyNumberDto> list(@PathParam("teamId") UUID team) {
        return assignments.takenNumbers(new TeamId(team)).stream().map(TakenJerseyNumberDto::of).toList();
    }
}
