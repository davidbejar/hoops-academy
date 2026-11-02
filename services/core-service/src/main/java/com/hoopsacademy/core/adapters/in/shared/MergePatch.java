package com.hoopsacademy.core.adapters.in.shared;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.common.problem.CodedProblemException;
import com.hoopsacademy.common.problem.Problem;
import com.hoopsacademy.core.domain.shared.Patch;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.function.Function;
import java.util.regex.Pattern;

/**
 * Reads a JSON merge-patch body (absent = unchanged, {@code null} = clear) into {@link Patch} values, collecting
 * every syntactic problem so the client gets one 400 with all violations. Domain rules are checked later (422).
 */
public final class MergePatch {

    private static final Pattern EMAIL = Pattern.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");

    private final JsonNode body;
    private final String prefix;
    private final List<Problem.Violation> violations = new ArrayList<>();

    private MergePatch(JsonNode body, String prefix) {
        this.body = body;
        this.prefix = prefix;
    }

    public static MergePatch of(JsonNode body) {
        if (body == null || !body.isObject()) {
            throw new InvalidRequestException(List.of(new Problem.Violation("body", "must be a JSON object")));
        }
        return new MergePatch(body, "");
    }

    /** A nullable text field of at most {@code maxLength} characters. */
    public Patch<String> text(String field, int maxLength) {
        return read(field, true, node -> {
            if (!node.isTextual() || node.asText().length() > maxLength) {
                return reject(field, "must be a string of at most " + maxLength + " characters");
            }
            return Optional.of(node.asText());
        });
    }

    /** A text field that may be absent but never null or blank. */
    public Patch<String> requiredText(String field, int maxLength) {
        return read(field, false, node -> {
            if (!node.isTextual() || node.asText().isBlank() || node.asText().length() > maxLength) {
                return reject(field, "must be a non-blank string of at most " + maxLength + " characters");
            }
            return Optional.of(node.asText());
        });
    }

    /** A text field matching {@code regex} (contract {@code pattern}). */
    public Patch<String> matching(String field, boolean nullable, Pattern regex) {
        return read(field, nullable, node -> {
            if (!node.isTextual() || !regex.matcher(node.asText()).matches()) {
                return reject(field, "must match " + regex.pattern());
            }
            return Optional.of(node.asText());
        });
    }

    /** An integer field within {@code min..max}. */
    public Patch<Integer> integer(String field, boolean nullable, int min, int max) {
        return read(field, nullable, node -> {
            if (!node.isInt() || node.asInt() < min || node.asInt() > max) {
                return reject(field, "must be an integer " + min + ".." + max);
            }
            return Optional.of(node.asInt());
        });
    }

    public Patch<String> email(String field, boolean nullable) {
        return read(field, nullable, node -> {
            if (!node.isTextual() || node.asText().length() > 254 || !EMAIL.matcher(node.asText()).matches()) {
                return reject(field, "must be an e-mail address");
            }
            return Optional.of(node.asText());
        });
    }

    /**
     * A field converted from its string form; a conversion failure is a 400 violation, while a domain rule the parser
     * enforces (e.g. an unknown time zone, 422) propagates unchanged.
     */
    public <T> Patch<T> parsed(String field, boolean nullable, Function<String, T> parser) {
        return read(field, nullable, node -> {
            if (!node.isTextual()) {
                return reject(field, "must be a string");
            }
            try {
                return Optional.of(parser.apply(node.asText()));
            } catch (CodedProblemException e) {
                throw e;
            } catch (RuntimeException e) {
                return reject(field, "has an invalid value");
            }
        });
    }

    /** Every property other than {@code fields} is a violation (contract {@code additionalProperties: false}). */
    public void allowOnly(String... fields) {
        java.util.Set<String> allowed = java.util.Set.of(fields);
        body.fieldNames().forEachRemaining(name -> {
            if (!allowed.contains(name)) {
                reject(name, "is not a known property");
            }
        });
    }

    /** @throws InvalidRequestException when any field was invalid or {@code requireAny} and nothing was sent */
    public void validate(boolean requireAny) {
        if (requireAny && body.isEmpty()) {
            violations.add(new Problem.Violation(prefix + "body", "must contain at least one property"));
        }
        if (!violations.isEmpty()) {
            throw new InvalidRequestException(violations);
        }
    }

    private <T> Patch<T> read(String field, boolean nullable, Function<JsonNode, Optional<T>> parse) {
        if (!body.has(field)) {
            return Patch.absent();
        }
        JsonNode node = body.get(field);
        if (node.isNull()) {
            if (!nullable) {
                reject(field, "must not be null");
                return Patch.absent();
            }
            return Patch.of(null);
        }
        return parse.apply(node).map(Patch::of).orElseGet(Patch::absent);
    }

    private <T> Optional<T> reject(String field, String message) {
        violations.add(new Problem.Violation(prefix + field, message));
        return Optional.empty();
    }
}
