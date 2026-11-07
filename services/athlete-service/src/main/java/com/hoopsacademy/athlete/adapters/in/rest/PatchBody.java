package com.hoopsacademy.athlete.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.athlete.application.InvalidRequestException;
import java.util.Iterator;
import java.util.LinkedHashSet;
import java.util.Optional;
import java.util.Set;
import java.util.TreeSet;
import java.util.function.Function;

/**
 * A partial-update body (ADR-0032): an absent or {@code null} member is unchanged, a member named in the {@code clear}
 * list is set to null. Nullable members give {@code Optional.empty()} when unchanged and
 * {@code Optional.of(Optional.empty())} when cleared. A member both cleared and given a value is a 400
 * ({@code CLEAR_CONFLICT}); a name outside the request's clearable members is a 400 on {@code clear}.
 */
final class PatchBody {

    private static final String CLEAR = "clear";

    private final JsonNode body;
    private final Set<String> clearable;
    private final Set<String> cleared;

    /** @param clearable the request's optional, nullable members: the {@code clear} enum of its contract schema */
    PatchBody(JsonNode body, Set<String> clearable) {
        // a body that is not an object has no members either: it is an empty patch below
        if (body == null) {
            throw emptyPatch();
        }
        this.body = body;
        this.clearable = Set.copyOf(clearable);
        this.cleared = clearList(body.get(CLEAR), this.clearable);
        if (cleared.isEmpty() && !hasMemberBesidesClear(body)) {
            throw emptyPatch();
        }
        for (String name : cleared) {
            JsonNode value = body.get(name);
            if (value != null && !value.isNull()) {
                throw new InvalidRequestException(name, "CLEAR_CONFLICT", name + " is both given a value and named in clear");
            }
        }
    }

    private static Set<String> clearList(JsonNode node, Set<String> clearable) {
        if (node == null || node.isNull()) {
            return Set.of();
        }
        if (!node.isArray()) {
            throw invalid(CLEAR, "must be a list of property names");
        }
        Set<String> names = new LinkedHashSet<>();
        for (JsonNode item : node) {
            if (!item.isTextual() || !clearable.contains(item.asText())) {
                throw invalid(CLEAR, "may only name " + String.join(", ", new TreeSet<>(clearable)));
            }
            if (!names.add(item.asText())) {
                throw invalid(CLEAR, "names " + item.asText() + " twice");
            }
        }
        return Set.copyOf(names);
    }

    private static boolean hasMemberBesidesClear(JsonNode body) {
        for (Iterator<String> names = body.fieldNames(); names.hasNext();) {
            if (!CLEAR.equals(names.next())) {
                return true;
            }
        }
        return false;
    }

    private static InvalidRequestException emptyPatch() {
        return new InvalidRequestException("body", "EMPTY_PATCH", "At least one property must be given");
    }

    /** A non-nullable member: absent = untouched, null = 400. */
    <T> Optional<T> required(String field, Function<JsonNode, T> parser) {
        JsonNode node = body.get(field);
        if (node == null) {
            return Optional.empty();
        }
        if (node.isNull()) {
            throw invalid(field, "must not be null");
        }
        return Optional.of(parse(field, node, parser));
    }

    /** A clearable member: absent or null = untouched, named in {@code clear} = set to null. */
    <T> Optional<Optional<T>> nullable(String field, Function<JsonNode, T> parser) {
        if (!clearable.contains(field)) {
            throw new IllegalStateException(field + " is not declared clearable for this request");
        }
        if (cleared.contains(field)) {
            return Optional.of(Optional.empty());
        }
        JsonNode node = body.get(field);
        if (node == null || node.isNull()) {
            return Optional.empty();
        }
        return Optional.of(Optional.of(parse(field, node, parser)));
    }

    static Function<JsonNode, String> text(int maxLength) {
        return node -> {
            if (!node.isTextual() || node.asText().length() > maxLength) {
                throw new IllegalArgumentException("a string of at most " + maxLength + " characters");
            }
            return node.asText();
        };
    }

    /** A non-blank string of at most {@code maxLength} characters. */
    static Function<JsonNode, String> nonBlankText(int maxLength) {
        return node -> {
            if (!node.isTextual() || node.asText().isBlank() || node.asText().length() > maxLength) {
                throw new IllegalArgumentException("a non-blank string of at most " + maxLength + " characters");
            }
            return node.asText();
        };
    }

    static Function<JsonNode, Integer> integer(int min, int max) {
        return node -> {
            if (!node.isInt() || node.asInt() < min || node.asInt() > max) {
                throw new IllegalArgumentException("an integer between " + min + " and " + max);
            }
            return node.asInt();
        };
    }

    /** A JSON number between {@code min} and {@code max} (inclusive). */
    static Function<JsonNode, java.math.BigDecimal> decimal(double min, double max) {
        return node -> {
            if (!node.isNumber() || node.asDouble() < min || node.asDouble() > max) {
                throw new IllegalArgumentException("a number between " + min + " and " + max);
            }
            return node.decimalValue();
        };
    }

    static <T> Function<JsonNode, T> fromText(Function<String, T> parser, String expected) {
        return node -> {
            if (!node.isTextual()) {
                throw new IllegalArgumentException(expected);
            }
            try {
                return parser.apply(node.asText());
            } catch (RuntimeException e) {
                throw new IllegalArgumentException(expected);
            }
        };
    }

    private static <T> T parse(String field, JsonNode node, Function<JsonNode, T> parser) {
        try {
            return parser.apply(node);
        } catch (IllegalArgumentException e) {
            throw invalid(field, "must be " + e.getMessage());
        }
    }

    private static InvalidRequestException invalid(String field, String message) {
        return new InvalidRequestException(field, "INVALID_VALUE", field + " " + message);
    }
}
