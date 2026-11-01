package com.hoopsacademy.common.problem;

import java.util.List;

/**
 * A business rule rejected the request (e.g. eligibility): 422. Services subclass it for specific rules and may
 * list the individual {@link #reasons()} (rendered as the Problem's {@code violations}). Pure Java.
 */
public class DomainRuleViolation extends CodedProblemException {

    private final List<Problem.Violation> reasons;

    public DomainRuleViolation(String message) {
        this(message, null);
    }

    public DomainRuleViolation(String message, String code) {
        this(message, code, List.of());
    }

    public DomainRuleViolation(String message, String code, List<Problem.Violation> reasons) {
        super(message, code);
        this.reasons = List.copyOf(reasons);
    }

    public List<Problem.Violation> reasons() {
        return reasons;
    }
}
