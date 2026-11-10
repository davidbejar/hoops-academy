package com.hoopsacademy.athlete.domain;

import java.util.Objects;
import java.util.Optional;

/**
 * One exercise of a plan. {@code position} is 0-based and owned by the plan. Only the items of a global template carry
 * {@code translations} of their title and description. {@code exerciseOrNull} is the catalogue exercise the item was
 * copied from (ADR-0047): its text is the item's own copy, and every later copy, edit or translation keeps the reference.
 */
public record PlanItem(
        PlanItemId id,
        int position,
        String title,
        String description,
        Integer durationMinutes,
        Integer sets,
        Integer repetitions,
        String videoUrl,
        Translations translations,
        ExerciseId exerciseOrNull) {

    public PlanItem {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(translations, "translations");
        ItemContent.requireValid("An item", "INVALID_ITEM", title, durationMinutes, sets, repetitions);
    }

    /** A new item that the plan will place; its position is assigned there. */
    public static PlanItem draft(String title, String description, Integer durationMinutes, Integer sets,
            Integer repetitions, String videoUrl) {
        return new PlanItem(PlanItemId.random(), 0, title, description, durationMinutes, sets, repetitions, videoUrl,
                Translations.NONE, null);
    }

    /** The catalogue exercise the item was copied from; empty for an item written by hand. */
    public Optional<ExerciseId> exercise() {
        return Optional.ofNullable(exerciseOrNull);
    }

    /** The same item with the given texts in other languages (template items). */
    public PlanItem translatedAs(Translations newTranslations) {
        return new PlanItem(id, position, title, description, durationMinutes, sets, repetitions, videoUrl,
                newTranslations, exerciseOrNull);
    }

    /**
     * The same item with every content field replaced (the caller merges partial changes); translations are dropped,
     * the exercise reference is kept.
     */
    public PlanItem edited(String newTitle, String newDescription, Integer newDuration, Integer newSets,
            Integer newRepetitions, String newVideoUrl) {
        return new PlanItem(id, position, newTitle, newDescription, newDuration, newSets, newRepetitions, newVideoUrl,
                Translations.NONE, exerciseOrNull);
    }

    PlanItem at(int newPosition) {
        return new PlanItem(id, newPosition, title, description, durationMinutes, sets, repetitions, videoUrl,
                translations, exerciseOrNull);
    }

    /** A copy with a fresh identity and without translations (the exercise reference kept), for copy-on-use. */
    PlanItem duplicated() {
        return new PlanItem(PlanItemId.random(), position, title, description, durationMinutes, sets, repetitions,
                videoUrl, Translations.NONE, exerciseOrNull);
    }

    /**
     * This item as shown for {@code requested} ({@code ownLanguage} is the language of its own texts). The result has
     * no translations left, so localizing it again changes nothing.
     */
    PlanItem localized(ContentLocale requested, String ownLanguage) {
        LocalizedText shown = translations.choose(requested, ownLanguage, new LocalizedText(title, description)).text();
        return new PlanItem(id, position, shown.title(), shown.description(), durationMinutes, sets, repetitions,
                videoUrl, Translations.NONE, exerciseOrNull);
    }
}
