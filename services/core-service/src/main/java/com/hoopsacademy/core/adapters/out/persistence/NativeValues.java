package com.hoopsacademy.core.adapters.out.persistence;

import java.sql.Date;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.OffsetDateTime;

/** Column values of native queries, whichever Java type the driver and Hibernate map them to; null stays null. */
public final class NativeValues {

    private NativeValues() {}

    /** A {@code timestamptz} column. */
    public static Instant instant(Object value) {
        return switch (value) {
            case null -> null;
            case Instant instant -> instant;
            case OffsetDateTime offset -> offset.toInstant();
            case Timestamp timestamp -> timestamp.toInstant();
            default -> throw new IllegalStateException("Not a timestamp: " + value.getClass().getName());
        };
    }

    /** A {@code date} column. */
    public static LocalDate date(Object value) {
        return switch (value) {
            case null -> null;
            case LocalDate local -> local;
            case Date sql -> sql.toLocalDate();
            default -> throw new IllegalStateException("Not a date: " + value.getClass().getName());
        };
    }
}
