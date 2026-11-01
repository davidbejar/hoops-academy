package com.hoopsacademy.athlete.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.athlete.application.ManageSchedules;
import com.hoopsacademy.athlete.domain.ScheduleId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Path("/api/athlete/training-schedules")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH, TenantRole.ASSISTANT_COACH, TenantRole.PARENT, TenantRole.PLAYER})
public class TrainingScheduleResource {

    private final ManageSchedules schedules;
    private final TenantContext tenant;

    TrainingScheduleResource(ManageSchedules schedules, TenantContext tenant) {
        this.schedules = schedules;
        this.tenant = tenant;
    }

    @GET
    public List<ScheduleDtos.Response> list(@QueryParam("teamId") String teamId, @QueryParam("activeOn") String activeOn) {
        return schedules.list(caller(), Requests.uuid("teamId", teamId).map(TeamId::new),
                        Requests.date("activeOn", activeOn)).stream()
                .map(ScheduleDtos.Response::from).toList();
    }

    @POST
    public Response create(@Valid @NotNull ScheduleDtos.CreateRequest request) {
        var created = schedules.create(caller(), new ManageSchedules.NewSchedule(new TeamId(request.teamId()),
                request.dayOfWeek(), Requests.time("startTime", request.startTime()), request.durationMinutes(),
                request.location(), request.validFrom(), request.validUntil()));
        return Response.status(Response.Status.CREATED).entity(ScheduleDtos.Response.from(created)).build();
    }

    @GET
    @Path("/{scheduleId}")
    public ScheduleDtos.Response get(@PathParam("scheduleId") UUID scheduleId) {
        return ScheduleDtos.Response.from(schedules.get(caller(), new ScheduleId(scheduleId)));
    }

    @PATCH
    @Path("/{scheduleId}")
    public ScheduleDtos.Response update(@PathParam("scheduleId") UUID scheduleId, JsonNode body) {
        PatchBody patch = new PatchBody(body);
        var change = new ManageSchedules.ScheduleChange(
                patch.required("dayOfWeek", PatchBody.fromText(s -> DayOfWeek.valueOf(s), "a day of week such as MONDAY")),
                patch.required("startTime", PatchBody.fromText(s -> Requests.time("startTime", s), "HH:mm")),
                patch.required("durationMinutes", PatchBody.integer(15, 480)),
                patch.nullable("location", PatchBody.text(200)),
                patch.required("validFrom", PatchBody.fromText(LocalDate::parse, "an ISO date")),
                patch.nullable("validUntil", PatchBody.fromText(LocalDate::parse, "an ISO date")));
        return ScheduleDtos.Response.from(schedules.update(caller(), new ScheduleId(scheduleId), change));
    }

    @DELETE
    @Path("/{scheduleId}")
    public Response end(@PathParam("scheduleId") UUID scheduleId) {
        schedules.end(caller(), new ScheduleId(scheduleId));
        return Response.noContent().build();
    }

    private AuthzContext caller() {
        return tenant.requireAuthz();
    }
}
