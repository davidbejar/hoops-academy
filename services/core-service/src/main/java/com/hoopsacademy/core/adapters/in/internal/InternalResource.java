package com.hoopsacademy.core.adapters.in.internal;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.authz.InternalAuthz;
import com.hoopsacademy.core.application.usage.CoreUsage;
import jakarta.annotation.security.RolesAllowed;
import jakarta.validation.constraints.Size;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.UUID;

/**
 * Service-to-service API (client-credentials token with realm role {@code service}; blocked at the proxy).
 * WP4 adds {@code /internal/teams/{teamId}/roster} and {@code /internal/players:batch} next to these.
 */
@Path("/internal")
@RolesAllowed("service")
@Produces(MediaType.APPLICATION_JSON)
public class InternalResource {

    private final InternalAuthz authz;
    private final CoreUsage usage;

    public InternalResource(InternalAuthz authz, CoreUsage usage) {
        this.authz = authz;
        this.usage = usage;
    }

    @GET
    @Path("/authz/{tenantId}/{sub}")
    public AuthzContextDto authzContext(@PathParam("tenantId") UUID tenantId,
            @PathParam("sub") @Size(min = 1, max = 255) String subject) {
        return AuthzContextDto.of(authz.of(new TenantId(tenantId), subject));
    }

    @GET
    @Path("/usage/{tenantId}")
    public UsageReportDto usage(@PathParam("tenantId") UUID tenantId) {
        return UsageReportDto.of(usage.of(new TenantId(tenantId)));
    }
}
