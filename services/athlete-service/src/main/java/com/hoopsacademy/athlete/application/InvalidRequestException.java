package com.hoopsacademy.athlete.application;

/** The request is syntactically fine but unusable (mapped to 400 with one field violation). */
public class InvalidRequestException extends RuntimeException {

    private final String field;
    private final String code;

    public InvalidRequestException(String field, String code, String message) {
        super(message);
        this.field = field;
        this.code = code;
    }

    public String field() {
        return field;
    }

    public String code() {
        return code;
    }
}
