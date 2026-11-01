package com.hoopsacademy.core.adapters.out.client;

import com.hoopsacademy.common.client.ServiceTokenClientFilter;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import java.util.UUID;
import org.eclipse.microprofile.rest.client.annotation.RegisterProvider;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

@RegisterRestClient(configKey = "game-usage")
@RegisterProvider(ServiceTokenClientFilter.class)
@Path("/internal/usage")
public interface GameUsageClient {

    @GET
    @Path("/{tenantId}")
    UsageReportDto usage(@PathParam("tenantId") UUID tenantId);
}
