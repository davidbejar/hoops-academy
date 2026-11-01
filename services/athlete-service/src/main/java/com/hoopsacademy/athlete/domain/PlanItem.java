package com.hoopsacademy.athlete.domain;

import java.util.Objects;

/** One exercise of a plan. {@code position} is 0-based and owned by the plan. */
public record PlanItem(
        PlanItemId id,
        int position,
        String title,
        String description,
        Integer durationMinutes,
        Integer sets,
        Integer repetitions,
        String videoUrl) {

    private static final int MAX_TITLE = 120;

    public PlanItem {
        Objects.requireNonNull(id, "id");
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
        return new PlanItem(PlanItemId.random(), 0, title, description, durationMinutes, sets, repetitions, videoUrl);
    }

    /** The same item with every content field replaced (the caller merges partial changes). */
    public PlanItem edited(String newTitle, String newDescription, Integer newDuration, Integer newSets,
            Integer newRepetitions, String newVideoUrl) {
        return new PlanItem(id, position, newTitle, newDescription, newDuration, newSets, newRepetitions, newVideoUrl);
    }

    PlanItem at(int newPosition) {
        return new PlanItem(id, newPosition, title, description, durationMinutes, sets, repetitions, videoUrl);
    }

    /** A copy with a fresh identity, for copy-on-use. */
    PlanItem duplicated() {
        return new PlanItem(PlanItemId.random(), position, title, description, durationMinutes, sets, repetitions, videoUrl);
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
