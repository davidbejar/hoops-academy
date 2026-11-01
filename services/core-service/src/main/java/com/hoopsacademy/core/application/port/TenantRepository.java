package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.tenant.Tenant;
import com.hoopsacademy.core.domain.tenant.TenantSlug;
import com.hoopsacademy.core.domain.tenant.TenantStatus;
import java.util.Optional;

/** The tenant registry as the platform role sees it (platform datasource, all tenants, no tenant content). */
public interface TenantRepository {

    boolean slugExists(TenantSlug slug);

    /** @throws com.hoopsacademy.common.problem.ConflictException {@code SLUG_TAKEN} on a concurrent duplicate */
    void insert(Tenant tenant);

    void update(Tenant tenant);

    Optional<Tenant> find(TenantId id);

    PageResult<Tenant> list(Optional<TenantStatus> status, Optional<String> query, PageRequest page);

    /** Ids of the tenants registered in {@code [from, to)} (onboarding repair). */
    java.util.List<TenantId> createdBetween(java.time.Instant from, java.time.Instant to);

    /** Compensation of a failed onboarding; impossible once the tenant's settings exist (FK). */
    void deleteUnprovisioned(TenantId id);
}
