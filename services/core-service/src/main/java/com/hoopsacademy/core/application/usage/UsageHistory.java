package com.hoopsacademy.core.application.usage;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.platform.PlatformTenantQueries;
import com.hoopsacademy.core.application.port.UsageSnapshotRepository;
import com.hoopsacademy.core.application.port.UsageSnapshotRepository.DailySnapshot;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.LocalDate;
import java.util.List;

/** {@code GET /platform/tenants/{id}/usage/history}: the stored daily snapshots of an existing tenant. */
@ApplicationScoped
public class UsageHistory {

    /** Inclusive range in UTC days. */
    public record Range(LocalDate from, LocalDate to) {}

    public record History(TenantId tenantId, Range range, List<DailySnapshot> snapshots) {}

    private final PlatformTenantQueries tenants;
    private final UsageSnapshotRepository snapshots;

    public UsageHistory(PlatformTenantQueries tenants, UsageSnapshotRepository snapshots) {
        this.tenants = tenants;
        this.snapshots = snapshots;
    }

    @Transactional
    public History of(TenantId tenant, Range range) {
        tenants.get(tenant);
        return new History(tenant, range, snapshots.history(tenant, range.from(), range.to()));
    }
}
