package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.TenantProfileRepository;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.tenant.TenantProfile;
import com.hoopsacademy.core.domain.tenant.TenantStatus;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.time.ZoneId;
import java.util.Optional;

@ApplicationScoped
class JpaTenantProfileRepository implements TenantProfileRepository {

    private final EntityManager em;
    private final BoundTenant boundTenant;

    JpaTenantProfileRepository(EntityManager em, BoundTenant boundTenant) {
        this.em = em;
        this.boundTenant = boundTenant;
    }

    @Override
    public Optional<TenantProfile> findCurrent() {
        return Optional.ofNullable(em.find(TenantRowEntity.class, boundTenant.id())).map(JpaTenantProfileRepository::toDomain);
    }

    @Override
    public void save(TenantProfile profile) {
        TenantRowEntity row = em.find(TenantRowEntity.class, profile.id().value());
        row.name = profile.name();
        row.timezone = profile.timezone().getId();
        row.defaultLocale = profile.defaultLocale().code();
        row.contactEmail = profile.contactEmail();
        row.websiteUrl = profile.websiteUrl();
    }

    private static TenantProfile toDomain(TenantRowEntity row) {
        return new TenantProfile(new TenantId(row.id), row.slug, row.name, ZoneId.of(row.timezone),
                AppLocale.fromCode(row.defaultLocale), row.contactEmail, row.websiteUrl, TenantStatus.valueOf(row.status));
    }
}
