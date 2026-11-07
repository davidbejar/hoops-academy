package com.hoopsacademy.core.domain.signup;

/**
 * The name of a requested academy: 1..120 characters, trimmed, inner whitespace collapsed, no control characters. The
 * uniqueness rule (case-insensitive, against academies and open requests) is the database's ({@code
 * core.academy_name_key}, V17) so that both sides compare the same way.
 */
public record AcademyName(String value) {

    public static final int MAX_LENGTH = 120;

    public AcademyName {
        value = PlainText.line(value, "academyName", MAX_LENGTH);
    }

    public static AcademyName of(String raw) {
        return new AcademyName(raw);
    }

    @Override
    public String toString() {
        return value;
    }
}
