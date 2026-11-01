package com.hoopsacademy.athlete.domain;

import com.hoopsacademy.common.problem.AccessDeniedException;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

/**
 * A training plan: an ordered list of exercises. A global template (read-only for every tenant) is copied into
 * a tenant-owned plan before use (copy-on-use); the copy is independent of its source.
 */
public record TrainingPlan(
        PlanId id,
        String name,
        String description,
        Actor authorOrNull,
        boolean template,
        String locale,
        boolean archived,
        PlanId sourcePlanIdOrNull,
        List<PlanItem> items,
        Instant createdAt,
        Instant updatedAt) {

    private static final int MAX_NAME = 120;
    private static final String DEFAULT_LOCALE = "en";

    public TrainingPlan {
        Objects.requireNonNull(id, "id");
        if (name == null || name.isBlank() || name.length() > MAX_NAME) {
            throw new TrainingRuleViolation("A plan needs a name of 1 to 120 characters", "INVALID_PLAN");
        }
        items = List.copyOf(items);
    }

    public static TrainingPlan create(String name, String description, Actor author, List<PlanItem> items, Instant now) {
        return new TrainingPlan(PlanId.random(), name, description, author, false, DEFAULT_LOCALE, false, null,
                numbered(items), now, now);
    }

    /** Rebuilds a global template (used by the seed tests and the persistence adapter). */
    public static TrainingPlan template(PlanId id, String name, String description, String locale, List<PlanItem> items,
            Instant now) {
        return new TrainingPlan(id, name, description, null, true, locale, false, null, numbered(items), now, now);
    }

    public Optional<Actor> author() {
        return Optional.ofNullable(authorOrNull);
    }

    public Optional<PlanId> sourcePlanId() {
        return Optional.ofNullable(sourcePlanIdOrNull);
    }

    public int itemCount() {
        return items.size();
    }

    public int totalDurationMinutes() {
        return items.stream().map(PlanItem::durationMinutes).filter(Objects::nonNull).mapToInt(Integer::intValue).sum();
    }

    /** @throws AccessDeniedException {@code PLAN_IS_TEMPLATE} for a global template */
    public void requireEditable() {
        if (template) {
            throw new AccessDeniedException("Templates are read-only; copy the template first", "PLAN_IS_TEMPLATE");
        }
    }

    /** A new tenant plan with its own identity and items; {@code name} defaults to this plan's name. */
    public TrainingPlan copiedBy(Actor author, Optional<String> name, Instant now) {
        List<PlanItem> duplicated = items.stream().map(PlanItem::duplicated).toList();
        return new TrainingPlan(PlanId.random(), name.orElse(this.name), description, author, false, locale, false, id,
                duplicated, now, now);
    }

    public TrainingPlan renamed(String newName, Instant now) {
        return changed(newName, description, archived, items, now);
    }

    public TrainingPlan described(String newDescription, Instant now) {
        return changed(name, newDescription, archived, items, now);
    }

    public TrainingPlan archived(boolean newArchived, Instant now) {
        return changed(name, description, newArchived, items, now);
    }

    public TrainingPlan withItemAppended(PlanItem item, Instant now) {
        List<PlanItem> all = new ArrayList<>(items);
        all.add(item);
        return changed(name, description, archived, numbered(all), now);
    }

    public TrainingPlan withItemReplaced(PlanItem replacement, Instant now) {
        requireItem(replacement.id());
        return changed(name, description, archived,
                items.stream().map(i -> i.id().equals(replacement.id()) ? replacement.at(i.position()) : i).toList(), now);
    }

    public TrainingPlan withoutItem(PlanItemId itemId, Instant now) {
        requireItem(itemId);
        return changed(name, description, archived,
                numbered(items.stream().filter(i -> !i.id().equals(itemId)).toList()), now);
    }

    /** @param order a permutation of this plan's item ids */
    public TrainingPlan reordered(List<PlanItemId> order, Instant now) {
        Map<PlanItemId, PlanItem> byId = items.stream().collect(Collectors.toMap(PlanItem::id, Function.identity()));
        if (order.size() != items.size() || !new HashSet<>(order).equals(byId.keySet())) {
            throw new TrainingRuleViolation("itemIds must list every item of the plan exactly once", "ITEM_ORDER_MISMATCH");
        }
        return changed(name, description, archived, numbered(order.stream().map(byId::get).toList()), now);
    }

    public PlanItem item(PlanItemId itemId) {
        return items.stream().filter(i -> i.id().equals(itemId)).findFirst().orElseThrow(() -> itemNotFound());
    }

    private void requireItem(PlanItemId itemId) {
        item(itemId);
    }

    private TrainingPlan changed(String newName, String newDescription, boolean newArchived, List<PlanItem> newItems,
            Instant now) {
        requireEditable();
        return new TrainingPlan(id, newName, newDescription, authorOrNull, template, locale, newArchived,
                sourcePlanIdOrNull, newItems, createdAt, now);
    }

    private static List<PlanItem> numbered(List<PlanItem> items) {
        return IntStream.range(0, items.size()).mapToObj(i -> items.get(i).at(i)).toList();
    }

    private static com.hoopsacademy.common.problem.NotFoundException itemNotFound() {
        return new com.hoopsacademy.common.problem.NotFoundException("Plan item not found");
    }
}
