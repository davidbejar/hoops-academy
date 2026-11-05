package com.hoopsacademy.game.support;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.report.LevelResolver;
import com.atlassian.oai.validator.report.ValidationReport;
import com.atlassian.oai.validator.restassured.OpenApiValidationFilter;
import io.restassured.filter.Filter;

/**
 * Validates REST Assured exchanges against libs/contracts game.yaml, every MatchEvent included (the contract is
 * written so the validator's default, strict configuration applies: see StrictValidatorCompatibilityTest).
 */
public final class Contract {

    /**
     * The test caller is simulated ({@code @TenantUser} / TenantUserRegistry), so no real token is needed; the
     * placeholder sent here stands for the bearer token every real client sends, so the contract's security
     * requirement is checked as well.
     */
    private static final String SIMULATED_BEARER = "Bearer test";

    private static final OpenApiInteractionValidator STRICT =
            OpenApiInteractionValidator.createForSpecificationUrl("/openapi/game.yaml").build();

    /** Request and response must match the contract. */
    public static final Filter FILTER = withSimulatedBearer(new OpenApiValidationFilter(STRICT));

    /**
     * Response validation only: for batches that send invalid events on purpose (the server rejects them per event,
     * libs/contracts README).
     */
    public static final Filter RESPONSES_ONLY = withSimulatedBearer(new OpenApiValidationFilter(
            OpenApiInteractionValidator.createForSpecificationUrl("/openapi/game.yaml")
                    .withLevelResolver(LevelResolver.create()
                            .withLevel("validation.request", ValidationReport.Level.IGNORE)
                            .build())
                    .build()));

    private Contract() {}

    private static Filter withSimulatedBearer(OpenApiValidationFilter validation) {
        return (request, response, context) -> {
            if (!request.getHeaders().hasHeaderWithName("Authorization")) {
                request.header("Authorization", SIMULATED_BEARER);
            }
            return validation.filter(request, response, context);
        };
    }
}
