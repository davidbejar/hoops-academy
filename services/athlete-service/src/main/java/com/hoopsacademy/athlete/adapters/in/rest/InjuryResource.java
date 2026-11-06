package com.hoopsacademy.athlete.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.athlete.application.ManageInjuries;
import com.hoopsacademy.athlete.domain.InjuryId;
import com.hoopsacademy.athlete.domain.InjurySeverity;
import com.hoopsacademy.athlete.domain.InjuryStatus;
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
import java.util.Set;
import java.util.UUID;

@Path("/api/athlete/injuries")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH, TenantRole.ASSISTANT_COACH, TenantRole.PARENT, TenantRole.PLAYER})
public class InjuryResource {

    /** The clear enum of the request schema in athlete.yaml (ADR-0032). */
    private static final Set<String> UPDATE_CLEARABLE = Set.of("description", "expectedReturnOn", "actualReturnOn");

    private final ManageInjuries injuries;
    private final TenantContext tenant;
    private final CallerActor actors;

    InjuryResource(ManageInjuries injuries, TenantContext tenant, CallerActor actors) {
        this.injuries = injuries;
        this.tenant = tenant;
        this.actors = actors;
    }

    @GET
    public PageDto<HealthDtos.InjuryResponse> list(@QueryParam("playerId") String playerId, @QueryParam("teamId") String teamId,
            @QueryParam("status") String status, @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size) {
        var search = new ManageInjuries.Search(Requests.uuid("playerId", playerId).map(PlayerId::new),
                Requests.uuid("teamId", teamId).map(TeamId::new),
                Requests.parse("status", status, InjuryStatus::valueOf, "OPEN or RECOVERED"), page, size);
        return PageDto.of(injuries.search(caller(), search), HealthDtos.InjuryResponse::from);
    }

    @POST
    public Response create(@Valid @NotNull HealthDtos.CreateInjuryRequest request) {
        AuthzContext caller = caller();
        var created = injuries.create(caller, actors.of(caller), new ManageInjuries.NewInjury(new PlayerId(request.playerId()),
                request.occurredOn(), request.bodyPart(), request.description(), request.severity(), request.expectedReturnOn()));
        return Response.status(Response.Status.CREATED).entity(HealthDtos.InjuryResponse.from(created)).build();
    }

    @GET
    @Path("/{injuryId}")
    public HealthDtos.InjuryResponse get(@PathParam("injuryId") UUID injuryId) {
        return HealthDtos.InjuryResponse.from(injuries.get(caller(), new InjuryId(injuryId)));
    }

    @PATCH
    @Path("/{injuryId}")
    public HealthDtos.InjuryResponse update(@PathParam("injuryId") UUID injuryId, JsonNode body) {
        PatchBody patch = new PatchBody(body, UPDATE_CLEARABLE);
        var isoDate = PatchBody.fromText(LocalDate::parse, "an ISO date");
        var change = new ManageInjuries.InjuryChange(
                patch.required("occurredOn", isoDate),
                patch.required("bodyPart", PatchBody.nonBlankText(80)),
                patch.nullable("description", PatchBody.text(2000)),
                patch.required("severity", PatchBody.fromText(InjurySeverity::valueOf, "MINOR, MODERATE or SEVERE")),
                patch.nullable("expectedReturnOn", isoDate),
                patch.nullable("actualReturnOn", isoDate),
                patch.required("status", PatchBody.fromText(InjuryStatus::valueOf, "OPEN or RECOVERED")));
        return HealthDtos.InjuryResponse.from(injuries.update(caller(), new InjuryId(injuryId), change));
    }

    @DELETE
    @Path("/{injuryId}")
    public Response delete(@PathParam("injuryId") UUID injuryId) {
        injuries.delete(caller(), new InjuryId(injuryId));
        return Response.noContent().build();
    }

    private AuthzContext caller() {
        return tenant.requireAuthz();
    }
}
