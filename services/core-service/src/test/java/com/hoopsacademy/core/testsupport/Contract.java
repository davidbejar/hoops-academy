package com.hoopsacademy.core.testsupport;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.report.LevelResolver;
import com.atlassian.oai.validator.report.ValidationReport;
import com.atlassian.oai.validator.restassured.OpenApiValidationFilter;

/**
 * Validates every REST-assured exchange against {@code libs/contracts/openapi/core.yaml} (loaded from the jar) with
 * the validator's default, strict configuration: the contract is written so that it applies (no {@code allOf}
 * compositions, see StrictValidatorCompatibilityTest), so an undeclared request or response field fails the test.
 */
public final class Contract {

    private static final String SPEC = "/openapi/core.yaml";

    /** Request AND response must match the contract. */
    public static final OpenApiValidationFilter CORE = new OpenApiValidationFilter(
            OpenApiInteractionValidator.createForSpecificationUrl(SPEC).build());

    /**
     * For negative tests that send a request the contract forbids on purpose (wrong media type, oversize body):
     * the request is not validated, the response still is.
     */
    public static final OpenApiValidationFilter RESPONSES_ONLY = new OpenApiValidationFilter(
            OpenApiInteractionValidator.createForSpecificationUrl(SPEC)
                    .withLevelResolver(LevelResolver.create()
                            .withLevel("validation.request", ValidationReport.Level.IGNORE)
                            .build())
                    .build());

    /**
     * For fault-injection tests (simulated database failure → 500): a status no operation declares is tolerated,
     * everything else (request, Problem body, content type) is still validated. Declared failures such as 502
     * IDENTITY_PROVIDER_UNAVAILABLE use {@link #CORE}.
     */
    public static final OpenApiValidationFilter UNEXPECTED_FAILURE = new OpenApiValidationFilter(
            OpenApiInteractionValidator.createForSpecificationUrl(SPEC)
                    .withLevelResolver(LevelResolver.create()
                            .withLevel("validation.response.status.unknown", ValidationReport.Level.IGNORE)
                            .build())
                    .build());

    private Contract() {}
}
