package com.hoopsacademy.core.testsupport;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.report.LevelResolver;
import com.atlassian.oai.validator.report.ValidationReport;
import com.atlassian.oai.validator.restassured.OpenApiValidationFilter;

/** Validates every REST-assured exchange against {@code libs/contracts/openapi/core.yaml} (loaded from the jar). */
public final class Contract {

    private static final String SPEC = "/openapi/core.yaml";

    /**
     * Request AND response must match the contract. One known false positive is muted for REQUESTS only: the validator
     * reports "additionalProperties" for properties declared in a sibling {@code allOf} part (InviteMemberRequest =
     * PersonalData + roles). Responses keep the strict check, so an undeclared response field still fails.
     */
    public static final OpenApiValidationFilter CORE = new OpenApiValidationFilter(
            OpenApiInteractionValidator.createForSpecificationUrl(SPEC)
                    .withLevelResolver(LevelResolver.create()
                            .withLevel("validation.request.body.schema.additionalProperties",
                                    ValidationReport.Level.IGNORE)
                            .build())
                    .build());

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
     * For failure-path tests (identity provider down → 502, simulated database failure → 500): statuses the contract
     * does not declare are tolerated, everything else (Problem body, content type) is still validated.
     */
    public static final OpenApiValidationFilter FAILURES = new OpenApiValidationFilter(
            OpenApiInteractionValidator.createForSpecificationUrl(SPEC)
                    .withLevelResolver(LevelResolver.create()
                            .withLevel("validation.response.status.unknown", ValidationReport.Level.IGNORE)
                            .withLevel("validation.request.body.schema.additionalProperties",
                                    ValidationReport.Level.IGNORE)
                            .build())
                    .build());

    private Contract() {}
}
