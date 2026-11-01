package com.hoopsacademy.athlete.adapters.in.rest;

import com.hoopsacademy.athlete.application.ManageNorms;
import com.hoopsacademy.athlete.domain.Gender;
import com.hoopsacademy.athlete.domain.NormId;
import com.hoopsacademy.athlete.domain.TestTypeId;
import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;
import java.util.UUID;

@Path("/api/athlete/physical-test-norms")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH, TenantRole.ASSISTANT_COACH, TenantRole.PARENT, TenantRole.PLAYER})
public class PhysicalTestNormResource {

    private final ManageNorms norms;
    private final TenantContext tenant;

    PhysicalTestNormResource(ManageNorms norms, TenantContext tenant) {
        this.norms = norms;
        this.tenant = tenant;
    }

    @GET
    public List<HealthDtos.NormResponse> list(@QueryParam("testTypeId") String testTypeId, @QueryParam("gender") String gender,
            @QueryParam("scope") String scope) {
        var parsedScope = Requests.parse("scope", scope, ManageNorms.Scope::valueOf, "EFFECTIVE, GLOBAL or TENANT")
                .orElse(ManageNorms.Scope.EFFECTIVE);
        return norms.list(parsedScope, Requests.uuid("testTypeId", testTypeId).map(TestTypeId::new),
                Requests.parse("gender", gender, Gender::valueOf, "MALE or FEMALE")).stream()
                .map(HealthDtos.NormResponse::from).toList();
    }

    @POST
    public Response create(@Valid @NotNull HealthDtos.NormRequest request) {
        var created = norms.create(tenant.requireAuthz(), fields(request));
        return Response.status(Response.Status.CREATED).entity(HealthDtos.NormResponse.from(created)).build();
    }

    @PUT
    @Path("/{normId}")
    public HealthDtos.NormResponse replace(@PathParam("normId") UUID normId, @Valid @NotNull HealthDtos.NormRequest request) {
        return HealthDtos.NormResponse.from(norms.replace(tenant.requireAuthz(), new NormId(normId), fields(request)));
    }

    @DELETE
    @Path("/{normId}")
    public Response delete(@PathParam("normId") UUID normId) {
        norms.delete(tenant.requireAuthz(), new NormId(normId));
        return Response.noContent().build();
    }

    private static ManageNorms.NormFields fields(HealthDtos.NormRequest r) {
        return new ManageNorms.NormFields(new TestTypeId(r.testTypeId()), r.gender(), r.minAge(), r.maxAge(), r.band(),
                r.minValue(), r.maxValue(), r.source());
    }
}
