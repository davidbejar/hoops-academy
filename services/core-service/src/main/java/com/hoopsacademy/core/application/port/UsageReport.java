package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.tenancy.TenantId;
import java.time.Instant;
import java.util.Map;

/** Usage counters of one service for one tenant (contract {@code UsageReport}). */
public record UsageReport(TenantId tenantId, String service, Instant collectedAt, Instant lastActivityAt,
        Map<String, Long> counters) {

    public UsageReport {
        counters = Map.copyOf(counters);
    }
}
