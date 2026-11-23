package com.hoopsacademy.core.adapters.out.persistence;

import java.util.Locale;

/** LIKE patterns of the list searches; the queries declare {@code escape '\'}. */
public final class LikePattern {

    private LikePattern() {}

    /** Matches any text that contains {@code text}, case-insensitively against a lower-cased column. */
    public static String contains(String text) {
        String escaped = text.toLowerCase(Locale.ROOT).replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
        return "%" + escaped + "%";
    }
}
