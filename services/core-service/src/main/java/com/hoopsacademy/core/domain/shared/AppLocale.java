package com.hoopsacademy.core.domain.shared;

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

    public static AppLocale fromCode(String code) {
        return Arrays.stream(values()).filter(locale -> locale.code.equals(code)).findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unsupported locale: " + code));
    }
}
