package com.hoopsacademy.game.adapters.in.internal;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.game.application.GetUsage;
import com.hoopsacademy.game.application.UsageCounter;
import jakarta.annotation.security.RolesAllowed;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.time.Clock;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/** Service-to-service usage report (contract: getGameUsage). Only the realm role {@code service} may call it. */
@Path("/internal/usage/{tenantId}")
@Produces(MediaType.APPLICATION_JSON)
@RolesAllowed("service")
public class UsageResource {

    private final TenantScope tenantScope;
    private final GetUsage getUsage;
    private final Clock clock;

    public UsageResource(TenantScope tenantScope, GetUsage getUsage, Clock clock) {
        this.tenantScope = tenantScope;
        this.getUsage = getUsage;
        this.clock = clock;
    }

    public record UsageReportDto(UUID tenantId, String service, Instant collectedAt, Instant lastActivityAt, Map<String, Long> counters) {}

    @GET
    public UsageReportDto usage(@PathParam("tenantId") String rawTenantId) {
        TenantId tenant = TenantId.parse(rawTenantId);
        UsageCounter.Usage usage = tenantScope.runAs(tenant, getUsage::handle);
        return new UsageReportDto(tenant.value(), "game", clock.instant(), usage.lastActivityAt(), usage.counters());
    }
}
