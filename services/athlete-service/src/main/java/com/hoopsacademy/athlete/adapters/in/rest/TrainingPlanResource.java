package com.hoopsacademy.athlete.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.athlete.application.ManagePlans;
import com.hoopsacademy.athlete.domain.PlanId;
import com.hoopsacademy.athlete.domain.PlanItemId;
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
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Path("/api/athlete/training-plans")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH, TenantRole.ASSISTANT_COACH, TenantRole.PARENT, TenantRole.PLAYER})
public class TrainingPlanResource {

    private static final int MAX_NAME = 120;
    private static final int MAX_TEXT = 4000;

    private final ManagePlans plans;
    private final TenantContext tenant;
    private final CallerActor actors;

    TrainingPlanResource(ManagePlans plans, TenantContext tenant, CallerActor actors) {
        this.plans = plans;
        this.tenant = tenant;
        this.actors = actors;
    }

    @GET
    public PageDto<PlanDtos.Summary> list(@QueryParam("template") String template, @QueryParam("q") String q,
            @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size) {
        Optional<String> query = Optional.ofNullable(q).filter(text -> !text.isBlank());
        if (query.filter(text -> text.length() > 100).isPresent()) {
            throw new com.hoopsacademy.athlete.application.InvalidRequestException("q", "INVALID_VALUE", "q must be at most 100 characters");
        }
        return PageDto.of(plans.list(Requests.bool("template", template, false), query, page, size), PlanDtos.Summary::from);
    }

    @POST
    public Response create(@Valid @NotNull PlanDtos.CreateRequest request) {
        AuthzContext caller = caller();
        var items = request.itemsOrEmpty().stream().map(TrainingPlanResource::fields).toList();
        var created = plans.create(caller, actors.of(caller),
                new ManagePlans.NewPlan(request.name(), request.description(), items));
        return Response.status(Response.Status.CREATED).entity(PlanDtos.Plan.from(created)).build();
    }

    @GET
    @Path("/{planId}")
    public PlanDtos.Plan get(@PathParam("planId") UUID planId) {
        return PlanDtos.Plan.from(plans.get(new PlanId(planId)));
    }

    @PATCH
    @Path("/{planId}")
    public PlanDtos.Plan update(@PathParam("planId") UUID planId, JsonNode body) {
        PatchBody patch = new PatchBody(body);
        var change = new ManagePlans.PlanChange(patch.required("name", PatchBody.nonBlankText(MAX_NAME)),
                patch.nullable("description", PatchBody.text(MAX_TEXT)));
        return PlanDtos.Plan.from(plans.update(caller(), new PlanId(planId), change));
    }

    @DELETE
    @Path("/{planId}")
    public Response delete(@PathParam("planId") UUID planId) {
        plans.delete(caller(), new PlanId(planId));
        return Response.noContent().build();
    }

    @POST
    @Path("/{planId}:copy")
    public Response copy(@PathParam("planId") UUID planId, @Valid PlanDtos.CopyRequest request) {
        AuthzContext caller = caller();
        var copy = plans.copy(caller, actors.of(caller), new PlanId(planId),
                Optional.ofNullable(request).map(PlanDtos.CopyRequest::name));
        return Response.status(Response.Status.CREATED).entity(PlanDtos.Plan.from(copy)).build();
    }

    /** Custom methods like {@code :copy}; clients send the colon unencoded (libs/contracts README). */
    @POST
    @Path("/{planId}:archive")
    public PlanDtos.Plan archive(@PathParam("planId") UUID planId) {
        return PlanDtos.Plan.from(plans.setArchived(caller(), new PlanId(planId), true));
    }

    @POST
    @Path("/{planId}:unarchive")
    public PlanDtos.Plan unarchive(@PathParam("planId") UUID planId) {
        return PlanDtos.Plan.from(plans.setArchived(caller(), new PlanId(planId), false));
    }

    @POST
    @Path("/{planId}/items")
    public Response addItem(@PathParam("planId") UUID planId, @Valid @NotNull PlanDtos.ItemInput request) {
        var item = plans.addItem(caller(), new PlanId(planId), fields(request));
        return Response.status(Response.Status.CREATED).entity(PlanDtos.Item.from(item)).build();
    }

    @PUT
    @Path("/{planId}/items")
    public List<PlanDtos.Item> reorder(@PathParam("planId") UUID planId, @Valid @NotNull PlanDtos.ReorderRequest request) {
        var order = request.itemIds().stream().map(PlanItemId::new).toList();
        return plans.reorder(caller(), new PlanId(planId), order).stream().map(PlanDtos.Item::from).toList();
    }

    @PATCH
    @Path("/{planId}/items/{itemId}")
    public PlanDtos.Item updateItem(@PathParam("planId") UUID planId, @PathParam("itemId") UUID itemId, JsonNode body) {
        PatchBody patch = new PatchBody(body);
        var change = new ManagePlans.ItemChange(
                patch.required("title", PatchBody.nonBlankText(120)),
                patch.nullable("description", PatchBody.text(MAX_TEXT)),
                patch.nullable("durationMinutes", PatchBody.integer(1, 480)),
                patch.nullable("sets", PatchBody.integer(1, 100)),
                patch.nullable("repetitions", PatchBody.integer(1, 1000)),
                patch.nullable("videoUrl", PatchBody.text(2000)));
        return PlanDtos.Item.from(plans.updateItem(caller(), new PlanId(planId), new PlanItemId(itemId), change));
    }

    @DELETE
    @Path("/{planId}/items/{itemId}")
    public Response deleteItem(@PathParam("planId") UUID planId, @PathParam("itemId") UUID itemId) {
        plans.deleteItem(caller(), new PlanId(planId), new PlanItemId(itemId));
        return Response.noContent().build();
    }

    private static ManagePlans.ItemFields fields(PlanDtos.ItemInput i) {
        return new ManagePlans.ItemFields(i.title(), i.description(), i.durationMinutes(), i.sets(), i.repetitions(),
                i.videoUrl());
    }

    private AuthzContext caller() {
        return tenant.requireAuthz();
    }
}
