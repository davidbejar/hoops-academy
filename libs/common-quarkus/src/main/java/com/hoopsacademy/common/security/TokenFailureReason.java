package com.hoopsacademy.common.security;

import org.jose4j.jwt.consumer.ErrorCodes;
import org.jose4j.jwt.consumer.InvalidJwtException;

/**
 * Names why a bearer token was refused from jose4j's validation error codes in the failure's cause chain. The
 * failure's messages are never used: jose4j puts the token's claims into them.
 */
public final class TokenFailureReason {

    private static final int MAX_CAUSE_DEPTH = 16;

    private TokenFailureReason() {}

    /** {@code expired}, {@code not_yet_valid}, {@code audience}, {@code signature}, {@code issuer}, {@code no_sub} or {@code invalid}. */
    public static String of(Throwable failure) {
        Throwable cause = failure;
        for (int depth = 0; cause != null && depth < MAX_CAUSE_DEPTH; depth++, cause = cause.getCause()) {
            if (cause instanceof InvalidJwtException jwt) {
                return reasonOf(jwt);
            }
            if (cause instanceof MissingSubjectException) {
                return "no_sub";
            }
        }
        return "invalid";
    }

    private static String reasonOf(InvalidJwtException jwt) {
        if (jwt.hasExpired()) {
            return "expired";
        }
        if (jwt.hasErrorCode(ErrorCodes.NOT_YET_VALID)) {
            return "not_yet_valid";
        }
        if (jwt.hasErrorCode(ErrorCodes.AUDIENCE_INVALID) || jwt.hasErrorCode(ErrorCodes.AUDIENCE_MISSING)) {
            return "audience";
        }
        if (jwt.hasErrorCode(ErrorCodes.SIGNATURE_INVALID) || jwt.hasErrorCode(ErrorCodes.SIGNATURE_MISSING)) {
            return "signature";
        }
        if (jwt.hasErrorCode(ErrorCodes.ISSUER_INVALID) || jwt.hasErrorCode(ErrorCodes.ISSUER_MISSING)) {
            return "issuer";
        }
        return "invalid";
    }
}
