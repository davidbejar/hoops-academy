package com.hoopsacademy.game.support;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.report.LevelResolver;
import com.atlassian.oai.validator.report.ValidationReport;
import com.atlassian.oai.validator.restassured.OpenApiValidationFilter;

/** Validates REST Assured exchanges against libs/contracts game.yaml (bearer auth is simulated, so not checked). */
public final class Contract {

    public static final OpenApiValidationFilter FILTER = new OpenApiValidationFilter(
            OpenApiInteractionValidator.createForSpecificationUrl("/openapi/game.yaml")
                    .withLevelResolver(LevelResolver.create()
                            .withLevel("validation.request.security.missing", ValidationReport.Level.IGNORE)
                            .withLevel("validation.request.security.invalid", ValidationReport.Level.IGNORE)
                            .build())
                    .build());

    /**
     * Response validation only: for batches that send invalid events on purpose (the server rejects them per event,
     * libs/contracts README).
     */
    public static final OpenApiValidationFilter RESPONSES_ONLY = new OpenApiValidationFilter(
            OpenApiInteractionValidator.createForSpecificationUrl("/openapi/game.yaml")
                    .withLevelResolver(LevelResolver.create()
                            .withLevel("validation.request", ValidationReport.Level.IGNORE)
                            .build())
                    .build());

    /*
     * swagger-request-validator 3.0.0 cannot validate the contract's MatchEvent oneOf: it ignores the discriminator and
     * reports the errors of every non-matching branch (PERIOD_START/PERIOD_END and SUB_IN/SUB_OUT subtypes are even
     * structurally identical). Contract gap, see the WP7 handover. Hence two narrower filters:
     */

    /**
     * submitMatchEvents: the request body (MatchEvents only) is not validated here, the server validates every event
     * against events/match-event.schema.json and test bodies come from the codec that round-trips the contract
     * examples; the response (MatchEventBatchResult, no MatchEvent inside) is fully validated.
     */
    public static final OpenApiValidationFilter BATCH = new OpenApiValidationFilter(
            OpenApiInteractionValidator.createForSpecificationUrl("/openapi/game.yaml")
                    .withLevelResolver(LevelResolver.create()
                            .withLevel("validation.request.security.missing", ValidationReport.Level.IGNORE)
                            .withLevel("validation.request.security.invalid", ValidationReport.Level.IGNORE)
                            .withLevel("validation.request.body", ValidationReport.Level.IGNORE)
                            .build())
                    .build());

    /**
     * listMatchEvents: path, parameters, status and content type are validated; the body schema is checked by
     * {@link EventSchema#assertValidFeed} (envelope fields + every event against the JSON Schema).
     */
    public static final OpenApiValidationFilter FEED = new OpenApiValidationFilter(
            OpenApiInteractionValidator.createForSpecificationUrl("/openapi/game.yaml")
                    .withLevelResolver(LevelResolver.create()
                            .withLevel("validation.request.security.missing", ValidationReport.Level.IGNORE)
                            .withLevel("validation.request.security.invalid", ValidationReport.Level.IGNORE)
                            .withLevel("validation.response.body.schema", ValidationReport.Level.IGNORE)
                            .build())
                    .build());

    private Contract() {}
}
