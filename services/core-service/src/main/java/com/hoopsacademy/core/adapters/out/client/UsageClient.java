package com.hoopsacademy.core.adapters.out.client;

import com.hoopsacademy.core.adapters.in.internal.UsageReportDto;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import java.util.UUID;

/**
 * {@code GET /internal/usage/{tenantId}} of a downstream service (the shared {@code UsageReport} schema, whose wire
 * record core's own internal endpoint already declares). One sub-interface per service carries its config key and
 * the service-token filter (Quarkus reads neither annotation from a super-interface).
 */
@Path("/internal/usage")
public interface UsageClient {

    @GET
    @Path("/{tenantId}")
    UsageReportDto usage(@PathParam("tenantId") UUID tenantId);
}
