package com.hoopsacademy.contracts;

import io.swagger.v3.parser.OpenAPIV3Parser;
import io.swagger.v3.parser.core.models.ParseOptions;
import io.swagger.v3.parser.core.models.SwaggerParseResult;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Services load the contracts from the classpath; the relative $refs to common.yaml must resolve there too. Use a plain
 * classpath location ("/openapi/core.yaml"): swagger-parser cannot resolve relative refs from a {@code jar:} URL
 * (i.e. not {@code getResource(...).toString()}).
 */
class PackagedResourcesTest {

    @ParameterizedTest
    @ValueSource(strings = {"/openapi/common.yaml", "/openapi/core.yaml", "/openapi/game.yaml", "/openapi/athlete.yaml",
            "/events/match-event.schema.json", "/events/examples/match-events.valid.json"})
    void contractFileIsOnTheClasspath(String resource) {
        assertThat(PackagedResourcesTest.class.getResource(resource)).as(resource).isNotNull();
    }

    @ParameterizedTest
    @ValueSource(strings = {"core", "game", "athlete"})
    void specParsesFromItsClasspathLocationWithExternalRefsResolved(String service) {
        ParseOptions options = new ParseOptions();
        options.setResolve(true);

        SwaggerParseResult result = new OpenAPIV3Parser().readLocation("/openapi/" + service + ".yaml", null, options);

        assertThat(result.getMessages()).isEmpty();
        assertThat(result.getOpenAPI().getComponents().getSchemas()).containsKey("Problem");
    }
}
