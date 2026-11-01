package com.hoopsacademy.game.adapters.in.rest;

import com.hoopsacademy.game.application.CancelMatch;
import com.hoopsacademy.game.application.CreateMatch;
import com.hoopsacademy.game.application.FinishMatch;
import com.hoopsacademy.game.application.GetMatch;
import com.hoopsacademy.game.application.ListMatches;
import com.hoopsacademy.game.application.MatchFilter;
import com.hoopsacademy.game.application.StartMatch;
import com.hoopsacademy.game.application.UpdateMatch;
import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.net.URI;
import java.time.Instant;
import java.util.UUID;

/**
 * Match CRUD and lifecycle. Tenant membership is checked by the common tenant filter (non-member: 404); who may
 * change a given team's matches is decided inside the use cases (ADMIN or staff of the team: otherwise 403).
 */
@Path("/api/game/matches")
@Produces(MediaType.APPLICATION_JSON)
public class MatchResource {

    private final CreateMatch createMatch;
    private final GetMatch getMatch;
    private final ListMatches listMatches;
    private final UpdateMatch updateMatch;
    private final StartMatch startMatch;
    private final FinishMatch finishMatch;
    private final CancelMatch cancelMatch;

    public MatchResource(
            CreateMatch createMatch, GetMatch getMatch, ListMatches listMatches, UpdateMatch updateMatch,
            StartMatch startMatch, FinishMatch finishMatch, CancelMatch cancelMatch) {
        this.createMatch = createMatch;
        this.getMatch = getMatch;
        this.listMatches = listMatches;
        this.updateMatch = updateMatch;
        this.startMatch = startMatch;
        this.finishMatch = finishMatch;
        this.cancelMatch = cancelMatch;
    }

    @GET
    public MatchPageDto list(
            @QueryParam("teamId") UUID teamId,
            @QueryParam("seasonId") UUID seasonId,
            @QueryParam("status") MatchStatus status,
            @QueryParam("scheduledFrom") Instant scheduledFrom,
            @QueryParam("scheduledTo") Instant scheduledTo,
            @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size) {
        MatchFilter filter = new MatchFilter(teamId == null ? null : TeamId.of(teamId),
                seasonId == null ? null : SeasonId.of(seasonId), status, scheduledFrom, scheduledTo);
        return MatchPageDto.from(listMatches.handle(filter, page, size));
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response create(@Valid CreateMatchRequest request) {
        MatchDto created = MatchDto.from(createMatch.handle(new CreateMatch.Command(TeamId.of(request.teamId()),
                request.opponentName(), request.homeAway(), request.scheduledAt(), request.venue(),
                request.periodCount(), request.periodMinutes())));
        return Response.created(URI.create("/api/game/matches/" + created.id())).entity(created).build();
    }

    @GET
    @Path("/{matchId}")
    public MatchDto get(@PathParam("matchId") UUID matchId) {
        return MatchDto.from(getMatch.handle(MatchId.of(matchId)));
    }

    @PATCH
    @Path("/{matchId}")
    @Consumes(MediaType.APPLICATION_JSON)
    public MatchDto update(@PathParam("matchId") UUID matchId, @Valid UpdateMatchRequest request) {
        if (request == null || request.isEmpty()) {
            throw new BadRequestException("At least one field must be given");
        }
        return MatchDto.from(updateMatch.handle(MatchId.of(matchId), new UpdateMatch.Command(request.opponentName,
                request.homeAway, request.scheduledAt, request.venueGiven, request.venue, request.periodCount,
                request.periodMinutes)));
    }

    @POST
    @Path("/{matchId}/start")
    public MatchDto start(@PathParam("matchId") UUID matchId) {
        return MatchDto.from(startMatch.handle(MatchId.of(matchId)));
    }

    @POST
    @Path("/{matchId}/finish")
    public MatchDto finish(@PathParam("matchId") UUID matchId) {
        return MatchDto.from(finishMatch.handle(MatchId.of(matchId)));
    }

    @POST
    @Path("/{matchId}/cancel")
    @Consumes(MediaType.APPLICATION_JSON)
    public MatchDto cancel(@PathParam("matchId") UUID matchId, @Valid CancelMatchRequest request) {
        return MatchDto.from(cancelMatch.handle(MatchId.of(matchId), request.reason()));
    }
}
