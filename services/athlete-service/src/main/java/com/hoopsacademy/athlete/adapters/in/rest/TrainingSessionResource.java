package com.hoopsacademy.athlete.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.athlete.application.ManageSessions;
import com.hoopsacademy.athlete.domain.SessionId;
import com.hoopsacademy.athlete.domain.SessionStatus;
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
import java.time.Instant;
import java.util.UUID;

@Path("/api/athlete/training-sessions")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH, TenantRole.ASSISTANT_COACH, TenantRole.PARENT, TenantRole.PLAYER})
public class TrainingSessionResource {

    private final ManageSessions sessions;
    private final TenantContext tenant;

    TrainingSessionResource(ManageSessions sessions, TenantContext tenant) {
        this.sessions = sessions;
        this.tenant = tenant;
    }

    @GET
    public PageDto<SessionDtos.Response> list(@QueryParam("teamId") String teamId, @QueryParam("from") String from,
            @QueryParam("to") String to, @QueryParam("status") String status,
            @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size) {
        var calendar = new ManageSessions.Calendar(Requests.uuid("teamId", teamId).map(TeamId::new),
                Requests.date("from", from), Requests.date("to", to),
                Requests.parse("status", status, SessionStatus::valueOf, "PLANNED, DONE or CANCELLED"), page, size);
        return PageDto.of(sessions.list(caller(), calendar), SessionDtos.Response::from);
    }

    @POST
    public Response create(@Valid @NotNull SessionDtos.CreateRequest request) {
        var created = sessions.createAdHoc(caller(), new ManageSessions.NewSession(new TeamId(request.teamId()),
                request.startsAt(), request.durationMinutes(), request.location(), request.planId(), request.notes()));
        return Response.status(Response.Status.CREATED).entity(SessionDtos.Response.from(created)).build();
    }

    @GET
    @Path("/{sessionId}")
    public SessionDtos.Response get(@PathParam("sessionId") UUID sessionId) {
        return SessionDtos.Response.from(sessions.get(caller(), new SessionId(sessionId)));
    }

    @PATCH
    @Path("/{sessionId}")
    public SessionDtos.Response update(@PathParam("sessionId") UUID sessionId, JsonNode body) {
        PatchBody patch = new PatchBody(body);
        var change = new ManageSessions.SessionChange(
                patch.required("startsAt", PatchBody.fromText(Instant::parse, "an ISO instant (UTC)")),
                patch.required("durationMinutes", PatchBody.integer(15, 480)),
                patch.nullable("location", PatchBody.text(200)),
                patch.nullable("planId", PatchBody.fromText(UUID::fromString, "a UUID")),
                patch.nullable("notes", PatchBody.text(2000)),
                patch.required("status", PatchBody.fromText(this::editableStatus, "PLANNED or DONE")));
        return SessionDtos.Response.from(sessions.update(caller(), new SessionId(sessionId), change));
    }

    @POST
    @Path("/{sessionId}/cancel")
    public SessionDtos.Response cancel(@PathParam("sessionId") UUID sessionId,
            @Valid @NotNull SessionDtos.CancelRequest request) {
        return SessionDtos.Response.from(sessions.cancel(caller(), new SessionId(sessionId), request.reason()));
    }

    private SessionStatus editableStatus(String raw) {
        SessionStatus status = SessionStatus.valueOf(raw);
        if (status == SessionStatus.CANCELLED) {
            throw new IllegalArgumentException("PLANNED or DONE");
        }
        return status;
    }

    private AuthzContext caller() {
        return tenant.requireAuthz();
    }
}
