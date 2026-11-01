package com.hoopsacademy.game.adapters.in.rest;

import com.hoopsacademy.game.application.GetPlayerSeasonStats;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.SeasonId;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import java.util.UUID;

/** A player's season statistics (aggregated projections); visibility is decided by the use case (else 404). */
@Path("/api/game/players/{playerId}/season-stats")
@Produces(MediaType.APPLICATION_JSON)
public class SeasonStatsResource {

    private final GetPlayerSeasonStats getSeasonStats;

    public SeasonStatsResource(GetPlayerSeasonStats getSeasonStats) {
        this.getSeasonStats = getSeasonStats;
    }

    @GET
    public StatisticsDtos.PlayerSeasonStatsDto seasonStats(
            @PathParam("playerId") UUID playerId, @QueryParam("seasonId") UUID seasonId) {
        if (seasonId == null) {
            throw new BadRequestException("seasonId is required");
        }
        return StatisticsDtos.PlayerSeasonStatsDto.from(getSeasonStats.handle(PlayerId.of(playerId), SeasonId.of(seasonId)));
    }
}
