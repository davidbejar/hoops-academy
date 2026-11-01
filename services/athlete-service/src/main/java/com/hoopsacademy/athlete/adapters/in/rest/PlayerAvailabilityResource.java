package com.hoopsacademy.athlete.adapters.in.rest;

import com.hoopsacademy.athlete.application.ManageInjuries;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.UUID;

/** Whether a player can train / play today. Not yet part of libs/contracts/openapi/athlete.yaml (see the WP10 handover). */
@Path("/api/athlete/players/{playerId}/availability")
@Produces(MediaType.APPLICATION_JSON)
@RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH, TenantRole.ASSISTANT_COACH, TenantRole.PARENT, TenantRole.PLAYER})
public class PlayerAvailabilityResource {

    private final ManageInjuries injuries;
    private final TenantContext tenant;

    PlayerAvailabilityResource(ManageInjuries injuries, TenantContext tenant) {
        this.injuries = injuries;
        this.tenant = tenant;
    }

    @GET
    public HealthDtos.AvailabilityResponse get(@PathParam("playerId") UUID playerId) {
        return HealthDtos.AvailabilityResponse.from(injuries.availability(tenant.requireAuthz(), new PlayerId(playerId)));
    }
}
