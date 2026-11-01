package com.hoopsacademy.common.problem;

/**
 * Base of the domain exceptions mapped to Problem+JSON. The optional {@link #code()} is a stable, machine-readable
 * reason in SCREAMING_SNAKE_CASE (e.g. {@code PLAYER_INELIGIBLE}) that clients may branch on. Pure Java.
 */
public abstract class CodedProblemException extends RuntimeException {

    private final String code;

    protected CodedProblemException(String message, String code) {
        super(message);
        this.code = code;
    }

    /** @return the machine-readable reason, or {@code null} when none was given */
    public String code() {
        return code;
    }
}
