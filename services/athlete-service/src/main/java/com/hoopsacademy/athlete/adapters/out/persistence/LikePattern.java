package com.hoopsacademy.athlete.adapters.out.persistence;

import java.util.Locale;

/** The {@code like :q escape '\'} pattern of a free-text search: lower case in the root locale, wildcards escaped. */
final class LikePattern {

    private LikePattern() {}

    /** Matches any text that contains {@code term}, case-insensitively against a {@code lower(...)} column. */
    static String contains(String term) {
        return "%" + term.toLowerCase(Locale.ROOT).replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%";
    }
}
