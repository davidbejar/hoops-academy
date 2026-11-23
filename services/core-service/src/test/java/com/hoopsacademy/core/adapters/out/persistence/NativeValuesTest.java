package com.hoopsacademy.core.adapters.out.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.sql.Date;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import org.junit.jupiter.api.Test;

/** CORE-10: one conversion of the values native queries return, whatever type the driver maps a column to. */
class NativeValuesTest {

    private static final Instant AT = Instant.parse("2026-11-23T10:15:30.123456Z");
    private static final LocalDate DAY = LocalDate.of(2026, 11, 23);

    @Test
    void everyTimestampTypeBecomesTheSameInstant() {
        assertThat(NativeValues.instant(AT)).isEqualTo(AT);
        assertThat(NativeValues.instant(AT.atOffset(ZoneOffset.ofHours(7)))).isEqualTo(AT);
        assertThat(NativeValues.instant(Timestamp.from(AT))).isEqualTo(AT);
    }

    @Test
    void everyDateTypeBecomesTheSameLocalDate() {
        assertThat(NativeValues.date(DAY)).isEqualTo(DAY);
        assertThat(NativeValues.date(Date.valueOf(DAY))).isEqualTo(DAY);
    }

    @Test
    void aNullColumnStaysNull() {
        assertThat(NativeValues.instant(null)).isNull();
        assertThat(NativeValues.date(null)).isNull();
    }

    @Test
    void anotherTypeIsAMappingErrorNamingTheType() {
        assertThatThrownBy(() -> NativeValues.instant("2026-11-23")).isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("java.lang.String");
        assertThatThrownBy(() -> NativeValues.date(42)).isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("java.lang.Integer");
    }
}
