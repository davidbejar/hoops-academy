package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.tenancy.TenantId;
import java.time.Instant;

/**
 * Keeps one aggregated usage report per tenant and UTC day (platform datasource) for trends and future billing.
 * Saving again on the same day replaces the day's report, except that a report with unavailable services never
 * replaces a complete one.
 */
public interface UsageSnapshotRepository {

    void save(TenantId tenant, Instant collectedAt, Object report);
}
