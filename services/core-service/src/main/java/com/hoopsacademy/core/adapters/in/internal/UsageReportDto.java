package com.hoopsacademy.core.adapters.in.internal;

import com.hoopsacademy.core.application.port.UsageReport;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/** Contract {@code UsageReport}. */
public record UsageReportDto(UUID tenantId, String service, Instant collectedAt, Instant lastActivityAt,
        Map<String, Long> counters) {

    public static UsageReportDto of(UsageReport report) {
        return new UsageReportDto(report.tenantId().value(), report.service(), report.collectedAt(),
                report.lastActivityAt(), report.counters());
    }
}
