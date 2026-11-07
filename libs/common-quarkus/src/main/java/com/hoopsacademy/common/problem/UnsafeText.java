package com.hoopsacademy.common.problem;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Request text the stack cannot take (SD-02 of the 2026-11 review). PostgreSQL rejects a NUL character in {@code text}
 * and {@code jsonb} ({@code invalid byte sequence for encoding "UTF8": 0x00}); without these rules that surfaced as a
 * 500. A URI carries no legitimate control character at all; JSON text may carry tab, newline and the other C0
 * characters (they are storable and encoded on output), only NUL is refused there.
 */
public final class UnsafeText {

    /** Problem {@code code} of a request refused for its characters. */
    public static final String CODE = "INVALID_CHARACTERS";

    private static final char NUL = '\0';
    private static final char FIRST_PRINTABLE = ' ';
    private static final char DEL = '\u007f';

    private UnsafeText() {
    }

    /** A raw (still percent-encoded) request URI with a C0 control character or DEL, literal or {@code %XX}. */
    static boolean uriHasControlCharacter(String rawUri) {
        if (rawUri == null) {
            return false;
        }
        for (int i = 0; i < rawUri.length(); i++) {
            char c = rawUri.charAt(i);
            if (isControl(c) || c == '%' && encodesControl(rawUri, i + 1)) {
                return true;
            }
        }
        return false;
    }

    /** JSON text PostgreSQL cannot store. */
    static boolean containsNul(String text) {
        return text != null && text.indexOf(NUL) >= 0;
    }

    /**
     * Where a JSON tree holds a NUL: the field names and array indexes from the root to the first such text value, or to
     * the object whose field name has one; empty when there is none.
     */
    static Optional<List<Object>> nulPathIn(JsonNode node) {
        return switch (node.getNodeType()) {
            case STRING -> containsNul(node.textValue()) ? Optional.of(List.of()) : Optional.empty();
            case ARRAY -> nulPathInElements(node);
            case OBJECT -> nulPathInFields(node);
            default -> Optional.empty();
        };
    }

    private static Optional<List<Object>> nulPathInElements(JsonNode array) {
        for (int i = 0; i < array.size(); i++) {
            Optional<List<Object>> found = nulPathIn(array.get(i));
            if (found.isPresent()) {
                return Optional.of(prepend(i, found.get()));
            }
        }
        return Optional.empty();
    }

    private static Optional<List<Object>> nulPathInFields(JsonNode object) {
        for (Map.Entry<String, JsonNode> field : object.properties()) {
            if (containsNul(field.getKey())) {
                return Optional.of(List.of());
            }
            Optional<List<Object>> found = nulPathIn(field.getValue());
            if (found.isPresent()) {
                return Optional.of(prepend(field.getKey(), found.get()));
            }
        }
        return Optional.empty();
    }

    private static List<Object> prepend(Object step, List<Object> path) {
        List<Object> longer = new ArrayList<>(path.size() + 1);
        longer.add(step);
        longer.addAll(path);
        return List.copyOf(longer);
    }

    private static boolean encodesControl(String rawUri, int digits) {
        if (digits + 2 > rawUri.length()) {
            return false;
        }
        int high = hexValue(rawUri.charAt(digits));
        int low = hexValue(rawUri.charAt(digits + 1));
        return high >= 0 && low >= 0 && isControl(high * 16 + low);
    }

    private static boolean isControl(int c) {
        return c < FIRST_PRINTABLE || c == DEL;
    }

    /** ASCII hex digits only: {@code Character.digit} alone also takes other scripts' digits. */
    private static int hexValue(char c) {
        return c <= 'f' ? Character.digit(c, 16) : -1;
    }
}
