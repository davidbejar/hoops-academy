package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.adapters.in.shared.Constraints;
import com.hoopsacademy.core.application.approvals.CreatePlayer;
import com.hoopsacademy.core.application.approvals.PlayerCommandResult;
import com.hoopsacademy.core.application.approvals.WithdrawPlayer;
import com.hoopsacademy.core.application.players.PlayerQueries;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import com.hoopsacademy.core.domain.roster.TeamId;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.Optional;
import java.util.UUID;

/** Players: list/get with the matrix visibility, add and withdraw (ADMIN direct, COACH via approval request). */
@Path("/api/core/players")
@Produces(MediaType.APPLICATION_JSON)
public class PlayerResource {

    /** Contract {@code WithdrawPlayerRequest}. */
    public record WithdrawRequest(@Size(max = 500) String reason) {}

    private final PlayerQueries queries;
    private final CreatePlayer createPlayer;
    private final WithdrawPlayer withdrawPlayer;

    public PlayerResource(PlayerQueries queries, CreatePlayer createPlayer, WithdrawPlayer withdrawPlayer) {
        this.queries = queries;
        this.createPlayer = createPlayer;
        this.withdrawPlayer = withdrawPlayer;
    }

    @GET
    public PlayerDto.PageDto list(
            @QueryParam("status") @Pattern(regexp = "PENDING_APPROVAL|ACTIVE|ORPHAN|WITHDRAWN") String status,
            @QueryParam("teamId") UUID team, @QueryParam("q") @Size(max = 100) String text,
            @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size) {
        PlayerQueries.Query query = new PlayerQueries.Query(Optional.ofNullable(status).map(PlayerStatus::valueOf),
                Optional.ofNullable(team).map(TeamId::new), Optional.ofNullable(text).filter(t -> !t.isBlank()));
        return PlayerDto.PageDto.of(queries.list(query, new PageRequest(page, size)));
    }

    @GET
    @Path("/{playerId}")
    public PlayerDto get(@PathParam("playerId") UUID id) {
        return PlayerDto.of(queries.get(new PlayerId(id)));
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response create(@Valid @NotNull CreatePlayerRequest request) {
        PlayerCommandResult result = createPlayer.handle(request.toCommand());
        return Response.status(result.pending() ? Response.Status.ACCEPTED : Response.Status.CREATED)
                .entity(PlayerCommandResultDto.of(result)).build();
    }

    @POST
    @Path("/{playerId}/withdraw")
    @Consumes(MediaType.APPLICATION_JSON)
    public Response withdraw(@PathParam("playerId") UUID id, @Valid WithdrawRequest request) {
        PlayerCommandResult result = withdrawPlayer.handle(new PlayerId(id), request == null ? null : request.reason());
        return Response.status(result.pending() ? Response.Status.ACCEPTED : Response.Status.OK)
                .entity(PlayerCommandResultDto.of(result)).build();
    }
}
