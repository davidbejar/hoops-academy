package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.core.application.port.TenantSettingsRepository;
import com.hoopsacademy.core.domain.tenant.AgeRule;
import com.hoopsacademy.core.domain.tenant.TenantSettings;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.time.Clock;
import java.util.Optional;

@ApplicationScoped
class JpaTenantSettingsRepository implements TenantSettingsRepository {

    private final EntityManager em;
    private final BoundTenant boundTenant;
    private final Clock clock;

    JpaTenantSettingsRepository(EntityManager em, BoundTenant boundTenant, Clock clock) {
        this.em = em;
        this.boundTenant = boundTenant;
        this.clock = clock;
    }

    @Override
    public void create(TenantSettings settings) {
        TenantSettingsEntity row = new TenantSettingsEntity();
        row.id = boundTenant.id();
        copy(settings, row);
        em.persist(row);
    }

    @Override
    public Optional<TenantSettings> findCurrent() {
        return Optional.ofNullable(em.find(TenantSettingsEntity.class, boundTenant.id()))
                .map(row -> new TenantSettings(AgeRule.valueOf(row.ageRule), row.maxPlayUpLevels,
                        row.attendanceLateThresholdMinutes));
    }

    @Override
    public void save(TenantSettings settings) {
        copy(settings, em.find(TenantSettingsEntity.class, boundTenant.id()));
    }

    private void copy(TenantSettings settings, TenantSettingsEntity row) {
        row.ageRule = settings.ageRule().name();
        row.maxPlayUpLevels = settings.maxPlayUpLevels();
        row.attendanceLateThresholdMinutes = settings.attendanceLateThresholdMinutes();
        row.updatedAt = clock.instant();
    }
}
