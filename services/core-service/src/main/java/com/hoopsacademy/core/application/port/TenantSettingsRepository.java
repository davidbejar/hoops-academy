package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.domain.tenant.TenantSettings;
import java.util.Optional;

/** Settings of the bound tenant. */
public interface TenantSettingsRepository {

    void create(TenantSettings settings);

    Optional<TenantSettings> findCurrent();

    void save(TenantSettings settings);
}
