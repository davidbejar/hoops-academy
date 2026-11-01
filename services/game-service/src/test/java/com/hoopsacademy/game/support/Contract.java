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

    private Contract() {}
}
