package com.hoopsacademy.core.adapters.in.platform;

import com.hoopsacademy.core.adapters.in.internal.UsageReportDto;
import com.hoopsacademy.core.application.usage.TenantUsage;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Contract {@code TenantUsage}. */
public record TenantUsageDto(UUID tenantId, Instant collectedAt, List<UsageReportDto> services,
        List<String> unavailableServices) {

    static TenantUsageDto of(TenantUsage usage) {
        return new TenantUsageDto(usage.tenantId().value(), usage.collectedAt(),
                usage.services().stream().map(UsageReportDto::of).toList(), usage.unavailableServices());
    }
}
