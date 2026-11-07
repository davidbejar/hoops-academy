package com.hoopsacademy.common.security;

import io.quarkus.security.AuthenticationFailedException;

/**
 * The cause of the 401 for a verified access token without a {@code sub} claim, so the failure is logged as
 * {@code invalid_token} with reason {@code no_sub} ({@link AuthenticationFailedException} itself is final).
 */
public class MissingSubjectException extends RuntimeException {

    private static final String MESSAGE = "The access token carries no 'sub' claim";

    public MissingSubjectException() {
        super(MESSAGE);
    }

    /** True when {@code failure} is (or was caused by) a missing {@code sub}. */
    public static boolean isCauseOf(Throwable failure) {
        return "no_sub".equals(TokenFailureReason.of(failure));
    }

    /** The authentication failure to throw. */
    public static AuthenticationFailedException failure() {
        return new AuthenticationFailedException(MESSAGE, new MissingSubjectException());
    }
}
