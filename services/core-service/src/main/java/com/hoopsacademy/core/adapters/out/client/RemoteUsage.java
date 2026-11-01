package com.hoopsacademy.core.adapters.out.client;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.RemoteUsagePort;
import com.hoopsacademy.core.application.port.UsageReport;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import org.jboss.logging.Logger;

/** Calls one service's {@code /internal/usage}; any failure or timeout counts as "unavailable". */
class RemoteUsage implements RemoteUsagePort {

    private static final Logger LOG = Logger.getLogger(RemoteUsage.class);

    private final String service;
    private final Function<UUID, UsageReportDto> client;

    RemoteUsage(String service, Function<UUID, UsageReportDto> client) {
        this.service = service;
        this.client = client;
    }

    @Override
    public String service() {
        return service;
    }

    @Override
    public Optional<UsageReport> fetch(TenantId tenant) {
        try {
            UsageReportDto dto = client.apply(tenant.value());
            return Optional.of(new UsageReport(tenant, service, dto.collectedAt(), dto.lastActivityAt(), dto.counters()));
        } catch (RuntimeException e) {
            LOG.warnf("Usage of %s for tenant %s unavailable: %s", service, tenant, e.getMessage());
            return Optional.empty();
        }
    }
}
