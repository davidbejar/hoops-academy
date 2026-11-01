package com.hoopsacademy.core.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.common.problem.Problem;
import com.hoopsacademy.core.adapters.in.shared.Constraints;
import com.hoopsacademy.core.adapters.in.shared.InvalidRequestException;
import com.hoopsacademy.core.adapters.in.shared.MergePatch;
import com.hoopsacademy.core.adapters.in.shared.Params;
import com.hoopsacademy.core.application.roster.AssignPlayerToTeam;
import com.hoopsacademy.core.application.roster.AssignPlayerToTeam.Assignment;
import com.hoopsacademy.core.application.roster.EligibilityQueries;
import com.hoopsacademy.core.application.roster.TeamPlayerService;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.JerseyNumber;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.shared.Patch;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
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
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** A team's player assignments (eligibility-checked) and the per-player eligibility check. */
@Path("/api/core/teams/{teamId}/players")
@Produces(MediaType.APPLICATION_JSON)
public class TeamPlayerResource {

    private static final java.util.regex.Pattern JERSEY = java.util.regex.Pattern.compile(Constraints.JERSEY);

    /** Contract {@code AssignPlayerRequest}. */
    public record AssignPlayerRequest(@NotNull UUID playerId, @Pattern(regexp = Constraints.JERSEY) String jerseyNumber,
            LocalDate joinedOn) {}

    private final AssignPlayerToTeam assign;
    private final TeamPlayerService assignments;
    private final EligibilityQueries eligibility;

    public TeamPlayerResource(AssignPlayerToTeam assign, TeamPlayerService assignments, EligibilityQueries eligibility) {
        this.assign = assign;
        this.assignments = assignments;
        this.eligibility = eligibility;
    }

    @GET
    public List<TeamPlayerDto> list(@PathParam("teamId") UUID team,
            @QueryParam("includeLeft") @DefaultValue("false") boolean includeLeft) {
        return assignments.list(new TeamId(team), includeLeft).stream().map(TeamPlayerDto::of).toList();
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response assign(@PathParam("teamId") UUID team, @Valid @NotNull AssignPlayerRequest request) {
        TeamPlayerDto created = TeamPlayerDto.of(assign.assign(new Assignment(new TeamId(team),
                new PlayerId(request.playerId()), Optional.ofNullable(JerseyNumber.ofNullable(request.jerseyNumber())),
                Optional.ofNullable(request.joinedOn()))));
        return Response.status(Response.Status.CREATED).entity(created).build();
    }

    @PATCH
    @Path("/{playerId}")
    @Consumes(MediaType.APPLICATION_JSON)
    public TeamPlayerDto renumber(@PathParam("teamId") UUID team, @PathParam("playerId") UUID player,
            @NotNull JsonNode body) {
        MergePatch patch = MergePatch.of(body);
        Patch<String> jersey = patch.matching("jerseyNumber", true, JERSEY);
        patch.validate(true);
        if (!jersey.isPresent()) {
            throw new InvalidRequestException(List.of(new Problem.Violation("jerseyNumber", "is required")));
        }
        return TeamPlayerDto.of(assignments.renumber(new TeamId(team), new PlayerId(player),
                JerseyNumber.ofNullable(jersey.applyTo(null))));
    }

    @DELETE
    @Path("/{playerId}")
    public void unassign(@PathParam("teamId") UUID team, @PathParam("playerId") UUID player) {
        assignments.unassign(new TeamId(team), new PlayerId(player));
    }

    @GET
    @Path("/{playerId}/eligibility")
    public EligibilityCheckDto check(@PathParam("teamId") UUID team, @PathParam("playerId") UUID player,
            @QueryParam("asOf") String asOf) {
        return EligibilityCheckDto.of(eligibility.check(new TeamId(team), new PlayerId(player), Params.date("asOf", asOf)));
    }
}
