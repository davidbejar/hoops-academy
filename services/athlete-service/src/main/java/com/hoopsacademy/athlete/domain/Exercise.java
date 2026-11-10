package com.hoopsacademy.athlete.domain;

import com.hoopsacademy.common.problem.AccessDeniedException;
import java.time.Instant;
import java.util.Objects;
import java.util.Optional;

/**
 * A catalogue exercise (decision 72, ADR-0047): the content a plan item is copied from. A global exercise is platform
 * content, read-only for every academy, written in {@code locale} with a stable {@code nameKey} and {@code translations}
 * into the other languages, and shown {@link #localized localized}; it is never archived. An academy's own exercise has
 * neither key nor translations and is shown as stored; it is edited and archived, never deleted, so the items that
 * reference it keep a readable source.
 */
public record Exercise(
        ExerciseId id,
        String nameKeyOrNull,
        String title,
        String description,
        Integer durationMinutes,
        Integer sets,
        Integer repetitions,
        String videoUrl,
        boolean global,
        String locale,
        Translations translations,
        boolean archived,
        Instant createdAt,
        Instant updatedAt) {

    private static final String DEFAULT_LOCALE = "en";

    public Exercise {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(translations, "translations");
        ItemContent.requireValid("An exercise", "INVALID_EXERCISE", title, durationMinutes, sets, repetitions);
        if (!global && (nameKeyOrNull != null || !translations.isEmpty())) {
            throw new IllegalStateException("Only global exercises carry a name key or translations");
        }
        if (global && archived) {
            throw new IllegalStateException("A global exercise is never archived");
        }
    }

    /** A new exercise of the academy's own. */
    public static Exercise create(String title, String description, Integer durationMinutes, Integer sets,
            Integer repetitions, String videoUrl, Instant now) {
        return new Exercise(ExerciseId.random(), null, title, description, durationMinutes, sets, repetitions, videoUrl,
                false, DEFAULT_LOCALE, Translations.NONE, false, now, now);
    }

    public Optional<String> nameKey() {
        return Optional.ofNullable(nameKeyOrNull);
    }

    /**
     * This exercise as shown to a caller who reads {@code requested}: a global exercise's texts in that language, else
     * in {@link ContentLocale#FALLBACK}, else its own; {@code locale} names the language shown and no translations are
     * left. An academy's exercise has no translations and comes back equal.
     */
    public Exercise localized(ContentLocale requested) {
        Translations.Choice shown = translations.choose(requested, locale, new LocalizedText(title, description));
        return new Exercise(id, nameKeyOrNull, shown.text().title(), shown.text().description(), durationMinutes, sets,
                repetitions, videoUrl, global, shown.language(), Translations.NONE, archived, createdAt, updatedAt);
    }

    /**
     * The same exercise with every content field replaced (the caller merges partial changes).
     *
     * @throws AccessDeniedException {@code EXERCISE_IS_GLOBAL} for a global exercise
     */
    public Exercise edited(String newTitle, String newDescription, Integer newDuration, Integer newSets,
            Integer newRepetitions, String newVideoUrl, Instant now) {
        requireEditable();
        return new Exercise(id, null, newTitle, newDescription, newDuration, newSets, newRepetitions, newVideoUrl, false,
                locale, Translations.NONE, archived, createdAt, now);
    }

    /** @throws AccessDeniedException {@code EXERCISE_IS_GLOBAL} for a global exercise */
    public Exercise archived(boolean newArchived, Instant now) {
        requireEditable();
        return new Exercise(id, null, title, description, durationMinutes, sets, repetitions, videoUrl, false, locale,
                Translations.NONE, newArchived, createdAt, now);
    }

    /** @throws AccessDeniedException {@code EXERCISE_IS_GLOBAL} for a global exercise */
    public void requireEditable() {
        if (global) {
            throw new AccessDeniedException("Global exercises are read-only", "EXERCISE_IS_GLOBAL");
        }
    }

    /**
     * A new plan item with this exercise's content (as it is here, so localize a global exercise first) that keeps
     * referencing it; the plan places it.
     *
     * @throws TrainingRuleViolation {@code EXERCISE_ARCHIVED} for an archived exercise
     */
    public PlanItem toItem() {
        if (archived) {
            throw new TrainingRuleViolation("An archived exercise cannot be added", "EXERCISE_ARCHIVED");
        }
        return new PlanItem(PlanItemId.random(), 0, title, description, durationMinutes, sets, repetitions, videoUrl,
                Translations.NONE, id);
    }
}
