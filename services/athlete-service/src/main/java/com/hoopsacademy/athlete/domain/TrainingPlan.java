package com.hoopsacademy.athlete.domain;

import com.hoopsacademy.common.problem.AccessDeniedException;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
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
 *
 * <p>A tenant plan may belong to one training session ({@code sessionOrNull}, ADR-0041): the ad-hoc plan that the
 * session's quick-added exercises go to. Only that session references it.
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
        SessionId sessionOrNull,
        List<PlanItem> items,
        Instant createdAt,
        Instant updatedAt) {

    private static final int MAX_NAME = 120;
    private static final String DEFAULT_LOCALE = "en";
    private static final Map<ContentLocale, String> SESSION_WORD = Map.of(
            ContentLocale.ES, "Sesión", ContentLocale.EN, "Session", ContentLocale.ID, "Sesi");

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
        if (template && sessionOrNull != null) {
            throw new IllegalStateException("A global template never belongs to a session");
        }
    }

    public static TrainingPlan create(String name, String description, Actor author, List<PlanItem> items, Instant now) {
        return new TrainingPlan(PlanId.random(), null, name, description, author, false, DEFAULT_LOCALE, Translations.NONE,
                false, null, null, numbered(items), now, now);
    }

    /** The empty ad-hoc plan of {@code session}, named after its {@code day} in {@code language} ("Sesión 2027-09-07"). */
    public static TrainingPlan forSession(SessionId session, LocalDate day, ContentLocale language, Actor author,
            Instant now) {
        String name = SESSION_WORD.get(language) + " " + day;
        return new TrainingPlan(PlanId.random(), null, name, null, author, false, language.code(), Translations.NONE,
                false, null, Objects.requireNonNull(session, "session"), List.of(), now, now);
    }

    /** Rebuilds a global template (used by the seed tests and the persistence adapter). */
    public static TrainingPlan template(PlanId id, String name, String description, String locale, List<PlanItem> items,
            Instant now) {
        return new TrainingPlan(id, null, name, description, null, true, locale, Translations.NONE, false, null, null,
                numbered(items), now, now);
    }

    /**
     * This template with its stable key and its texts in other languages.
     *
     * @throws IllegalStateException for a tenant plan
     */
    public TrainingPlan translatedAs(String nameKey, Translations newTranslations) {
        return new TrainingPlan(id, nameKey, name, description, authorOrNull, template, locale, newTranslations, archived,
                sourcePlanIdOrNull, sessionOrNull, items, createdAt, updatedAt);
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
                template, shown.language(), Translations.NONE, archived, sourcePlanIdOrNull, sessionOrNull, shownItems,
                createdAt, updatedAt);
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

    /** The session this ad-hoc plan belongs to; empty for templates and ordinary tenant plans. */
    public Optional<SessionId> session() {
        return Optional.ofNullable(sessionOrNull);
    }

    public boolean isAdHocFor(SessionId candidate) {
        return sessionOrNull != null && sessionOrNull.equals(candidate);
    }

    /**
     * A session may reference any readable plan except the ad-hoc plan of another session.
     *
     * @throws TrainingRuleViolation {@code PLAN_OF_ANOTHER_SESSION}
     */
    public void requireAttachableTo(SessionId candidate) {
        if (sessionOrNull != null && !sessionOrNull.equals(candidate)) {
            throw new TrainingRuleViolation("This plan belongs to another session", "PLAN_OF_ANOTHER_SESSION");
        }
    }

    /** The items whose (shown) title contains {@code query}, ignoring case, in plan order. */
    public List<PlanItem> itemsMatching(String query) {
        String needle = query.toLowerCase(Locale.ROOT);
        return items.stream().filter(i -> i.title().toLowerCase(Locale.ROOT).contains(needle)).toList();
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
        return copy(author, name.orElse(this.name), null, now);
    }

    /**
     * Copy on write for a session's quick-add: a copy of this plan (as it is here, so localize a template first) that
     * belongs to {@code session}.
     */
    public TrainingPlan adHocCopyFor(SessionId session, Actor author, Instant now) {
        return copy(author, name, Objects.requireNonNull(session, "session"), now);
    }

    private TrainingPlan copy(Actor author, String copyName, SessionId session, Instant now) {
        List<PlanItem> duplicated = items.stream().map(PlanItem::duplicated).toList();
        return new TrainingPlan(PlanId.random(), null, copyName, description, author, false, locale, Translations.NONE,
                false, id, session, duplicated, now, now);
    }

    /** Quick-add: copies of {@code sources} (fresh ids, no translations) appended in the given order. */
    public TrainingPlan withCopiesAppended(List<PlanItem> sources, Instant now) {
        List<PlanItem> all = new ArrayList<>(items);
        sources.stream().map(PlanItem::duplicated).forEach(all::add);
        return changed(name, description, archived, numbered(all), now);
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
                newArchived, sourcePlanIdOrNull, sessionOrNull, newItems, createdAt, now);
    }

    private static List<PlanItem> numbered(List<PlanItem> items) {
        return IntStream.range(0, items.size()).mapToObj(i -> items.get(i).at(i)).toList();
    }

    private static com.hoopsacademy.common.problem.NotFoundException itemNotFound() {
        return new com.hoopsacademy.common.problem.NotFoundException("Plan item not found");
    }
}
