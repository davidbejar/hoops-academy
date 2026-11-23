package com.hoopsacademy.common.tenancy;

import io.quarkus.security.Authenticated;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;

/**
 * A test-only /platform endpoint, rooted at its own path like core's platform resources: under a class at {@code /} the
 * route template OpenTelemetry records (and the security events name) would read {@code //platform/probe/ping}.
 */
@Path("/platform/probe/ping")
public class PlatformProbeResource {

    @Inject
    TenantContext tenantContext;

    @GET
    @Authenticated
    public String platformPing() {
        return "tenant-bound=" + tenantContext.tenantId().isPresent();
    }
}
