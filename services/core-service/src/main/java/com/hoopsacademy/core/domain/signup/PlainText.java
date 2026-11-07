package com.hoopsacademy.core.domain.signup;

import com.hoopsacademy.core.domain.shared.Require;
import java.util.regex.Pattern;

/** One-line text from an anonymous form: whitespace runs collapsed, no control or format characters (bidi tricks). */
final class PlainText {

    private static final Pattern WHITESPACE = Pattern.compile("\\s+");
    private static final Pattern FORBIDDEN = Pattern.compile("[\\p{Cc}\\p{Cf}]");

    private PlainText() {}

    /** @return the trimmed, collapsed value, 1..{@code maxLength} characters */
    static String line(String raw, String field, int maxLength) {
        if (raw == null) {
            throw Require.violation(field, field + " is required");
        }
        String value = WHITESPACE.matcher(raw.strip()).replaceAll(" ");
        if (value.isEmpty() || value.length() > maxLength || FORBIDDEN.matcher(value).find()) {
            throw Require.violation(field, field + " must be 1.." + maxLength + " characters without control characters");
        }
        return value;
    }
}
