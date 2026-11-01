package com.hoopsacademy.core.adapters.in.platform;

import com.hoopsacademy.core.adapters.in.internal.UsageReportDto;
import com.hoopsacademy.core.application.port.UsageSnapshotRepository.DailySnapshot;
import com.hoopsacademy.core.application.usage.UsageHistory;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Contract {@code TenantUsageHistory} (+ {@code TenantUsageSnapshot}). */
public record TenantUsageHistoryDto(UUID tenantId, LocalDate from, LocalDate to, List<SnapshotDto> snapshots) {

    public record SnapshotDto(LocalDate date, Instant collectedAt, List<UsageReportDto> services,
            List<String> unavailableServices) {

        static SnapshotDto of(DailySnapshot snapshot) {
            return new SnapshotDto(snapshot.date(), snapshot.usage().collectedAt(),
                    snapshot.usage().services().stream().map(UsageReportDto::of).toList(),
                    snapshot.usage().unavailableServices());
        }
    }

    static TenantUsageHistoryDto of(UsageHistory.History history) {
        return new TenantUsageHistoryDto(history.tenantId().value(), history.range().from(), history.range().to(),
                history.snapshots().stream().map(SnapshotDto::of).toList());
    }
}
