package com.hoopsacademy.core.adapters.in.shared;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.common.problem.CodedProblemException;
import com.hoopsacademy.common.problem.Problem;
import com.hoopsacademy.core.domain.shared.Patch;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.TreeSet;
import java.util.function.Function;
import java.util.regex.Pattern;

/**
 * Reads a partial-update body (ADR-0032) into {@link Patch} values: an absent or {@code null} member is unchanged, a
 * member named in the {@code clear} list is set to null. A member is nullable exactly when the request declares it
 * clearable (the {@code clear} enum of its contract schema); {@code null} for any other member is a violation. A member
 * both cleared and given a value is a {@code CLEAR_CONFLICT}. Every syntactic problem is collected so the client gets
 * one 400 with all violations; domain rules are checked later (422).
 */
public final class PatchBody {

    private static final String CLEAR = "clear";
    private static final String CLEAR_CONFLICT = "CLEAR_CONFLICT";
    private static final String INVALID_VALUE = "INVALID_VALUE";
    private static final Pattern EMAIL = Pattern.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");

    private final JsonNode body;
    private final Set<String> clearable;
    private final List<Problem.Violation> violations = new ArrayList<>();
    private final Set<String> cleared;

    private PatchBody(JsonNode body, Set<String> clearable) {
        this.body = body;
        this.clearable = Set.copyOf(clearable);
        this.cleared = clearList(body.get(CLEAR));
        for (String name : cleared) {
            JsonNode value = body.get(name);
            if (value != null && !value.isNull()) {
                violations.add(new Problem.Violation(name, CLEAR_CONFLICT,
                        name + " is both given a value and named in clear"));
            }
        }
    }

    /** A body with nothing to clear: {@code null} is never accepted and any {@code clear} name is a violation. */
    public static PatchBody of(JsonNode body) {
        return of(body, Set.of());
    }

    /** @param clearable the request's optional members that can be emptied: the {@code clear} enum of its schema */
    public static PatchBody of(JsonNode body, Set<String> clearable) {
        if (body == null || !body.isObject()) {
            throw new InvalidRequestException(List.of(new Problem.Violation("body", "must be a JSON object")));
        }
        return new PatchBody(body, clearable);
    }

    private Set<String> clearList(JsonNode node) {
        if (node == null || node.isNull()) {
            return Set.of();
        }
        if (!node.isArray()) {
            invalidClear("must be a list of property names");
            return Set.of();
        }
        Set<String> names = new LinkedHashSet<>();
        for (JsonNode item : node) {
            if (!item.isTextual() || !clearable.contains(item.asText())) {
                invalidClear(clearable.isEmpty() ? "this request has nothing to clear"
                        : "may only name " + String.join(", ", new TreeSet<>(clearable)));
                return Set.of();
            }
            if (!names.add(item.asText())) {
                invalidClear("names " + item.asText() + " twice");
                return Set.of();
            }
        }
        return Set.copyOf(names);
    }

    private void invalidClear(String message) {
        violations.add(new Problem.Violation(CLEAR, INVALID_VALUE, CLEAR + " " + message));
    }

    /** A text member of at most {@code maxLength} characters. */
    public Patch<String> text(String field, int maxLength) {
        return read(field, node -> {
            if (!node.isTextual() || node.asText().length() > maxLength) {
                return reject(field, "must be a string of at most " + maxLength + " characters");
            }
            return Optional.of(node.asText());
        });
    }

    /** A text member that is never blank. */
    public Patch<String> nonBlankText(String field, int maxLength) {
        return read(field, node -> {
            if (!node.isTextual() || node.asText().isBlank() || node.asText().length() > maxLength) {
                return reject(field, "must be a non-blank string of at most " + maxLength + " characters");
            }
            return Optional.of(node.asText());
        });
    }

    /** A text member matching {@code regex} (contract {@code pattern}). */
    public Patch<String> matching(String field, Pattern regex) {
        return read(field, node -> {
            if (!node.isTextual() || !regex.matcher(node.asText()).matches()) {
                return reject(field, "must match " + regex.pattern());
            }
            return Optional.of(node.asText());
        });
    }

    /** An integer member within {@code min..max}. */
    public Patch<Integer> integer(String field, int min, int max) {
        return read(field, node -> {
            if (!node.isInt() || node.asInt() < min || node.asInt() > max) {
                return reject(field, "must be an integer " + min + ".." + max);
            }
            return Optional.of(node.asInt());
        });
    }

    public Patch<String> email(String field) {
        return read(field, node -> {
            if (!node.isTextual() || node.asText().length() > 254 || !EMAIL.matcher(node.asText()).matches()) {
                return reject(field, "must be an e-mail address");
            }
            return Optional.of(node.asText());
        });
    }

    /**
     * A member converted from its string form; a conversion failure is a 400 violation, while a domain rule the parser
     * enforces (e.g. an unknown time zone, 422) propagates unchanged.
     */
    public <T> Patch<T> parsed(String field, Function<String, T> parser) {
        return read(field, node -> {
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
        Set<String> allowed = Set.of(fields);
        body.fieldNames().forEachRemaining(name -> {
            if (!allowed.contains(name)) {
                reject(name, "is not a known property");
            }
        });
    }

    /** @throws InvalidRequestException when any member was invalid or the body changes nothing (no member, empty clear) */
    public void validate() {
        if (violations.isEmpty() && cleared.isEmpty() && !hasMemberBesidesClear()) {
            violations.add(new Problem.Violation("body", "must contain at least one property"));
        }
        if (!violations.isEmpty()) {
            throw new InvalidRequestException(violations);
        }
    }

    private boolean hasMemberBesidesClear() {
        for (Iterator<String> names = body.fieldNames(); names.hasNext();) {
            if (!CLEAR.equals(names.next())) {
                return true;
            }
        }
        return false;
    }

    private <T> Patch<T> read(String field, Function<JsonNode, Optional<T>> parse) {
        if (cleared.contains(field)) {
            return Patch.of(null);
        }
        JsonNode node = body.get(field);
        if (node == null) {
            return Patch.absent();
        }
        if (node.isNull()) {
            if (!clearable.contains(field)) {
                reject(field, "must not be null");
            }
            return Patch.absent();
        }
        return parse.apply(node).map(Patch::of).orElseGet(Patch::absent);
    }

    private <T> Optional<T> reject(String field, String message) {
        violations.add(new Problem.Violation(field, message));
        return Optional.empty();
    }
}
