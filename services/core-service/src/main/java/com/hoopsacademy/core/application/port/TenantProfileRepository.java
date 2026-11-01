package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.domain.tenant.TenantProfile;
import java.util.Optional;

/** The bound tenant's own registry row (default datasource; RLS shows exactly that row). */
public interface TenantProfileRepository {

    Optional<TenantProfile> findCurrent();

    void save(TenantProfile profile);
}
