package com.hoopsacademy.core.adapters.in.shared;

import com.hoopsacademy.common.problem.Problem;
import java.util.List;

/** A syntactically invalid request found by hand-written parsing (merge-patch bodies, enum query params): 400. */
public class InvalidRequestException extends RuntimeException {

    private final List<Problem.Violation> violations;

    public InvalidRequestException(List<Problem.Violation> violations) {
        super("Request validation failed");
        this.violations = List.copyOf(violations);
    }

    public static InvalidRequestException of(String field, String message) {
        return new InvalidRequestException(List.of(new Problem.Violation(field, message)));
    }

    public List<Problem.Violation> violations() {
        return violations;
    }
}
