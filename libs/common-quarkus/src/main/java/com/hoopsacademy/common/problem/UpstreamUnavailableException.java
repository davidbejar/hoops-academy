package com.hoopsacademy.common.problem;

/**
 * A service this one depends on (core-service behind {@code RosterPort}, ADR-0008) did not answer in time or failed:
 * answered as 503 Problem with code {@value #CODE}; the message (which may name hosts or statuses) is logged, never
 * sent to the client. Contract: {@code common.yaml#/components/responses/ServiceUnavailable}.
 */
public class UpstreamUnavailableException extends CodedProblemException {

    public static final String CODE = "UPSTREAM_UNAVAILABLE";

    public UpstreamUnavailableException(String message, Throwable cause) {
        super(message, CODE);
        initCause(cause);
    }
}
