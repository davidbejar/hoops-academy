package com.hoopsacademy.game.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.game.domain.HomeAway;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.LinkedHashSet;
import java.util.Set;

/**
 * PATCH body (ADR-0032): an absent or {@code null} property is unchanged; a property named in {@code clear} is set
 * to null. Naming a property both in {@code clear} and with a value is a 400 ({@code CLEAR_CONFLICT}).
 */
public class UpdateMatchRequest {

    static final Set<String> CLEARABLE = Set.of("venue");

    @Size(min = 1, max = 120)
    public String opponentName;

    public HomeAway homeAway;
    public Instant scheduledAt;

    @Size(max = 200)
    public String venue;

    @Min(1) @Max(8)
    public Integer periodCount;

    @Min(1) @Max(60)
    public Integer periodMinutes;

    /** The raw {@code clear} member, validated by {@link #clearedProperties()}. */
    public JsonNode clear;

    /** @return the validated names in {@code clear}; 400 on a non-list, an unknown or duplicate name or a conflict */
    Set<String> clearedProperties() {
        if (clear == null || clear.isNull()) {
            return Set.of();
        }
        if (!clear.isArray()) {
            throw invalid("clear", "INVALID_VALUE", "clear must be a list of property names");
        }
        Set<String> names = new LinkedHashSet<>();
        for (JsonNode item : clear) {
            if (!item.isTextual() || !CLEARABLE.contains(item.asText())) {
                throw invalid("clear", "INVALID_VALUE", "clear may only name " + String.join(", ", CLEARABLE));
            }
            if (!names.add(item.asText())) {
                throw invalid("clear", "INVALID_VALUE", "clear names " + item.asText() + " twice");
            }
        }
        if (names.contains("venue") && venue != null) {
            throw invalid("venue", "CLEAR_CONFLICT", "venue is both given a value and named in clear");
        }
        return names;
    }

    boolean isEmpty() {
        return opponentName == null && homeAway == null && scheduledAt == null && venue == null && periodCount == null
                && periodMinutes == null;
    }

    private static InvalidRequestException invalid(String field, String code, String message) {
        return new InvalidRequestException(field, code, message);
    }
}
