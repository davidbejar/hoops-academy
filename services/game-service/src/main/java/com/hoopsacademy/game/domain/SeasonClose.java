package com.hoopsacademy.game.domain;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Objects;

/** When a season closes (ADR-0042): the start of the day after its last day, in the academy's time zone. */
public record SeasonClose(Instant at) {

    public SeasonClose {
        Objects.requireNonNull(at, "at");
    }

    public static SeasonClose after(LocalDate lastDay, ZoneId zone) {
        return new SeasonClose(lastDay.plusDays(1).atStartOfDay(zone).toInstant());
    }

    /** True from the closing instant on. */
    public boolean hasPassed(Instant now) {
        return !now.isBefore(at);
    }
}
