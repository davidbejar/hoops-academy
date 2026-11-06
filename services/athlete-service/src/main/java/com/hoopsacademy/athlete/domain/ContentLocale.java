package com.hoopsacademy.athlete.domain;

import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

/** A language the global templates are written in (common.yaml Locale). English is the fallback (decision 43). */
public enum ContentLocale {
    ES("es"),
    EN("en"),
    ID("id");

    public static final ContentLocale FALLBACK = EN;

    /** Java's historical code for Indonesian, still produced by some runtimes. */
    private static final String LEGACY_INDONESIAN = "in";

    private final String code;

    ContentLocale(String code) {
        this.code = code;
    }

    public String code() {
        return code;
    }

    /** The language of a code or language tag ({@code es}, {@code es-AR}, {@code ID}); empty when unsupported. */
    public static Optional<ContentLocale> fromCode(String tag) {
        if (tag == null) {
            return Optional.empty();
        }
        String primary = tag.trim().split("[-_]", 2)[0].toLowerCase(Locale.ROOT);
        String language = LEGACY_INDONESIAN.equals(primary) ? ID.code : primary;
        return Arrays.stream(values()).filter(l -> l.code.equals(language)).findFirst();
    }

    /** The first supported language of a preference-ordered list of language tags, else {@link #FALLBACK}. */
    public static ContentLocale negotiate(List<String> preferred) {
        return preferred.stream().map(ContentLocale::fromCode).flatMap(Optional::stream).findFirst().orElse(FALLBACK);
    }
}
