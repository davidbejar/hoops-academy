package com.hoopsacademy.athlete.domain;

import java.util.Objects;

/**
 * One exercise of a plan. {@code position} is 0-based and owned by the plan. Only the items of a global template carry
 * {@code translations} of their title and description.
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
        Translations translations) {

    private static final int MAX_TITLE = 120;

    public PlanItem {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(translations, "translations");
        if (title == null || title.isBlank() || title.length() > MAX_TITLE) {
            throw invalid("An item needs a title of 1 to 120 characters");
        }
        requireBetween(durationMinutes, 1, 480, "durationMinutes");
        requireBetween(sets, 1, 100, "sets");
        requireBetween(repetitions, 1, 1000, "repetitions");
    }

    /** A new item that the plan will place; its position is assigned there. */
    public static PlanItem draft(String title, String description, Integer durationMinutes, Integer sets,
            Integer repetitions, String videoUrl) {
        return new PlanItem(PlanItemId.random(), 0, title, description, durationMinutes, sets, repetitions, videoUrl,
                Translations.NONE);
    }

    /** The same item with the given texts in other languages (template items). */
    public PlanItem translatedAs(Translations newTranslations) {
        return new PlanItem(id, position, title, description, durationMinutes, sets, repetitions, videoUrl,
                newTranslations);
    }

    /** The same item with every content field replaced (the caller merges partial changes); translations are dropped. */
    public PlanItem edited(String newTitle, String newDescription, Integer newDuration, Integer newSets,
            Integer newRepetitions, String newVideoUrl) {
        return new PlanItem(id, position, newTitle, newDescription, newDuration, newSets, newRepetitions, newVideoUrl,
                Translations.NONE);
    }

    PlanItem at(int newPosition) {
        return new PlanItem(id, newPosition, title, description, durationMinutes, sets, repetitions, videoUrl,
                translations);
    }

    /** A copy with a fresh identity and without translations, for copy-on-use. */
    PlanItem duplicated() {
        return new PlanItem(PlanItemId.random(), position, title, description, durationMinutes, sets, repetitions,
                videoUrl, Translations.NONE);
    }

    /**
     * This item as shown for {@code requested} ({@code ownLanguage} is the language of its own texts). The result has
     * no translations left, so localizing it again changes nothing.
     */
    PlanItem localized(ContentLocale requested, String ownLanguage) {
        LocalizedText shown = translations.choose(requested, ownLanguage, new LocalizedText(title, description)).text();
        return new PlanItem(id, position, shown.title(), shown.description(), durationMinutes, sets, repetitions,
                videoUrl, Translations.NONE);
    }

    private static void requireBetween(Integer value, int min, int max, String field) {
        if (value != null && (value < min || value > max)) {
            throw invalid(field + " must be between " + min + " and " + max);
        }
    }

    private static TrainingRuleViolation invalid(String message) {
        return new TrainingRuleViolation(message, "INVALID_ITEM");
    }
}
