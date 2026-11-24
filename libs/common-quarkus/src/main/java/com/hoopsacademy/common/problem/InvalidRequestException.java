package com.hoopsacademy.common.problem;

import java.util.List;

/**
 * A request the framework accepted but hand-written reading found unusable (a merge-patch body, a query parameter
 * parsed by hand, a date range): 400 {@code validation} with every violation. Pure Java.
 */
public class InvalidRequestException extends RuntimeException {

    private final List<Problem.Violation> violations;

    public InvalidRequestException(List<Problem.Violation> violations) {
        super("Request validation failed");
        this.violations = List.copyOf(violations);
    }

    /** One violation with a machine-readable {@code code} (e.g. {@code INVALID_VALUE}). */
    public static InvalidRequestException of(String field, String code, String message) {
        return new InvalidRequestException(List.of(new Problem.Violation(field, code, message)));
    }

    public static InvalidRequestException of(String field, String message) {
        return new InvalidRequestException(List.of(new Problem.Violation(field, message)));
    }

    public List<Problem.Violation> violations() {
        return violations;
    }
}
