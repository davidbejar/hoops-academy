package com.hoopsacademy.core.application.usage;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.platform.PlatformTenantQueries;
import com.hoopsacademy.core.application.port.RemoteUsagePort;
import com.hoopsacademy.core.application.port.UsageReport;
import com.hoopsacademy.core.application.port.UsageSnapshotRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Instance;
import jakarta.transaction.Transactional;
import java.time.Clock;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/** {@code GET /platform/tenants/{id}/usage}: core + game + athlete, stored as a usage snapshot. */
@ApplicationScoped
public class AggregateTenantUsage {

    private final PlatformTenantQueries tenants;
    private final CoreUsage coreUsage;
    private final Instance<RemoteUsagePort> remoteServices;
    private final UsageSnapshots snapshots;
    private final Clock clock;

    public AggregateTenantUsage(PlatformTenantQueries tenants, CoreUsage coreUsage,
            Instance<RemoteUsagePort> remoteServices, UsageSnapshots snapshots, Clock clock) {
        this.tenants = tenants;
        this.coreUsage = coreUsage;
        this.remoteServices = remoteServices;
        this.snapshots = snapshots;
        this.clock = clock;
    }

    public TenantUsage of(TenantId tenant) {
        tenants.get(tenant);
        List<UsageReport> reports = new ArrayList<>(List.of(coreUsage.of(tenant)));
        List<String> unavailable = new ArrayList<>();
        for (RemoteUsagePort remote : remoteServices) {
            Optional<UsageReport> report = remote.fetch(tenant);
            report.ifPresentOrElse(reports::add, () -> unavailable.add(remote.service()));
        }
        TenantUsage usage = new TenantUsage(tenant, clock.instant(), reports, unavailable.stream().sorted().toList());
        snapshots.save(usage);
        return usage;
    }

    /** Platform-datasource transaction for the snapshot insert. */
    @ApplicationScoped
    public static class UsageSnapshots {

        private final UsageSnapshotRepository repository;

        public UsageSnapshots(UsageSnapshotRepository repository) {
            this.repository = repository;
        }

        @Transactional
        public void save(TenantUsage usage) {
            repository.save(usage.tenantId(), usage.collectedAt(), usage);
        }
    }
}
