package com.hoopsacademy.game.application.sheet;

/** The languages a match sheet's labels are printed in (ADR-0048: es / en / id, English the fallback). */
public enum SheetLanguage {
    ES("es"),
    EN("en"),
    ID("id");

    public static final SheetLanguage FALLBACK = EN;

    private final String code;

    SheetLanguage(String code) {
        this.code = code;
    }

    /** The ISO 639-1 code pdf-service takes as {@code locale}. */
    public String code() {
        return code;
    }
}
