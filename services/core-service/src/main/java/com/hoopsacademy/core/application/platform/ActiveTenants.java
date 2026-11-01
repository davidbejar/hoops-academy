package com.hoopsacademy.core.application.platform;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.TenantRepository;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.tenant.Tenant;
import com.hoopsacademy.core.domain.tenant.TenantStatus;
import io.quarkus.narayana.jta.QuarkusTransaction;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/** Ids of every ACTIVE tenant, read page by page through the platform datasource (for the scheduled jobs). */
@ApplicationScoped
public class ActiveTenants {

    private static final int PAGE_SIZE = 200;

    private final TenantRepository registry;

    public ActiveTenants(TenantRepository registry) {
        this.registry = registry;
    }

    public List<TenantId> list() {
        List<TenantId> ids = new ArrayList<>();
        PageResult<Tenant> page;
        int number = 0;
        do {
            PageRequest request = new PageRequest(number++, PAGE_SIZE);
            page = QuarkusTransaction.requiringNew().call(
                    () -> registry.list(Optional.of(TenantStatus.ACTIVE), Optional.empty(), request));
            page.items().forEach(tenant -> ids.add(tenant.id()));
        } while (number < page.totalPages());
        return ids;
    }
}
