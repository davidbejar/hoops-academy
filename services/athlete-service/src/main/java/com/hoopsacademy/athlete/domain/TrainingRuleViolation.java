package com.hoopsacademy.athlete.domain;

/** A training business rule was broken (mapped to 422 by the REST adapter). */
public class TrainingRuleViolation extends RuntimeException {

    private final String code;

    public TrainingRuleViolation(String message, String code) {
        super(message);
        this.code = code;
    }

    public String code() {
        return code;
    }
}
