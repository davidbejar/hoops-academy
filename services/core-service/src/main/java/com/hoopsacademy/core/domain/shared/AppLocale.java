package com.hoopsacademy.core.domain.shared;

import com.hoopsacademy.common.i18n.AppLanguage;
import java.util.Arrays;

/** UI language of the platform (contract {@code Locale}). */
public enum AppLocale {
    ES("es"),
    EN("en"),
    ID("id");

    private final String code;

    AppLocale(String code) {
        this.code = code;
    }

    public String code() {
        return code;
    }

    /** The locale of a language common-quarkus negotiated (e.g. from {@code Accept-Language}). */
    public static AppLocale of(AppLanguage language) {
        return valueOf(language.name());
    }

    public static AppLocale fromCode(String code) {
        return Arrays.stream(values()).filter(locale -> locale.code.equals(code)).findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unsupported locale: " + code));
    }
}
