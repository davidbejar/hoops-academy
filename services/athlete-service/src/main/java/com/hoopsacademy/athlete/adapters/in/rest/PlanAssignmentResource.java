package com.hoopsacademy.athlete.adapters.in.rest;

import com.hoopsacademy.athlete.application.ManageAssignments;
import com.hoopsacademy.athlete.application.ManageCompletions;
import com.hoopsacademy.athlete.domain.AssignmentId;
import com.hoopsacademy.athlete.domain.PlanId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.Optional;
import java.util.UUID;

@Path("/api/athlete/plan-assignments")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH, TenantRole.ASSISTANT_COACH, TenantRole.PARENT, TenantRole.PLAYER})
public class PlanAssignmentResource {

    private final ManageAssignments assignments;
    private final ManageCompletions completions;
    private final TenantContext tenant;
    private final CallerActor actors;

    PlanAssignmentResource(ManageAssignments assignments, ManageCompletions completions, TenantContext tenant,
            CallerActor actors) {
        this.assignments = assignments;
        this.completions = completions;
        this.tenant = tenant;
        this.actors = actors;
    }

    @GET
    public PageDto<AssignmentDtos.Response> list(@QueryParam("teamId") String teamId, @QueryParam("playerId") String playerId,
            @QueryParam("dueFrom") String dueFrom, @QueryParam("dueTo") String dueTo,
            @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size) {
        var filter = new ManageAssignments.Filter(Requests.uuid("teamId", teamId).map(TeamId::new),
                Requests.uuid("playerId", playerId).map(PlayerId::new), Requests.date("dueFrom", dueFrom),
                Requests.date("dueTo", dueTo), page, size);
        return PageDto.of(assignments.list(caller(), filter), AssignmentDtos.Response::from);
    }

    @POST
    public Response create(@Valid @NotNull AssignmentDtos.CreateRequest request) {
        AuthzContext caller = caller();
        var created = assignments.create(caller, actors.of(caller), new ManageAssignments.NewAssignment(
                new PlanId(request.planId()), Optional.ofNullable(request.teamId()).map(TeamId::new),
                Optional.ofNullable(request.playerId()).map(PlayerId::new), request.dueOn(), request.notes()));
        return Response.status(Response.Status.CREATED).entity(AssignmentDtos.Response.from(created)).build();
    }

    @GET
    @Path("/{assignmentId}")
    public AssignmentDtos.Response get(@PathParam("assignmentId") UUID assignmentId) {
        return AssignmentDtos.Response.from(assignments.get(caller(), new AssignmentId(assignmentId)));
    }

    @DELETE
    @Path("/{assignmentId}")
    public Response delete(@PathParam("assignmentId") UUID assignmentId) {
        assignments.delete(caller(), new AssignmentId(assignmentId));
        return Response.noContent().build();
    }

    @GET
    @Path("/{assignmentId}/progress")
    public AssignmentDtos.Progress progress(@PathParam("assignmentId") UUID assignmentId) {
        return AssignmentDtos.Progress.from(completions.progress(caller(), new AssignmentId(assignmentId)));
    }

    @PUT
    @Path("/{assignmentId}/completions/{playerId}")
    public AssignmentDtos.CompletionResponse record(@PathParam("assignmentId") UUID assignmentId,
            @PathParam("playerId") UUID playerId, @Valid @NotNull AssignmentDtos.CompletionRequest request) {
        AuthzContext caller = caller();
        return AssignmentDtos.CompletionResponse.from(completions.record(caller, actors.of(caller),
                new AssignmentId(assignmentId), new PlayerId(playerId), request.status(), request.comment()));
    }

    private AuthzContext caller() {
        return tenant.requireAuthz();
    }
}
