package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.tenancy.TenantId;
import java.time.Instant;

/** Keeps every aggregated usage report (platform datasource) for trends and future billing. */
public interface UsageSnapshotRepository {

    void save(TenantId tenant, Instant collectedAt, Object report);
}
