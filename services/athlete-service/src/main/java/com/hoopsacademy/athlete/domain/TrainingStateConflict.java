package com.hoopsacademy.athlete.domain;

/** An operation is not allowed in the current state, e.g. changing a cancelled session (mapped to 409). */
public class TrainingStateConflict extends RuntimeException {

    private final String code;

    public TrainingStateConflict(String message, String code) {
        super(message);
        this.code = code;
    }

    public String code() {
        return code;
    }
}
