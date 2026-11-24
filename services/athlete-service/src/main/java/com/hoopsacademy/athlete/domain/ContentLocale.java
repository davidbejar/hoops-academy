package com.hoopsacademy.athlete.domain;

import com.hoopsacademy.common.i18n.AppLanguage;
import java.util.Optional;

/**
 * A language the global templates are written in (common.yaml Locale). English is the fallback (decision 43). The
 * request's language comes from common-quarkus' {@code AcceptLanguage}; the codes and tags are read as
 * {@link AppLanguage} reads them.
 */
public enum ContentLocale {
    ES("es"),
    EN("en"),
    ID("id");

    public static final ContentLocale FALLBACK = EN;

    private final String code;

    ContentLocale(String code) {
        this.code = code;
    }

    public String code() {
        return code;
    }

    public static ContentLocale of(AppLanguage language) {
        return valueOf(language.name());
    }

    /** The language of a code or language tag ({@code es}, {@code es-AR}, {@code ID}); empty when unsupported. */
    public static Optional<ContentLocale> fromCode(String tag) {
        return AppLanguage.fromTag(tag).map(ContentLocale::of);
    }
}
