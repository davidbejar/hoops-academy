package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.athlete.application.PageResult;
import com.hoopsacademy.athlete.application.PlanRepository;
import com.hoopsacademy.athlete.domain.Actor;
import com.hoopsacademy.athlete.domain.ContentLocale;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlanId;
import com.hoopsacademy.athlete.domain.PlanItem;
import com.hoopsacademy.athlete.domain.PlanItemId;
import com.hoopsacademy.athlete.domain.SessionId;
import com.hoopsacademy.athlete.domain.TrainingPlan;
import com.hoopsacademy.common.tenancy.CurrentTenant;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@ApplicationScoped
class PlanJpaRepository implements PlanRepository {

    private final EntityManager em;
    private final CurrentTenant currentTenant;

    PlanJpaRepository(EntityManager em, CurrentTenant currentTenant) {
        this.em = em;
        this.currentTenant = currentTenant;
    }

    @Override
    public void save(TrainingPlan plan) {
        UUID owner = currentTenant.tenantId().orElseThrow(() -> new IllegalStateException("No tenant bound")).value();
        PlanEntity entity = em.find(PlanEntity.class, plan.id().value());
        if (entity == null) {
            entity = new PlanEntity();
            entity.id = plan.id().value();
            entity.ownerTenantId = owner;
            entity.template = plan.template();
            entity.createdAt = plan.createdAt();
            entity.authorPersonId = plan.author().map(a -> a.personId().value()).orElse(null);
            entity.authorName = plan.author().map(Actor::displayName).orElse(null);
            entity.sourcePlanId = plan.sourcePlanId().map(PlanId::value).orElse(null);
            entity.sessionId = plan.session().map(SessionId::value).orElse(null);
        }
        entity.name = plan.name();
        entity.description = plan.description();
        entity.locale = plan.locale();
        entity.archived = plan.archived();
        entity.updatedAt = plan.updatedAt();
        em.persist(entity);
        syncItems(plan, owner);
    }

    private void syncItems(TrainingPlan plan, UUID owner) {
        Map<UUID, PlanItemEntity> existing = itemsOf(List.of(plan.id().value())).stream()
                .collect(Collectors.toMap(i -> i.id, i -> i));
        List<UUID> kept = new ArrayList<>();
        for (PlanItem item : plan.items()) {
            PlanItemEntity entity = existing.get(item.id().value());
            if (entity == null) {
                entity = new PlanItemEntity();
                entity.id = item.id().value();
                entity.planId = plan.id().value();
                entity.ownerTenantId = owner;
            }
            entity.position = item.position();
            entity.title = item.title();
            entity.description = item.description();
            entity.durationMinutes = item.durationMinutes();
            entity.sets = item.sets();
            entity.repetitions = item.repetitions();
            entity.videoUrl = item.videoUrl();
            em.persist(entity);
            kept.add(entity.id);
        }
        existing.values().stream().filter(e -> !kept.contains(e.id)).forEach(em::remove);
    }

    @Override
    public Optional<TrainingPlan> find(PlanId id) {
        return Optional.ofNullable(em.find(PlanEntity.class, id.value())).map(e -> toDomain(e, itemsOf(List.of(e.id))));
    }

    @Override
    public List<TrainingPlan> findAll(Collection<PlanId> ids) {
        if (ids.isEmpty()) {
            return List.of();
        }
        List<PlanEntity> entities = em.createQuery("select p from PlanEntity p where p.id in :ids order by p.name, p.id",
                PlanEntity.class).setParameter("ids", ids.stream().map(PlanId::value).toList()).getResultList();
        return withItems(entities);
    }

    /**
     * The name a caller reading {@code :language} is shown: the translation, else the English one, else the own name.
     * Equivalent to {@code TrainingPlan.localized} because V4 keeps a template's own language out of its i18n.
     */
    private static final String SHOWN_NAME = "coalesce("
            + "cast(function('jsonb_extract_path_text', p.i18n, :language, 'name') as String), "
            + "cast(function('jsonb_extract_path_text', p.i18n, '" + ContentLocale.FALLBACK.code() + "', 'name') as String), "
            + "p.name)";

    /** The title of an item {@code i} as shown for {@code :language}, by the same rule as {@link #SHOWN_NAME}. */
    private static final String SHOWN_TITLE = "coalesce("
            + "cast(function('jsonb_extract_path_text', i.i18n, :language, 'title') as String), "
            + "cast(function('jsonb_extract_path_text', i.i18n, '" + ContentLocale.FALLBACK.code() + "', 'title') as String), "
            + "i.title)";

    /**
     * Ad-hoc session plans are never listed. {@code q} matches the shown name or the shown title of an item; without a
     * trigram index (the migrator may not create extensions, ADR-0041) the item side is a correlated EXISTS over
     * {@code plan_item_plan_idx}, fine for the few hundred plans of an academy and the ten templates.
     */
    @Override
    public PageResult<TrainingPlan> search(Search search) {
        StringBuilder where = new StringBuilder(search.templates() ? " where p.ownerTenantId is null"
                : " where p.ownerTenantId is not null and p.sessionId is null");
        if (!search.includeArchived()) {
            where.append(" and p.archived = false");
        }
        search.query().ifPresent(q -> where.append(" and (lower(" + SHOWN_NAME + ") like :q escape '\\'"
                + " or exists (select i.id from PlanItemEntity i where i.planId = p.id"
                + " and lower(" + SHOWN_TITLE + ") like :q escape '\\'))"));
        var select = em.createQuery("select p from PlanEntity p" + where + " order by " + SHOWN_NAME + ", p.id",
                PlanEntity.class).setParameter("language", search.language().code());
        var count = em.createQuery("select count(p) from PlanEntity p" + where, Long.class);
        search.query().ifPresent(q -> {
            String pattern = "%" + q.toLowerCase().replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%";
            select.setParameter("q", pattern);
            count.setParameter("q", pattern).setParameter("language", search.language().code());
        });
        List<PlanEntity> page = select.setFirstResult(search.page() * search.size()).setMaxResults(search.size())
                .getResultList();
        return new PageResult<>(withItems(page), search.page(), search.size(), count.getSingleResult());
    }

    @Override
    public void delete(PlanId id) {
        PlanEntity entity = em.find(PlanEntity.class, id.value());
        if (entity != null) {
            itemsOf(List.of(id.value())).forEach(em::remove);
            em.flush();
            em.remove(entity);
        }
    }

    @Override
    public long countTenantPlans() {
        return em.createQuery("select count(p) from PlanEntity p where p.ownerTenantId is not null", Long.class)
                .getSingleResult();
    }

    private List<TrainingPlan> withItems(List<PlanEntity> entities) {
        if (entities.isEmpty()) {
            return List.of();
        }
        Map<UUID, List<PlanItemEntity>> items = itemsOf(entities.stream().map(e -> e.id).toList()).stream()
                .collect(Collectors.groupingBy(i -> i.planId, HashMap::new, Collectors.toList()));
        return entities.stream().map(e -> toDomain(e, items.getOrDefault(e.id, List.of()))).toList();
    }

    private List<PlanItemEntity> itemsOf(Collection<UUID> planIds) {
        return em.createQuery("select i from PlanItemEntity i where i.planId in :ids order by i.planId, i.position",
                PlanItemEntity.class).setParameter("ids", planIds).getResultList();
    }

    private static TrainingPlan toDomain(PlanEntity e, List<PlanItemEntity> items) {
        Actor author = e.authorPersonId == null ? null
                : new Actor(new PersonId(e.authorPersonId), e.authorName == null ? "Member" : e.authorName);
        return new TrainingPlan(new PlanId(e.id), e.nameKey, e.name, e.description, author, e.template, e.locale,
                TemplateTextsJson.read(e.i18n, "name"), e.archived,
                e.sourcePlanId == null ? null : new PlanId(e.sourcePlanId),
                e.sessionId == null ? null : new SessionId(e.sessionId),
                items.stream().sorted(java.util.Comparator.comparingInt(i -> i.position))
                        .map(i -> new PlanItem(new PlanItemId(i.id), i.position, i.title, i.description,
                                i.durationMinutes, i.sets, i.repetitions, i.videoUrl,
                                TemplateTextsJson.read(i.i18n, "title"))).toList(),
                e.createdAt, e.updatedAt);
    }
}
