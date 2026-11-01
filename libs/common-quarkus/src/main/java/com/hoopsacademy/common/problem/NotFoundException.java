package com.hoopsacademy.common.problem;

/** A requested resource does not exist in the caller's tenant (or the caller may not know it exists): 404. Pure Java, usable from domain code. */
public class NotFoundException extends CodedProblemException {

    public NotFoundException(String message) {
        this(message, null);
    }

    public NotFoundException(String message, String code) {
        super(message, code);
    }
}
