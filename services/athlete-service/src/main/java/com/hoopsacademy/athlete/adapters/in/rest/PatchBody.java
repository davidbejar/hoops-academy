package com.hoopsacademy.athlete.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.athlete.application.InvalidRequestException;
import java.util.Optional;
import java.util.function.Function;

/**
 * A JSON merge-patch body that tells "field absent" (untouched) from "field null" (clear). Absent members give
 * {@code Optional.empty()}; a present nullable member gives {@code Optional.of(Optional.empty())} when it is null.
 */
final class PatchBody {

    private final JsonNode body;

    PatchBody(JsonNode body) {
        if (body == null || !body.isObject() || body.isEmpty()) {
            throw new InvalidRequestException("body", "EMPTY_PATCH", "At least one property must be given");
        }
        this.body = body;
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

    /** A nullable member: absent = untouched, null = clear. */
    <T> Optional<Optional<T>> nullable(String field, Function<JsonNode, T> parser) {
        JsonNode node = body.get(field);
        if (node == null) {
            return Optional.empty();
        }
        return Optional.of(node.isNull() ? Optional.empty() : Optional.of(parse(field, node, parser)));
    }

    static Function<JsonNode, String> text(int maxLength) {
        return node -> {
            if (!node.isTextual() || node.asText().length() > maxLength) {
                throw new IllegalArgumentException("a string of at most " + maxLength + " characters");
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
