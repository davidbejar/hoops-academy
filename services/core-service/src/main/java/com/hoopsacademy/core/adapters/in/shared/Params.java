package com.hoopsacademy.core.adapters.in.shared;

import com.hoopsacademy.common.problem.Problem;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Optional;

/** Conversions of optional query parameters with a 400 Problem on malformed input. */
public final class Params {

    private Params() {}

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
