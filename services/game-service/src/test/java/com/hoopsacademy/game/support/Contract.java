package com.hoopsacademy.game.support;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.report.LevelResolver;
import com.atlassian.oai.validator.report.ValidationReport;
import com.atlassian.oai.validator.restassured.OpenApiValidationFilter;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Validates REST Assured exchanges against libs/contracts game.yaml (bearer auth is simulated, so not checked). */
public final class Contract {

    /** A variant's fixed type as written in game.yaml (initialised first: {@link #EVENTS} needs it). */
    private static final Pattern VARIANT_TYPE = Pattern.compile(
            "type:\\n\\s+allOf: \\[\\{\\$ref: '#/components/schemas/MatchEventType'}]\\n\\s+enum: \\[([A-Z_]+)]");

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

    /**
     * submitMatchEvents with valid events and listMatchEvents: request AND response fully validated, every MatchEvent
     * included. Each variant fixes its {@code type} in game.yaml as {@code allOf: [MatchEventType]} + {@code enum: [X]}
     * (the form dart-dio generates correctly). swagger-request-validator only discriminates the oneOf once combinators
     * are resolved, and resolving drops that sibling {@code enum}; so this filter reads a derived copy of the contract
     * in which each variant's type is spelled {@code {type: string, enum: [X]}} — the same constraint, see
     * {@link #eventsSpecification()}. Not used for the other operations: resolving combinators drops {@code nullable}
     * from allOf-wrapped fields such as {@code jerseyNumber} (libs/contracts README). Batches with invalid events on
     * purpose use {@link #RESPONSES_ONLY}.
     */
    public static final OpenApiValidationFilter EVENTS = new OpenApiValidationFilter(
            OpenApiInteractionValidator.createForSpecificationUrl(eventsSpecification())
                    .withResolveCombinators(true)
                    .withLevelResolver(LevelResolver.create()
                            .withLevel("validation.request.security.missing", ValidationReport.Level.IGNORE)
                            .withLevel("validation.request.security.invalid", ValidationReport.Level.IGNORE)
                            .build())
                    .build());

    /** game.yaml (+ common.yaml) from the contracts jar with each variant's fixed type spelled as a plain enum. */
    static String eventsSpecification() {
        try {
            Path dir = Files.createTempDirectory("game-contract");
            String game = resource("/openapi/game.yaml");
            Matcher matcher = VARIANT_TYPE.matcher(game);
            if (!matcher.find()) {
                throw new IllegalStateException("game.yaml no longer fixes the MatchEvent variant types as expected");
            }
            Files.writeString(dir.resolve("game.yaml"), matcher.replaceAll("type: {type: string, enum: [$1]}"));
            Files.writeString(dir.resolve("common.yaml"), resource("/openapi/common.yaml"));
            return dir.resolve("game.yaml").toString();
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    private static String resource(String name) throws IOException {
        try (InputStream in = Contract.class.getResourceAsStream(name)) {
            if (in == null) {
                throw new IllegalStateException(name + " not on the test classpath (contracts jar)");
            }
            return new String(in.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    /** submitMatchEvents (see {@link #EVENTS}). */
    public static final OpenApiValidationFilter BATCH = EVENTS;

    /** listMatchEvents (see {@link #EVENTS}). */
    public static final OpenApiValidationFilter FEED = EVENTS;

    private Contract() {}
}
