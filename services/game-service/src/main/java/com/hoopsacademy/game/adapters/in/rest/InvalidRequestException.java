package com.hoopsacademy.game.adapters.in.rest;

/** The request body is well-formed but unusable (mapped to 400 with one field violation). */
class InvalidRequestException extends RuntimeException {

    private final String field;
    private final String code;

    InvalidRequestException(String field, String code, String message) {
        super(message);
        this.field = field;
        this.code = code;
    }

    String field() {
        return field;
    }

    String code() {
        return code;
    }
}
