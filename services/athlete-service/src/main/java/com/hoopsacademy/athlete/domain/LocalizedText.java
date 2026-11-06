package com.hoopsacademy.athlete.domain;

/** A translated title (plan name or item title, 1 to 120 characters) with its optional description. */
public record LocalizedText(String title, String description) {

    private static final int MAX_TITLE = 120;

    public LocalizedText {
        if (title == null || title.isBlank() || title.length() > MAX_TITLE) {
            throw new TrainingRuleViolation("A translated title needs 1 to 120 characters", "INVALID_TRANSLATION");
        }
    }
}
