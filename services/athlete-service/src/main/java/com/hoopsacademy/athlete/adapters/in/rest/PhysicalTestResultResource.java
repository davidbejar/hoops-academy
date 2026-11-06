package com.hoopsacademy.athlete.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.athlete.application.ManageTestResults;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.athlete.domain.TestResultId;
import com.hoopsacademy.athlete.domain.TestTypeId;
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

@Path("/api/athlete/physical-test-results")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH, TenantRole.ASSISTANT_COACH, TenantRole.PARENT, TenantRole.PLAYER})
public class PhysicalTestResultResource {

    /** The clear enum of the request schema in athlete.yaml (ADR-0032). */
    private static final Set<String> UPDATE_CLEARABLE = Set.of("notes");

    private final ManageTestResults results;
    private final TenantContext tenant;
    private final CallerActor actors;

    PhysicalTestResultResource(ManageTestResults results, TenantContext tenant, CallerActor actors) {
        this.results = results;
        this.tenant = tenant;
        this.actors = actors;
    }

    @GET
    public PageDto<HealthDtos.ResultResponse> list(@QueryParam("playerId") String playerId, @QueryParam("teamId") String teamId,
            @QueryParam("testTypeId") String testTypeId, @QueryParam("from") String from, @QueryParam("to") String to,
            @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size) {
        var search = new ManageTestResults.Search(Requests.uuid("playerId", playerId).map(PlayerId::new),
                Requests.uuid("teamId", teamId).map(TeamId::new), Requests.uuid("testTypeId", testTypeId).map(TestTypeId::new),
                Requests.date("from", from), Requests.date("to", to), page, size);
        return PageDto.of(results.search(caller(), search), HealthDtos.ResultResponse::from);
    }

    @POST
    public Response create(@Valid @NotNull HealthDtos.CreateResultRequest request) {
        AuthzContext caller = caller();
        var created = results.create(caller, actors.of(caller), new ManageTestResults.NewResult(new PlayerId(request.playerId()),
                new TestTypeId(request.testTypeId()), request.measuredOn(), request.value(), request.notes()));
        return Response.status(Response.Status.CREATED).entity(HealthDtos.ResultResponse.from(created)).build();
    }

    @GET
    @Path("/{resultId}")
    public HealthDtos.ResultResponse get(@PathParam("resultId") UUID resultId) {
        return HealthDtos.ResultResponse.from(results.get(caller(), new TestResultId(resultId)));
    }

    @PATCH
    @Path("/{resultId}")
    public HealthDtos.ResultResponse update(@PathParam("resultId") UUID resultId, JsonNode body) {
        PatchBody patch = new PatchBody(body, UPDATE_CLEARABLE);
        var change = new ManageTestResults.ResultChange(
                patch.required("measuredOn", PatchBody.fromText(LocalDate::parse, "an ISO date")),
                patch.required("value", node -> {
                    if (!node.isNumber()) {
                        throw new IllegalArgumentException("a number");
                    }
                    return node.decimalValue();
                }),
                patch.nullable("notes", PatchBody.text(1000)));
        return HealthDtos.ResultResponse.from(results.update(caller(), new TestResultId(resultId), change));
    }

    @DELETE
    @Path("/{resultId}")
    public Response delete(@PathParam("resultId") UUID resultId) {
        results.delete(caller(), new TestResultId(resultId));
        return Response.noContent().build();
    }

    private AuthzContext caller() {
        return tenant.requireAuthz();
    }
}
