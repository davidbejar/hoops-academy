package com.hoopsacademy.athlete.config;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;

/**
 * Secrets come only from the environment (CLAUDE.md rule 6, ADR-0012): outside the %test profile no password or
 * client secret may carry a fallback such as {@code ${X:change-me}} or an empty {@code ${X:}} — a missing variable
 * must fail the start instead of connecting with a guessable or empty credential.
 */
class NoBuiltInCredentialsTest {

    private static final Pattern SECRET_KEY = Pattern.compile("(?i).*(password|secret).*");
    private static final Pattern ENV_WITH_FALLBACK = Pattern.compile("\\$\\{[A-Z0-9_]+:[^}]*}");

    @Test
    void credentialsHaveNoFallbackValueOutsideTests() throws IOException {
        Properties properties = new Properties();
        try (InputStream in = getClass().getClassLoader().getResourceAsStream("application.properties")) {
            properties.load(in);
        }
        assertThat(properties.stringPropertyNames())
                .filteredOn(key -> SECRET_KEY.matcher(key).matches() && !key.startsWith("%test."))
                .allSatisfy(key -> assertThat(properties.getProperty(key))
                        .as(key).matches("\\$\\{[A-Z0-9_]+}")
                        .doesNotContainPattern(ENV_WITH_FALLBACK));
    }
}
