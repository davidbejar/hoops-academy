package com.hoopsacademy.core.domain.identity;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import org.junit.jupiter.api.Test;

class TemporaryPasswordStatusTest {

    private static final Instant ISSUED = Instant.parse("2026-11-01T10:00:00Z");
    private static final Instant EXPIRED = Instant.parse("2026-11-04T10:00:00Z");

    @Test
    void anIssuedPasswordIsActiveUntilTheSweepExpiresIt() {
        assertThat(TemporaryPasswordStatus.of(ISSUED, null)).isEqualTo(TemporaryPasswordStatus.ACTIVE);
    }

    @Test
    void anExpiredPasswordStaysExpiredUntilANewOneIsIssued() {
        assertThat(TemporaryPasswordStatus.of(ISSUED, EXPIRED)).isEqualTo(TemporaryPasswordStatus.EXPIRED);
        assertThat(TemporaryPasswordStatus.of(null, EXPIRED)).isEqualTo(TemporaryPasswordStatus.EXPIRED);
    }

    @Test
    void nothingIssuedIsNone() {
        assertThat(TemporaryPasswordStatus.of(null, null)).isEqualTo(TemporaryPasswordStatus.NONE);
    }
}
