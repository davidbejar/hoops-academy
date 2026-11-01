package com.hoopsacademy.core.adapters.out.platform;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.TenantRepository;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.tenant.Tenant;
import com.hoopsacademy.core.domain.tenant.TenantSlug;
import com.hoopsacademy.core.domain.tenant.TenantStatus;
import io.quarkus.hibernate.orm.PersistenceUnit;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceException;
import jakarta.persistence.TypedQuery;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

@ApplicationScoped
class PlatformTenantRepository implements TenantRepository {

    private final EntityManager em;

    PlatformTenantRepository(@PersistenceUnit("platform") EntityManager em) {
        this.em = em;
    }

    @Override
    public boolean slugExists(TenantSlug slug) {
        return em.createQuery("select count(t) from PlatformTenantEntity t where t.slug = :slug", Long.class)
                .setParameter("slug", slug.value()).getSingleResult() > 0;
    }

    @Override
    public void insert(Tenant tenant) {
        PlatformTenantEntity row = new PlatformTenantEntity();
        row.id = tenant.id().value();
        row.slug = tenant.slug().value();
        row.createdAt = tenant.createdAt();
        copy(tenant, row);
        em.persist(row);
        try {
            em.flush();
        } catch (PersistenceException e) {
            throw new ConflictException("Slug '" + tenant.slug() + "' is already taken", "SLUG_TAKEN");
        }
    }

    @Override
    public void update(Tenant tenant) {
        copy(tenant, em.find(PlatformTenantEntity.class, tenant.id().value()));
    }

    @Override
    public Optional<Tenant> find(TenantId id) {
        return Optional.ofNullable(em.find(PlatformTenantEntity.class, id.value())).map(PlatformTenantRepository::toDomain);
    }

    @Override
    public PageResult<Tenant> list(Optional<TenantStatus> status, Optional<String> query, PageRequest page) {
        List<String> conditions = new ArrayList<>();
        Map<String, Object> parameters = new HashMap<>();
        status.ifPresent(s -> {
            conditions.add("t.status = :status");
            parameters.put("status", s.name());
        });
        query.ifPresent(q -> {
            conditions.add("(lower(t.name) like :q escape '\\' or t.slug like :q escape '\\')");
            parameters.put("q", "%" + q.toLowerCase(Locale.ROOT).replace("\\", "\\\\").replace("%", "\\%")
                    .replace("_", "\\_") + "%");
        });
        String where = conditions.isEmpty() ? "" : " where " + String.join(" and ", conditions);
        TypedQuery<PlatformTenantEntity> items = em.createQuery(
                "select t from PlatformTenantEntity t" + where + " order by t.createdAt desc, t.id",
                PlatformTenantEntity.class);
        TypedQuery<Long> total = em.createQuery("select count(t) from PlatformTenantEntity t" + where, Long.class);
        parameters.forEach((name, value) -> {
            items.setParameter(name, value);
            total.setParameter(name, value);
        });
        return new PageResult<>(items.setFirstResult(page.offset()).setMaxResults(page.size()).getResultStream()
                .map(PlatformTenantRepository::toDomain).toList(), page, total.getSingleResult());
    }

    @Override
    public java.util.List<TenantId> createdBetween(java.time.Instant from, java.time.Instant to) {
        return em.createQuery("select t.id from PlatformTenantEntity t where t.createdAt >= :from and t.createdAt < :to"
                        + " order by t.createdAt", java.util.UUID.class)
                .setParameter("from", from).setParameter("to", to)
                .getResultStream().map(TenantId::new).toList();
    }

    @Override
    public void deleteUnprovisioned(TenantId id) {
        em.createQuery("delete from PlatformTenantEntity t where t.id = :id").setParameter("id", id.value())
                .executeUpdate();
    }

    private static void copy(Tenant tenant, PlatformTenantEntity row) {
        row.name = tenant.name();
        row.status = tenant.status().name();
        row.statusReason = tenant.statusReason();
        row.timezone = tenant.timezone().getId();
        row.defaultLocale = tenant.defaultLocale().code();
        row.suspendedAt = tenant.suspendedAt();
        row.withdrawnAt = tenant.withdrawnAt();
        row.retainUntil = tenant.retainUntil();
    }

    private static Tenant toDomain(PlatformTenantEntity row) {
        return new Tenant(new TenantId(row.id), TenantSlug.of(row.slug), row.name, TenantStatus.valueOf(row.status),
                row.statusReason, ZoneId.of(row.timezone), AppLocale.fromCode(row.defaultLocale), row.createdAt,
                row.suspendedAt, row.withdrawnAt, row.retainUntil);
    }
}
