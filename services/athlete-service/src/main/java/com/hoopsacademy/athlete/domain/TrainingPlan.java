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
 *
 * <p>A template's own texts are in {@code locale}; it may carry a stable {@code nameKey} and {@code translations}
 * into the other languages, and is shown {@link #localized localized} to the caller's language (decision 43). Tenant
 * plans have neither and are shown as stored.
 */
public record TrainingPlan(
        PlanId id,
        String nameKeyOrNull,
        String name,
        String description,
        Actor authorOrNull,
        boolean template,
        String locale,
        Translations translations,
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
        Objects.requireNonNull(translations, "translations");
        if (!template && (nameKeyOrNull != null || !translations.isEmpty())) {
            throw new IllegalStateException("Only global templates carry a name key or translations");
        }
    }

    public static TrainingPlan create(String name, String description, Actor author, List<PlanItem> items, Instant now) {
        return new TrainingPlan(PlanId.random(), null, name, description, author, false, DEFAULT_LOCALE, Translations.NONE,
                false, null, numbered(items), now, now);
    }

    /** Rebuilds a global template (used by the seed tests and the persistence adapter). */
    public static TrainingPlan template(PlanId id, String name, String description, String locale, List<PlanItem> items,
            Instant now) {
        return new TrainingPlan(id, null, name, description, null, true, locale, Translations.NONE, false, null,
                numbered(items), now, now);
    }

    /**
     * This template with its stable key and its texts in other languages.
     *
     * @throws IllegalStateException for a tenant plan
     */
    public TrainingPlan translatedAs(String nameKey, Translations newTranslations) {
        return new TrainingPlan(id, nameKey, name, description, authorOrNull, template, locale, newTranslations, archived,
                sourcePlanIdOrNull, items, createdAt, updatedAt);
    }

    /**
     * This plan as shown to a caller who reads {@code requested}: a template's texts (its items' too) in that language,
     * else in {@link ContentLocale#FALLBACK}, else its own; {@code locale} names the language shown. The result keeps
     * the name key but no translations, so localizing it again changes nothing. A tenant plan has no translations and
     * comes back equal.
     */
    public TrainingPlan localized(ContentLocale requested) {
        Translations.Choice shown = translations.choose(requested, locale, new LocalizedText(name, description));
        List<PlanItem> shownItems = items.stream().map(i -> i.localized(requested, locale)).toList();
        return new TrainingPlan(id, nameKeyOrNull, shown.text().title(), shown.text().description(), authorOrNull,
                template, shown.language(), Translations.NONE, archived, sourcePlanIdOrNull, shownItems, createdAt,
                updatedAt);
    }

    public Optional<String> nameKey() {
        return Optional.ofNullable(nameKeyOrNull);
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

    /**
     * A new tenant plan with its own identity and items; {@code name} defaults to this plan's name. The copy keeps the
     * texts as they are here (copy a {@link #localized localized} template to copy it in the caller's language) and
     * neither the name key nor translations.
     */
    public TrainingPlan copiedBy(Actor author, Optional<String> name, Instant now) {
        List<PlanItem> duplicated = items.stream().map(PlanItem::duplicated).toList();
        return new TrainingPlan(PlanId.random(), null, name.orElse(this.name), description, author, false, locale,
                Translations.NONE, false, id, duplicated, now, now);
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
        return new TrainingPlan(id, nameKeyOrNull, newName, newDescription, authorOrNull, template, locale, translations,
                newArchived, sourcePlanIdOrNull, newItems, createdAt, now);
    }

    private static List<PlanItem> numbered(List<PlanItem> items) {
        return IntStream.range(0, items.size()).mapToObj(i -> items.get(i).at(i)).toList();
    }

    private static com.hoopsacademy.common.problem.NotFoundException itemNotFound() {
        return new com.hoopsacademy.common.problem.NotFoundException("Plan item not found");
    }
}
