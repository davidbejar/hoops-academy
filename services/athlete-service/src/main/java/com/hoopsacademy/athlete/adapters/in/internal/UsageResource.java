package com.hoopsacademy.athlete.adapters.in.internal;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.hoopsacademy.athlete.application.ReportUsage;
import com.hoopsacademy.common.tenancy.TenantId;
import jakarta.annotation.security.RolesAllowed;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/** Service-to-service usage counters ({@code /internal/usage/{tenantId}}); callers need the {@code service} role. */
@Path("/internal/usage/{tenantId}")
@Produces(MediaType.APPLICATION_JSON)
@RolesAllowed("service")
public class UsageResource {

    private final ReportUsage usage;

    UsageResource(ReportUsage usage) {
        this.usage = usage;
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record UsageReportDto(UUID tenantId, String service, Instant collectedAt, Map<String, Long> counters) {}

    @GET
    public UsageReportDto get(@PathParam("tenantId") String tenantId) {
        ReportUsage.Usage report = usage.forTenant(TenantId.parse(tenantId));
        return new UsageReportDto(report.tenantId().value(), "athlete", report.collectedAt(), report.counters());
    }
}
