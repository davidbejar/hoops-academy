package com.hoopsacademy.athlete.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.athlete.application.ManagePlannedAbsences;
import com.hoopsacademy.athlete.domain.AbsenceId;
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
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.time.LocalDate;
import java.util.UUID;

@Path("/api/athlete/planned-absences")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH, TenantRole.ASSISTANT_COACH, TenantRole.PARENT, TenantRole.PLAYER})
public class PlannedAbsenceResource {

    private final ManagePlannedAbsences absences;
    private final TenantContext tenant;
    private final CallerActor actors;

    PlannedAbsenceResource(ManagePlannedAbsences absences, TenantContext tenant, CallerActor actors) {
        this.absences = absences;
        this.tenant = tenant;
        this.actors = actors;
    }

    @GET
    public PageDto<AbsenceDtos.Response> list(@QueryParam("playerId") String playerId, @QueryParam("teamId") String teamId,
            @QueryParam("from") String from, @QueryParam("to") String to,
            @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size) {
        var search = new ManagePlannedAbsences.Search(Requests.uuid("playerId", playerId).map(PlayerId::new),
                Requests.uuid("teamId", teamId).map(TeamId::new), Requests.date("from", from), Requests.date("to", to),
                page, size);
        return PageDto.of(absences.search(caller(), search), AbsenceDtos.Response::from);
    }

    @POST
    public Response create(@Valid @NotNull AbsenceDtos.CreateRequest request) {
        AuthzContext caller = caller();
        var created = absences.create(caller, actors.of(caller), new ManagePlannedAbsences.NewAbsence(
                new PlayerId(request.playerId()), request.fromDate(), request.toDate(), request.reason()));
        return Response.status(Response.Status.CREATED).entity(AbsenceDtos.Response.from(created)).build();
    }

    @GET
    @Path("/{absenceId}")
    public AbsenceDtos.Response get(@PathParam("absenceId") UUID absenceId) {
        return AbsenceDtos.Response.from(absences.get(caller(), new AbsenceId(absenceId)));
    }

    @PATCH
    @Path("/{absenceId}")
    public AbsenceDtos.Response update(@PathParam("absenceId") UUID absenceId, JsonNode body) {
        PatchBody patch = new PatchBody(body);
        var change = new ManagePlannedAbsences.AbsenceChange(
                patch.required("fromDate", PatchBody.fromText(LocalDate::parse, "an ISO date")),
                patch.required("toDate", PatchBody.fromText(LocalDate::parse, "an ISO date")),
                patch.nullable("reason", PatchBody.text(500)));
        return AbsenceDtos.Response.from(absences.update(caller(), new AbsenceId(absenceId), change));
    }

    @DELETE
    @Path("/{absenceId}")
    public Response delete(@PathParam("absenceId") UUID absenceId) {
        absences.delete(caller(), new AbsenceId(absenceId));
        return Response.noContent().build();
    }

    private AuthzContext caller() {
        return tenant.requireAuthz();
    }
}
