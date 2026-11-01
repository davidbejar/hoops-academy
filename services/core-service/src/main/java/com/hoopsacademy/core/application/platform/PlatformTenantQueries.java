package com.hoopsacademy.core.application.platform;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.TenantRepository;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.tenant.Tenant;
import com.hoopsacademy.core.domain.tenant.TenantStatus;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.Optional;

/** Registry reads for super admins. */
@ApplicationScoped
public class PlatformTenantQueries {

    private final TenantRepository tenants;

    public PlatformTenantQueries(TenantRepository tenants) {
        this.tenants = tenants;
    }

    @Transactional
    public Tenant get(TenantId id) {
        return tenants.find(id).orElseThrow(() -> new NotFoundException("Tenant not found"));
    }

    @Transactional
    public PageResult<Tenant> list(Optional<TenantStatus> status, Optional<String> query, PageRequest page) {
        return tenants.list(status, query, page);
    }
}
