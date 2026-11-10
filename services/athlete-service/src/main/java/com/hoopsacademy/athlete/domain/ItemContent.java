package com.hoopsacademy.athlete.domain;

/**
 * The limits an exercise and a plan item share (an item is a copy of an exercise's content): a title of 1 to 120
 * characters, a duration of 1 to 480 minutes, 1 to 100 sets and 1 to 1000 repetitions, each optional but the title.
 */
final class ItemContent {

    private static final int MAX_TITLE = 120;

    private ItemContent() {}

    /** @throws TrainingRuleViolation with {@code code} when a value is out of its limits */
    static void requireValid(String what, String code, String title, Integer durationMinutes, Integer sets,
            Integer repetitions) {
        if (title == null || title.isBlank() || title.length() > MAX_TITLE) {
            throw new TrainingRuleViolation(what + " needs a title of 1 to 120 characters", code);
        }
        requireBetween(durationMinutes, 1, 480, "durationMinutes", code);
        requireBetween(sets, 1, 100, "sets", code);
        requireBetween(repetitions, 1, 1000, "repetitions", code);
    }

    private static void requireBetween(Integer value, int min, int max, String field, String code) {
        if (value != null && (value < min || value > max)) {
            throw new TrainingRuleViolation(field + " must be between " + min + " and " + max, code);
        }
    }
}
