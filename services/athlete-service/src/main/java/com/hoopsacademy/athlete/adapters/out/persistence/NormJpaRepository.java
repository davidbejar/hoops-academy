package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.athlete.application.NormRepository;
import com.hoopsacademy.athlete.domain.Gender;
import com.hoopsacademy.athlete.domain.NormBand;
import com.hoopsacademy.athlete.domain.NormId;
import com.hoopsacademy.athlete.domain.PhysicalTestNorm;
import com.hoopsacademy.athlete.domain.TestTypeId;
import com.hoopsacademy.common.tenancy.CurrentTenant;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

@ApplicationScoped
class NormJpaRepository implements NormRepository {

    private static final String ORDER = " order by n.testTypeId, n.gender, n.minAge, n.id";

    private final EntityManager em;
    private final CurrentTenant currentTenant;

    NormJpaRepository(EntityManager em, CurrentTenant currentTenant) {
        this.em = em;
        this.currentTenant = currentTenant;
    }

    @Override
    public void save(PhysicalTestNorm norm) {
        NormEntity entity = em.find(NormEntity.class, norm.id().value());
        boolean created = entity == null;
        if (created) {
            entity = new NormEntity();
            entity.id = norm.id().value();
            entity.ownerTenantId = currentTenant.tenantId().orElseThrow(() -> new IllegalStateException("No tenant bound")).value();
            entity.createdAt = Instant.now();
        }
        entity.testTypeId = norm.testTypeId().value();
        entity.gender = norm.gender().name();
        entity.minAge = norm.minAge();
        entity.maxAge = norm.maxAge();
        entity.band = norm.band().name();
        entity.minValue = norm.minValue().orElse(null);
        entity.maxValue = norm.maxValue().orElse(null);
        entity.referencePending = norm.referencePending();
        entity.source = norm.source();
        if (created) {
            em.persist(entity);
        }
    }

    @Override
    public Optional<PhysicalTestNorm> find(NormId id) {
        return Optional.ofNullable(em.find(NormEntity.class, id.value())).map(NormJpaRepository::toDomain);
    }

    @Override
    public void delete(NormId id) {
        NormEntity entity = em.find(NormEntity.class, id.value());
        if (entity != null) {
            em.remove(entity);
        }
    }

    @Override
    public List<PhysicalTestNorm> list(Optional<TestTypeId> type, Optional<Gender> gender) {
        String where = " where 1 = 1" + (type.isPresent() ? " and n.testTypeId = :type" : "")
                + (gender.isPresent() ? " and n.gender = :gender" : "");
        var query = em.createQuery("select n from NormEntity n" + where + ORDER, NormEntity.class);
        type.ifPresent(t -> query.setParameter("type", t.value()));
        gender.ifPresent(g -> query.setParameter("gender", g.name()));
        return query.getResultList().stream().map(NormJpaRepository::toDomain).toList();
    }

    @Override
    public List<PhysicalTestNorm> forTypes(Collection<TestTypeId> types) {
        if (types.isEmpty()) {
            return List.of();
        }
        return em.createQuery("select n from NormEntity n where n.testTypeId in :types" + ORDER, NormEntity.class)
                .setParameter("types", types.stream().map(TestTypeId::value).toList()).getResultList().stream()
                .map(NormJpaRepository::toDomain).toList();
    }

    @Override
    public List<PhysicalTestNorm> tenantNorms(TestTypeId type, Gender gender) {
        return em.createQuery("select n from NormEntity n where n.testTypeId = :type and n.gender = :gender "
                        + "and n.ownerTenantId is not null" + ORDER, NormEntity.class)
                .setParameter("type", type.value()).setParameter("gender", gender.name()).getResultList().stream()
                .map(NormJpaRepository::toDomain).toList();
    }

    private static PhysicalTestNorm toDomain(NormEntity e) {
        return PhysicalTestNorm.of(new NormId(e.id), new TestTypeId(e.testTypeId), Gender.valueOf(e.gender), e.minAge, e.maxAge,
                NormBand.valueOf(e.band), e.minValue, e.maxValue, e.referencePending, e.source, e.ownerTenantId == null);
    }
}
