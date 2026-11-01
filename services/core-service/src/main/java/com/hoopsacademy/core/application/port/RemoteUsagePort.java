package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.tenancy.TenantId;
import java.util.Optional;

/** {@code /internal/usage/{tenantId}} of one other service; empty when it does not answer in time. */
public interface RemoteUsagePort {

    String service();

    Optional<UsageReport> fetch(TenantId tenant);
}
