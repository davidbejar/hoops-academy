package com.hoopsacademy.common.i18n;

import java.util.Arrays;
import java.util.Locale;
import java.util.Optional;

/**
 * The languages of the platform (common.yaml {@code Locale}: es, en, id); English is the fallback (ADR-0039, ADR-0048).
 * The services keep their own uses (core's export labels, game's sheet locale, athlete's template texts).
 */
public enum AppLanguage {
    ES("es"),
    EN("en"),
    ID("id");

    public static final AppLanguage FALLBACK = EN;

    /** Java's historical code for Indonesian, still produced by some runtimes. */
    private static final String LEGACY_INDONESIAN = "in";

    private final String code;

    AppLanguage(String code) {
        this.code = code;
    }

    /** The ISO 639-1 code. */
    public String code() {
        return code;
    }

    /** The language of a code or language tag ({@code es}, {@code es-AR}, {@code ID}, {@code in}); empty otherwise. */
    public static Optional<AppLanguage> fromTag(String tag) {
        if (tag == null) {
            return Optional.empty();
        }
        String primary = tag.trim().split("[-_]", 2)[0].toLowerCase(Locale.ROOT);
        String language = LEGACY_INDONESIAN.equals(primary) ? ID.code : primary;
        return Arrays.stream(values()).filter(candidate -> candidate.code.equals(language)).findFirst();
    }
}
