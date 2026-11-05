package com.hoopsacademy.e2e.support;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.restassured.OpenApiValidationFilter;
import io.restassured.filter.Filter;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Request and response validation against {@code libs/contracts/openapi/<service>.yaml} read from disk (no dependency
 * on the contracts module), in the validator's default, strict configuration: the contracts are written so that it
 * applies (no allOf compositions, see StrictValidatorCompatibilityTest in libs/contracts), so every exchange of a
 * validated call, the match-event feed included, must match the contract exactly.
 */
public final class Contracts {
    private static final Map<String, Filter> CACHE = new ConcurrentHashMap<>();

    private Contracts() {}

    /** @return the validating filter for the service owning {@code path}, or null for non-API paths. */
    public static Filter forPath(String path) {
        String file;
        if (path.startsWith("/api/core/") || path.startsWith("/platform/")) {
            file = "core";
        } else if (path.startsWith("/api/game/")) {
            file = "game";
        } else if (path.startsWith("/api/athlete/")) {
            file = "athlete";
        } else {
            return null;
        }
        return CACHE.computeIfAbsent(file, f -> new OpenApiValidationFilter(OpenApiInteractionValidator
                .createForSpecificationUrl(E2eEnv.contractsDir().resolve(f + ".yaml").toUri().toString())
                .build()));
    }
}
