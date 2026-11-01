package com.hoopsacademy.game.adapters.in.rest;

import com.hoopsacademy.game.application.GetMatchRoster;
import com.hoopsacademy.game.application.ReplaceMatchRoster;
import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.PlayerId;
import jakarta.validation.Valid;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.UUID;

@Path("/api/game/matches/{matchId}/roster")
@Produces(MediaType.APPLICATION_JSON)
public class MatchRosterResource {

    private final GetMatchRoster getMatchRoster;
    private final ReplaceMatchRoster replaceMatchRoster;

    public MatchRosterResource(GetMatchRoster getMatchRoster, ReplaceMatchRoster replaceMatchRoster) {
        this.getMatchRoster = getMatchRoster;
        this.replaceMatchRoster = replaceMatchRoster;
    }

    @GET
    public MatchRosterDto get(@PathParam("matchId") UUID matchId) {
        return MatchRosterDto.from(getMatchRoster.handle(MatchId.of(matchId)));
    }

    @PUT
    @Consumes(MediaType.APPLICATION_JSON)
    public MatchRosterDto replace(@PathParam("matchId") UUID matchId, @Valid ReplaceMatchRosterRequest request) {
        var entries = request.entries().stream()
                .map(e -> new ReplaceMatchRoster.Entry(PlayerId.of(e.playerId()), e.jerseyNumber(), e.isStarter()))
                .toList();
        return MatchRosterDto.from(replaceMatchRoster.handle(MatchId.of(matchId), entries));
    }
}
