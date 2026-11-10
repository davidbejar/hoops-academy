package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.athlete.application.ExerciseRepository;
import com.hoopsacademy.athlete.application.PageResult;
import com.hoopsacademy.athlete.domain.ContentLocale;
import com.hoopsacademy.athlete.domain.Exercise;
import com.hoopsacademy.athlete.domain.ExerciseId;
import com.hoopsacademy.common.paging.PageOffset;
import com.hoopsacademy.common.tenancy.CurrentTenant;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.Collection;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

@ApplicationScoped
class ExerciseJpaRepository implements ExerciseRepository {

    /**
     * The title a caller reading {@code :language} is shown: the translation, else the English one, else the own title.
     * Equivalent to {@code Exercise.localized} because V10 keeps a global exercise's own language out of its i18n.
     */
    private static final String SHOWN_TITLE = "coalesce("
            + "cast(function('jsonb_extract_path_text', e.i18n, :language, 'title') as String), "
            + "cast(function('jsonb_extract_path_text', e.i18n, '" + ContentLocale.FALLBACK.code() + "', 'title') as String), "
            + "e.title)";

    private final EntityManager em;
    private final CurrentTenant currentTenant;

    ExerciseJpaRepository(EntityManager em, CurrentTenant currentTenant) {
        this.em = em;
        this.currentTenant = currentTenant;
    }

    @Override
    public void save(Exercise exercise) {
        ExerciseEntity entity = em.find(ExerciseEntity.class, exercise.id().value());
        if (entity == null) {
            entity = new ExerciseEntity();
            entity.id = exercise.id().value();
            entity.ownerTenantId = currentTenant.tenantId().orElseThrow(() -> new IllegalStateException("No tenant bound"))
                    .value();
            entity.createdAt = exercise.createdAt();
        }
        entity.title = exercise.title();
        entity.description = exercise.description();
        entity.durationMinutes = exercise.durationMinutes();
        entity.sets = exercise.sets();
        entity.repetitions = exercise.repetitions();
        entity.videoUrl = exercise.videoUrl();
        entity.locale = exercise.locale();
        entity.archived = exercise.archived();
        entity.updatedAt = exercise.updatedAt();
        em.persist(entity);
    }

    @Override
    public Optional<Exercise> find(ExerciseId id) {
        return Optional.ofNullable(em.find(ExerciseEntity.class, id.value())).map(ExerciseJpaRepository::toDomain);
    }

    @Override
    public List<Exercise> findAll(Collection<ExerciseId> ids) {
        if (ids.isEmpty()) {
            return List.of();
        }
        return em.createQuery("select e from ExerciseEntity e where e.id in :ids", ExerciseEntity.class)
                .setParameter("ids", ids.stream().map(ExerciseId::value).toList()).getResultList().stream()
                .map(ExerciseJpaRepository::toDomain).toList();
    }

    @Override
    public PageResult<Exercise> search(Search search) {
        StringBuilder where = new StringBuilder(" where 1 = 1");
        search.scope().ifPresent(scope -> where.append(scope == Scope.GLOBAL ? " and e.ownerTenantId is null"
                : " and e.ownerTenantId is not null"));
        if (!search.includeArchived()) {
            where.append(" and e.archived = false");
        }
        search.query().ifPresent(q -> where.append(" and lower(" + SHOWN_TITLE + ") like :q escape '\\'"));
        var select = em.createQuery("select e from ExerciseEntity e" + where + " order by " + SHOWN_TITLE + ", e.id",
                ExerciseEntity.class).setParameter("language", search.language().code());
        var count = em.createQuery("select count(e) from ExerciseEntity e" + where, Long.class);
        search.query().ifPresent(q -> {
            String pattern = "%" + q.toLowerCase(Locale.ROOT).replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
                    + "%";
            select.setParameter("q", pattern);
            count.setParameter("q", pattern).setParameter("language", search.language().code());
        });
        List<Exercise> page = select.setFirstResult(PageOffset.of(search.page(), search.size()))
                .setMaxResults(search.size()).getResultList().stream().map(ExerciseJpaRepository::toDomain).toList();
        return new PageResult<>(page, search.page(), search.size(), count.getSingleResult());
    }

    private static Exercise toDomain(ExerciseEntity e) {
        return new Exercise(new ExerciseId(e.id), e.nameKey, e.title, e.description, e.durationMinutes, e.sets,
                e.repetitions, e.videoUrl, e.ownerTenantId == null, e.locale, TemplateTextsJson.read(e.i18n, "title"),
                e.archived, e.createdAt, e.updatedAt);
    }
}
