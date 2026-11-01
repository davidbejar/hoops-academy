package com.hoopsacademy.core.application.usage;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.UsageReport;
import java.time.Instant;
import java.util.List;

/** Usage of a tenant across all services; services that did not answer are listed instead of failing. */
public record TenantUsage(TenantId tenantId, Instant collectedAt, List<UsageReport> services,
        List<String> unavailableServices) {

    public TenantUsage {
        services = List.copyOf(services);
        unavailableServices = List.copyOf(unavailableServices);
    }
}
