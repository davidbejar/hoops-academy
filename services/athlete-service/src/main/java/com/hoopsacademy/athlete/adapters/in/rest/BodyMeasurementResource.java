package com.hoopsacademy.athlete.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.athlete.application.InvalidRequestException;
import com.hoopsacademy.athlete.application.ManageMeasurements;
import com.hoopsacademy.athlete.domain.BodyMeasurementId;
import com.hoopsacademy.athlete.domain.PlayerId;
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
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Path("/api/athlete/body-measurements")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH, TenantRole.ASSISTANT_COACH, TenantRole.PARENT, TenantRole.PLAYER})
public class BodyMeasurementResource {

    private final ManageMeasurements measurements;
    private final TenantContext tenant;
    private final CallerActor actors;

    BodyMeasurementResource(ManageMeasurements measurements, TenantContext tenant, CallerActor actors) {
        this.measurements = measurements;
        this.tenant = tenant;
        this.actors = actors;
    }

    @GET
    public List<HealthDtos.MeasurementResponse> history(@QueryParam("playerId") String playerId, @QueryParam("from") String from,
            @QueryParam("to") String to) {
        PlayerId player = Requests.uuid("playerId", playerId).map(PlayerId::new)
                .orElseThrow(() -> new InvalidRequestException("playerId", "REQUIRED", "playerId is required"));
        return measurements.history(caller(), player, Requests.date("from", from), Requests.date("to", to)).stream()
                .map(HealthDtos.MeasurementResponse::from).toList();
    }

    @POST
    public Response create(@Valid @NotNull HealthDtos.CreateMeasurementRequest request) {
        AuthzContext caller = caller();
        var created = measurements.create(caller, actors.of(caller), new ManageMeasurements.NewMeasurement(
                new PlayerId(request.playerId()), request.measuredOn(), request.heightCm(), request.weightKg()));
        return Response.status(Response.Status.CREATED).entity(HealthDtos.MeasurementResponse.from(created)).build();
    }

    @PATCH
    @Path("/{measurementId}")
    public HealthDtos.MeasurementResponse update(@PathParam("measurementId") UUID measurementId, JsonNode body) {
        PatchBody patch = new PatchBody(body);
        var change = new ManageMeasurements.MeasurementChange(
                patch.required("measuredOn", PatchBody.fromText(LocalDate::parse, "an ISO date")),
                patch.nullable("heightCm", PatchBody.decimal(50, 250)),
                patch.nullable("weightKg", PatchBody.decimal(10, 250)));
        return HealthDtos.MeasurementResponse.from(measurements.update(caller(), new BodyMeasurementId(measurementId), change));
    }

    @DELETE
    @Path("/{measurementId}")
    public Response delete(@PathParam("measurementId") UUID measurementId) {
        measurements.delete(caller(), new BodyMeasurementId(measurementId));
        return Response.noContent().build();
    }

    private AuthzContext caller() {
        return tenant.requireAuthz();
    }
}
