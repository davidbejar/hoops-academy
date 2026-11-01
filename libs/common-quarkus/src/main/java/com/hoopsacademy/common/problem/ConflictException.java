package com.hoopsacademy.common.problem;

/** The request conflicts with the current state (duplicate, concurrent modification): 409. Pure Java, usable from domain code. */
public class ConflictException extends CodedProblemException {

    public ConflictException(String message) {
        this(message, null);
    }

    public ConflictException(String message, String code) {
        super(message, code);
    }
}
