package com.hoopsacademy.common.problem;

/** The caller is a tenant member but lacks the role or relation required: 403. Pure Java, usable from domain code. */
public class AccessDeniedException extends CodedProblemException {

    public AccessDeniedException(String message) {
        this(message, null);
    }

    public AccessDeniedException(String message, String code) {
        super(message, code);
    }
}
