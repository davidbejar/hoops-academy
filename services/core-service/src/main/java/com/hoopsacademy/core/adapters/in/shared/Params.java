package com.hoopsacademy.core.adapters.in.shared;

import com.hoopsacademy.common.problem.Problem;
import java.time.Instant;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Conversions of optional query parameters with a 400 Problem on malformed input. */
public final class Params {

    private Params() {}

    public static Optional<UUID> uuid(String name, String value) {
        if (value == null) {
            return Optional.empty();
        }
        try {
            return Optional.of(UUID.fromString(value));
        } catch (IllegalArgumentException e) {
            throw new InvalidRequestException(List.of(new Problem.Violation(name, "must be a uuid")));
        }
    }

    public static Optional<Instant> instant(String name, String value) {
        if (value == null) {
            return Optional.empty();
        }
        try {
            return Optional.of(OffsetDateTime.parse(value).toInstant());
        } catch (DateTimeParseException e) {
            throw new InvalidRequestException(List.of(new Problem.Violation(name, "must be a date-time (RFC 3339)")));
        }
    }

    public static Optional<LocalDate> date(String name, String value) {
        if (value == null) {
            return Optional.empty();
        }
        try {
            return Optional.of(LocalDate.parse(value));
        } catch (DateTimeParseException e) {
            throw new InvalidRequestException(List.of(new Problem.Violation(name, "must be a date (yyyy-MM-dd)")));
        }
    }
}
