package com.hoopsacademy.game.application;

import com.hoopsacademy.common.problem.CodedProblemException;

/** core-service could not be reached in time or failed: answered as 503 Problem, code UPSTREAM_UNAVAILABLE. */
public final class UpstreamUnavailableException extends CodedProblemException {

    public static final String CODE = "UPSTREAM_UNAVAILABLE";

    public UpstreamUnavailableException(String message, Throwable cause) {
        super(message, CODE);
        initCause(cause);
    }
}
