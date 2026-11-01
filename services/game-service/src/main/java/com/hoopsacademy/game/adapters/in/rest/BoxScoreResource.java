package com.hoopsacademy.game.adapters.in.rest;

import com.hoopsacademy.game.application.GetBoxScore;
import com.hoopsacademy.game.domain.MatchId;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.UUID;

/** Box score of a match from its stored projection; which player lines are visible is decided by the use case. */
@Path("/api/game/matches/{matchId}/box-score")
@Produces(MediaType.APPLICATION_JSON)
public class BoxScoreResource {

    private final GetBoxScore getBoxScore;

    public BoxScoreResource(GetBoxScore getBoxScore) {
        this.getBoxScore = getBoxScore;
    }

    @GET
    public StatisticsDtos.BoxScoreDto boxScore(@PathParam("matchId") UUID matchId) {
        return StatisticsDtos.BoxScoreDto.from(getBoxScore.handle(MatchId.of(matchId)));
    }
}
