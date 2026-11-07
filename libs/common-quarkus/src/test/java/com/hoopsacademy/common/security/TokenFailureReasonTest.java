package com.hoopsacademy.common.security;

import static org.assertj.core.api.Assertions.assertThat;

import io.quarkus.security.AuthenticationFailedException;
import java.util.List;
import org.jose4j.jwt.consumer.ErrorCodeValidator;
import org.jose4j.jwt.consumer.ErrorCodes;
import org.jose4j.jwt.consumer.InvalidJwtException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class TokenFailureReasonTest {

    @ParameterizedTest
    @CsvSource({
        ErrorCodes.EXPIRED + ", expired",
        ErrorCodes.NOT_YET_VALID + ", not_yet_valid",
        ErrorCodes.AUDIENCE_INVALID + ", audience",
        ErrorCodes.AUDIENCE_MISSING + ", audience",
        ErrorCodes.SIGNATURE_INVALID + ", signature",
        ErrorCodes.SIGNATURE_MISSING + ", signature",
        ErrorCodes.ISSUER_INVALID + ", issuer",
        ErrorCodes.ISSUER_MISSING + ", issuer",
        ErrorCodes.MALFORMED_CLAIM + ", invalid"})
    void aJoseValidationErrorNamesWhatFailed(int code, String reason) {
        Throwable failure = new AuthenticationFailedException(jwtError(code, "claims {\"email\":\"a@b.c\"} rejected"));

        assertThat(TokenFailureReason.of(failure)).isEqualTo(reason);
    }

    @Test
    void anythingElseIsInvalidAndTheMessageIsNeverUsed() {
        assertThat(TokenFailureReason.of(new AuthenticationFailedException("eyJhbGciOi.secret.token"))).isEqualTo("invalid");
        assertThat(TokenFailureReason.of(null)).isEqualTo("invalid");
    }

    @Test
    void aTokenWithoutSubjectIsNoSub() {
        assertThat(TokenFailureReason.of(MissingSubjectException.failure())).isEqualTo("no_sub");
    }

    @Test
    void aDeepCauseIsFoundAndASelfCausedChainEnds() {
        Throwable deep = new RuntimeException(new IllegalStateException(jwtError(ErrorCodes.EXPIRED, "x")));
        assertThat(TokenFailureReason.of(deep)).isEqualTo("expired");

        Throwable loop = new LoopingException();
        assertThat(TokenFailureReason.of(loop)).isEqualTo("invalid");
    }

    @Test
    void theChainIsSearchedSixteenCausesDeep() {
        assertThat(TokenFailureReason.of(wrapped(jwtError(ErrorCodes.EXPIRED, "x"), 15))).isEqualTo("expired");
        assertThat(TokenFailureReason.of(wrapped(jwtError(ErrorCodes.EXPIRED, "x"), 16))).isEqualTo("invalid");
    }

    private static Throwable wrapped(Throwable cause, int times) {
        Throwable out = cause;
        for (int i = 0; i < times; i++) {
            out = new RuntimeException(out);
        }
        return out;
    }

    private static InvalidJwtException jwtError(int code, String message) {
        return new InvalidJwtException(message, List.of(new ErrorCodeValidator.Error(code, message)), null);
    }

    private static final class LoopingException extends RuntimeException {
        @Override
        public synchronized Throwable getCause() {
            return new LoopingException();
        }
    }
}
