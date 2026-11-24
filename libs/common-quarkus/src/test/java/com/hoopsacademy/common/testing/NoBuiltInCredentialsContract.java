package com.hoopsacademy.common.testing;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Properties;
import java.util.Set;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;

/**
 * Secrets come only from the environment (CLAUDE.md rule 6, ADR-0012): outside the %test profile no password or
 * client secret of a service's shipped {@code application.properties} may carry a fallback such as
 * {@code ${X:change-me}} or an empty {@code ${X:}}: a missing variable must fail the start instead of connecting with a
 * guessable or empty credential. A service extends this class (WP137, X-10); an exemption names its key and the
 * decision that allows it.
 */
public abstract class NoBuiltInCredentialsContract {

    /** A credential key ends in password or secret ({@code hoops.temporary-password.ttl} is a duration, not one). */
    private static final Pattern SECRET_KEY = Pattern.compile("(?i).*[.-](password|secret)");
    private static final Pattern ENV_WITHOUT_FALLBACK = Pattern.compile("\\$\\{[A-Z0-9_]+}");

    /** Keys whose fallback a decision allows; none by default. */
    protected Set<String> exemptions() {
        return Set.of();
    }

    @Test
    void credentialsHaveNoFallbackValueOutsideTests() {
        Properties shipped = shipped();
        assertThat(shipped.stringPropertyNames())
                .filteredOn(key -> SECRET_KEY.matcher(key).matches() && !key.startsWith("%test."))
                .filteredOn(key -> !exemptions().contains(key))
                .allSatisfy(key -> assertThat(shipped.getProperty(key)).as(key).matches(ENV_WITHOUT_FALLBACK));
    }

    @Test
    void everyExemptionNamesAShippedKey() {
        assertThat(shipped().stringPropertyNames()).containsAll(exemptions());
    }

    private static Properties shipped() {
        Properties properties = new Properties();
        try (InputStream in = Files.newInputStream(Path.of("src/main/resources/application.properties"))) {
            properties.load(in);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        return properties;
    }
}
