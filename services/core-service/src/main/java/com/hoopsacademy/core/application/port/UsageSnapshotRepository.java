package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.usage.TenantUsage;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/**
 * Keeps one aggregated usage report per tenant and UTC day (platform datasource) for trends and future billing.
 * Saving again on the same day replaces the day's report, except that a report with unavailable services never
 * replaces a complete one.
 */
public interface UsageSnapshotRepository {

    void save(TenantId tenant, Instant collectedAt, Object report);

    /** One stored snapshot: its UTC day and the aggregated usage as it was saved. */
    record DailySnapshot(LocalDate date, TenantUsage usage) {}

    /** The tenant's snapshots with {@code from <= date <= to}, ascending by date. */
    List<DailySnapshot> history(TenantId tenant, LocalDate from, LocalDate to);
}
