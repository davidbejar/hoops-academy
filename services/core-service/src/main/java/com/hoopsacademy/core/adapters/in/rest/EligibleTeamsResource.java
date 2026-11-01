package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.application.roster.EligibilityQueries;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.SeasonId;
import jakarta.validation.constraints.NotNull;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import java.util.List;
import java.util.UUID;

/** {@code GET /players/{id}/eligible-teams}: the teams the assignment UI may offer (the rest of /players is WP5). */
@Path("/api/core/players/{playerId}/eligible-teams")
@Produces(MediaType.APPLICATION_JSON)
public class EligibleTeamsResource {

    private final EligibilityQueries eligibility;

    public EligibleTeamsResource(EligibilityQueries eligibility) {
        this.eligibility = eligibility;
    }

    @GET
    public List<EligibilityCheckDto.EligibleTeamDto> eligibleTeams(@PathParam("playerId") UUID player,
            @QueryParam("seasonId") @NotNull UUID season) {
        return eligibility.eligibleTeams(new PlayerId(player), new SeasonId(season)).stream()
                .map(EligibilityCheckDto.EligibleTeamDto::of).toList();
    }
}
