package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.PlanId;
import com.hoopsacademy.athlete.domain.TrainingPlan;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

/** Plans visible to the current tenant: its own plans and the global templates (which can never be written). */
public interface PlanRepository {

    /** Query for the plan list; {@code query} is a case-insensitive part of the name. */
    record Search(boolean templates, boolean includeArchived, Optional<String> query, int page, int size) {}

    /** Inserts or updates a tenant plan together with its items. */
    void save(TrainingPlan plan);

    Optional<TrainingPlan> find(PlanId id);

    List<TrainingPlan> findAll(Collection<PlanId> ids);

    boolean exists(PlanId id);

    PageResult<TrainingPlan> search(Search search);

    void delete(PlanId id);

    /** Number of tenant plans (templates excluded). */
    long countTenantPlans();
}
