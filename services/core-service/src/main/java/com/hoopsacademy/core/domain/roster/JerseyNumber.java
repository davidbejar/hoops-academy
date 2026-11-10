package com.hoopsacademy.core.domain.roster;

import com.hoopsacademy.core.domain.shared.Require;
import java.util.Comparator;
import java.util.regex.Pattern;

/**
 * A jersey as printed: one or two digits, so "0", "00" and "7" are different numbers. Ordered by value, the plain
 * number before its leading-zero form ("0", "00", "7", "07", "8").
 */
public record JerseyNumber(String value) implements Comparable<JerseyNumber> {

    private static final Pattern DIGITS = Pattern.compile("^[0-9]{1,2}$");
    private static final Comparator<JerseyNumber> ORDER = Comparator
            .comparingInt((JerseyNumber number) -> Integer.parseInt(number.value))
            .thenComparingInt(number -> number.value.length());

    public JerseyNumber {
        if (value == null || !DIGITS.matcher(value).matches()) {
            throw Require.violation("jerseyNumber", "jerseyNumber must be one or two digits");
        }
    }

    public static JerseyNumber of(String value) {
        return new JerseyNumber(value);
    }

    public static JerseyNumber ofNullable(String value) {
        return value == null ? null : new JerseyNumber(value);
    }

    @Override
    public int compareTo(JerseyNumber other) {
        return ORDER.compare(this, other);
    }
}
