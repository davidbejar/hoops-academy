package com.hoopsacademy.e2e.support;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.report.LevelResolver;
import com.atlassian.oai.validator.report.ValidationReport;
import com.atlassian.oai.validator.restassured.OpenApiValidationFilter;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Response validation against {@code libs/contracts/openapi/<service>.yaml} read from disk (no dependency on the
 * contracts module). Requests are not validated here (bearer auth is real, and some steps send deliberately invalid
 * bodies); every response of a validated call must match the contract.
 */
public final class Contracts {
    private static final Map<String, OpenApiValidationFilter> CACHE = new ConcurrentHashMap<>();

    private Contracts() {}

    /** @return the validating filter for the service owning {@code path}, or null for non-API paths. */
    public static OpenApiValidationFilter forPath(String path) {
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
        return CACHE.computeIfAbsent(file, f -> new OpenApiValidationFilter(
                OpenApiInteractionValidator.createForSpecificationUrl(E2eEnv.contractsDir().resolve(f + ".yaml").toUri().toString())
                        .withLevelResolver(LevelResolver.create()
                                .withLevel("validation.request", ValidationReport.Level.IGNORE)
                                .withLevel("validation.response.body.missing", ValidationReport.Level.WARN)
                                .build())
                        .build()));
    }
}
