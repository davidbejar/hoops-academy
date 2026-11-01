package com.hoopsacademy.common.client;

import com.hoopsacademy.common.tenancy.CurrentTenant;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.client.ClientRequestContext;
import jakarta.ws.rs.client.ClientRequestFilter;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/**
 * Forwards the bound tenant to downstream services as the tenant header. A header set explicitly by the caller is
 * kept. Register on a REST client with {@code @RegisterProvider(TenantHeaderPropagationFilter.class)}.
 */
@ApplicationScoped
public class TenantHeaderPropagationFilter implements ClientRequestFilter {

    private final CurrentTenant currentTenant;
    private final String tenantHeader;

    public TenantHeaderPropagationFilter(
            CurrentTenant currentTenant,
            @ConfigProperty(name = "hoops.tenancy.header", defaultValue = "X-Tenant-Id") String tenantHeader) {
        this.currentTenant = currentTenant;
        this.tenantHeader = tenantHeader;
    }

    @Override
    public void filter(ClientRequestContext request) {
        if (request.getHeaders().containsKey(tenantHeader)) {
            return;
        }
        currentTenant.tenantId().ifPresent(tenant -> request.getHeaders().putSingle(tenantHeader, tenant.toString()));
    }
}
