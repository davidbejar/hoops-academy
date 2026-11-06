package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.Actor;
import com.hoopsacademy.athlete.domain.ContentLocale;
import com.hoopsacademy.athlete.domain.PlanId;
import com.hoopsacademy.athlete.domain.PlanItem;
import com.hoopsacademy.athlete.domain.PlanItemId;
import com.hoopsacademy.athlete.domain.TrainingPlan;
import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.Optional;

/**
 * Training plans and their items. Everybody in the tenant reads plans and the global templates; ADMIN and staff
 * roles write tenant plans. Templates are never edited, they are copied (copy-on-use).
 *
 * <p>Templates are read in the caller's language (decision 43): lists, details and copies resolve their texts for the
 * given {@link ContentLocale}; a copy keeps the texts it was made with. Tenant plans are returned as stored.
 */
@ApplicationScoped
public class ManagePlans {

    public record NewPlan(String name, String description, List<ItemFields> items) {}

    /** Item content as given by a client (also the merged result of a partial change). */
    public record ItemFields(String title, String description, Integer durationMinutes, Integer sets,
            Integer repetitions, String videoUrl) {

        PlanItem toDraft() {
            return PlanItem.draft(title, description, durationMinutes, sets, repetitions, videoUrl);
        }
    }

    /** A partial plan change: {@code Optional.empty()} = untouched, a present optional holding null = clear. */
    public record PlanChange(Optional<String> name, Optional<Optional<String>> description) {}

    /** A partial item change, same convention as {@link PlanChange}. */
    public record ItemChange(Optional<String> title, Optional<Optional<String>> description,
            Optional<Optional<Integer>> durationMinutes, Optional<Optional<Integer>> sets,
            Optional<Optional<Integer>> repetitions, Optional<Optional<String>> videoUrl) {}

    private final PlanRepository plans;
    private final AssignmentRepository assignments;
    private final PlanAccess access;
    private final TenantClock clock;

    public ManagePlans(PlanRepository plans, AssignmentRepository assignments, PlanAccess access, TenantClock clock) {
        this.plans = plans;
        this.assignments = assignments;
        this.access = access;
        this.clock = clock;
    }

    @Transactional
    public PageResult<TrainingPlan> list(boolean templates, Optional<String> query, ContentLocale language, int page,
            int size) {
        return plans.search(new PlanRepository.Search(templates, false, query, language, page, size))
                .map(plan -> plan.localized(language));
    }

    @Transactional
    public TrainingPlan get(PlanId id, ContentLocale language) {
        return load(id).localized(language);
    }

    @Transactional
    public TrainingPlan create(AuthzContext caller, Actor actor, NewPlan request) {
        access.requireStaffRole(caller);
        List<PlanItem> items = request.items().stream().map(ItemFields::toDraft).toList();
        TrainingPlan plan = TrainingPlan.create(request.name(), request.description(), actor, items, clock.now());
        plans.save(plan);
        return plan;
    }

    @Transactional
    public TrainingPlan copy(AuthzContext caller, Actor actor, PlanId source, Optional<String> name,
            ContentLocale language) {
        access.requireStaffRole(caller);
        TrainingPlan copy = load(source).localized(language).copiedBy(actor, name, clock.now());
        plans.save(copy);
        return copy;
    }

    @Transactional
    public TrainingPlan update(AuthzContext caller, PlanId id, PlanChange change) {
        return edit(caller, id, plan -> {
            TrainingPlan edited = plan;
            if (change.name().isPresent()) {
                edited = edited.renamed(change.name().get(), clock.now());
            }
            if (change.description().isPresent()) {
                edited = edited.described(change.description().get().orElse(null), clock.now());
            }
            return edited;
        });
    }

    @Transactional
    public TrainingPlan setArchived(AuthzContext caller, PlanId id, boolean archived) {
        return edit(caller, id, plan -> plan.archived(archived, clock.now()));
    }

    @Transactional
    public void delete(AuthzContext caller, PlanId id) {
        access.requireStaffRole(caller);
        TrainingPlan plan = load(id);
        plan.requireEditable();
        if (assignments.existsForPlan(id)) {
            throw new ConflictException("A plan with assignments cannot be deleted", "PLAN_HAS_ASSIGNMENTS");
        }
        plans.delete(id);
    }

    @Transactional
    public PlanItem addItem(AuthzContext caller, PlanId id, ItemFields fields) {
        TrainingPlan changed = edit(caller, id, plan -> plan.withItemAppended(fields.toDraft(), clock.now()));
        return changed.items().get(changed.items().size() - 1);
    }

    @Transactional
    public PlanItem updateItem(AuthzContext caller, PlanId id, PlanItemId itemId, ItemChange change) {
        TrainingPlan changed = edit(caller, id, plan -> {
            PlanItem current = plan.item(itemId);
            PlanItem merged = current.edited(
                    change.title().orElse(current.title()),
                    Patches.apply(change.description(), current.description()),
                    Patches.apply(change.durationMinutes(), current.durationMinutes()),
                    Patches.apply(change.sets(), current.sets()),
                    Patches.apply(change.repetitions(), current.repetitions()),
                    Patches.apply(change.videoUrl(), current.videoUrl()));
            return plan.withItemReplaced(merged, clock.now());
        });
        return changed.item(itemId);
    }

    @Transactional
    public void deleteItem(AuthzContext caller, PlanId id, PlanItemId itemId) {
        edit(caller, id, plan -> plan.withoutItem(itemId, clock.now()));
    }

    @Transactional
    public List<PlanItem> reorder(AuthzContext caller, PlanId id, List<PlanItemId> order) {
        return edit(caller, id, plan -> plan.reordered(order, clock.now())).items();
    }

    private TrainingPlan edit(AuthzContext caller, PlanId id, java.util.function.UnaryOperator<TrainingPlan> change) {
        access.requireStaffRole(caller);
        TrainingPlan current = load(id);
        current.requireEditable();
        TrainingPlan changed = change.apply(current);
        plans.save(changed);
        return changed;
    }

    private TrainingPlan load(PlanId id) {
        return plans.find(id).orElseThrow(() -> new NotFoundException("Plan not found"));
    }
}
