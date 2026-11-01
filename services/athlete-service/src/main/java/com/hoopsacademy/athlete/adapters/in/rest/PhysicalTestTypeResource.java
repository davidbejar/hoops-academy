package com.hoopsacademy.athlete.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.athlete.application.ManageTestTypes;
import com.hoopsacademy.athlete.domain.TestTypeId;
import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;
import java.util.UUID;

@Path("/api/athlete/physical-test-types")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH, TenantRole.ASSISTANT_COACH, TenantRole.PARENT, TenantRole.PLAYER})
public class PhysicalTestTypeResource {

    private final ManageTestTypes types;
    private final TenantContext tenant;

    PhysicalTestTypeResource(ManageTestTypes types, TenantContext tenant) {
        this.types = types;
        this.tenant = tenant;
    }

    @GET
    public List<HealthDtos.TestTypeResponse> list() {
        return types.list().stream().map(HealthDtos.TestTypeResponse::from).toList();
    }

    @POST
    public Response create(@Valid @NotNull HealthDtos.CreateTestTypeRequest request) {
        var created = types.create(tenant.requireAuthz(), new ManageTestTypes.NewType(request.code(), request.name(),
                request.unit(), request.higherIsBetter(), request.description()));
        return Response.status(Response.Status.CREATED).entity(HealthDtos.TestTypeResponse.from(created)).build();
    }

    @GET
    @Path("/{testTypeId}")
    public HealthDtos.TestTypeResponse get(@PathParam("testTypeId") UUID testTypeId) {
        return HealthDtos.TestTypeResponse.from(types.get(new TestTypeId(testTypeId)));
    }

    @PATCH
    @Path("/{testTypeId}")
    public HealthDtos.TestTypeResponse update(@PathParam("testTypeId") UUID testTypeId, JsonNode body) {
        PatchBody patch = new PatchBody(body);
        var change = new ManageTestTypes.TypeChange(
                patch.required("name", PatchBody.nonBlankText(120)),
                patch.required("unit", PatchBody.nonBlankText(16)),
                patch.required("higherIsBetter", node -> {
                    if (!node.isBoolean()) {
                        throw new IllegalArgumentException("true or false");
                    }
                    return node.asBoolean();
                }),
                patch.nullable("description", PatchBody.text(2000)));
        return HealthDtos.TestTypeResponse.from(types.update(tenant.requireAuthz(), new TestTypeId(testTypeId), change));
    }
}
