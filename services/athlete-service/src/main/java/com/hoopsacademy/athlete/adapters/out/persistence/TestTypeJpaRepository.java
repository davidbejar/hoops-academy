package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.athlete.application.TestTypeRepository;
import com.hoopsacademy.athlete.domain.PhysicalTestType;
import com.hoopsacademy.athlete.domain.TestTypeId;
import com.hoopsacademy.common.tenancy.CurrentTenant;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@ApplicationScoped
class TestTypeJpaRepository implements TestTypeRepository {

    private final EntityManager em;
    private final CurrentTenant currentTenant;

    TestTypeJpaRepository(EntityManager em, CurrentTenant currentTenant) {
        this.em = em;
        this.currentTenant = currentTenant;
    }

    @Override
    public void save(PhysicalTestType type) {
        TestTypeEntity entity = em.find(TestTypeEntity.class, type.id().value());
        boolean created = entity == null;
        if (created) {
            entity = new TestTypeEntity();
            entity.id = type.id().value();
            entity.ownerTenantId = currentTenant.tenantId().orElseThrow(() -> new IllegalStateException("No tenant bound")).value();
            entity.createdAt = Instant.now();
        }
        entity.code = type.code();
        entity.name = type.name();
        entity.unit = type.unit();
        entity.higherIsBetter = type.higherIsBetter();
        entity.description = type.description();
        if (created) {
            em.persist(entity);
        }
    }

    @Override
    public Optional<PhysicalTestType> find(TestTypeId id) {
        return Optional.ofNullable(em.find(TestTypeEntity.class, id.value())).map(TestTypeJpaRepository::toDomain);
    }

    @Override
    public Map<TestTypeId, PhysicalTestType> findAll(Collection<TestTypeId> ids) {
        if (ids.isEmpty()) {
            return Map.of();
        }
        List<UUID> raw = ids.stream().map(TestTypeId::value).toList();
        return em.createQuery("select t from TestTypeEntity t where t.id in :ids", TestTypeEntity.class)
                .setParameter("ids", raw).getResultList().stream().map(TestTypeJpaRepository::toDomain)
                .collect(Collectors.toMap(PhysicalTestType::id, t -> t));
    }

    @Override
    public List<PhysicalTestType> list() {
        return em.createQuery("select t from TestTypeEntity t order by t.code", TestTypeEntity.class).getResultList().stream()
                .map(TestTypeJpaRepository::toDomain).toList();
    }

    @Override
    public boolean codeExists(String code) {
        return em.createQuery("select count(t) from TestTypeEntity t where t.code = :code", Long.class)
                .setParameter("code", code).getSingleResult() > 0;
    }

    @Override
    public void delete(TestTypeId id) {
        TestTypeEntity entity = em.find(TestTypeEntity.class, id.value());
        if (entity != null) {
            em.remove(entity);
            em.flush();
        }
    }

    private static PhysicalTestType toDomain(TestTypeEntity e) {
        return new PhysicalTestType(new TestTypeId(e.id), e.code, e.name, e.unit, e.higherIsBetter, e.description,
                e.ownerTenantId == null);
    }
}
