package com.hoopsacademy.athlete.application;

/** A service this one depends on (core-service) did not answer in time or failed: 503 {@code UPSTREAM_UNAVAILABLE}. */
public class UpstreamUnavailableException extends RuntimeException {

    public static final String CODE = "UPSTREAM_UNAVAILABLE";

    public UpstreamUnavailableException(String message, Throwable cause) {
        super(message, cause);
    }
}
