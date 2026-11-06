package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.ContentLocale;
import com.hoopsacademy.athlete.domain.PlanId;
import com.hoopsacademy.athlete.domain.TrainingPlan;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

/** Plans visible to the current tenant: its own plans and the global templates (which can never be written). */
public interface PlanRepository {

    /**
     * Query for the plan list, ordered by name; {@code query} is a case-insensitive part of the name. For templates
     * both use the name in {@code language} (else in {@link ContentLocale#FALLBACK}, else the own name), the name the
     * caller is shown.
     */
    record Search(boolean templates, boolean includeArchived, Optional<String> query, ContentLocale language, int page,
            int size) {}

    /** Inserts or updates a tenant plan together with its items (never a name key or translations). */
    void save(TrainingPlan plan);

    /** A plan as stored: a template with its name key and translations. */
    Optional<TrainingPlan> find(PlanId id);

    List<TrainingPlan> findAll(Collection<PlanId> ids);

    PageResult<TrainingPlan> search(Search search);

    void delete(PlanId id);

    /** Number of tenant plans (templates excluded). */
    long countTenantPlans();
}
