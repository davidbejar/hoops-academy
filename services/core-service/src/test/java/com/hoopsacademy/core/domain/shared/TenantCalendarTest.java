package com.hoopsacademy.core.domain.shared;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.core.domain.eligibility.AgeFunction;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import org.junit.jupiter.api.Test;

class TenantCalendarTest {

    private static final ZoneId JAKARTA = ZoneId.of("Asia/Jakarta");
    private static final ZoneId MADRID = ZoneId.of("Europe/Madrid");

    @Test
    void todayDependsOnTheTenantTimeZone() {
        Instant jakartaMidnight = Instant.parse("2026-11-01T17:00:00Z");
        assertThat(TenantCalendar.today(jakartaMidnight, JAKARTA)).isEqualTo(LocalDate.of(2026, 11, 2));
        assertThat(TenantCalendar.today(jakartaMidnight, MADRID)).isEqualTo(LocalDate.of(2026, 11, 1));
        assertThat(TenantCalendar.today(jakartaMidnight.minusSeconds(1), JAKARTA)).isEqualTo(LocalDate.of(2026, 11, 1));
    }

    @Test
    void aBirthdayStartsAtLocalMidnightNotAtUtcMidnight() {
        LocalDate born = LocalDate.of(2014, 11, 2);
        Instant madridMidnight = Instant.parse("2026-11-01T23:00:00Z");
        int beforeInMadrid = AgeFunction.BIRTHDAY.ageOf(born, 2026, TenantCalendar.today(madridMidnight.minusSeconds(1), MADRID));
        int atMidnightInMadrid = AgeFunction.BIRTHDAY.ageOf(born, 2026, TenantCalendar.today(madridMidnight, MADRID));
        int sameInstantInJakarta = AgeFunction.BIRTHDAY.ageOf(born, 2026,
                TenantCalendar.today(madridMidnight.minusSeconds(1), JAKARTA));
        assertThat(beforeInMadrid).isEqualTo(11);
        assertThat(atMidnightInMadrid).isEqualTo(12);
        assertThat(sameInstantInJakarta).isEqualTo(12);
    }
}
