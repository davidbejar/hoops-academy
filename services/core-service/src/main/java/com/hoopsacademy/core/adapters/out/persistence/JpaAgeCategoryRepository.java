package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.core.application.port.AgeCategoryRepository;
import com.hoopsacademy.core.domain.roster.AgeCategory;
import com.hoopsacademy.core.domain.roster.AgeCategoryId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.List;
import java.util.Optional;

@ApplicationScoped
class JpaAgeCategoryRepository implements AgeCategoryRepository {

    private static final String TAKEN = "AGE_CATEGORY_TAKEN";

    private final EntityManager em;

    JpaAgeCategoryRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public void insert(AgeCategory category) {
        AgeCategoryEntity row = new AgeCategoryEntity();
        row.id = category.id().value();
        copy(category, row);
        em.persist(row);
        ConstraintConflicts.flush(em, TAKEN, "Code or rank already used");
    }

    @Override
    public void update(AgeCategory category) {
        copy(category, em.find(AgeCategoryEntity.class, category.id().value()));
        ConstraintConflicts.flush(em, TAKEN, "Code or rank already used");
    }

    @Override
    public void delete(AgeCategoryId id) {
        em.createQuery("delete from AgeCategoryEntity c where c.id = :id").setParameter("id", id.value()).executeUpdate();
    }

    @Override
    public Optional<AgeCategory> find(AgeCategoryId id) {
        return em.createQuery("select c from AgeCategoryEntity c where c.id = :id", AgeCategoryEntity.class)
                .setParameter("id", id.value()).getResultStream().findFirst().map(JpaAgeCategoryRepository::toDomain);
    }

    @Override
    public List<AgeCategory> listByRank() {
        return em.createQuery("select c from AgeCategoryEntity c order by c.sortRank", AgeCategoryEntity.class)
                .getResultStream().map(JpaAgeCategoryRepository::toDomain).toList();
    }

    private static void copy(AgeCategory category, AgeCategoryEntity row) {
        row.code = category.code();
        row.name = category.name();
        row.maxAge = category.maxAge();
        row.sortRank = category.rank();
    }

    private static AgeCategory toDomain(AgeCategoryEntity row) {
        return new AgeCategory(new AgeCategoryId(row.id), row.code, row.name, row.maxAge, row.sortRank);
    }
}
