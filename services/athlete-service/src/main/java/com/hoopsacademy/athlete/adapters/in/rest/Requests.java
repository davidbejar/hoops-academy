package com.hoopsacademy.athlete.adapters.in.rest;

import com.hoopsacademy.athlete.application.InvalidRequestException;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeParseException;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;

/** Parsing of raw query parameters: malformed values are a 400 with the offending field (not a 404). */
final class Requests {

    private Requests() {}

    static Optional<UUID> uuid(String field, String raw) {
        return parse(field, raw, UUID::fromString, "a UUID");
    }

    static Optional<LocalDate> date(String field, String raw) {
        return parse(field, raw, LocalDate::parse, "an ISO date (YYYY-MM-DD)");
    }

    static <T> Optional<T> parse(String field, String raw, Function<String, T> parser, String expected) {
        if (raw == null || raw.isBlank()) {
            return Optional.empty();
        }
        try {
            return Optional.of(parser.apply(raw));
        } catch (IllegalArgumentException | DateTimeParseException e) {
            throw new InvalidRequestException(field, "INVALID_VALUE", field + " must be " + expected);
        }
    }

    static LocalTime time(String field, String raw) {
        try {
            return LocalTime.parse(raw);
        } catch (DateTimeParseException e) {
            throw new InvalidRequestException(field, "INVALID_VALUE", field + " must be HH:mm");
        }
    }

    static String formatTime(LocalTime time) {
        return "%02d:%02d".formatted(time.getHour(), time.getMinute());
    }
}
