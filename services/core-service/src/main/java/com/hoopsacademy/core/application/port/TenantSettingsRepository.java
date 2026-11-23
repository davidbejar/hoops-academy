package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.core.domain.tenant.TenantSettings;
import java.util.Optional;

/** Settings of the bound tenant. */
public interface TenantSettingsRepository {

    void create(TenantSettings settings);

    Optional<TenantSettings> findCurrent();

    /** @throws NotFoundException "Tenant settings not found" (404) */
    default TenantSettings requireCurrent() {
        return findCurrent().orElseThrow(() -> new NotFoundException("Tenant settings not found"));
    }

    void save(TenantSettings settings);
}
