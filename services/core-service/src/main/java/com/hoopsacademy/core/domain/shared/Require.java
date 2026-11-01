package com.hoopsacademy.core.domain.shared;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.common.problem.Problem;
import java.util.List;

/** Small guard clauses that raise a 422 with the offending field. */
public final class Require {

    private Require() {}

    /** @return the stripped text, which must be 1..{@code maxLength} characters */
    public static String text(String value, String field, int maxLength) {
        if (value == null || value.isBlank() || value.strip().length() > maxLength) {
            throw violation(field, field + " must be 1.." + maxLength + " characters");
        }
        return value.strip();
    }

    public static <T> T present(T value, String field) {
        if (value == null) {
            throw violation(field, field + " is required");
        }
        return value;
    }

    public static DomainRuleViolation violation(String field, String message) {
        return new DomainRuleViolation(message, "INVALID_" + toConstant(field),
                List.of(new Problem.Violation(field, message)));
    }

    private static String toConstant(String field) {
        return field.replaceAll("([a-z])([A-Z])", "$1_$2").toUpperCase(java.util.Locale.ROOT);
    }
}
