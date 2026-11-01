package com.hoopsacademy.game.domain;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import java.util.regex.Pattern;

/** A jersey number: one or two digits, kept as text (as core does) so "00" and "0" stay distinct. */
public record JerseyNumber(String value) {

    private static final Pattern FORMAT = Pattern.compile("^[0-9]{1,2}$");

    public JerseyNumber {
        if (value == null || !FORMAT.matcher(value).matches()) {
            throw new DomainRuleViolation("Jersey number must be one or two digits", "INVALID_JERSEY_NUMBER");
        }
    }

    public static JerseyNumber ofNullable(String value) {
        return value == null ? null : new JerseyNumber(value);
    }
}
