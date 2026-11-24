package com.hoopsacademy.common.testing;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.report.LevelResolver;
import com.atlassian.oai.validator.report.ValidationReport;
import com.atlassian.oai.validator.restassured.OpenApiValidationFilter;
import io.restassured.filter.Filter;

/**
 * REST Assured filters that validate every exchange against one OpenAPI file of {@code libs/contracts} (loaded from the
 * contracts jar, e.g. {@code /openapi/core.yaml}) in the validator's default, strict configuration: the contracts are
 * written so that it applies (no {@code allOf}, StrictValidatorCompatibilityTest), so an undeclared request or response
 * field fails the test. One home for core's, game's and athlete's modes (WP137, LIB-05, X-10).
 */
public final class ContractFilters {

    /**
     * The test caller is simulated ({@code @TenantUser}), so no real token is needed; this placeholder stands for the
     * bearer token every real client sends, so the contract's security requirement is checked as well.
     */
    public static final String SIMULATED_BEARER = "Bearer test";

    private final String spec;

    private ContractFilters(String spec) {
        this.spec = spec;
    }

    /** @param spec the contract on the classpath, e.g. {@code /openapi/game.yaml} */
    public static ContractFilters forSpec(String spec) {
        return new ContractFilters(spec);
    }

    /** Request and response must match the contract. */
    public OpenApiValidationFilter strict() {
        return new OpenApiValidationFilter(OpenApiInteractionValidator.createForSpecificationUrl(spec).build());
    }

    /**
     * For negative tests that send a request the contract forbids on purpose (wrong media type, oversize body, invalid
     * events): the request is not validated, the response still is.
     */
    public OpenApiValidationFilter responsesOnly() {
        return ignoring("validation.request");
    }

    /**
     * For fault-injection tests (a simulated database failure is a 500): a status no operation declares is tolerated,
     * everything else (request, Problem body, content type) is still validated.
     */
    public OpenApiValidationFilter toleratingUndeclaredStatus() {
        return ignoring("validation.response.status.unknown");
    }

    /** {@code validation} with the simulated bearer token added to a request that carries none. */
    public static Filter withSimulatedBearer(Filter validation) {
        return (request, response, context) -> {
            if (!request.getHeaders().hasHeaderWithName("Authorization")) {
                request.header("Authorization", SIMULATED_BEARER);
            }
            return validation.filter(request, response, context);
        };
    }

    private OpenApiValidationFilter ignoring(String level) {
        return new OpenApiValidationFilter(OpenApiInteractionValidator.createForSpecificationUrl(spec)
                .withLevelResolver(LevelResolver.create().withLevel(level, ValidationReport.Level.IGNORE).build())
                .build());
    }
}
