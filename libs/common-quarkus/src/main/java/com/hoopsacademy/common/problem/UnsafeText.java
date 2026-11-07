package com.hoopsacademy.common.problem;

/** Request text the stack cannot take (SD-02). Red stub: the rules follow in the next commit. */
public final class UnsafeText {

    public static final String CODE = "INVALID_CHARACTERS";

    private UnsafeText() {
    }

    static boolean uriHasControlCharacter(String rawUri) {
        return false;
    }

    static boolean containsNul(String text) {
        return false;
    }
}
